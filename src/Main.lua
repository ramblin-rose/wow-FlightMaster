local AddOn = _G[select(1, ...)]
local L = AddOn.L
--------------------------------
function AddOn:OnInitialize()
	local options = {
		name = AddOn.String.CommandName,
		handler = self,
		type = "group",
		args = {
			[L.on] = {
				name = L.on,
				desc = ENABLE .. " " .. AddOn.String.Title,
				type = "input",
				set = function()
					AddOn:SendMessage(AddOn.Message.ENABLE_ADDON)
					AddOn:Print(READY)
					AddOn:SetEnabled(true)
				end,
			},
			[L.off] = {
				name = L.off,
				desc = DISABLE .. " " .. AddOn.String.Title,
				type = "input",
				set = function()
					AddOn:SendMessage(AddOn.Message.DISABLE_ADDON)
					AddOn:Print(ADDON_DISABLED)
					AddOn:SetEnabled(false)
				end,
			},
		},
	}
	LibStub("AceConfig-3.0"):RegisterOptionsTable(tostring(self), options, AddOn.String.CommandName)

	AddOn.db = LibStub("AceDB-3.0"):New(AddOn.name .. "DB", {
		global = {},
	})

	AddOn.messageHandler = {
		[AddOn.Message.ENABLE_ADDON] = AddOn.onEnableAddOn,
		[AddOn.Message.DISABLE_ADDON] = AddOn.onDisableAddOn,
	}

	AddOn:RegisterMessage(AddOn.Message.ENABLE_ADDON, function(...)
		AddOn:onMessage(...)
	end)
	AddOn:RegisterMessage(AddOn.Message.DISABLE_ADDON, function(...)
		AddOn:onMessage(...)
	end)
	AddOn:SecureHookScript(WorldMapFrame, "OnHide", AddOn.OnHideWorldMapFrame)
	AddOn:SecureHookScript(WorldMapFrame, "OnEvent", function(_, event)
		-- todo workaround for zoom
		if event == "QUEST_LOG_UPDATE" then
			AddOn:UpdateMapTaxiNodes()
		end
	end)
	AddOn:SecureHook(WorldMapFrame, "Maximize", function()
		AddOn:UpdateMapTaxiNodes()
	end)
	AddOn:SecureHook(WorldMapFrame, "Minimize", function()
		AddOn:UpdateMapTaxiNodes()
	end)

	AddOn.frame = CreateFrame("Frame", "FlightPathTonicFrame", WorldMapFrame.ScrollContainer)
	AddOn.frame:SetFrameStrata("HIGH")
	AddOn.frame:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 100)
	AddOn.frameRouteMap = CreateFrame("Frame", "FlightPathTonicFrameRouteMap", AddOn.frame)
	AddOn.frameRouteMap:SetFrameStrata(AddOn.frame:GetFrameStrata())
	AddOn.frameRouteMap:SetFrameLevel(AddOn.frame:GetFrameLevel() - 10)

	AddOn.taxiNodePositions = {}
	AddOn.taxiButtons = {}
	AddOn.routeLines = {}
	AddOn.factionGroup = UnitFactionGroup("player")

	AddOn:SetEnabled(true)
	AddOn:SendMessage(AddOn.Message.ENABLE_ADDON)
end
--------------------------------
function AddOn:onMessage(message, ...)
	local handler = AddOn.messageHandler[message]
	if type(handler) == "function" then
		handler(...)
	end
end
--------------------------------
function AddOn:SetEnabled(enable)
	AddOn.enabled = enable
end
--------------------------------
function AddOn:GetEnabled()
	return AddOn.enabled
end
--------------------------------
function AddOn:onEnableAddOn()
	TaxiFrame:Hide()
	WorldMapFrame:Hide()
	AddOn:RegisterEvent("TAXIMAP_OPENED", AddOn.OnTaxiMapOpened)
end
--------------------------------
function AddOn:onDisableAddOn()
	TaxiFrame:Hide()
	WorldMapFrame:Hide()
	AddOn:UnregisterEvent("TAXIMAP_OPENED")
end
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
function AddOn:OnHideTaxiFrame(...)
	-- Do nothing stub. Deferring this event until the WorldMapFrame closes maintains the flight master context (taxi nodes)
	-- Once the WorldMapFrame is closed the TaxiFrame event is invoked and this hook removed.
