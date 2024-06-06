local AddOn = _G[select(1, ...)]
--------------------------------
function AddOn:InitMap() end
--------------------------------
function AddOn:GetNearestContinentID(mapID)
	if mapID then
		local mapInfo = C_Map.GetMapInfo(mapID)
		if mapInfo then
			if mapInfo.mapType == 2 then
				return mapID
			elseif mapInfo.mapType > 2 then
				return AddOn:GetNearestContinentID(mapInfo.parentMapID)
			end
		end
	end
end
--------------------------------
function AddOn:GetPlayerContinentMapID()
	local mapID = C_Map.GetBestMapForUnit("player")
	return AddOn:GetNearestContinentID(mapID)
end
--------------------------------
function AddOn:GetPlayerMapPosition()
	local mapID = C_Map.GetBestMapForUnit("player")
	if mapID then
		return C_Map.GetPlayerMapPosition(mapID, "player")
	end
end
