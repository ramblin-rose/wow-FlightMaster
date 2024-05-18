local AddOn = _G[select(1, ...)]
--------------------------------
function AddOn:InitTaxi()
	AddOn.taxiNodePositions = {}
	AddOn.taxiButtons = {}
	AddOn.routeLines = {}
	AddOn.factionGroup = UnitFactionGroup("player")
end
--------------------------------
function AddOn:DisplayTaxiNode(button, nodeType, x, y)
	button:ClearAllPoints()
	button:SetNormalTexture(TaxiButtonTypes[nodeType].file)
	button:SetPoint("CENTER", AddOn.frame, AddOn.VIEWPORT_ORIGIN, x, y)
	button:SetNormalTexture(TaxiButtonTypes[nodeType].file)
	button:GetHighlightTexture():SetAlpha(TaxiButtonTypes[nodeType].highlightBrightness)
	button:Show()
end
--------------------------------
function AddOn:HideTaxiNodeButtons()
	local taxiButtons = AddOn.taxiButtons
	for _, button in ipairs(taxiButtons) do
		button:Hide()
	end
end
--------------------------------
function AddOn:TaxiNodeOnButtonEnter(button)
	local index = button:GetID()

	local numNodes = NumTaxiNodes()
	local numRoutes = GetNumRoutes(index)
	local nodeType = TaxiNodeGetType(index)
	local taxiButtons = AddOn.taxiButtons
	local isZone = AddOn.mapInfo and AddOn.mapInfo.mapType ~= 2
	local line

	AddOn:HideRouteLines()

	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:AddLine(TaxiNodeName(index), nil, nil, nil, true)

	if nodeType ~= "DISTANT" then
		local currType
		for i = 1, numNodes do
			currType = TaxiNodeGetType(i)
			if currType == "DISTANT" then
				taxiButtons[i]:Hide()
			end
		end
	end

	if nodeType == "REACHABLE" then
		SetTooltipMoney(GameTooltip, TaxiNodeCost(button:GetID()))
		if not isZone then
			for i = 1, numRoutes do
				line = AddOn:GetRouteLine(i)
				if i <= numRoutes then
					AddOn:PerformRouteLineDraw(line, index, i, AddOn.frameRouteMap)
					line:Show()
				else
					line:Hide()
				end
			end
		end
	elseif nodeType == "UNREACHABLE" then
		button:SetNormalTexture(TaxiButtonTypes[nodeType].hoverFile)
		button:GetHighlightTexture():SetAlpha(TaxiButtonTypes[nodeType].highlightBrightness)
	elseif nodeType == "CURRENT" then
		GameTooltip:AddLine(TAXINODEYOUAREHERE, 1.0, 1.0, 1.0, true)
		AddOn:DrawOneHopLines()
	end

	GameTooltip:Show()
end
--------------------------------
function AddOn:TaxiNodeOnButtonLeave(button)
	GameTooltip:Hide()
	local index = button:GetID()
	local nodeType = TaxiNodeGetType(index)
	if TaxiButtonTypes[nodeType] then
		-- Don't leave it with the hover icon (if it had one)
		button:SetNormalTexture(TaxiButtonTypes[nodeType].file)
	end
end
--------------------------------
function AddOn:GetMapTaxiNodes(mapID)
	local nodes = C_TaxiMap.GetTaxiNodesForMap(mapID)
	local result = {}
	for i, e in ipairs(nodes) do
		if AddOn:ShouldShowTaxiNode(e) then
			result[e.name] = e
		end
	end
	return result
end
--------------------------------
function AddOn:ShouldShowTaxiNode(taxiNodeInfo)
	if taxiNodeInfo.faction == Enum.FlightPathFaction.Horde then
		return AddOn.factionGroup == "Horde"
	end

	if taxiNodeInfo.faction == Enum.FlightPathFaction.Alliance then
		return AddOn.factionGroup == "Alliance"
	end

	return true
end
--------------------------------
function AddOn:EnsureTaxiNodes(taxiButtons, numNodes)
	if numNodes > #taxiButtons then
		local button
		for i = #taxiButtons + 1, numNodes do
			button = CreateFrame("Button", nil, AddOn.frame, "TaxiNodeButtonTemplate")
			button:SetID(i)
			table.insert(taxiButtons, button)
		end
	end
