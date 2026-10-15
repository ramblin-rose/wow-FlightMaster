local AddOn = _G[select(1, ...)]
--------------------------------
local MAX_SECONDS = 3600
local MAX_N = 1000000
local MAX_ID = 2147483647
local MAX_POINTS = 16
--------------------------------
local function boundedInt(v, minV, maxV)
	v = tonumber(v)
	if not v or v ~= v or v < minV or v > maxV then
		return nil
	end
	local i = math.floor(v)
	if i ~= v then
		return nil
	end
	return i
end
--------------------------------
function AddOn:MergeRemoteFlightTime(originID, destID, seconds, n, hash)
	originID = boundedInt(originID, 1, MAX_ID)
	destID = boundedInt(destID, 1, MAX_ID)
	seconds = tonumber(seconds)
	if not seconds or seconds ~= seconds then
		return false
	end
	seconds = math.floor(seconds)
	if n == nil then
		n = 1
	else
		n = boundedInt(n, 1, MAX_N)
	end
	if not originID or not destID or not n or seconds < 1 or seconds > MAX_SECONDS then
		return false
	end
	if type(hash) == "number" then
		local expected = self:HashFlightTimeRecord(originID, destID, seconds, n)
		if hash ~= expected then
			return false
		end
	end
	local localSeconds, localN = self:GetFlightTimeMeta(originID, destID)
	if localSeconds then
		if hash and hash == self:HashFlightTimeRecord(originID, destID, localSeconds, localN) then
			if self.LogSyncFlightReceived then
				self:LogSyncFlightReceived("t", originID, destID, seconds, false)
			end
			return false
		end
		if n <= (localN or 1) then
			if self.LogSyncFlightReceived then
				self:LogSyncFlightReceived("t", originID, destID, seconds, false)
			end
			return false
		end
	end
	self:ApplySyncedFlightTime(originID, destID, seconds, n)
	if self.LogSyncFlightReceived then
		self:LogSyncFlightReceived("t", originID, destID, seconds, true)
	end
	return true
end
--------------------------------
function AddOn:MergeRemoteFlightPath(originID, destID, n, instanceID, pts, hash)
	originID = boundedInt(originID, 1, MAX_ID)
	destID = boundedInt(destID, 1, MAX_ID)
	if n == nil then
		n = 1
	else
		n = boundedInt(n, 1, MAX_N)
	end
	if instanceID ~= nil then
		instanceID = boundedInt(instanceID, 0, MAX_ID)
		if not instanceID then
			return false
		end
	end
	if not originID or not destID or not n or type(pts) ~= "table" or #pts < 1 or #pts > MAX_POINTS then
		return false
	end
	if type(hash) == "number" then
		local expected = self:HashFlightPathPoints(originID, destID, n, instanceID, pts)
		if hash ~= expected then
			return false
		end
	end
	local samples = self:ExpandPathPoints(instanceID, pts)
	if not samples then
		return false
	end
	local localSamples, localN = self:GetFlightPathMeta(originID, destID)
	if localSamples then
		if #localSamples > #samples then
			if self.LogSyncFlightReceived then
				self:LogSyncFlightReceived("p", originID, destID, #samples, false)
			end
			return false
		end
		if #localSamples == #samples and (localN or 1) >= n then
			if self.LogSyncFlightReceived then
				self:LogSyncFlightReceived("p", originID, destID, #samples, false)
			end
			return false
		end
	end
	self:ApplySyncedFlightPath(originID, destID, samples, n)
	if self.LogSyncFlightReceived then
		self:LogSyncFlightReceived("p", originID, destID, #samples, true)
	end
	return true
end
