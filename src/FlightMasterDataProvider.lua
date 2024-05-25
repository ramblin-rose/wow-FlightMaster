local AddOn = _G[select(1, ...)]
--------------------------------
FlightMasterPointDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin)

function FlightMasterPointDataProviderMixin:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate("FlightMasterPointPinTemplate")
	AddOn:HideRouteLines()
	AddOn:HideTaxiNodeButtons()
end
--------------------------------
function FlightMasterPointDataProviderMixin:RefreshAllData(fromOnShow)
	self:RemoveAllData()
	AddOn:HideRouteLines()
	AddOn:HideTaxiNodeButtons()
	AddOn.frame:SetAllPoints()
	AddOn.frameRouteMap:SetAllPoints()
	AddOn.mapInfo = C_Map.GetMapInfo(self:GetMap():GetMapID())

	local numNodes = NumTaxiNodes()
	AddOn:EnsureTaxiButtons(numNodes)

	local taxiNodes = AddOn:GetNamedMapTaxiNodes(self:GetMap():GetMapID())
	local name, taxiNode, nodeType, pin

	wipe(AddOn.taxiNodePositions)

	for i = 1, numNodes do
		-- GetNamedMapTaxiNodes s *all* taxi nodes on the map; filter for the nodes reflected by the Taxi methods.
		name = TaxiNodeName(i)
		taxiNode = taxiNodes[name]
		if taxiNode then
			nodeType = TaxiNodeGetType(i)
			if self:ShouldShowTaxiNode(nodeType, AddOn.factionGroup, taxiNode) then
				pin = self:GetMap():AcquirePin("FlightMasterPointPinTemplate", taxiNode)
				pin.fm_pinInfo = {
					index = i,
					pin = pin,
					nodeType = TaxiNodeGetType(i),
					button = AddOn.taxiButtons[i],
				}
				AddOn.taxiNodePositions[i] = taxiNode
			end
		end
	end
end
--------------------------------
function FlightMasterPointDataProviderMixin:ShouldShowTaxiNode(nodeType, factionGroup, taxiNode)
	if nodeType == "DISTANT" then
		return false
	end
	if taxiNode.faction == Enum.FlightPathFaction.Horde then
		return factionGroup == "Horde"
	end

	if taxiNode.faction == Enum.FlightPathFaction.Alliance then
		return factionGroup == "Alliance"
	end

	return true
end
--------------------------------
--[[ Pin ]]
-- this is a positioning proxy for taxi node buttons; never display this pin.
FlightMasterPointPinMixin = BaseMapPoiPinMixin:CreateSubPin("PIN_FRAME_LEVEL_AREA_POI")

function FlightMasterPointPinMixin:ApplyCurrentPosition()
	self:GetMap():ApplyPinPosition(self, self.normalizedX, self.normalizedY, self.insetIndex)
	self:Hide()

	local pinInfo = self.fm_pinInfo
	if pinInfo then
		local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
		pinInfo.button:ClearAllPoints()
		pinInfo.button:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
		pinInfo.button:Show()
	end
end
--------------------------------
function FlightMasterPointPinMixin:SetTexture(poiInfo)
	local pinInfo = self.fm_pinInfo
	if pinInfo then
		pinInfo.button:SetWidth(12)
		pinInfo.button:SetHeight(12)
		local texInfo = TaxiButtonTypes[pinInfo.nodeType]
		if texInfo then
			pinInfo.button:SetNormalTexture(texInfo.file)
		end
	end
end
