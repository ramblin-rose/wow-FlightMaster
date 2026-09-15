-- Directed origin→destination flight times, partitioned by client family.
-- A→B is not B→A; hop-sum is an estimate, not a measured through-flight.
local AddOn = _G[select(1, ...)]
--------------------------------
local FLIGHT_TIMES_VERSION = 1
local TAKEOFF_INTERVAL = 0.1
local TAKEOFF_TIMEOUT = 15

local pending
local watchTimer
local controlEventRegistered
--------------------------------
local function getClientFamily()
	local build = select(4, GetBuildInfo())
	if type(build) ~= "number" or build < 20000 then
		return "classic-era"
	end
	if build < 50000 then
		return "tbc"
	end
	return "mop"
end
--------------------------------
local function tableGet(t, key)
	if type(t) ~= "table" or key == nil then
		return nil
	end
	local value = t[key]
	if value ~= nil then
		return value
	end
	if type(key) == "number" then
		return t[tostring(key)]
	end
	local asNumber = tonumber(key)
	if asNumber then
		return t[asNumber]
	end
end
--------------------------------
local function ensureStore()
	local db = AddOn.db and AddOn.db.global
	if not db then
		return nil
	end
	local era = getClientFamily()
	local store = db.flightTimes
	if type(store) ~= "table" or store.version ~= FLIGHT_TIMES_VERSION or store.era ~= era then
		store = {
			version = FLIGHT_TIMES_VERSION,
			era = era,
			times = {},
		}
		db.flightTimes = store
	elseif type(store.times) ~= "table" then
		store.times = {}
	end
	return store
end
--------------------------------
function AddOn:GetTaxiNodeID(node)
	if type(node) ~= "table" then
		return nil
	end
	local id = node.nodeID
	if type(id) == "string" then
		id = tonumber(id)
	end
	if type(id) == "number" and id > 0 then
		return id
	end
