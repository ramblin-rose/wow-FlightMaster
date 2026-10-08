-- Directed origin→destination flight times, partitioned by AceDB faction and client family.
-- Missing A→B may use B→A as an estimate, for any hop count. Hop-sum is also an estimate.
local AddOn = _G[select(1, ...)]
--------------------------------
local FLIGHT_TIMES_VERSION = 3
local FLIGHT_PATHS_VERSION = 3
local TAKEOFF_INTERVAL = 0.1
local TAKEOFF_TIMEOUT = 15
local PATH_SAMPLE_INTERVAL = 5

local pending
local watchTimer
local pathTimer
local controlEventRegistered
local normalizePathSamples
--------------------------------
function AddOn:GetClientFamily()
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
function AddOn:GetPlayerFaction()
	local faction = UnitFactionGroup("player")
	if faction == "Alliance" or faction == "Horde" then
		return faction
	end
	return "Neutral"
end
--------------------------------
function AddOn:GetSyncFaction()
	local faction = UnitFactionGroup("player")
	if faction == "Alliance" or faction == "Horde" then
		return faction
	end
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
local function migrateTimeMap(oldTimes)
	local dest = {}
	if type(oldTimes) ~= "table" then
		return dest
	end
	for origin, tos in pairs(oldTimes) do
		if type(tos) == "table" then
			local row = {}
			for destID, value in pairs(tos) do
				if type(value) == "table" then
					local seconds = tonumber(value.seconds)
					if seconds and seconds > 0 then
						row[destID] = {
							seconds = math.floor(seconds),
							n = math.max(1, math.floor(tonumber(value.n) or 1)),
						}
					end
				else
					local seconds = tonumber(value)
					if seconds and seconds > 0 then
						row[destID] = { seconds = math.floor(seconds), n = 1 }
					end
				end
			end
			if next(row) then
				dest[origin] = row
			end
		end
	end
	return dest
end
--------------------------------
local function migratePathMap(oldPaths)
	local dest = {}
	if type(oldPaths) ~= "table" then
		return dest
	end
	for origin, tos in pairs(oldPaths) do
		if type(tos) == "table" then
			local row = {}
			for destID, value in pairs(tos) do
				if type(value) == "table" and value.samples then
					row[destID] = {
						samples = value.samples,
						n = math.max(1, math.floor(tonumber(value.n) or 1)),
					}
				elseif type(value) == "table" then
					row[destID] = { samples = value, n = 1 }
				end
			end
			if next(row) then
				dest[origin] = row
			end
		end
	end
	return dest
end
--------------------------------
local function globalEraMatches(root, era)
	if type(root) ~= "table" then
		return false
	end
	if root.era == nil then
		return true
	end
	return root.era == era
end
--------------------------------
local function takeGlobalMap(root, mapKey, faction)
	if type(root) ~= "table" then
		return nil, false
	end
	if type(root.byFaction) == "table" then
		local bucket = root.byFaction[faction]
		if type(bucket) == "table" and type(bucket[mapKey]) == "table" then
			return bucket[mapKey], false
		end
		return nil, false
	end
	if type(root[mapKey]) == "table" then
		return root[mapKey], true
	end
	return nil, false
end
--------------------------------
local function pruneGlobalSection(sv, field, mapKey, faction, consumedV1)
	local root = sv[field]
	if type(root) ~= "table" then
		return
	end
	if type(root.byFaction) == "table" then
		root.byFaction[faction] = nil
		if not next(root.byFaction) then
			root.byFaction = nil
		end
	end
	if consumedV1 then
		root[mapKey] = nil
	end
	if root.byFaction == nil and (type(root[mapKey]) ~= "table" or not next(root[mapKey])) then
		sv[field] = nil
	end
end
--------------------------------
local function factionStoreValid(store, version, era, mapKey)
	return type(store) == "table" and store.version == version and store.era == era and type(store[mapKey]) == "table"
