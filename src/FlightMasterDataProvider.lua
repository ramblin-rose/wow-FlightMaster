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
function MapCanvasDataProviderMixin:OnCanvasScaleChanged()
	self:RefreshAllData()
end

function MapCanvasDataProviderMixin:OnCanvasSizeChanged()
	self:RefreshAllData()
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
	local mapTaxiNodes = C_TaxiMap.GetTaxiNodesForMap(mapID)
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
		local isZoneMap = AddOn.mapInfo.mapType == 3
			and (AddOn:GetNearestContinentID(AddOn.mapInfo.mapID) == playerContinentMapID)
		local isContinentMap = AddOn.mapInfo.mapType == 2 and AddOn.mapInfo.mapID == playerContinentMapID
		if isZoneMap or isContinentMap then
			local numNodes = NumTaxiNodes()
			local name, pin, taxiNode, nodeType
			local taxiNodeNameMap = self:GetNamedMapTaxiNodes(self:GetMap():GetMapID())

			for i = 1, numNodes do
				name = TaxiNodeName(i)
				nodeType = TaxiNodeGetType(i)
				taxiNode = taxiNodeNameMap[name]
				if taxiNode and (nodeType ~= "DISTANT" or (nodeType == "DISTANT" and AddOn.showUnknownPoints)) then
					pin = self:GetMap():AcquirePin("FlightMasterPointPinTemplate", taxiNode)
					pin.fm_pinInfo = {
						index = i,
						taxiNode = taxiNode,
						nodeType = TaxiNodeGetType(i),
						name = taxiNode.name,
					}
					pin:UpdateTexture()
					if pin.fm_pinInfo.nodeType == "CURRENT" then
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
	self:SetSize(16, 16)

	if self.Texture then
		self.Texture:SetWidth(12)
		self.Texture:SetHeight(12)
	end

	if self.HighlightTexture then
		self.HighlightTexture:SetWidth(12)
		self.HighlightTexture:SetHeight(12)
	end
end
--------------------------------
function FlightMasterPointPinMixin:UpdateTexture()
	if self.fm_pinInfo then
		local texInfo = TaxiButtonTypes[self.fm_pinInfo.nodeType]
		self.Texture:SetTexture(texInfo.file)
		self.HighlightTexture:SetTexture("Interface\\TaxiFrame\\UI-Taxi-Icon-Yellow")
	else
		self.Texture:SetTexture(0, 0, 0, 0)
		self.HighlightTexture:SetTexture(0, 0, 0, 0)
	end
end
--------------------------------
function FlightMasterPointPinMixin:OnMouseEnter()
	local index = self.fm_pinInfo.index
	local numRoutes = GetNumRoutes(index)
	local nodeType = TaxiNodeGetType(index)
	local isZone = AddOn.mapInfo and AddOn.mapInfo.mapType ~= 2
	local line

	AddOn:HideRouteLines()

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(TaxiNodeName(index), nil, nil, nil, true)

	if nodeType == "REACHABLE" then
		SetTooltipMoney(GameTooltip, TaxiNodeCost(index))
		if not isZone then
			for i = 1, numRoutes do
				line = AddOn:GetRouteLine(i)
				if i <= numRoutes then
					AddOn:PerformRouteLineDraw(line, index, i, AddOn.lineCanvas)
					line:Show()
				else
					line:Hide()
				end
			end
		end
	elseif nodeType == "UNREACHABLE" then
		-- tbd
	elseif nodeType == "CURRENT" and not isZone then
		GameTooltip:AddLine(TAXINODEYOUAREHERE, 1.0, 1.0, 1.0, true)
		AddOn:DrawOneHopLines()
	end

	GameTooltip:Show()
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
	local index = self.fm_pinInfo.index
	-- preliminary code for taxi logging feature.
	local sourceNode = AddOn.originTaxiNode
	local destNode = self.fm_pinInfo.taxiNode
	local key = AddOn:GetTaxiLogKey(sourceNode.position, destNode.position)
	AddOn:SendMessage(AddOn.Message.TAXI_START, AddOn:GetPlayerContinentMapID(), key)
	TakeTaxiNode(index)
end
