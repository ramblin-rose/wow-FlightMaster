local AddOn = _G[select(1, ...)]
--------------------------------
FlightMasterPointDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin)
function AddOn:InitFlightMasterDataProvider()
	AddOn.factionGroup = UnitFactionGroup("player")
	AddOn.taxiNodePositions = {}
	AddOn.showUnknownPoints = false
	AddOn.dataProvider = CreateFromMixins(FlightMasterPointDataProviderMixin)
	AddOn.pointPinTemplate = "FlightMasterPointPinTemplate"
	AddOn.pinPools = AddOn.pinPools or {}
	AddOn.pinPools[AddOn.pointPinTemplate] =
		CreateFramePool("Button", WorldMapFrame.scrollContainer or WorldMapFrame, AddOn.pointPinTemplate)
	-- Determine if player is a class that shapechanges - druid of shaman - and setup the cancelform feature.
	local _, _, classId = UnitClass("player")
	AddOn.isPlayerShapeShifter = classId == 11 or classId == 7
	WorldMapFrame:AddDataProvider(AddOn.dataProvider)
end
--------------------------------
function FlightMasterPointDataProviderMixin:OnAdded(mapCanvas)
	MapCanvasDataProviderMixin.OnAdded(self, mapCanvas)
	AddOn.lineCanvas = AddOn.frameRouteMap
end
--------------------------------
function FlightMasterPointDataProviderMixin:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate(AddOn.pointPinTemplate)
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
local function shortTaxiName(name)
	if type(name) ~= "string" then
		return ""
	end
	local short = name:match("^([^,]+)") or name
	return short:gsub("^%s+", ""):gsub("%s+$", ""):lower()
end
--------------------------------
function FlightMasterPointDataProviderMixin:FindNamedMapTaxiNode(taxiNodeNameMap, name)
	if not name then
		return
	end
	local taxiNode = taxiNodeNameMap[name]
	if taxiNode then
		return taxiNode
	end
	local short = shortTaxiName(name)
	if short == "" then
		return
	end
	for nodeName, node in pairs(taxiNodeNameMap) do
		if shortTaxiName(nodeName) == short then
			return node
		end
	end
end
--------------------------------
function FlightMasterPointDataProviderMixin:GetSecureTaxiMacroFormatString()
	if AddOn.isPlayerShapeShifter and AddOn:GetAutoCancelShapeShift() then
		-- stylua: ignore start
		return [[
/cancelform [nocombat]
/script TakeTaxiNode(%d)
]]
		-- stylua: ignore end
	else
		return [[/script TakeTaxiNode(%d)]]
	end
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
			local name, pin, taxiNode, sessionType
			local taxiNodeNameMap = self:GetNamedMapTaxiNodes(AddOn.mapInfo.mapID)
			local shouldShowUnknown = AddOn:GetShowUnknownFlightMasters()
			local secureTaxiMacroFormatString = self:GetSecureTaxiMacroFormatString()
			for i = 1, numNodes do
				name = TaxiNodeName(i)
				taxiNode = self:FindNamedMapTaxiNode(taxiNodeNameMap, name)
				sessionType = TaxiNodeGetType(i)

				-- Always keep hop endpoints, including TBC DISTANT nodes.
				-- C_TaxiMap.slotIndex is not the live taxi-session index.
				if taxiNode then
					taxiNode.slotIndex = i
					AddOn.taxiNodePositions[i] = taxiNode
				end

				local isSessionFlyable = sessionType == "CURRENT" or sessionType == "REACHABLE"
				local shouldShowPin = taxiNode
					and (
						isSessionFlyable
						or taxiNode.state ~= Enum.FlightPathState.Unreachable
						or shouldShowUnknown
					)

				if shouldShowPin then
					pin = self:GetMap():AcquirePin(AddOn.pointPinTemplate, taxiNode)
					pin.taxiNode = taxiNode
					pin.taxiSlotIndex = i
					pin:EnableMouse(true)
					pin:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
					pin:SetAttribute("type", "macro")
					pin:SetAttribute("macrotext", string.format(secureTaxiMacroFormatString, i))
					-- intentionally updating texture outside of SetTexture
					pin:UpdateTexture()

					if sessionType == "CURRENT" or pin.taxiNode.state == Enum.FlightPathState.Current then
						AddOn.originTaxiNode = taxiNode
					end
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
	local state = self.taxiNode and self.taxiNode.state
	local slotIndex = self.taxiSlotIndex or (self.taxiNode and self.taxiNode.slotIndex)
	if slotIndex and slotIndex >= 1 and slotIndex <= NumTaxiNodes() then
		local sessionType = TaxiNodeGetType(slotIndex)
		if sessionType == "CURRENT" then
			state = Enum.FlightPathState.Current
		elseif sessionType == "REACHABLE" then
			state = Enum.FlightPathState.Reachable
		elseif sessionType == "DISTANT" then
			state = Enum.FlightPathState.Unreachable
		end
	end
	local texInfo = state and FlightPathNodeTexture[state]
	if texInfo then
		self.Texture:SetTexture(texInfo.file)
		self.HighlightTexture:SetTexture("Interface\\TaxiFrame\\UI-Taxi-Icon-Yellow")
	else
		self.Texture:SetTexture(0, 0, 0, 0)
		self.HighlightTexture:SetTexture(0, 0, 0, 0)
	end
end
--------------------------------
function FlightMasterPointPinMixin:OnMouseEnter()
	local index = self.taxiSlotIndex or (self.taxiNode and self.taxiNode.slotIndex)
	if not index or index < 1 or index > NumTaxiNodes() then
		return
	end

	local numRoutes = GetNumRoutes(index)
	local isZone = AddOn.mapInfo and AddOn.mapInfo.mapType ~= 2
	local sessionType = TaxiNodeGetType(index)
	local line

	AddOn:HideRouteLines()

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(TaxiNodeName(index), nil, nil, nil, true)

	if sessionType == "REACHABLE" then
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
	elseif sessionType == "DISTANT" or sessionType == "NONE" then
		GameTooltip:AddLine(ERR_TAXINOPATHS, 250, 250, 250, true)
	elseif sessionType == "CURRENT" and not isZone then
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