end
--------------------------------
local function migrateGlobalSection(field, mapKey, version, migrate)
	if not AddOn.db then
		return
	end
	local factionDB = AddOn.db.faction
	local globalDB = AddOn.db.global
	if not factionDB or not globalDB then
		return
	end
	local era = AddOn:GetClientFamily()
	local faction = AddOn:GetPlayerFaction()
	local dest = factionDB[field]
	if factionStoreValid(dest, version, era, mapKey) then
		if globalEraMatches(globalDB[field], era) then
			pruneGlobalSection(globalDB, field, mapKey, faction, false)
		end
		return
	end
	local map = {}
	local consumedV1 = false
	local globalRoot = globalDB[field]
	if globalEraMatches(globalRoot, era) then
		local source
		source, consumedV1 = takeGlobalMap(globalRoot, mapKey, faction)
		map = migrate(source)
	end
	factionDB[field] = {
		version = version,
		era = era,
		[mapKey] = map,
	}
	if globalEraMatches(globalRoot, era) then
		pruneGlobalSection(globalDB, field, mapKey, faction, consumedV1)
	end
end
--------------------------------
local function migrateGlobalFlightData()
	migrateGlobalSection("flightTimes", "times", FLIGHT_TIMES_VERSION, migrateTimeMap)
	migrateGlobalSection("flightPaths", "paths", FLIGHT_PATHS_VERSION, migratePathMap)
	if AddOn.InvalidateSyncMerkle then
		AddOn:InvalidateSyncMerkle()
	end
end
--------------------------------
local function ensureFactionStore(field, mapKey, version)
	if not AddOn.db or not AddOn.db.faction then
		return nil
	end
	local era = AddOn:GetClientFamily()
	local store = AddOn.db.faction[field]
	if not factionStoreValid(store, version, era, mapKey) then
		store = {
			version = version,
			era = era,
			[mapKey] = {},
		}
		AddOn.db.faction[field] = store
	end
	return store
end
--------------------------------
local function ensureStore()
	return ensureFactionStore("flightTimes", "times", FLIGHT_TIMES_VERSION)
end
--------------------------------
local function ensurePathStore()
	return ensureFactionStore("flightPaths", "paths", FLIGHT_PATHS_VERSION)
end
--------------------------------
local function readTimeRecord(value)
	if type(value) == "table" then
		local seconds = tonumber(value.seconds)
		if seconds and seconds > 0 then
			return seconds, math.max(1, math.floor(tonumber(value.n) or 1))
		end
		return nil
	end
	local seconds = tonumber(value)
	if seconds and seconds > 0 then
		return seconds, 1
	end
end
--------------------------------
local function readPathRecord(value)
	if type(value) ~= "table" then
		return nil
	end
	if value.samples then
		local samples = normalizePathSamples(value.samples)
		if samples then
			return samples, math.max(1, math.floor(tonumber(value.n) or 1))
		end
		return nil
	end
	local samples = normalizePathSamples(value)
	if samples then
		return samples, 1
	end
end
--------------------------------
local function notifyObservation(kind, originID, destID)
	if AddOn.OnLocalFlightObservation then
		AddOn:OnLocalFlightObservation(kind, originID, destID)
	end
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
function AddOn:GetFlightTimeMeta(originNodeID, destNodeID)
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
	return readTimeRecord(tableGet(from, destNodeID))
end
--------------------------------
function AddOn:GetFlightTime(originNodeID, destNodeID)
	local seconds = AddOn:GetFlightTimeMeta(originNodeID, destNodeID)
	return seconds
end
--------------------------------
function AddOn:GetFlightTimeOrReverse(originNodeID, destNodeID)
	local known = AddOn:GetFlightTime(originNodeID, destNodeID)
	if known then
		return known, false
	end
	local reverse = AddOn:GetFlightTime(destNodeID, originNodeID)
	if reverse then
		return reverse, true
	end
