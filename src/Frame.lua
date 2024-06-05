local AddOn = _G[select(1, ...)]
--------------------------------
function AddOn:InitFrame()
	-- AddOn.frame = CreateFrame("Frame", "FlightMasterFrame", WorldMapFrame.ScrollContainer)
	-- AddOn.frame:SetFrameStrata("HIGH")
	-- AddOn.frame:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 100)
	-- alternative to dealing with a pin canvas
	AddOn.frameRouteMap = CreateFrame("Frame", "FlightMasterFrameRouteMap", WorldMapFrame.ScrollContainer.Child)
	AddOn.frameRouteMap:SetFrameStrata("MEDIUM")
	AddOn.frameRouteMap:SetFrameLevel(2000)
end
--------------------------------
function AddOn:GetFrameDim(frame)
	return frame:GetWidth(), frame:GetHeight()
end
