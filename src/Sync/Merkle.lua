local AddOn = _G[select(1, ...)]
--------------------------------
local BUCKETS = 32
--------------------------------
local function bucketIndex(self, originID)
	return (self:SyncAdler32(tostring(originID)) % BUCKETS) + 1
end
--------------------------------
local function hashList(self, entries)
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
	return self:SyncAdler32(table.concat(chunks))
end
--------------------------------
local function rebuild(self)
	local s = self:EnsureSyncState()
	if not s.merkleDirty then
		return
	end
	local timeLists = {}
	local pathLists = {}
	for i = 1, BUCKETS do
		timeLists[i] = {}
		pathLists[i] = {}
	end
	if self.ForEachFlightTime then
		self:ForEachFlightTime(function(originID, destID, seconds, n)
			local i = bucketIndex(self, originID)
			timeLists[i][#timeLists[i] + 1] = {
				key = originID .. ":" .. destID,
				hash = self:HashFlightTimeRecord(originID, destID, seconds, n),
			}
		end)
	end
	if self.ForEachFlightPath then
		self:ForEachFlightPath(function(originID, destID, samples, n)
			local inst, pts = self:QuantizePathPoints(samples)
			if not pts then
				return
			end
			local i = bucketIndex(self, originID)
			pathLists[i][#pathLists[i] + 1] = {
				key = originID .. ":" .. destID,
				hash = self:HashFlightPathPoints(originID, destID, n, inst, pts),
			}
		end)
	end
	s.timeBuckets = {}
	s.pathBuckets = {}
	for i = 1, BUCKETS do
		s.timeBuckets[i] = hashList(self, timeLists[i])
		s.pathBuckets[i] = hashList(self, pathLists[i])
	end
	s.timeRoot = self:SyncAdler32(self:PackBucketHashes(s.timeBuckets))
	s.pathRoot = self:SyncAdler32(self:PackBucketHashes(s.pathBuckets))
	s.merkleDirty = false
end
--------------------------------
function AddOn:InvalidateSyncMerkle()
	self:EnsureSyncState().merkleDirty = true
end
--------------------------------
function AddOn:GetSyncTimeDigest()
	rebuild(self)
	local s = self.sync
	return s.timeRoot, s.timeBuckets
end
--------------------------------
function AddOn:GetSyncPathDigest()
	rebuild(self)
	local s = self.sync
	return s.pathRoot, s.pathBuckets
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
	return bucketIndex(self, originID)
end
--------------------------------
function AddOn:CollectSyncBucketTimes(index)
	index = tonumber(index)
	if not index or index < 1 or index > BUCKETS then
		return nil
	end
	local recs = {}
	self:ForEachFlightTime(function(originID, destID, seconds, n)
		if bucketIndex(self, originID) == index then
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
	self:ForEachFlightPath(function(originID, destID, samples, n)
		local inst, pts = self:QuantizePathPoints(samples)
		if not pts then
			return
		end
		if bucketIndex(self, originID) == index then
			recs[#recs + 1] = {
				o = originID,
				d = destID,
				h = self:HashFlightPathPoints(originID, destID, n, inst, pts),
			}
		end
	end)
	return recs
end
--------------------------------
function AddOn:DifferingBuckets(localHashes, remoteBlob)
	local remote = self:UnpackBucketHashes(remoteBlob)
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
