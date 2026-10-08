local AddOn = _G[select(1, ...)]
--------------------------------
local LOGIN_PING_MIN = 10
local LOGIN_PING_SPAN = 30
local PERIODIC_DIGEST = 12 * 60
local PERIODIC_JITTER = 60
local TAXI_DIGEST_GAP = 60
local PEER_TTL = 15 * 60
local PEER_DIGEST_DELAY_MIN = 2
local PEER_DIGEST_DELAY_MAX = 5
local BATCH_ENCODE_LEVEL = 6
local Q_CHUNK = 8
local MAX_IN_INDICES = 32
local MAX_IN_RECS = 32
local MAX_IN_PATH_GET = 8
local BUCKET_COUNT = 32
local TIME_REPLY_GAP = 0.3
local PATH_REPLY_GAP = 0.5

local started
local digestTimer
local periodicTimer
local lastDigestWhisper = 0
local peers = {}
local peerDigestPending = {}
local lastRumorAt
local lastRumorKind
local lastMismatch
local syncInfoEnabled = false
local timeReplyQueue = {}
local pathReplyQueue = {}
local replyBusy = false
--------------------------------
function AddOn:IsSyncInfoEnabled()
	return syncInfoEnabled == true
end
--------------------------------
function AddOn:ToggleSyncInfo()
	syncInfoEnabled = not syncInfoEnabled
	local state = syncInfoEnabled and AddOn.L.on or AddOn.L.off
	AddOn:Print(string.format(AddOn.L.syncInfoToggled, state))
end
--------------------------------
function AddOn:LogSyncFlightReceived(kind, originID, destID, detail, stored)
	if not syncInfoEnabled then
		return
	end
	local kept = stored and AddOn.L.syncInfoStored or AddOn.L.syncInfoIgnored
	if kind == "p" then
		AddOn:Print(string.format(AddOn.L.syncInfoPath, originID, destID, detail, kept))
	else
		AddOn:Print(string.format(AddOn.L.syncInfoTime, originID, destID, detail, kept))
	end
end
--------------------------------
local function notePeer(sender)
	if type(sender) ~= "string" or sender == "" then
		return
	end
	local isNew = peers[sender] == nil
	peers[sender] = GetTime()
	if isNew and not peerDigestPending[sender] then
		peerDigestPending[sender] = true
		AddOn.Timer:ScheduleTimer(function()
			peerDigestPending[sender] = nil
			if started and AddOn:GetShareFlightData() then
				AddOn:WhisperSyncDigests(sender)
			end
		end, math.random(PEER_DIGEST_DELAY_MIN, PEER_DIGEST_DELAY_MAX))
	end
end
--------------------------------
local function peerCount()
	local n = 0
	for _ in pairs(peers) do
		n = n + 1
	end
	return n
