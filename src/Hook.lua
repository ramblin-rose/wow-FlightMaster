local AddOn = _G[select(1, ...)]
--------------------------------
function AddOn:InitHook()
	AddOn:SecureHookScript(WorldMapFrame, "OnHide", AddOn.OnHideWorldMapFrame)
end
