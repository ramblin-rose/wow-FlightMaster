local AddOn = _G[select(1, ...)]
--------------------------------
function AddOn:InitFrame()
	AddOn.VIEWPORT_ORIGIN = "TOPLEFT"
	AddOn.frame = CreateFrame("Frame", "FlightPathTonicFrame", WorldMapFrame.ScrollContainer)
	AddOn.frame:SetFrameStrata("HIGH")
	AddOn.frame:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 100)
	AddOn.frameRouteMap = CreateFrame("Frame", "FlightPathTonicFrameRouteMap", AddOn.frame)
	AddOn.frameRouteMap:SetFrameStrata(AddOn.frame:GetFrameStrata())
	AddOn.frameRouteMap:SetFrameLevel(AddOn.frame:GetFrameLevel() - 10)
end

function AddOn:GetFrameDim()
	return AddOn.frame:GetWidth(), AddOn.frame:GetHeight()
end
