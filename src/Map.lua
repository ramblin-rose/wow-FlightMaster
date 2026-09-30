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
function AddOn:GetPlayerWorldPosition()
	if UnitPosition then
		local posY, posX, posZ, instanceID = UnitPosition("player")
		if posX and posY then
			return {
				x = posX,
				y = posY,
				z = posZ,
				instanceID = instanceID,
			}
		end
	end
	local mapID = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	if not mapID or not C_Map.GetPlayerMapPosition or not C_Map.GetWorldPosFromMapPos then
		return
	end
	local mapPos = C_Map.GetPlayerMapPosition(mapID, "player")
	if not mapPos then
		return
	end
	local x, y = AddOn:GetPositionXY(mapPos)
	if not x or not y then
		return
	end
	local fromPos = (CreateVector2D and CreateVector2D(x, y)) or { x = x, y = y }
	local continentID, worldPos = C_Map.GetWorldPosFromMapPos(mapID, fromPos)
	if not continentID or not worldPos then
		return
	end
	local wx, wy = AddOn:GetPositionXY(worldPos)
	if not wx or not wy then
		return
	end
	-- Store in UnitPosition order (x = east-west, y = north-south).
	return {
		x = wy,
		y = wx,
		instanceID = continentID,
	}
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
function AddOn:WorldToMapXY(worldX, worldY, instanceID, toMapID)
	if not worldX or not worldY or not toMapID or not C_Map.GetMapPosFromWorldPos then
		return
	end
	-- World x/y follow UnitPosition (east-west, north-south). C_Map world Vector2D is
	-- rotated 90°: Vector2D.x is north-south, Vector2D.y is east-west.
	local vector = (CreateVector2D and CreateVector2D(worldY, worldX)) or { x = worldY, y = worldX }
	local function tryConvert(continentID)
		if not continentID then
			return
		end
		local ok, mapIDOrPos, mapPos = pcall(C_Map.GetMapPosFromWorldPos, continentID, vector, toMapID)
		if not ok then
			return
		end
		if mapPos then
			return AddOn:GetPositionXY(mapPos)
		end
		if type(mapIDOrPos) == "table" then
			return AddOn:GetPositionXY(mapIDOrPos)
		end
	end
	local x, y = tryConvert(instanceID)
	if x then
		return x, y
	end
	if C_Map.GetWorldPosFromMapPos then
		local origin = (CreateVector2D and CreateVector2D(0.5, 0.5)) or { x = 0.5, y = 0.5 }
		local mapInstance = C_Map.GetWorldPosFromMapPos(toMapID, origin)
		if mapInstance and mapInstance ~= instanceID then
			return tryConvert(mapInstance)
		end
	end
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
