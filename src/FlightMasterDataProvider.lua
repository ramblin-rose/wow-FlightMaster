local AddOn = _G[select(1, ...)]
--------------------------------
FlightMasterPointDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin)
function AddOn:InitFlightMasterDataProvider()
	AddOn.factionGroup = UnitFactionGroup("player")
	AddOn.taxiNodePositions = {}
	AddOn.showUnknownPoints = false
	AddOn.dataProvider = CreateFromMixins(FlightMasterPointDataProviderMixin)
	WorldMapFrame:AddDataProvider(AddOn.dataProvider)
end
--------------------------------
function FlightMasterPointDataProviderMixin:OnAdded(mapCanvas)
	MapCanvasDataProviderMixin.OnAdded(self, mapCanvas)
	AddOn.lineCanvas = AddOn.frameRouteMap
end
--------------------------------
function FlightMasterPointDataProviderMixin:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate("FlightMasterPointPinTemplate")
	AddOn:HideRouteLines()
	wipe(AddOn.taxiNodePositions)
	AddOn.currentTaxiNode = nil
end
--------------------------------
function FlightMasterPointDataProviderMixin:GetNamedMapTaxiNodes(mapID)
	local mapTaxiNodes = C_TaxiMap.GetAllTaxiNodes(mapID)
	local taxiNodeNameMap = {}

	for _, e in ipairs(mapTaxiNodes) do
		taxiNodeNameMap[e.name] = e
	end

	return taxiNodeNameMap, #mapTaxiNodes
end
--------------------------------
function FlightMasterPointDataProviderMixin:RefreshAllData(fromOnShow)
	self:RemoveAllData()
	if AddOn.flightMasterContext then
		local playerContinentMapID = AddOn:GetPlayerContinentMapID()

		AddOn.mapInfo = C_Map.GetMapInfo(self:GetMap():GetMapID())
		AddOn.frameRouteMap:SetAllPoints()
		-- mapInfo.mapType 2 (continent) must match player continent;
		-- mapInfo.mayType 3 (zone) must be a zone in player continent;
		-- ignore otherwise.
		local isValidZoneMap = AddOn.mapInfo.mapType == 3
			and (AddOn:GetNearestContinentID(AddOn.mapInfo.mapID) == playerContinentMapID)

		local isValidContinentMap = AddOn.mapInfo.mapType == 2 and AddOn.mapInfo.mapID == playerContinentMapID

		if isValidZoneMap or isValidContinentMap then
			local numNodes = NumTaxiNodes()
			local name, pin, taxiNode, nodeType
			local taxiNodeNameMap = self:GetNamedMapTaxiNodes(AddOn.mapInfo.mapID)
			local shouldShowUnknown = AddOn:GetShowUnknownFlightMasters()
			for i = 1, numNodes do
				name = TaxiNodeName(i)
				taxiNode = taxiNodeNameMap[name]

				if
					taxiNode
					and (
						taxiNode.state ~= Enum.FlightPathState.Unreachable
						or (taxiNode.state == Enum.FlightPathState.Unreachable and shouldShowUnknown)
					)
				then
					pin = self:GetMap():AcquirePin("FlightMasterPointPinTemplate", taxiNode)
					pin.taxiNode = taxiNode

					-- intentionally updating texture outside of SetTexture
					pin:UpdateTexture()

					if pin.taxiNode.state == Enum.FlightPathState.Current then
						AddOn.originTaxiNode = taxiNode
					end
					AddOn.taxiNodePositions[i] = taxiNode
				end
			end
			if AddOn.mapInfo.mapType == 2 then
				AddOn:DrawOneHopLines()
			end
		end
	end
end
--------------------------------
function FlightMasterPointDataProviderMixin:ShouldShowTaxiNode(mapTaxiNode)
	if mapTaxiNode.faction == Enum.FlightPathFaction.Horde then
		return AddOn.factionGroup == "Horde"
	end

	if mapTaxiNode.faction == Enum.FlightPathFaction.Alliance then
		return AddOn.factionGroup == "Alliance"
	end

	return true
