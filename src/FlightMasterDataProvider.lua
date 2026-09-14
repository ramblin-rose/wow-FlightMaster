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
		CreateFramePool("Button", WorldMapFrame.ScrollContainer or WorldMapFrame.scrollContainer or WorldMapFrame, AddOn.pointPinTemplate)
	if WorldMapFrame.SetPinTemplateType then
		WorldMapFrame:SetPinTemplateType(AddOn.pointPinTemplate, "Button")
	end
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
local function shortTaxiName(name)
	if type(name) ~= "string" then
		return ""
	end
	local short = name:match("^([^,]+)") or name
	short = short:gsub("^%s+", ""):gsub("%s+$", ""):lower()
	return short
end
--------------------------------
local function namesLooselyEqual(a, b)
	if a == b then
		return true
	end
	if #a < 5 or #b < 5 then
		return false
	end
	return a:sub(1, #b) == b or b:sub(1, #a) == a
end
--------------------------------
local function ingestTaxiNodes(nodes, bySlot, byName, byShort, hasSlot)
	if type(nodes) ~= "table" then
		return
	end
	for _, node in ipairs(nodes) do
		if hasSlot and node.slotIndex and node.slotIndex > 0 then
			bySlot[node.slotIndex] = node
		end
		if node.name then
			byName[node.name] = byName[node.name] or node
			local short = shortTaxiName(node.name)
			if short ~= "" then
				byShort[short] = byShort[short] or node
			end
		end
	end
end
--------------------------------
function FlightMasterPointDataProviderMixin:GetMapTaxiNodeLookup(mapID)
	local bySlot, byName, byShort = {}, {}, {}
	if mapID and C_TaxiMap then
		if C_TaxiMap.GetAllTaxiNodes then
			ingestTaxiNodes(C_TaxiMap.GetAllTaxiNodes(mapID), bySlot, byName, byShort, true)
		end
		if not next(bySlot) and not next(byName) and C_TaxiMap.GetTaxiNodesForMap then
			ingestTaxiNodes(C_TaxiMap.GetTaxiNodesForMap(mapID), bySlot, byName, byShort, false)
		end
	end
	return bySlot, byName, byShort
end
--------------------------------
function FlightMasterPointDataProviderMixin:FindTaxiNode(slotIndex, name, bySlot, byName, byShort)
	if slotIndex and bySlot[slotIndex] then
		return bySlot[slotIndex]
	end
	if name and byName[name] then
		return byName[name]
	end
	local short = shortTaxiName(name)
	if short == "" then
		return
	end
	if byShort[short] then
		return byShort[short]
	end
	for key, node in pairs(byShort) do
		if namesLooselyEqual(short, key) then
			return node
		end
	end
end
--------------------------------
local function taxiNodeTypeToState(nodeType)
	if nodeType == "CURRENT" then
		return Enum.FlightPathState.Current
	elseif nodeType == "REACHABLE" then
		return Enum.FlightPathState.Reachable
	end
	return Enum.FlightPathState.Unreachable
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
		if not AddOn.mapInfo then
			return
		end
		AddOn.frameRouteMap:SetAllPoints()
		-- continent must match player continent;
		-- zone (or other child map) must belong to player continent;
		-- ignore otherwise.
		local continentMapType = AddOn:GetContinentMapType()
		local isValidZoneMap = AddOn.mapInfo.mapType > continentMapType
			and (AddOn:GetNearestContinentID(AddOn.mapInfo.mapID) == playerContinentMapID)

		local isValidContinentMap = AddOn.mapInfo.mapType == continentMapType
			and AddOn.mapInfo.mapID == playerContinentMapID

		if isValidZoneMap or isValidContinentMap then
			local numNodes = NumTaxiNodes()
			local name, pin, taxiNode
			local bySlot, byName, byShort = self:GetMapTaxiNodeLookup(AddOn.mapInfo.mapID)
			local shouldShowUnknown = AddOn:GetShowUnknownFlightMasters()
			local secureTaxiMacroFormatString = self:GetSecureTaxiMacroFormatString()
			for i = 1, numNodes do
				name = TaxiNodeName(i)
				taxiNode = self:FindTaxiNode(i, name, bySlot, byName, byShort)

				if taxiNode then
					taxiNode.slotIndex = taxiNode.slotIndex or i
					if taxiNode.state == nil then
						taxiNode.state = taxiNodeTypeToState(TaxiNodeGetType(i))
					end
				end

				if
					taxiNode
					and (
						taxiNode.state ~= Enum.FlightPathState.Unreachable
						or (taxiNode.state == Enum.FlightPathState.Unreachable and shouldShowUnknown)
					)
				then
					pin = self:GetMap():AcquirePin(AddOn.pointPinTemplate, taxiNode)
					pin.taxiNode = taxiNode
					pin:EnableMouse(true)
					pin:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
					pin:SetAttribute("type", "macro")
					pin:SetAttribute("macrotext", string.format(secureTaxiMacroFormatString, pin.taxiNode.slotIndex))
					-- intentionally updating texture outside of SetTexture
					pin:UpdateTexture()

					if pin.taxiNode.state == Enum.FlightPathState.Current then
						AddOn.originTaxiNode = taxiNode
					end
					AddOn.taxiNodePositions[i] = taxiNode
				end
			end
			if AddOn.mapInfo.mapType == continentMapType then
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
	local texInfo = self.taxiNode and FlightPathNodeTexture[self.taxiNode.state]
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
	if not self.taxiNode then
		return
	end
	local index = self.taxiNode.slotIndex
	if index > 0 and index <= NumTaxiNodes() then
		local numRoutes = GetNumRoutes(index)
		local isZone = AddOn.mapInfo and AddOn.mapInfo.mapType ~= AddOn:GetContinentMapType()
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
