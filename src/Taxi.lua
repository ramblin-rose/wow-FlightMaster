local AddOn = _G[select(1, ...)]
--------------------------------
function AddOn:InitTaxi()
	AddOn.taxiNodePositions = {}
	AddOn.taxiButtons = {}
	AddOn.factionGroup = UnitFactionGroup("player")
	WorldMapFrame:AddDataProvider(CreateFromMixins(FlightMasterPointDataProviderMixin))
end
--------------------------------
function AddOn:EnsureTaxiButtons(numNodes)
	if numNodes > #AddOn.taxiButtons then
		local button
		for i = #AddOn.taxiButtons + 1, numNodes do
			button = CreateFrame("Button", nil, AddOn.frame, "TaxiNodeButtonTemplate")
			button:SetID(i)
			table.insert(AddOn.taxiButtons, button)
		end
	end
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
function AddOn:GetNamedMapTaxiNodes(mapID)
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
function AddOn:ShouldShowTaxiNode(taxiNode)
	if taxiNode.faction == Enum.FlightPathFaction.Horde then
		return AddOn.factionGroup == "Horde"
	end

	if taxiNode.faction == Enum.FlightPathFaction.Alliance then
		return AddOn.factionGroup == "Alliance"
	end

	return true
end
--------------------------------
function AddOn:GetSourceTaxiNodeIndex()
	local numNodes = NumTaxiNodes()
	for i = 1, numNodes do
		if TaxiNodeGetType(i) == "CURRENT" then
			return i
		end
	end
	assert(false)
end
--------------------------------
function AddOn:TaxiTakeNode(id)
	local source, dest = AddOn.taxiNodePositions[AddOn:GetSourceTaxiNodeIndex()], AddOn.taxiNodePositions[id]
	local key = AddOn:GetTaxiLogKey(source.position, dest.position)
	AddOn:SendMessage(AddOn.Message.TAXI_START, AddOn:GetPlayerContinentMapID(), key)
	TakeTaxiNode(id)
end