end
--------------------------------
--[[ Pin ]]
-- Until it is determined how to get along with Questie POI's we shall be rude with insisting upon topmost
FlightMasterPointPinMixin = BaseMapPoiPinMixin:CreateSubPin("PIN_FRAME_LEVEL_TOPMOST")
----------------------------------
function FlightMasterPointPinMixin:SetTexture(poiInfo)
	local size = AddOn.db.global.poiPinDimension

	self:SetSize(size, size)

	if self.Texture then
		self.Texture:SetSize(size, size)
	end

	if self.HighlightTexture then
		self.HighlightTexture:SetSize(size, size)
	end
end
--------------------------------
FlightPathNodeTexture = {}
FlightPathNodeTexture[Enum.FlightPathState.Current] = {
	file = "Interface\\TaxiFrame\\UI-Taxi-Icon-Green",
	highlightBrightness = 0,
}
FlightPathNodeTexture[Enum.FlightPathState.Reachable] = {
	file = "Interface\\TaxiFrame\\UI-Taxi-Icon-White",
	highlightBrightness = 1,
}
FlightPathNodeTexture[Enum.FlightPathState.Unreachable] = {
	file = "Interface\\TaxiFrame\\UI-Taxi-Icon-Nub",
	highlightBrightness = 0,
}
--------------------------------
function FlightMasterPointPinMixin:UpdateTexture()
	if self.taxiNode then
		local texInfo = FlightPathNodeTexture[self.taxiNode.state]
		self.Texture:SetTexture(texInfo.file)
		self.HighlightTexture:SetTexture("Interface\\TaxiFrame\\UI-Taxi-Icon-Yellow")
	else
		self.Texture:SetTexture(0, 0, 0, 0)
		self.HighlightTexture:SetTexture(0, 0, 0, 0)
	end
end
--------------------------------
function FlightMasterPointPinMixin:OnMouseEnter()
	local index = self.taxiNode.slotIndex
	if index > 0 and index < NumTaxiNodes() then
		local numRoutes = GetNumRoutes(index)
		local isZone = AddOn.mapInfo and AddOn.mapInfo.mapType ~= 2
		local line

		AddOn:HideRouteLines()

		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(TaxiNodeName(index), nil, nil, nil, true)

		if self.taxiNode.state == Enum.FlightPathState.Reachable then
			SetTooltipMoney(GameTooltip, TaxiNodeCost(index))
			for i = 1, numRoutes do
				line = AddOn:GetRouteLine(i)
				if i <= numRoutes then
					AddOn:PerformRouteLineDraw(line, index, i, AddOn.lineCanvas)
					line:Show()
				else
					line:Hide()
				end
			end
		elseif self.taxiNode.state == Enum.FlightPathState.Unreachable then
			GameTooltip:AddLine(ERR_TAXINOPATHS, 250, 250, 250, true)
		elseif self.taxiNode.state == Enum.FlightPathState.Current and not isZone then
			GameTooltip:AddLine(TAXINODEYOUAREHERE, 1.0, 1.0, 1.0, true)
			AddOn:DrawOneHopLines()
		end

		GameTooltip:Show()
	end
end
--------------------------------
function FlightMasterPointPinMixin:OnMouseLeave()
	GameTooltip:Hide()
end
--------------------------------
function FlightMasterPointPinMixin:IsMouseClickEnabled()
	return true
end
--------------------------------
function FlightMasterPointPinMixin:OnMouseDown()
	-- preliminary code for taxi logging feature.
	local sourceNode = AddOn.originTaxiNode
	local destNode = self.taxiNode
	local key = AddOn:GetTaxiLogKey(sourceNode.position, destNode.position)
	AddOn:SendMessage(AddOn.Message.TAXI_START, AddOn:GetPlayerContinentMapID(), key)
	TakeTaxiNode(self.taxiNode.slotIndex)
end
