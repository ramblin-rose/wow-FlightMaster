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
--------------------------------
function AddOn:GetPositionXY(position)
	if not position then
		return
	end
	if position.GetXY then
		return position:GetXY()
	end
	return position.x, position.y
end
--------------------------------
function AddOn:ConvertMapPosition(position, fromMapID, toMapID)
	if not position or not fromMapID or not toMapID then
		return
	end
	if fromMapID == toMapID then
		return position
	end
	if not C_Map.GetWorldPosFromMapPos or not C_Map.GetMapPosFromWorldPos then
		return
	end

	local x, y = AddOn:GetPositionXY(position)
	if not x or not y then
		return
	end

	local fromPos = (CreateVector2D and CreateVector2D(x, y)) or { x = x, y = y }
	local continentID, worldPos = C_Map.GetWorldPosFromMapPos(fromMapID, fromPos)
	if not continentID or not worldPos then
		return
	end
	local _, mapPos = C_Map.GetMapPosFromWorldPos(continentID, worldPos, toMapID)
	return mapPos
end
--------------------------------
function AddOn:IsPositionOnMap(position)
	local x, y = AddOn:GetPositionXY(position)
	return x and y and x >= -0.05 and x <= 1.05 and y >= -0.05 and y <= 1.05
end
