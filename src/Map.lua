local AddOn = _G[select(1, ...)]
--------------------------------
local continentMapType = (Enum and Enum.UIMapType and Enum.UIMapType.Continent) or 2
--------------------------------
function AddOn:InitMap() end
--------------------------------
function AddOn:GetContinentMapType()
	return continentMapType
end
--------------------------------
function AddOn:GetNearestContinentID(mapID)
	if not mapID then
		return
	end

	local mapInfo = C_Map.GetMapInfo(mapID)
	if not mapInfo then
		return
	end

	if mapInfo.mapType == continentMapType then
		return mapID
	end

	if MapUtil and MapUtil.GetMapParentInfo then
		local parent = MapUtil.GetMapParentInfo(mapID, continentMapType)
		if parent and parent.mapID then
			return parent.mapID
		end
	end

	if mapInfo.mapType > continentMapType then
		return AddOn:GetNearestContinentID(mapInfo.parentMapID)
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
