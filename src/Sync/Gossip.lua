local AddOn = _G[select(1, ...)]
--------------------------------
local MAX_TX = 2
local TICK = 1

local rumors = {}
local gossipTimer
local lastSend = 0
--------------------------------
local function rumorKey(kind, originID, destID)
	return kind .. ":" .. originID .. ":" .. destID
end
--------------------------------
function AddOn:GetSyncRumorCount()
	local n = 0
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
	if kind == "p" and not AddOn:GetShareFlightPaths() then
		return
	end
	if not AddOn:GetShareFlightData() then
		return
	end
	local key = rumorKey(kind, originID, destID)
	local now = GetTime()
	rumors[key] = {
		kind = kind,
		o = originID,
		d = destID,
		remaining = MAX_TX,
		due = now + math.random(3, 8),
	}
end
--------------------------------
local function buildRumor(kind, originID, destID)
	if kind == "t" then
		local seconds, n = AddOn:GetFlightTimeMeta(originID, destID)
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
			h = AddOn:HashFlightTimeRecord(originID, destID, seconds, n),
		}
	end
	local samples, n = AddOn:GetFlightPathMeta(originID, destID)
	if not samples then
		return nil
	end
	local inst, pts = AddOn:QuantizePathPoints(samples)
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
		h = AddOn:HashFlightPathPoints(originID, destID, n, inst, pts),
	}
end
--------------------------------
local function gossipTick()
	if not AddOn:GetShareFlightData() then
		return
	end
	local now = GetTime()
	local minGap = 0.8 + math.random() * 1.4
	if now - lastSend < minGap then
		return
	end
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
	local msg = buildRumor(chosen.kind, chosen.o, chosen.d)
	if not msg then
		rumors[chosenKey] = nil
		return
	end
	local level = chosen.kind == "p" and 6 or 1
	if AddOn:BroadcastSyncMessage(msg, level) then
		lastSend = now
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
	if gossipTimer then
		return
	end
	gossipTimer = AddOn.Timer:ScheduleRepeatingTimer(gossipTick, TICK)
end
--------------------------------
function AddOn:StopSyncGossip()
	if gossipTimer then
		AddOn.Timer:CancelTimer(gossipTimer)
		gossipTimer = nil
	end
	wipe(rumors)
end