end
--------------------------------
function AddOn:OnTaxiMapOpened(...)
	AddOn.flightMasterName = UnitName("target")
	-- hooking the OnHide method allows the context - i.e. taxi nodes - of the flight master to remain whilst player interacts with WorldMapFrame
	-- when WorldMapFrame is closed this context is released
	local hook = AddOn.hooks[TaxiFrame]
	if not hook or hook.OnHide == nil then
		AddOn:RawHookScript(TaxiFrame, "OnHide", "OnHideTaxiFrame")
	end

	ToggleWorldMap()
	WorldMapFrame:SetMapID(AddOn:GetPlayerContinentMapID())
	AddOn:UpdateMapTaxiNodes()
end
--------------------------------
function AddOn:OnHideWorldMapFrame()
	if AddOn.flightMasterName then
		AddOn:HideTaxiButtons()
		if AddOn.hooks[TaxiFrame] and AddOn.hooks[TaxiFrame].OnHide then
			AddOn.hooks[TaxiFrame]:OnHide(TaxiFrame)
			AddOn:Unhook(TaxiFrame, "OnHide")
		end
		AddOn.flightMasterName = nil
	end
end
--------------------------------
-- Namely get world coordinates of nodes that may be shown
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
function AddOn:HideTaxiButtons()
	local taxiButtons = AddOn.taxiButtons
	for _, button in ipairs(taxiButtons) do
		button:Hide()
	end
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
function AddOn:DisplayTaxiNode(button, nodeType, x, y)
	button:SetParent(AddOn.frame)
	button:ClearAllPoints()
	button:SetNormalTexture(TaxiButtonTypes[nodeType].file)

	button:SetPoint("CENTER", AddOn.frame, "TOPLEFT", x, y)
	button:SetNormalTexture(TaxiButtonTypes[nodeType].file)
	button:GetHighlightTexture():SetAlpha(TaxiButtonTypes[nodeType].highlightBrightness)
	button:Show()
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
function AddOn:UpdateMapTaxiNodes()
	local mapID = WorldMapFrame:GetMapID()
	local mapInfo = C_Map.GetMapInfo(mapID)
	local playerContinentMapID = AddOn:GetPlayerContinentMapID()
	local taxiNodePositions = AddOn.taxiNodePositions
	local taxiButtons = AddOn.taxiButtons

	AddOn:HideRouteLines()
	AddOn:HideTaxiButtons()
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
			local x, y

			for i = 1, numNodes do
				mapTaxiNode = mapTaxiNodes[TaxiNodeName(i)]
				button = taxiButtons[i]
				nodeType = TaxiNodeGetType(i)
				if mapTaxiNode then
					taxiNodePositions[i] = {
						type = nodeType,
						mapTaxiNode = mapTaxiNode,
						name = mapTaxiNode.name,
						x = mapTaxiNode.position.x,
						y = mapTaxiNode.position.y,
					}

					x, y = mapTaxiNode.position.x * width, mapTaxiNode.position.y * -height

					-- prevent dangling taxi nodes on the edge of zone maps
					local onEdge = false
					if mapInfo.mapType == 3 then
						if x < 0 or x > (width - button:GetWidth()) then
							onEdge = true
						elseif y > button:GetHeight() or math.abs(y) > (height - button:GetHeight()) then
							onEdge = true
						end
					end
					if not onEdge then
						-- soothe the irritation of overlapping mercurial boots. Serenity Now!
						local nudge = AddOn:GetTaxiNodeNudge(mapID, mapTaxiNode)
						x = x + nudge.x
						y = y + nudge.y
						AddOn:DisplayTaxiNode(button, nodeType, x, y)
					end
				end
			end
			-- only draw route lines at continent level
			AddOn:DrawOneHopLines()
		end
	end
end
--------------------------------
function AddOn:NudgeTaxiNodes() end
--------------------------------
function AddOn:GetRouteLine(lineIndex)
	local routeLines = AddOn.routeLines
	local line
	if lineIndex > #routeLines then
		line = AddOn.frameRouteMap:CreateTexture(nil, "BACKGROUND")
		line:SetTexture("Interface\\TaxiFrame\\UI-Taxi-Line")
		table.insert(routeLines, line)
	else
		line = routeLines[lineIndex]
	end
	return line
end
--------------------------------
function AddOn:HideRouteLines()
	local routeLines = AddOn.routeLines
	for i = 1, #routeLines do
		AddOn:GetRouteLine(i):Hide()
	end
