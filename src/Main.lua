local AddOn = _G[select(1, ...)]
--------------------------------
function AddOn:OnInitialize()
	AddOn:InitConfig()
	AddOn:InitFrame()
	AddOn:InitHook()
	AddOn:InitMap()
	AddOn:InitMessage()
	AddOn:InitRoute()
	AddOn:InitTaxi()
	AddOn:InitTaxiLog()

	AddOn:SetEnabled(true)
	AddOn:AddMessageHandler(AddOn.Message.ENABLE_ADDON, AddOn.onEnableAddOn)
	AddOn:AddMessageHandler(AddOn.Message.DISABLE_ADDON, AddOn.onDisableAddOn)
	AddOn:SendMessage(AddOn.Message.ENABLE_ADDON)
end
--------------------------------
function AddOn:onEnableAddOn()
	TaxiFrame:Hide()
	WorldMapFrame:Hide()
	AddOn:RegisterEvent("TAXIMAP_OPENED", AddOn.OnTaxiMapOpened)
end
--------------------------------
function AddOn:onDisableAddOn()
	TaxiFrame:Hide()
	WorldMapFrame:Hide()
	AddOn:UnregisterEvent("TAXIMAP_OPENED")
end
--------------------------------
function AddOn:OnHideTaxiFrame(...)
	-- Do nothing stub. Deferring this event until the WorldMapFrame closes maintains the flight master context (taxi nodes)
	-- Once the WorldMapFrame is closed the TaxiFrame event is invoked and this hook removed.
end
--------------------------------
function AddOn:OnTaxiMapOpened(...)
	AddOn.flightMasterName = UnitName("target")
	-- hooking the OnHide method allows the context - i.e. taxi nodes - of the flight master to remain whilst player interacts with WorldMapFrame
	-- when WorldMapFrame is closed this context is released
	local hook = AddOn.hooks[TaxiFrame]
	if not hook or hook.OnHide == nil then
		AddOn:RawHookScript(TaxiFrame, "OnHide", "OnHideTaxiFrame")
	end

	ToggleWorldMap()
	WorldMapFrame:SetMapID(AddOn:GetPlayerContinentMapID())
end
--------------------------------
function AddOn:OnHideWorldMapFrame()
	GameTooltip:Hide() -- cover edge case when TaxiNodeOnButtonLeave isn't fired when selecting a destination
	if AddOn.flightMasterName then
		AddOn:HideTaxiNodeButtons()
		if AddOn.hooks[TaxiFrame] and AddOn.hooks[TaxiFrame].OnHide then
			AddOn.hooks[TaxiFrame]:OnHide(TaxiFrame)
			AddOn:Unhook(TaxiFrame, "OnHide")
		end
		AddOn.flightMasterName = nil
	end
end
--------------------------------
