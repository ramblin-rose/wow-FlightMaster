local AddOn = _G[select(1, ...)]
--------------------------------
function AddOn:InitFrame()
	AddOn.frame = CreateFrame("Frame", "FlightMasterFrame", WorldMapFrame.ScrollContainer)
	AddOn.frame:SetFrameStrata("HIGH")
	AddOn.frame:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 100)
	AddOn.frameRouteMap = CreateFrame("Frame", "FlightMasterFrameRouteMap", AddOn.frame)
	AddOn.frameRouteMap:SetFrameStrata(AddOn.frame:GetFrameStrata())
	AddOn.frameRouteMap:SetFrameLevel(AddOn.frame:GetFrameLevel() - 10)
end
--------------------------------
function AddOn:GetFrameDim(frame)
	return frame:GetWidth(), frame:GetHeight()
end