end
--------------------------------
local function writeTimeRecord(originNodeID, destNodeID, seconds, n, silent)
	local store = ensureStore()
	if not store then
		return false
	end
	local from = store.times[originNodeID]
	if type(from) ~= "table" then
		from = {}
		store.times[originNodeID] = from
	end
	from[destNodeID] = { seconds = seconds, n = n }
	if not silent then
		notifyObservation("t", originNodeID, destNodeID)
	elseif AddOn.InvalidateSyncMerkle then
		AddOn:InvalidateSyncMerkle()
	end
	return true
end
--------------------------------
function AddOn:SetFlightTime(originNodeID, destNodeID, seconds)
	originNodeID = tonumber(originNodeID)
	destNodeID = tonumber(destNodeID)
	seconds = math.floor(tonumber(seconds) or 0)
	if not originNodeID or not destNodeID or seconds < 1 then
		return
	end
	local oldSeconds, oldN = AddOn:GetFlightTimeMeta(originNodeID, destNodeID)
	local n = 1
	if oldSeconds then
		if math.abs(oldSeconds - seconds) / oldSeconds < 0.15 then
			n = (oldN or 1) + 1
			seconds = math.floor((oldSeconds * (oldN or 1) + seconds) / n + 0.5)
		else
			n = oldN or 1
		end
	end
	writeTimeRecord(originNodeID, destNodeID, seconds, n, false)
end
--------------------------------
function AddOn:ApplySyncedFlightTime(originNodeID, destNodeID, seconds, n)
	originNodeID = tonumber(originNodeID)
	destNodeID = tonumber(destNodeID)
	seconds = math.floor(tonumber(seconds) or 0)
	n = math.max(1, math.floor(tonumber(n) or 1))
	if not originNodeID or not destNodeID or seconds < 1 then
		return
	end
	writeTimeRecord(originNodeID, destNodeID, seconds, n, true)
end
--------------------------------
function AddOn:ForEachFlightTime(fn)
	if type(fn) ~= "function" then
		return
	end
	local store = ensureStore()
	if not store or type(store.times) ~= "table" then
		return
	end
	for origin, tos in pairs(store.times) do
		origin = tonumber(origin)
		if origin and type(tos) == "table" then
			for dest, value in pairs(tos) do
				dest = tonumber(dest)
				local seconds, n = readTimeRecord(value)
				if dest and seconds then
					fn(origin, dest, seconds, n)
				end
			end
		end
	end
