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

local syncInfoEnabled = false
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
local function timerLib(self)
	return self.Timer or AddOn.Timer
end
--------------------------------
local function notePeer(self, sender)
	if type(sender) ~= "string" or sender == "" then
		return
	end
	local s = self:EnsureSyncState()
	local isNew = s.peers[sender] == nil
	s.peers[sender] = GetTime()
	if isNew and not s.peerDigestPending[sender] then
		s.peerDigestPending[sender] = true
		timerLib(self):ScheduleTimer(function()
			s.peerDigestPending[sender] = nil
			if s.started and self:GetShareFlightData() then
				self:WhisperSyncDigests(sender)
			end
		end, math.random(PEER_DIGEST_DELAY_MIN, PEER_DIGEST_DELAY_MAX))
	end
end
--------------------------------
local function peerCount(self)
	local n = 0
	for _ in pairs(self:EnsureSyncState().peers) do
		n = n + 1
	end
	return n
end
--------------------------------
local function randomRecentPeer(self)
	local now = GetTime()
	local list = {}
	for name, seen in pairs(self:EnsureSyncState().peers) do
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
local function pumpReplyQueue(self)
	local s = self:EnsureSyncState()
	if s.replyBusy then
		return
	end
	local job
	local delay = TIME_REPLY_GAP
	if #s.timeReplyQueue > 0 then
		job = table.remove(s.timeReplyQueue, 1)
		delay = TIME_REPLY_GAP
	elseif #s.pathReplyQueue > 0 then
		job = table.remove(s.pathReplyQueue, 1)
		delay = PATH_REPLY_GAP
	end
	if not job then
		return
	end
	s.replyBusy = true
	job()
	timerLib(self):ScheduleTimer(function()
		s.replyBusy = false
		pumpReplyQueue(self)
	end, delay)
