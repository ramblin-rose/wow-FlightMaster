local AddOn = _G[select(1, ...)]
--------------------------------
function AddOn:InitFrame()
	-- alternative to dealing with a pin canvas
	AddOn.frameRouteMap = CreateFrame("Frame", "FlightMasterFrameRouteMap", WorldMapFrame.ScrollContainer.Child)
	AddOn.frameRouteMap:SetFrameStrata("MEDIUM")
	AddOn.frameRouteMap:SetFrameLevel(2100) -- value allows for route lines on zone maps
end
--------------------------------
function AddOn:GetFrameDim(frame)
	return frame:GetWidth(), frame:GetHeight()
end