end
--------------------------------
function normalizePathSamples(samples)
	if type(samples) ~= "table" then
		return nil
	end
	local out = {}
	local n = #samples
	if n > 0 and type(samples[1]) == "table" then
		for i = 1, n do
			local s = samples[i]
			if type(s) == "table" and s.x and s.y then
				out[#out + 1] = s
			end
		end
	else
		local i = 1
		while true do
			local s = samples[i] or samples[tostring(i)]
			if type(s) ~= "table" or not s.x or not s.y then
				break
			end
			out[i] = s
			i = i + 1
		end
	end
	if #out > 0 then
		return out
	end
end
--------------------------------
function AddOn:GetFlightPathMeta(originNodeID, destNodeID)
	originNodeID = tonumber(originNodeID)
	destNodeID = tonumber(destNodeID)
	if not originNodeID or not destNodeID then
		return nil
	end
	local store = ensurePathStore()
	if not store then
		return nil
	end
	local from = tableGet(store.paths, originNodeID)
	return readPathRecord(tableGet(from, destNodeID))
end
--------------------------------
function AddOn:GetFlightPath(originNodeID, destNodeID)
	local samples = AddOn:GetFlightPathMeta(originNodeID, destNodeID)
	return samples
end
--------------------------------
local function copyPathSamples(samples)
	local copy = {}
	for i = 1, #samples do
		local p = samples[i]
		if type(p) == "table" and p.x and p.y then
			copy[#copy + 1] = {
				x = p.x,
				y = p.y,
				z = p.z,
				instanceID = p.instanceID,
			}
		end
	end
	if #copy < 1 then
		return nil
	end
	return copy
end
--------------------------------
local function writePathRecord(originNodeID, destNodeID, samples, n, silent)
	local store = ensurePathStore()
	if not store then
		return false
	end
	local from = store.paths[originNodeID]
	if type(from) ~= "table" then
		from = {}
		store.paths[originNodeID] = from
	end
	from[destNodeID] = { samples = samples, n = n }
	if not silent then
		notifyObservation("p", originNodeID, destNodeID)
	elseif AddOn.InvalidateSyncMerkle then
		AddOn:InvalidateSyncMerkle()
	end
	return true
end
--------------------------------
function AddOn:SetFlightPath(originNodeID, destNodeID, samples)
	originNodeID = tonumber(originNodeID)
	destNodeID = tonumber(destNodeID)
	if not originNodeID or not destNodeID or type(samples) ~= "table" then
		return
	end
	local copy = copyPathSamples(samples)
	if not copy then
		return
	end
	local _, oldN = AddOn:GetFlightPathMeta(originNodeID, destNodeID)
	writePathRecord(originNodeID, destNodeID, copy, (oldN or 0) + 1, false)
end
--------------------------------
function AddOn:ApplySyncedFlightPath(originNodeID, destNodeID, samples, n)
	originNodeID = tonumber(originNodeID)
	destNodeID = tonumber(destNodeID)
	n = math.max(1, math.floor(tonumber(n) or 1))
	if not originNodeID or not destNodeID or type(samples) ~= "table" then
		return
	end
	local copy = copyPathSamples(samples)
	if not copy then
		return
	end
	writePathRecord(originNodeID, destNodeID, copy, n, true)
end
--------------------------------
function AddOn:ForEachFlightPath(fn)
	if type(fn) ~= "function" then
		return
	end
	local store = ensurePathStore()
	if not store or type(store.paths) ~= "table" then
		return
	end
	for origin, tos in pairs(store.paths) do
		origin = tonumber(origin)
		if origin and type(tos) == "table" then
			for dest, value in pairs(tos) do
				dest = tonumber(dest)
				local samples, n = readPathRecord(value)
				if dest and samples then
					fn(origin, dest, samples, n)
				end
			end
		end
	end
end
--------------------------------
function AddOn:CountKnownFlightData()
	local times, paths = 0, 0
	AddOn:ForEachFlightTime(function()
		times = times + 1
	end)
	AddOn:ForEachFlightPath(function()
		paths = paths + 1
	end)
	return times, paths
end
--------------------------------
function AddOn:PrintFlightDataCount()
	local times, paths = AddOn:CountKnownFlightData()
	AddOn:Print(string.format(AddOn.L.flightDataCount, times, paths))
end
--------------------------------
function AddOn:WipeFactionFlightTimes()
	local store = ensureStore()
	if not store then
		return
	end
	store.times = {}
	if AddOn.InvalidateSyncMerkle then
		AddOn:InvalidateSyncMerkle()
	end
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
		local leg = AddOn:GetFlightTimeOrReverse(originID, destID)
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
	local seconds, fromReverse = AddOn:GetFlightTimeOrReverse(originID, destID)
	if seconds then
		return seconds, fromReverse
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
function AddOn:FormatEstimatedFlightTime(seconds)
	return "\226\137\136 " .. AddOn:FormatFlightTime(seconds)
end
--------------------------------
function AddOn:AddFlightTimeTooltipLine(destSlot)
	if not AddOn:GetShowFlightTimes() then
		return
	end
	local L = AddOn.L
	local seconds, estimated = AddOn:GetDisplayedFlightTime(destSlot)
	if seconds then
		local formatted
		if estimated then
			formatted = AddOn:FormatEstimatedFlightTime(seconds)
		else
			formatted = AddOn:FormatFlightTime(seconds)
		end
		GameTooltip:AddLine("|cffffd100" .. L.flightTimeLabel .. "|r |cffffffff" .. formatted .. "|r", 1, 1, 1)
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
		known = pending.known,
		pathSamples = pending.pathSamples,
	}