end
--------------------------------
local function enqueueTimeReply(self, fn)
	local s = self:EnsureSyncState()
	s.timeReplyQueue[#s.timeReplyQueue + 1] = fn
	pumpReplyQueue(self)
end
--------------------------------
local function enqueuePathReply(self, fn)
	local s = self:EnsureSyncState()
	s.pathReplyQueue[#s.pathReplyQueue + 1] = fn
	pumpReplyQueue(self)
end
--------------------------------
local function sendBatches(self, msgBuilder, recs, target, pathKind)
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
		enqueue(self, function()
			self:WhisperSyncMessage(builder(copy), target, BATCH_ENCODE_LEVEL)
		end)
		batch = {}
	end
	for i = 1, #recs do
		batch[#batch + 1] = recs[i]
		local trial = msgBuilder(batch)
		local encoded = self:SyncEncode(trial, BATCH_ENCODE_LEVEL)
		if not encoded or #encoded > self:SyncMaxEncoded() then
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
local function recordCounts(self)
	if self.CountKnownFlightData then
		return self:CountKnownFlightData()
	end
	return 0, 0
end
--------------------------------
function AddOn:BuildTimeDigestMessage()
	local root, buckets = self:GetSyncTimeDigest()
	local times = recordCounts(self)
	return {
		t = "D",
		k = "t",
		r = root,
		n = times,
		b = self:PackBucketHashes(buckets),
	}
end
--------------------------------
function AddOn:BuildPathDigestMessage()
	local root, buckets = self:GetSyncPathDigest()
	local _, paths = recordCounts(self)
	return {
		t = "D",
		k = "p",
		r = root,
		n = paths,
		b = self:PackBucketHashes(buckets),
	}
end
--------------------------------
function AddOn:AnnounceSyncPresence()
	local s = self:EnsureSyncState()
	if not s.started or not self:GetShareFlightData() then
		return
	end
	self:BroadcastSyncMessage({ t = "P" }, 1)
end
--------------------------------
function AddOn:WhisperSyncDigests(target)
	local s = self:EnsureSyncState()
	if not s.started or not self:GetShareFlightData() or type(target) ~= "string" then
		return
	end
	self:WhisperSyncMessage(self:BuildTimeDigestMessage(), target, 1)
	if self:GetShareFlightPaths() then
		self:WhisperSyncMessage(self:BuildPathDigestMessage(), target, 1)
	end
	s.lastDigestWhisper = GetTime()
end
--------------------------------
function AddOn:WhisperSyncDigestsToRandomPeer()
	local peer = randomRecentPeer(self)
	if peer then
		self:WhisperSyncDigests(peer)
		return true
	end
	self:AnnounceSyncPresence()
	return false
end
--------------------------------
local function schedulePeriodicAntiEntropy(self)
	local s = self:EnsureSyncState()
	if s.periodicTimer then
		timerLib(self):CancelTimer(s.periodicTimer)
		s.periodicTimer = nil
	end
	if not s.started then
		return
	end
	s.periodicTimer = timerLib(self):ScheduleTimer(function()
		s.periodicTimer = nil
		if s.started and self:GetShareFlightData() then
			self:WhisperSyncDigestsToRandomPeer()
			schedulePeriodicAntiEntropy(self)
		end
	end, PERIODIC_DIGEST + math.random(0, PERIODIC_JITTER))
end
--------------------------------
local function handleRumor(self, msg)
	local applied = false
	if msg.k == "t" then
		applied = self:MergeRemoteFlightTime(msg.o, msg.d, msg.s, msg.n, msg.h)
		if applied then
			self:InfectFlightRumor("t", msg.o, msg.d)
		end
	elseif msg.k == "p" then
		if not self:GetShareFlightPaths() then
			return
		end
		applied = self:MergeRemoteFlightPath(msg.o, msg.d, msg.n, msg.i, msg.p, msg.h)
		if applied then
			self:InfectFlightRumor("p", msg.o, msg.d)
		end
	end
	if applied then
		local s = self:EnsureSyncState()
		s.lastRumorAt = GetTime()
		s.lastRumorKind = msg.k
		self:InvalidateSyncMerkle()
	end
end
--------------------------------
local function handleDigest(self, msg, sender)
	if msg.k == "p" and not self:GetShareFlightPaths() then
		return
	end
	local localRoot, localBuckets
	if msg.k == "p" then
		localRoot, localBuckets = self:GetSyncPathDigest()
	else
		localRoot, localBuckets = self:GetSyncTimeDigest()
	end
	if msg.r == localRoot then
		return
	end
	if type(msg.b) == "string" and self:SyncAdler32(msg.b) ~= msg.r then
		return
	end
	local remoteN = tonumber(msg.n) or 0
	local times, paths = recordCounts(self)
	local localN = times
	if msg.k == "p" then
		localN = paths
	end
	if remoteN == 0 and localN > 0 then
		return
	end
	local diff = self:DifferingBuckets(localBuckets, msg.b)
	if not diff or #diff < 1 then
		return
	end
	self:EnsureSyncState().lastMismatch = #diff
	local kind = msg.k == "p" and "p" or "t"
	for i = 1, #diff, Q_CHUNK do
		local chunk = {}
		for j = i, math.min(i + Q_CHUNK - 1, #diff) do
			chunk[#chunk + 1] = diff[j]
		end
		self:WhisperSyncMessage({ t = "Q", k = kind, i = chunk }, sender, 1)
	end
end
--------------------------------
local function handleBucketQuery(self, msg, sender)
	local indices = msg.i
	if type(indices) ~= "table" then
		return
	end
	local n = math.min(#indices, MAX_IN_INDICES)
	if msg.k == "p" then
		if not self:GetShareFlightPaths() then
			return
		end
		for i = 1, n do
			local idx = tonumber(indices[i])
			if idx and idx == math.floor(idx) and idx >= 1 and idx <= BUCKET_COUNT then
				local recs = self:CollectSyncBucketPathKeys(idx)
				if recs and #recs > 0 then
					sendBatches(self, function(batch)
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
			local recs = self:CollectSyncBucketTimes(idx)
			if recs and #recs > 0 then
				sendBatches(self, function(batch)
					return { t = "A", k = "t", recs = batch }
				end, recs, sender, false)
			end
		end
	end
end
--------------------------------
local function handleTimeBatch(self, msg)
	local recs = msg.recs
	if type(recs) ~= "table" then
		return
	end
	local any = false
	for i = 1, math.min(#recs, MAX_IN_RECS) do
		local r = recs[i]
		if type(r) == "table" then
			if self:MergeRemoteFlightTime(r.o, r.d, r.s, r.n, r.h) then
				any = true
			end
		end
	end
	if any then
		self:InvalidateSyncMerkle()
	end
end
--------------------------------
local function handlePathKeys(self, msg, sender)
	if not self:GetShareFlightPaths() then
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
				local samples, n = self:GetFlightPathMeta(o, d)
				local have
				if samples then
					local inst, pts = self:QuantizePathPoints(samples)
					if pts then
						have = self:HashFlightPathPoints(o, d, n, inst, pts)
					end
				end
				if have ~= e.h then
					want[#want + 1] = { o = o, d = d }
				end
			end
		end
	end
	if #want > 0 then
		sendBatches(self, function(batch)
			return { t = "G", k = "p", e = batch }
		end, want, sender, true)
	end
end
--------------------------------
local function handleGetPath(self, msg, sender)
	if not self:GetShareFlightPaths() then
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
			local samples, n = self:GetFlightPathMeta(o, d)
			if samples then
				local inst, pts = self:QuantizePathPoints(samples)
				if pts then
					local origin, dest, sampleN = o, d, n
					enqueuePathReply(self, function()
						self:WhisperSyncMessage({
							t = "R",
							k = "p",
							o = origin,
							d = dest,
							n = sampleN,
							i = inst,
							p = pts,
							h = self:HashFlightPathPoints(origin, dest, sampleN, inst, pts),
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
	notePeer(self, sender)
	local t = msg.t
	if t == "P" then
		return
	elseif t == "O" then
		return
	elseif t == "R" then
		handleRumor(self, msg)
	elseif t == "D" then
		handleDigest(self, msg, sender)
	elseif t == "Q" then
		handleBucketQuery(self, msg, sender)
	elseif t == "A" then
		handleTimeBatch(self, msg)
	elseif t == "K" then
		handlePathKeys(self, msg, sender)
	elseif t == "G" then
		handleGetPath(self, msg, sender)
	end
end
--------------------------------
function AddOn:OnLocalFlightObservation(kind, originID, destID)
	self:InvalidateSyncMerkle()
	local s = self:EnsureSyncState()
	if not s.started or not self:GetShareFlightData() then
		return
	end
	self:InfectFlightRumor(kind, originID, destID)
end
--------------------------------
function AddOn:NotifySyncTaxiMapOpened()
	local s = self:EnsureSyncState()
	if not s.started then
		self:StartFlightSync()
	end
	s = self:EnsureSyncState()
	if not s.started or not self:GetShareFlightData() then
		return
	end
	local now = GetTime()
	if now - s.lastDigestWhisper < TAXI_DIGEST_GAP then
		return
	end
	self:WhisperSyncDigestsToRandomPeer()
end
--------------------------------
function AddOn:PrintSyncStatus()
	local s = self:EnsureSyncState()
	local root = select(1, self:GetSyncTimeDigest())
	local pathRoot = select(1, self:GetSyncPathDigest())
	local channel = self:GetSyncChannelId() or 0
	self:Print(
		string.format(
			"sync share=%s paths=%s era=%s faction=%s channel=%s peers=%d rumors=%d timeRoot=%s pathRoot=%s mismatch=%s lastRumor=%s",
			tostring(not not self:GetShareFlightData()),
			tostring(not not self:GetShareFlightPaths()),
			tostring(self:GetClientFamily()),
			tostring(self:GetSyncFaction() or "-"),
			tostring(channel),
			peerCount(self),
			self:GetSyncRumorCount(),
			tostring(root or "-"),
			tostring(pathRoot or "-"),
			tostring(s.lastMismatch or "-"),
			s.lastRumorKind and (s.lastRumorKind .. "@" .. math.floor(GetTime() - (s.lastRumorAt or 0)) .. "s") or "-"
		)
	)
	if s.started and self:GetShareFlightData() then
		self:AnnounceSyncPresence()
	end
end
--------------------------------
function AddOn:StartFlightSync()
	local s = self:EnsureSyncState()
	if s.started then
		return
	end
	if not self:GetShareFlightData() then
		return
	end
	if not self:GetSyncFaction() then
		return
	end
	s.started = true
	self:JoinSyncChannel()
	self:StartSyncGossip()
	if s.digestTimer then
		timerLib(self):CancelTimer(s.digestTimer)
	end
	s.digestTimer = timerLib(self):ScheduleTimer(function()
		s.digestTimer = nil
		self:AnnounceSyncPresence()
	end, LOGIN_PING_MIN + math.random(0, LOGIN_PING_SPAN))
	schedulePeriodicAntiEntropy(self)
end
--------------------------------
function AddOn:StopFlightSync()
	local s = self:EnsureSyncState()
	s.started = false
	self:StopSyncGossip()
	self:LeaveSyncChannel()
	if s.digestTimer then
		timerLib(self):CancelTimer(s.digestTimer)
		s.digestTimer = nil
	end
	if s.periodicTimer then
		timerLib(self):CancelTimer(s.periodicTimer)
		s.periodicTimer = nil
	end
	wipe(s.peers)
	wipe(s.peerDigestPending)
	wipe(s.timeReplyQueue)
	wipe(s.pathReplyQueue)
	s.replyBusy = false
end
--------------------------------
function AddOn:InitSync()
	self:EnsureSyncState()
	self:InitSyncTransport()
	self:AddMessageHandler(self.Message.ENABLE_ADDON, function()
		self:StartFlightSync()
	end)
	self:AddMessageHandler(self.Message.DISABLE_ADDON, function()
		self:StopFlightSync()
	end)
	self:StartFlightSync()
end
