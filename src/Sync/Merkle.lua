local AddOn = _G[select(1, ...)]
--------------------------------
local BUCKETS = 32

local dirty = true
local timeRoot
local timeBuckets
local pathRoot
local pathBuckets
--------------------------------
local function bucketIndex(originID)
	return (AddOn:SyncAdler32(tostring(originID)) % BUCKETS) + 1
end
--------------------------------
local function hashList(entries)
	table.sort(entries, function(a, b)
		return a.key < b.key
	end)
	local chunks = {}
	for i = 1, #entries do
		local h = entries[i].hash % 4294967296
		local b1 = h % 256
		h = (h - b1) / 256
		local b2 = h % 256
		h = (h - b2) / 256
		local b3 = h % 256
		h = (h - b3) / 256
		local b4 = h % 256
		chunks[i] = string.char(b1, b2, b3, b4)
	end
	return AddOn:SyncAdler32(table.concat(chunks))
end
--------------------------------
local function rebuild()
	if not dirty then
		return
	end
	local timeLists = {}
	local pathLists = {}
	for i = 1, BUCKETS do
		timeLists[i] = {}
		pathLists[i] = {}
	end
	if AddOn.ForEachFlightTime then
		AddOn:ForEachFlightTime(function(originID, destID, seconds, n)
			local i = bucketIndex(originID)
			timeLists[i][#timeLists[i] + 1] = {
				key = originID .. ":" .. destID,
				hash = AddOn:HashFlightTimeRecord(originID, destID, seconds, n),
			}
		end)
	end
	if AddOn.ForEachFlightPath then
		AddOn:ForEachFlightPath(function(originID, destID, samples, n)
			local inst, pts = AddOn:QuantizePathPoints(samples)
			if not pts then
				return
			end
			local i = bucketIndex(originID)
			pathLists[i][#pathLists[i] + 1] = {
				key = originID .. ":" .. destID,
				hash = AddOn:HashFlightPathPoints(originID, destID, n, inst, pts),
			}
		end)
	end
	timeBuckets = {}
	pathBuckets = {}
	for i = 1, BUCKETS do
		timeBuckets[i] = hashList(timeLists[i])
		pathBuckets[i] = hashList(pathLists[i])
	end
	timeRoot = AddOn:SyncAdler32(AddOn:PackBucketHashes(timeBuckets))
	pathRoot = AddOn:SyncAdler32(AddOn:PackBucketHashes(pathBuckets))
	dirty = false
end
--------------------------------
function AddOn:InvalidateSyncMerkle()
	dirty = true
end
--------------------------------
function AddOn:GetSyncTimeDigest()
	rebuild()
	return timeRoot, timeBuckets
end
--------------------------------
function AddOn:GetSyncPathDigest()
	rebuild()
	return pathRoot, pathBuckets
end
--------------------------------
function AddOn:GetSyncBucketCount()
	return BUCKETS
end
--------------------------------
function AddOn:GetSyncBucketIndex(originID)
	originID = tonumber(originID)
	if not originID then
		return nil
	end
	return bucketIndex(originID)
end
--------------------------------
function AddOn:CollectSyncBucketTimes(index)
	index = tonumber(index)
	if not index or index < 1 or index > BUCKETS then
		return nil
	end
	local recs = {}
	AddOn:ForEachFlightTime(function(originID, destID, seconds, n)
		if bucketIndex(originID) == index then
			recs[#recs + 1] = { o = originID, d = destID, s = seconds, n = n }
		end
	end)
	return recs
end
--------------------------------
function AddOn:CollectSyncBucketPathKeys(index)
	index = tonumber(index)
	if not index or index < 1 or index > BUCKETS then
		return nil
	end
	local recs = {}
	AddOn:ForEachFlightPath(function(originID, destID, samples, n)
		local inst, pts = AddOn:QuantizePathPoints(samples)
		if not pts then
			return
		end
		if bucketIndex(originID) == index then
			recs[#recs + 1] = {
				o = originID,
				d = destID,
				h = AddOn:HashFlightPathPoints(originID, destID, n, inst, pts),
			}
		end
	end)
	return recs
end
--------------------------------
function AddOn:DifferingBuckets(localHashes, remoteBlob)
	local remote = AddOn:UnpackBucketHashes(remoteBlob)
	if not remote or type(localHashes) ~= "table" then
		return nil
	end
	local diff = {}
	for i = 1, BUCKETS do
		if (localHashes[i] or 0) ~= (remote[i] or 0) then
			diff[#diff + 1] = i
		end
	end
	return diff
end