end
--------------------------------
---@return number, number
function AddOn:PerformRouteLineDraw(line, taxiNodeIndex, routeNodeIndex, frame)
	local taxiNodePositions = AddOn.taxiNodePositions
	local width = frame:GetWidth()
	local height = frame:GetHeight()
	local srcSlot, dstSlot
	local sX, sY, dX, dY
	local nudge
	---@diagnostic disable-next-line: redundant-parameter
	srcSlot = TaxiGetNodeSlot(taxiNodeIndex, routeNodeIndex, true)
	nudge = AddOn:GetTaxiNodeNudge(AddOn.mapInfo.mapID, taxiNodePositions[srcSlot].mapTaxiNode)
	sX = (taxiNodePositions[srcSlot].x + (nudge.x / 1000)) * width
	sY = (1.0 - (taxiNodePositions[srcSlot].y + (nudge.y / -1000))) * height

	---@diagnostic disable-next-line: redundant-parameter
	dstSlot = TaxiGetNodeSlot(taxiNodeIndex, routeNodeIndex, false)
	if taxiNodePositions[dstSlot] then
		nudge = AddOn:GetTaxiNodeNudge(AddOn.mapInfo.mapID, taxiNodePositions[dstSlot].mapTaxiNode)
		dX = (taxiNodePositions[dstSlot].x + (nudge.x / 1000)) * width
		dY = (1.0 - taxiNodePositions[dstSlot].y + (nudge.y / 1000)) * height

		DrawLine(line, AddOn.frameRouteMap, sX, sY, dX, dY, 32, TAXIROUTE_LINEFACTOR)
		line:Show()
	end
	---@diagnostic disable-next-line: return-type-mismatch
	return srcSlot, dstSlot
end
function AddOn:DrawOneHopLines()
	if AddOn.mapInfo and AddOn.mapInfo.mapType == 2 then
		local numNodes = NumTaxiNodes()
		if numNodes > 0 then
			local numLines = 0
			local numSingleHops = 0
			local routeLines = AddOn.routeLines
			local nodeType, line

			for i = 1, numNodes do
				nodeType = TaxiNodeGetType(i)
				---@diagnostic disable-next-line: redundant-parameter
				if (nodeType == "REACHABLE") and TaxiIsDirectFlight(i) then
					numSingleHops = numSingleHops + 1
					numLines = numLines + 1
					line = AddOn:GetRouteLine(numLines)
					if line then
						AddOn:PerformRouteLineDraw(line, i, 1, AddOn.frameRouteMap)
					end
				elseif nodeType == "DISTANT" then
					numSingleHops = numSingleHops + 1
					local button = AddOn.taxiButtons[i]
					button:Hide()
				end
			end
			for i = numLines + 1, #routeLines do
				line = AddOn:GetRouteLine(i)
				line:Hide()
			end

			if numSingleHops == 0 then
				UIErrorsFrame:AddMessage(ERR_TAXINOPATHS, 1.0, 0.1, 0.1, 1.0)
			end
		end
	end
end
--------------------------------
function AddOn:TaxiNodeOnButtonEnter(button)
	local index = button:GetID()

	local numNodes = NumTaxiNodes()
	local numRoutes = GetNumRoutes(index)
	local nodeType = TaxiNodeGetType(index)
	local taxiButtons = AddOn.taxiButtons
	local routeLines = AddOn.routeLines
	local isZone = AddOn.mapInfo and AddOn.mapInfo.mapType ~= 2
	local taxiNodePositions = AddOn.taxiNodePositions
	local node = taxiNodePositions[index]
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
			if numRoutes > #routeLines then
				for i = #routeLines + 1, numRoutes do
					AddOn:GetRouteLine(i)
				end
			end
			local dstSlot
			for i = 1, numRoutes do
				line = AddOn:GetRouteLine(i)
				if i <= numRoutes then
					dstSlot = AddOn:PerformRouteLineDraw(line, index, i, AddOn.frameRouteMap)
					nodeType = TaxiNodeGetType(dstSlot)
					if nodeType == "DISTANT" then
						button = taxiButtons[dstSlot]
						button:Show()
					end
				else
					line:Hide()
				end
			end
		end
	elseif nodeType == "UNREACHABLE" then
		button:SetNormalTexture(TaxiButtonTypes[nodeType].hoverFile)
		button:GetHighlightTexture():SetAlpha(TaxiButtonTypes[nodeType].highlightBrightness)
		-- AddOn:HideRouteLines()
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
