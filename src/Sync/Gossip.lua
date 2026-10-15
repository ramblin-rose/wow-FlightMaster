local AddOn = _G[select(1, ...)]
--------------------------------
local MAX_TX = 2
local TICK = 1
--------------------------------
local function rumorKey(kind, originID, destID)
	return kind .. ":" .. originID .. ":" .. destID
end
--------------------------------
function AddOn:GetSyncRumorCount()
	local n = 0
	local rumors = self:EnsureSyncState().rumors
	for _ in pairs(rumors) do
		n = n + 1
	end
	return n
end
--------------------------------
function AddOn:InfectFlightRumor(kind, originID, destID)
	originID = tonumber(originID)
	destID = tonumber(destID)
	if kind ~= "t" and kind ~= "p" then
		return
	end
	if not originID or not destID then
		return
	end
	if kind == "p" and not self:GetShareFlightPaths() then
		return
	end
	if not self:GetShareFlightData() then
		return
	end
	local s = self:EnsureSyncState()
	local key = rumorKey(kind, originID, destID)
	local now = GetTime()
	s.rumors[key] = {
		kind = kind,
		o = originID,
		d = destID,
		remaining = MAX_TX,
		due = now + math.random(3, 8),
	}
end
--------------------------------
local function buildRumor(self, kind, originID, destID)
	if kind == "t" then
		local seconds, n = self:GetFlightTimeMeta(originID, destID)
		if not seconds then
			return nil
		end
		return {
			t = "R",
			k = "t",
			o = originID,
			d = destID,
			s = seconds,
			n = n,
			h = self:HashFlightTimeRecord(originID, destID, seconds, n),
		}
	end
	local samples, n = self:GetFlightPathMeta(originID, destID)
	if not samples then
		return nil
	end
	local inst, pts = self:QuantizePathPoints(samples)
	if not pts then
		return nil
	end
	return {
		t = "R",
		k = "p",
		o = originID,
		d = destID,
		n = n,
		i = inst,
		p = pts,
		h = self:HashFlightPathPoints(originID, destID, n, inst, pts),
	}
end
--------------------------------
function AddOn:SyncGossipTick()
	if not self:GetShareFlightData() then
		return
	end
	local s = self:EnsureSyncState()
	local now = GetTime()
	local minGap = 0.8 + math.random() * 1.4
	if now - s.lastSend < minGap then
		return
	end
	local rumors = s.rumors
	local chosenKey, chosen
	for key, rumor in pairs(rumors) do
		if rumor.remaining < 1 then
			rumors[key] = nil
		elseif now >= rumor.due and (not chosen or rumor.due < chosen.due) then
			chosenKey = key
			chosen = rumor
		end
	end
	if not chosen then
		return
	end
	local msg = buildRumor(self, chosen.kind, chosen.o, chosen.d)
	if not msg then
		rumors[chosenKey] = nil
		return
	end
	local level = chosen.kind == "p" and 6 or 1
	if self:BroadcastSyncMessage(msg, level) then
		s.lastSend = now
		chosen.remaining = chosen.remaining - 1
		chosen.due = now + math.random(3, 8)
		if chosen.remaining < 1 then
			rumors[chosenKey] = nil
		end
	else
		chosen.due = now + math.random(5, 12)
	end
end
--------------------------------
function AddOn:StartSyncGossip()
	local s = self:EnsureSyncState()
	if s.gossipTimer then
		return
	end
	s.gossipTimer = (self.Timer or AddOn.Timer):ScheduleRepeatingTimer(function()
		self:SyncGossipTick()
	end, TICK)
end
--------------------------------
function AddOn:StopSyncGossip()
	local s = self:EnsureSyncState()
	if s.gossipTimer then
		(self.Timer or AddOn.Timer):CancelTimer(s.gossipTimer)
		s.gossipTimer = nil
	end
	wipe(s.rumors)
end