end
--------------------------------
-- empirical values
local nudgeNodes = {
	[1414] = { -- Kalimdor
		["41,60"] = { x = 4, y = 12 },
		["44,46"] = { x = -5, y = 5 },
		["45,47"] = { x = 6, y = -2 },
		["47,40"] = { x = -5, y = 2 },
		["48,43"] = { x = 2, y = -2 },
		["49,81"] = { x = -6, y = 4 },
		["50,81"] = { x = 6, y = -2 },
	},
	[113] = { -- Northrend
		["52,33"] = { x = -2, y = 4 },
		["52,34"] = { x = 0, y = -3 },
		["65,45"] = { x = -3, y = 2 },
		["67,47"] = { x = 3, y = 12 },
	},
	[1415] = { -- Eastern Kingdoms
		["52,33"] = { x = -2, y = -4 }, -- Throndroril River, Eastern Plaguelands
		["56,32"] = { x = -8, y = 0 }, -- Light's Shield Tower, Eastern Plaguelands
		["57,30"] = { x = -8, y = 0 }, -- Eastwall Tower, Eastern Plaguelands
		["55,35"] = { x = -12, y = 4 }, -- Crown Guard Tower, Eastern Plaguelands
		["47,62"] = { x = 0, y = -16 }, -- Thorium Point, Searing Gorge
		["53,77"] = { x = 6, y = 0 }, -- Bogpaddle, Swamp of Sorrows
		["54,75"] = { x = 0, y = -26 }, -- Marshtide Watch, Swamp of Sorrows
		["53,80"] = { x = 0, y = -12 }, -- Nethergarde Keep, Blasted Lands
		["50,53"] = { x = 4, y = 0 }, -- Greenwarden's Grove, Wetlands
		["51,53"] = { x = -16, y = -4 }, -- Whelgar's Retreat, Wetlands
	},
	[1955] = { -- Outlands
	},
	[203] = { -- Vashj'ir
	},
}

local defaultNudge = { x = 0, y = 0 }
--------------------------------
function AddOn:GetTaxiNodeNudgeKey(x, y)
	return math.floor(x * 100) .. "," .. math.floor(y * 100)
end
--------------------------------
function AddOn:GetTaxiNodeNudge(mapID, mapTaxiNode)
	local list = nudgeNodes[mapID]
	local nudge = defaultNudge
	local key
	if list then
		key = AddOn:GetTaxiNodeNudgeKey(mapTaxiNode.position.x, mapTaxiNode.position.y)
		nudge = nudgeNodes[mapID][key] or nudge
	end
	return nudge, key
end
--------------------------------
-- returns x, y, shouldDisplay
function AddOn:FinalizeNodePosition(mapInfo, mapTaxiNode, button, width, height)
	local shouldDisplay = true
	local x, y = mapTaxiNode.position.x * width, mapTaxiNode.position.y * -height
	-- prevent dangling taxi nodes on the edge of zone maps
	if mapInfo.mapType == 3 then
		if x < 0 or x > (width - button:GetWidth()) then
			shouldDisplay = false
		elseif y > button:GetHeight() or math.abs(y) > (height - button:GetHeight()) then
			shouldDisplay = false
		end
	end

	-- soothe the irritation of overlapping mercurial boots. Serenity Now!
	local nudge = AddOn:GetTaxiNodeNudge(mapInfo.mapID, mapTaxiNode)
	x = x + nudge.x
	y = y + nudge.y
	return x, y, shouldDisplay
end
--------------------------------
function AddOn:UpdateTaxiMap()
	local mapID = WorldMapFrame:GetMapID()
	local mapInfo = C_Map.GetMapInfo(mapID)
	local playerContinentMapID = AddOn:GetPlayerContinentMapID()
	local taxiNodePositions = AddOn.taxiNodePositions
	local taxiButtons = AddOn.taxiButtons

	AddOn:HideRouteLines()
	AddOn:HideTaxiNodeButtons()
	AddOn.mapInfo = nil
	wipe(taxiNodePositions)
	-- mapInfo.mapType 2 (continent) must match player continent;
	-- mapInfo.mayType 3 (zone) must be a zone in player continent;
	-- ignore otherwise.
	if
		(mapInfo.mapType == 2 and mapID == playerContinentMapID)
		or (mapInfo.mapType == 3 and (AddOn:GetNearestContinentID(mapID) == playerContinentMapID))
	then
		local numNodes = NumTaxiNodes()
		local button

		AddOn.mapInfo = mapInfo
		AddOn.frame:SetAllPoints()
		AddOn.frameRouteMap:SetAllPoints()
		AddOn:EnsureTaxiNodes(taxiButtons, numNodes)

		local mapTaxiNodes = AddOn:GetMapTaxiNodes(mapID)

		if mapTaxiNodes then
			local nodeType, mapTaxiNode
			local width = AddOn.frame:GetWidth()
			local height = AddOn.frame:GetHeight()
			local posNode
			local shouldDisplay

			for i = 1, numNodes do
				mapTaxiNode = mapTaxiNodes[TaxiNodeName(i)]
				button = taxiButtons[i]
				nodeType = TaxiNodeGetType(i)
				if mapTaxiNode then
					taxiNodePositions[i] = {
						type = nodeType,
						node = mapTaxiNode,
					}

					posNode = taxiNodePositions[i]

					posNode.x, posNode.y, shouldDisplay =
						AddOn:FinalizeNodePosition(mapInfo, mapTaxiNode, button, width, height)

					if shouldDisplay then
						AddOn:DisplayTaxiNode(button, nodeType, posNode.x, posNode.y)
					end
				end
			end
			-- only draw route lines at continent level
			AddOn:DrawOneHopLines()
		end
	end
end
--------------------------------
function AddOn:TaxiTakeNode(id)
	TakeTaxiNode(id)
end