end
--------------------------------
local function stopFlightPathSampling()
	if pathTimer then
		AddOn.Timer:CancelTimer(pathTimer)
		pathTimer = nil
	end
end
--------------------------------
local function sampleFlightPath()
	if not pending then
		return
	end
	pending.pathSamples = pending.pathSamples or {}
	if type(AddOn.GetPlayerWorldPosition) == "function" then
		local pos = AddOn:GetPlayerWorldPosition()
		if not pos then
			return
		end
		pending.pathSamples[#pending.pathSamples + 1] = pos
	end
end
--------------------------------
local function startFlightPathSampling()
	stopFlightPathSampling()
	if not pending then
		return
	end
	pending.pathSamples = pending.pathSamples or {}
	sampleFlightPath()
	pathTimer = AddOn.Timer:ScheduleRepeatingTimer(function()
		if pending and pending.confirmed and UnitOnTaxi("player") then
			sampleFlightPath()
		end
	end, PATH_SAMPLE_INTERVAL)
end
--------------------------------
function AddOn:AbortFlightTimeSample()
	local wasFlying = pending and pending.confirmed
	stopFlightPathSampling()
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
	sampleFlightPath()
	local pathSamples = pending.pathSamples
	AddOn:AbortFlightTimeSample()
	if invalid then
		return
	end
	local elapsed = math.floor(GetTime() - startTime + 0.5)
	if elapsed > 0 then
		AddOn:SetFlightTime(originID, destID, elapsed)
	end
	if type(pathSamples) == "table" and #pathSamples > 0 then
		AddOn:SetFlightPath(originID, destID, pathSamples)
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
	startFlightPathSampling()
	persistActiveFlight()
	AddOn:SendMessage(
		AddOn.Message.TAXI_START,
		pending.originID,
		pending.destID,
		pending.duration,
		pending.destName,
		pending.estimated,
		pending.arrivalClock,
		pending.numHops,
		pending.known
	)
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
	-- TODO we should show an inflight control so the early landing and sound control are still available.
	-- we could do this by altering the flight destination text widget to have all borders but be be one
	-- layer below the progress frame, so that when the progress frame is hidden in this state.
	-- OR, when the flight time is unknown create loop animation of the progress bar with the text
	-- "Learning about this flight path
	if not AddOn:GetEnabled() then
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

	local flightTime, fromReverse = AddOn:GetFlightTimeOrReverse(originID, destID)
	local known = flightTime ~= nil and not fromReverse
	local numHops = GetNumRoutes and GetNumRoutes(index)
	pending = {
		originID = originID,
		destID = destID,
		startTime = GetTime(),
		confirmed = false,
		invalid = false,
		duration = flightTime or AddOn:EstimateFlightTime(index),
		destName = destName,
		estimated = not known,
		numHops = tonumber(numHops),
		known = known,
	}

	if UnitOnTaxi("player") then
		confirmTakeoff()
	end
	startFlightTimeWatch()
end
--------------------------------
function AddOn:OnFlightTimeControlGained()
	local playSound = AddOn.ShouldFlightTimerPlayArrivalSound and AddOn:ShouldFlightTimerPlayArrivalSound()
	finishFlightTimeSample()
	if playSound then
		AddOn:PlayArrivalSound()
	end
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
				known = saved.known,
				pathSamples = saved.pathSamples,
			}
			if not controlEventRegistered then
				controlEventRegistered = true
				AddOn:RegisterEvent("PLAYER_CONTROL_GAINED", "OnFlightTimeControlGained")
			end
			startFlightPathSampling()
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
					saved.numHops,
					saved.known
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
	migrateGlobalFlightData()
	ensureStore()
	ensurePathStore()
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