end
--------------------------------
local function randomRecentPeer()
	local now = GetTime()
	local list = {}
	for name, seen in pairs(peers) do
		if now - seen <= PEER_TTL then
			list[#list + 1] = name
		end
	end
	if #list < 1 then
		return nil
	end
	return list[math.random(1, #list)]
end
--------------------------------
local function pumpReplyQueue()
	if replyBusy then
		return
	end
	local job
	local delay = TIME_REPLY_GAP
	if #timeReplyQueue > 0 then
		job = table.remove(timeReplyQueue, 1)
		delay = TIME_REPLY_GAP
	elseif #pathReplyQueue > 0 then
		job = table.remove(pathReplyQueue, 1)
		delay = PATH_REPLY_GAP
	end
	if not job then
		return
	end
	replyBusy = true
	job()
	AddOn.Timer:ScheduleTimer(function()
		replyBusy = false
		pumpReplyQueue()
	end, delay)
end
--------------------------------
local function enqueueTimeReply(fn)
	timeReplyQueue[#timeReplyQueue + 1] = fn
	pumpReplyQueue()
end
--------------------------------
local function enqueuePathReply(fn)
	pathReplyQueue[#pathReplyQueue + 1] = fn
	pumpReplyQueue()
end
--------------------------------
local function sendBatches(msgBuilder, recs, target, pathKind)
	if type(recs) ~= "table" or #recs < 1 or type(target) ~= "string" then
		return
	end
	local enqueue = pathKind and enqueuePathReply or enqueueTimeReply
	local batch = {}
	local function flush()
		if #batch < 1 then
			return
		end
		local copy = {}
		for i = 1, #batch do
			copy[i] = batch[i]
		end
		local builder = msgBuilder
		enqueue(function()
			AddOn:WhisperSyncMessage(builder(copy), target, BATCH_ENCODE_LEVEL)
		end)
		batch = {}
	end
	for i = 1, #recs do
		batch[#batch + 1] = recs[i]
		local trial = msgBuilder(batch)
		local encoded = AddOn:SyncEncode(trial, BATCH_ENCODE_LEVEL)
		if not encoded or #encoded > AddOn:SyncMaxEncoded() then
			batch[#batch] = nil
			if #batch < 1 then
				batch = { recs[i] }
				flush()
			else
				flush()
				batch[1] = recs[i]
			end
		end
	end
	flush()
end
--------------------------------
local function recordCounts()
	if AddOn.CountKnownFlightData then
		return AddOn:CountKnownFlightData()
	end
	return 0, 0
end
--------------------------------
function AddOn:BuildTimeDigestMessage()
	local root, buckets = AddOn:GetSyncTimeDigest()
	local times = recordCounts()
	return {
		t = "D",
		k = "t",
		r = root,
		n = times,
		b = AddOn:PackBucketHashes(buckets),
	}
end
--------------------------------
function AddOn:BuildPathDigestMessage()
	local root, buckets = AddOn:GetSyncPathDigest()
	local _, paths = recordCounts()
	return {
		t = "D",
		k = "p",
		r = root,
		n = paths,
		b = AddOn:PackBucketHashes(buckets),
	}
end
--------------------------------
function AddOn:AnnounceSyncPresence()
	if not started or not AddOn:GetShareFlightData() then
		return
	end
	AddOn:BroadcastSyncMessage({ t = "P" }, 1)
end
--------------------------------
function AddOn:WhisperSyncDigests(target)
	if not started or not AddOn:GetShareFlightData() or type(target) ~= "string" then
		return
	end
	AddOn:WhisperSyncMessage(AddOn:BuildTimeDigestMessage(), target, 1)
	if AddOn:GetShareFlightPaths() then
		AddOn:WhisperSyncMessage(AddOn:BuildPathDigestMessage(), target, 1)
	end
	lastDigestWhisper = GetTime()
end
--------------------------------
function AddOn:WhisperSyncDigestsToRandomPeer()
	local peer = randomRecentPeer()
	if peer then
		AddOn:WhisperSyncDigests(peer)
		return true
	end
	AddOn:AnnounceSyncPresence()
	return false
end
--------------------------------
local function schedulePeriodicAntiEntropy()
	if periodicTimer then
		AddOn.Timer:CancelTimer(periodicTimer)
		periodicTimer = nil
	end
	if not started then
		return
	end
	periodicTimer = AddOn.Timer:ScheduleTimer(function()
		periodicTimer = nil
		if started and AddOn:GetShareFlightData() then
			AddOn:WhisperSyncDigestsToRandomPeer()
			schedulePeriodicAntiEntropy()
		end
	end, PERIODIC_DIGEST + math.random(0, PERIODIC_JITTER))
end
--------------------------------
local function handleRumor(msg, sender)
	local applied = false
	if msg.k == "t" then
		applied = AddOn:MergeRemoteFlightTime(msg.o, msg.d, msg.s, msg.n, msg.h)
		if applied then
			AddOn:InfectFlightRumor("t", msg.o, msg.d)
		end
	elseif msg.k == "p" then
		if not AddOn:GetShareFlightPaths() then
			return
		end
		applied = AddOn:MergeRemoteFlightPath(msg.o, msg.d, msg.n, msg.i, msg.p, msg.h)
		if applied then
			AddOn:InfectFlightRumor("p", msg.o, msg.d)
		end
	end
	if applied then
		lastRumorAt = GetTime()
		lastRumorKind = msg.k
		AddOn:InvalidateSyncMerkle()
	end
end
--------------------------------
local function handleDigest(msg, sender)
	if msg.k == "p" and not AddOn:GetShareFlightPaths() then
		return
	end
	local localRoot, localBuckets
	if msg.k == "p" then
		localRoot, localBuckets = AddOn:GetSyncPathDigest()
	else
		localRoot, localBuckets = AddOn:GetSyncTimeDigest()
	end
	if msg.r == localRoot then
		return
	end
	if type(msg.b) == "string" and AddOn:SyncAdler32(msg.b) ~= msg.r then
		return
	end
	local remoteN = tonumber(msg.n) or 0
	local times, paths = recordCounts()
	local localN = times
	if msg.k == "p" then
		localN = paths
	end
	if remoteN == 0 and localN > 0 then
		return
	end
	local diff = AddOn:DifferingBuckets(localBuckets, msg.b)
	if not diff or #diff < 1 then
		return
	end
	lastMismatch = #diff
	local kind = msg.k == "p" and "p" or "t"
	for i = 1, #diff, Q_CHUNK do
		local chunk = {}
		for j = i, math.min(i + Q_CHUNK - 1, #diff) do
			chunk[#chunk + 1] = diff[j]
		end
		AddOn:WhisperSyncMessage({ t = "Q", k = kind, i = chunk }, sender, 1)
	end
end
--------------------------------
local function handleBucketQuery(msg, sender)
	local indices = msg.i
	if type(indices) ~= "table" then
		return
	end
	local n = math.min(#indices, MAX_IN_INDICES)
	if msg.k == "p" then
		if not AddOn:GetShareFlightPaths() then
			return
		end
		for i = 1, n do
			local idx = tonumber(indices[i])
			if idx and idx == math.floor(idx) and idx >= 1 and idx <= BUCKET_COUNT then
				local recs = AddOn:CollectSyncBucketPathKeys(idx)
				if recs and #recs > 0 then
					sendBatches(function(batch)
						return { t = "K", k = "p", n = idx, e = batch }
					end, recs, sender, true)
				end
			end
		end
		return
	end
	for i = 1, n do
		local idx = tonumber(indices[i])
		if idx and idx == math.floor(idx) and idx >= 1 and idx <= BUCKET_COUNT then
			local recs = AddOn:CollectSyncBucketTimes(idx)
			if recs and #recs > 0 then
				sendBatches(function(batch)
					return { t = "A", k = "t", recs = batch }
				end, recs, sender, false)
			end
		end
	end
end
--------------------------------
local function handleTimeBatch(msg)
	local recs = msg.recs
	if type(recs) ~= "table" then
		return
	end
	local any = false
	for i = 1, math.min(#recs, MAX_IN_RECS) do
		local r = recs[i]
		if type(r) == "table" then
			if AddOn:MergeRemoteFlightTime(r.o, r.d, r.s, r.n, r.h) then
				any = true
			end
		end
	end
	if any then
		AddOn:InvalidateSyncMerkle()
	end
end
--------------------------------
local function handlePathKeys(msg, sender)
	if not AddOn:GetShareFlightPaths() then
		return
	end
	local entries = msg.e
	if type(entries) ~= "table" then
		return
	end
	local want = {}
	for i = 1, math.min(#entries, MAX_IN_RECS) do
		local e = entries[i]
		if type(e) == "table" then
			local o, d = tonumber(e.o), tonumber(e.d)
			if o and d then
				local samples, n = AddOn:GetFlightPathMeta(o, d)
				local have
				if samples then
					local inst, pts = AddOn:QuantizePathPoints(samples)
					if pts then
						have = AddOn:HashFlightPathPoints(o, d, n, inst, pts)
					end
				end
				if have ~= e.h then
					want[#want + 1] = { o = o, d = d }
				end
			end
		end
	end
	if #want > 0 then
		sendBatches(function(batch)
			return { t = "G", k = "p", e = batch }
		end, want, sender, true)
	end
end
--------------------------------
local function handleGetPath(msg, sender)
	if not AddOn:GetShareFlightPaths() then
		return
	end
	local entries = msg.e
	if type(entries) ~= "table" then
		return
	end
	for i = 1, math.min(#entries, MAX_IN_PATH_GET) do
		local e = entries[i]
		if type(e) == "table" then
			local o, d = tonumber(e.o), tonumber(e.d)
			local samples, n = AddOn:GetFlightPathMeta(o, d)
			if samples then
				local inst, pts = AddOn:QuantizePathPoints(samples)
				if pts then
					local origin, dest, sampleN = o, d, n
					enqueuePathReply(function()
						AddOn:WhisperSyncMessage({
							t = "R",
							k = "p",
							o = origin,
							d = dest,
							n = sampleN,
							i = inst,
							p = pts,
							h = AddOn:HashFlightPathPoints(origin, dest, sampleN, inst, pts),
						}, sender, BATCH_ENCODE_LEVEL)
					end)
				end
			end
		end
	end
end
--------------------------------
function AddOn:HandleFlightSyncMessage(msg, distribution, sender)
	if type(msg) ~= "table" or type(sender) ~= "string" then
		return
	end
	notePeer(sender)
	local t = msg.t
	if t == "P" then
		return
	elseif t == "O" then
		return
	elseif t == "R" then
		handleRumor(msg, sender)
	elseif t == "D" then
		handleDigest(msg, sender)
	elseif t == "Q" then
		handleBucketQuery(msg, sender)
	elseif t == "A" then
		handleTimeBatch(msg)
	elseif t == "K" then
		handlePathKeys(msg, sender)
	elseif t == "G" then
		handleGetPath(msg, sender)
	end
end
--------------------------------
function AddOn:OnLocalFlightObservation(kind, originID, destID)
	AddOn:InvalidateSyncMerkle()
	if not started or not AddOn:GetShareFlightData() then
		return
	end
	AddOn:InfectFlightRumor(kind, originID, destID)
end
--------------------------------
function AddOn:NotifySyncTaxiMapOpened()
	if not started then
		AddOn:StartFlightSync()
	end
	if not started or not AddOn:GetShareFlightData() then
		return
	end
	local now = GetTime()
	if now - lastDigestWhisper < TAXI_DIGEST_GAP then
		return
	end
	AddOn:WhisperSyncDigestsToRandomPeer()
end
--------------------------------
function AddOn:PrintSyncStatus()
	local root = select(1, AddOn:GetSyncTimeDigest())
	local pathRoot = select(1, AddOn:GetSyncPathDigest())
	local channel = AddOn:GetSyncChannelId() or 0
	AddOn:Print(
		string.format(
			"sync share=%s paths=%s era=%s faction=%s channel=%s peers=%d rumors=%d timeRoot=%s pathRoot=%s mismatch=%s lastRumor=%s",
			tostring(not not AddOn:GetShareFlightData()),
			tostring(not not AddOn:GetShareFlightPaths()),
			tostring(AddOn:GetClientFamily()),
			tostring(AddOn:GetSyncFaction() or "-"),
			tostring(channel),
			peerCount(),
			AddOn:GetSyncRumorCount(),
			tostring(root or "-"),
			tostring(pathRoot or "-"),
			tostring(lastMismatch or "-"),
			lastRumorKind and (lastRumorKind .. "@" .. math.floor(GetTime() - (lastRumorAt or 0)) .. "s") or "-"
		)
	)
	if started and AddOn:GetShareFlightData() then
		AddOn:AnnounceSyncPresence()
	end
end
--------------------------------
function AddOn:StartFlightSync()
	if started then
		return
	end
	if not AddOn:GetShareFlightData() then
		return
	end
	if not AddOn:GetSyncFaction() then
		return
	end
	started = true
	AddOn:JoinSyncChannel()
	AddOn:StartSyncGossip()
	if digestTimer then
		AddOn.Timer:CancelTimer(digestTimer)
	end
	digestTimer = AddOn.Timer:ScheduleTimer(function()
		digestTimer = nil
		AddOn:AnnounceSyncPresence()
	end, LOGIN_PING_MIN + math.random(0, LOGIN_PING_SPAN))
	schedulePeriodicAntiEntropy()
end
--------------------------------
function AddOn:StopFlightSync()
	started = false
	AddOn:StopSyncGossip()
	AddOn:LeaveSyncChannel()
	if digestTimer then
		AddOn.Timer:CancelTimer(digestTimer)
		digestTimer = nil
	end
	if periodicTimer then
		AddOn.Timer:CancelTimer(periodicTimer)
		periodicTimer = nil
	end
	wipe(peers)
	wipe(peerDigestPending)
	wipe(timeReplyQueue)
	wipe(pathReplyQueue)
	replyBusy = false
end
--------------------------------
function AddOn:InitSync()
	AddOn:InitSyncTransport()
	AddOn:AddMessageHandler(AddOn.Message.ENABLE_ADDON, function()
		AddOn:StartFlightSync()
	end)
	AddOn:AddMessageHandler(AddOn.Message.DISABLE_ADDON, function()
		AddOn:StopFlightSync()
	end)
	AddOn:StartFlightSync()
end
