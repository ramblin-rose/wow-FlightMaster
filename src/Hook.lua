local AddOn = _G[select(1, ...)]
--------------------------------
function AddOn:InitHook()
	AddOn:SecureHookScript(WorldMapFrame, "OnHide", AddOn.OnHideWorldMapFrame)
	AddOn:SecureHookScript(WorldMapFrame, "OnEvent", function(_, event)
		-- todo workaround for zoom
		if event == "QUEST_LOG_UPDATE" then
			AddOn:OnWorldMapMinMax()
		end
	end)
	AddOn:SecureHook(WorldMapFrame, "Maximize", function()
		AddOn:OnWorldMapMinMax()
	end)
	AddOn:SecureHook(WorldMapFrame, "Minimize", function()
		AddOn:OnWorldMapMinMax()
	end)
end