end
--------------------------------
local function lookupNodeIDByName(name)
	if type(name) ~= "string" or name == "" or not C_TaxiMap or not C_TaxiMap.GetAllTaxiNodes then
		return nil
	end
	local mapIDs, seen = {}, {}
	local function addMapID(mapID)
		if type(mapID) == "number" and mapID > 0 and not seen[mapID] then
			seen[mapID] = true
			mapIDs[#mapIDs + 1] = mapID
		end
	end
	if GetTaxiMapID then
		addMapID(GetTaxiMapID())
	end
	if AddOn.mapInfo then
		addMapID(AddOn.mapInfo.mapID)
	end
	if AddOn.GetPlayerContinentMapID then
		addMapID(AddOn:GetPlayerContinentMapID())
	end
	for i = 1, #mapIDs do
		local nodes = C_TaxiMap.GetAllTaxiNodes(mapIDs[i])
		if type(nodes) == "table" then
			for _, node in ipairs(nodes) do
				if node.name == name then
					local id = AddOn:GetTaxiNodeID(node)
					if id then
						return id
					end
				end
			end
		end
	end
end
--------------------------------
function AddOn:GetTaxiNodeIDForSlot(slot)
	if type(slot) ~= "number" or slot < 1 then
		return nil
	end
	local node = AddOn.taxiNodePositions and AddOn.taxiNodePositions[slot]
	local id = AddOn:GetTaxiNodeID(node)
	if id then
		return id
	end
	if TaxiNodeName then
		return lookupNodeIDByName(TaxiNodeName(slot))
	end
end
--------------------------------
function AddOn:GetCurrentTaxiSlot()
	local numNodes = NumTaxiNodes()
	if not numNodes or numNodes < 1 then
		return nil
	end
	for i = 1, numNodes do
		if TaxiNodeGetType(i) == "CURRENT" then
			return i
		end
	end
end
--------------------------------
function AddOn:GetOriginTaxiNodeID()
	local originID = AddOn:GetTaxiNodeID(AddOn.originTaxiNode)
	if originID then
		return originID
	end
	return AddOn:GetTaxiNodeIDForSlot(AddOn:GetCurrentTaxiSlot())
end
--------------------------------
function AddOn:GetFlightTime(originNodeID, destNodeID)
	originNodeID = tonumber(originNodeID)
	destNodeID = tonumber(destNodeID)
	if not originNodeID or not destNodeID then
		return nil
	end
	local store = ensureStore()
	if not store then
		return nil
	end
	local from = tableGet(store.times, originNodeID)
	local seconds = tableGet(from, destNodeID)
	seconds = tonumber(seconds)
	if seconds and seconds > 0 then
		return seconds
	end
end
--------------------------------
function AddOn:SetFlightTime(originNodeID, destNodeID, seconds)
	originNodeID = tonumber(originNodeID)
	destNodeID = tonumber(destNodeID)
	seconds = math.floor(tonumber(seconds) or 0)
	if not originNodeID or not destNodeID or seconds < 1 then
		return
	end
	local store = ensureStore()
	if not store then
		return
	end
	local from = store.times[originNodeID]
	if type(from) ~= "table" then
		from = {}
		store.times[originNodeID] = from
	end
	from[destNodeID] = seconds
end
--------------------------------
function AddOn:EstimateFlightTime(destSlot)
	if type(destSlot) ~= "number" or destSlot < 1 then
		return nil
	end
	local numRoutes = GetNumRoutes(destSlot)
	if not numRoutes or numRoutes < 1 then
		return nil
	end
	local total = 0
	for hop = 1, numRoutes do
		local srcSlot = TaxiGetNodeSlot(destSlot, hop, true)
		local dstSlot = TaxiGetNodeSlot(destSlot, hop, false)
		if (not dstSlot or dstSlot < 1) and hop == numRoutes then
			dstSlot = destSlot
		end
		local originID = AddOn:GetTaxiNodeIDForSlot(srcSlot)
		local destID = AddOn:GetTaxiNodeIDForSlot(dstSlot)
		local leg = AddOn:GetFlightTime(originID, destID)
		if not leg then
			return nil
		end
		total = total + leg
	end
	if total < 1 then
		return nil
	end
	return total
end
--------------------------------
function AddOn:GetDisplayedFlightTime(destSlot)
	local originID = AddOn:GetOriginTaxiNodeID()
	local destID = AddOn:GetTaxiNodeIDForSlot(destSlot)
	local known = AddOn:GetFlightTime(originID, destID)
	if known then
		return known, false
	end
	local estimate = AddOn:EstimateFlightTime(destSlot)
	if estimate then
		return estimate, true
	end
end
--------------------------------
function AddOn:FormatFlightTime(seconds)
	seconds = math.floor(tonumber(seconds) or 0)
	if seconds < 0 then
		seconds = 0
	end
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	if TIMER_MINUTES_DISPLAY then
		return string.format(TIMER_MINUTES_DISPLAY, minutes, secs)
	end
	return string.format("%d:%02d", minutes, secs)
end
--------------------------------
function AddOn:AddFlightTimeTooltipLine(destSlot)
	if not AddOn:GetShowFlightTimes() then
		return
	end
	local L = AddOn.L
	local seconds, estimated = AddOn:GetDisplayedFlightTime(destSlot)
	if seconds then
		local formatted = AddOn:FormatFlightTime(seconds)
		if estimated then
			formatted = "~" .. formatted
		end
		GameTooltip:AddLine(
			"|cffffd100" .. L.flightTimeLabel .. "|r |cffffffff" .. formatted .. "|r",
			1,
			1,
			1
		)
		return
	end
	GameTooltip:AddLine("|cff808080" .. L.flightTimeLabel .. " " .. L.flightTimeUnknown .. "|r", 0.5, 0.5, 0.5)
end
--------------------------------
local function nowServerTime()
	if GetServerTime then
		return GetServerTime()
	end
	return time()
end
--------------------------------
local function clearActiveFlight()
	if AddOn.db and AddOn.db.global then
		AddOn.db.global.activeFlight = nil
	end
end
--------------------------------
local function persistActiveFlight()
	if not AddOn.db or not AddOn.db.global then
		return
	end
	if not pending or not pending.confirmed or not pending.duration or pending.duration < 1 then
		AddOn.db.global.activeFlight = nil
		return
	end
	AddOn.db.global.activeFlight = {
		originID = pending.originID,
		destID = pending.destID,
		destName = pending.destName,
		duration = pending.duration,
		estimated = pending.estimated,
		startServerTime = pending.startServerTime,
		invalid = pending.invalid,
		arrivalClock = pending.arrivalClock,
		numHops = pending.numHops,
	}
end
--------------------------------
function AddOn:AbortFlightTimeSample()
	local wasFlying = pending and pending.confirmed
	if watchTimer then
		AddOn.Timer:CancelTimer(watchTimer)
		watchTimer = nil
	end
	if controlEventRegistered then
		AddOn:UnregisterEvent("PLAYER_CONTROL_GAINED")
		controlEventRegistered = false
	end
	pending = nil
	clearActiveFlight()
	if wasFlying then
		AddOn:SendMessage(AddOn.Message.TAXI_END)
	end
end
--------------------------------
local function finishFlightTimeSample()
	if not pending or not pending.confirmed then
		return
	end
	if UnitOnTaxi("player") then
		return
	end
	local originID = pending.originID
	local destID = pending.destID
	local startTime = pending.startTime
	local invalid = pending.invalid
	AddOn:AbortFlightTimeSample()
	if invalid then
		return
	end
	local elapsed = math.floor(GetTime() - startTime + 0.5)
	if elapsed > 0 then
		AddOn:SetFlightTime(originID, destID, elapsed)
	end
end
--------------------------------
local function confirmTakeoff()
	if not pending or pending.confirmed then
		return
	end
	pending.confirmed = true
	pending.startTime = GetTime()
	pending.startServerTime = nowServerTime()
	if AddOn.FormatArrivalClock then
		pending.arrivalClock = AddOn:FormatArrivalClock(pending.duration)
	end
	if not controlEventRegistered then
		controlEventRegistered = true
		AddOn:RegisterEvent("PLAYER_CONTROL_GAINED", "OnFlightTimeControlGained")
	end
	persistActiveFlight()
	AddOn:SendMessage(AddOn.Message.TAXI_START, pending.originID, pending.destID, pending.duration, pending.destName, pending.estimated, pending.arrivalClock, pending.numHops)
end
--------------------------------
local function startFlightTimeWatch()
	if watchTimer then
		AddOn.Timer:CancelTimer(watchTimer)
		watchTimer = nil
	end
	local elapsed = 0
	watchTimer = AddOn.Timer:ScheduleRepeatingTimer(function()
		if not pending then
			return
		end
		if not pending.confirmed then
			if UnitOnTaxi("player") then
				confirmTakeoff()
				return
			end
			elapsed = elapsed + TAKEOFF_INTERVAL
			if elapsed >= TAKEOFF_TIMEOUT then
				AddOn:AbortFlightTimeSample()
			end
			return
		end
		finishFlightTimeSample()
	end, TAKEOFF_INTERVAL)
end
--------------------------------
function AddOn:OnTakeTaxiNode(index)
	if not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes() then
		return
	end
	AddOn:AbortFlightTimeSample()
	if type(index) ~= "number" or index < 1 then
		return
	end

	local originID = AddOn:GetOriginTaxiNodeID()
	local destID = AddOn:GetTaxiNodeIDForSlot(index)
	if not originID or not destID or originID == destID then
		return
	end

	local destName
	local destNode = AddOn.taxiNodePositions and AddOn.taxiNodePositions[index]
	if destNode and destNode.name then
		destName = destNode.name
	elseif TaxiNodeName then
		destName = TaxiNodeName(index)
	end

	local known = AddOn:GetFlightTime(originID, destID)
	local numHops = GetNumRoutes and GetNumRoutes(index)
	pending = {
		originID = originID,
		destID = destID,
		startTime = GetTime(),
		confirmed = false,
		invalid = false,
		duration = known or AddOn:EstimateFlightTime(index),
		destName = destName,
		estimated = not known,
		numHops = tonumber(numHops),
	}

	if UnitOnTaxi("player") then
		confirmTakeoff()
	end
	startFlightTimeWatch()
end
--------------------------------
function AddOn:OnFlightTimeControlGained()
	finishFlightTimeSample()
end
--------------------------------
local function invalidateFlightTimeSample()
	if pending then
		pending.invalid = true
		persistActiveFlight()
	end
	if AddOn.flightTimerState then
		AddOn.flightTimerState.earlyLandingRequested = true
		if AddOn.UpdateFlightTimerEarlyLandingButton then
			AddOn:UpdateFlightTimerEarlyLandingButton()
		end
	end
end
--------------------------------
local function restoredProgressIsValid(saved, elapsed)
	if type(saved) ~= "table" or saved.invalid then
		return false
	end
	local duration = tonumber(saved.duration)
	if not duration or duration < 1 then
		return false
	end
	if not tonumber(saved.startServerTime) then
		return false
	end
	if type(elapsed) ~= "number" or elapsed < 0 or elapsed >= duration then
		return false
	end
	return true
end
--------------------------------
function AddOn:RestoreInFlightSession()
	local saved = AddOn.db and AddOn.db.global and AddOn.db.global.activeFlight
	if type(saved) ~= "table" or not tonumber(saved.startServerTime) or not tonumber(saved.duration) then
		return
	end
	local attempts = 0
	local function tryRestore()
		if UnitOnTaxi("player") then
			local elapsed = nowServerTime() - saved.startServerTime
			if elapsed < 0 then
				clearActiveFlight()
				return
			end
			pending = {
				originID = saved.originID,
				destID = saved.destID,
				destName = saved.destName,
				duration = saved.duration,
				estimated = saved.estimated,
				confirmed = true,
				invalid = saved.invalid,
				startServerTime = saved.startServerTime,
				startTime = GetTime() - elapsed,
				arrivalClock = saved.arrivalClock,
				numHops = saved.numHops,
			}
			if not controlEventRegistered then
				controlEventRegistered = true
				AddOn:RegisterEvent("PLAYER_CONTROL_GAINED", "OnFlightTimeControlGained")
			end
			startFlightTimeWatch()
			if restoredProgressIsValid(saved, elapsed) then
				AddOn:StartFlightTimerBar(
					saved.originID,
					saved.destID,
					saved.duration,
					saved.destName,
					saved.estimated,
					elapsed,
					saved.arrivalClock,
					saved.numHops
				)
			end
			return
		end
		attempts = attempts + 1
		if attempts >= 50 then
			clearActiveFlight()
			return
		end
		AddOn.Timer:ScheduleTimer(tryRestore, TAKEOFF_INTERVAL)
	end
	tryRestore()
end
--------------------------------
function AddOn:InitTaxiLog()
	ensureStore()
	if AddOn.db and AddOn.db.global then
		AddOn.db.global.taxiLog = nil
	end

	AddOn:SecureHook("TaxiRequestEarlyLanding", invalidateFlightTimeSample)
	if ConfirmSummon then
		AddOn:SecureHook("ConfirmSummon", invalidateFlightTimeSample)
	end
	if C_SummonInfo and C_SummonInfo.ConfirmSummon then
		AddOn:SecureHook(C_SummonInfo, "ConfirmSummon", invalidateFlightTimeSample)
	end
end
