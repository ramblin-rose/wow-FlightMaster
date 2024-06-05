-- This feature is in an intermediary state and is not ready for beta
--The inverse of travel time from point A to point B is not always equal
local AddOn = _G[select(1, ...)]
--------------------------------
local taxiRequestEarlyLanding = false
--------------------------------
function AddOn:InitTaxiLog()
	AddOn.db.global.taxiLog = AddOn.db.global.taxiLog or {}

	AddOn:AddMessageHandler(AddOn.Message.TAXI_START, function(...)
		AddOn:onTaxiStart(...)
	end)
	-- invalidate logging if early landing requested
	AddOn:SecureHook("TaxiRequestEarlyLanding", function()
		taxiRequestEarlyLanding = true
	end)
end
--------------------------------
function AddOn:onTaxiStart(mapID, key)
	local startTime = GetTime()

	taxiRequestEarlyLanding = false

	AddOn:RegisterEvent("PLAYER_CONTROL_GAINED", function()
		-- AddOn:onTaxiEnd(mapID, key, startTime)
	end)
end
--------------------------------
function AddOn:onTaxiEnd(mapID, key, startTime)
	AddOn:UnregisterEvent("PLAYER_CONTROL_GAINED")

	if taxiRequestEarlyLanding == false then
		-- AddOn:LogTravelTime(mapID, key, GetTime() - startTime)
	end
end
--------------------------------
local util = AddOn.Utility
function AddOn:GetTaxiLogKey(startPos, endPos)
	return util.round(startPos.x * 100)
		.. ","
		.. util.round(startPos.y * 100)
		.. "|"
		.. util.round(endPos.x * 100)
		.. ","
		.. util.round(endPos.y * 100)
end
--------------------------------
function AddOn:LogTravelTime(mapID, key, timeSpan)
	local db = AddOn.db.global.taxiLog
	db[mapID] = db[mapID] or {}
	db[mapID][key] = util.round(timeSpan)
	return db[mapID][key]
end
--------------------------------
function AddOn:GetTravelTime(mapID, key)
	local db = AddOn.db.global.taxiLog
	if db[mapID] then
		return db[mapID][key]
	end
end
