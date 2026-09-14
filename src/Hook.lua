local AddOn = _G[select(1, ...)]
--------------------------------
function AddOn:InitHook()
	AddOn:SecureHookScript(WorldMapFrame, "OnHide", AddOn.OnHideWorldMapFrame)
	AddOn:SecureHookScript(WorldMapFrame, "OnShow", AddOn.OnShowWorldMapFrame)
	if WorldMapFrame.Minimize then
		AddOn:SecureHook(WorldMapFrame, "Minimize", AddOn.RestoreTaxiContinentMap)
	end
	if WorldMapFrame.Maximize then
		AddOn:SecureHook(WorldMapFrame, "Maximize", AddOn.RestoreTaxiContinentMap)
	end
end
