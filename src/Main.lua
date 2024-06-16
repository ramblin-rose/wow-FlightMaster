local AddOn = _G[select(1, ...)]
--------------------------------

function AddOn:OnInitialize()
	AddOn.Timer = LibStub("AceTimer-3.0")
	AddOn:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		AddOn:UnregisterEvent("PLAYER_ENTERING_WORLD")
		AddOn:InitConfig()
		AddOn:InitFrame()
		AddOn:InitHook()
		AddOn:InitMap()
		AddOn:InitMessage()
		AddOn:InitRoute()
		AddOn:InitFlightMasterDataProvider()
		AddOn:InitTaxiLog()
		AddOn:SetEnabled(true)
		AddOn:AddMessageHandler(AddOn.Message.ENABLE_ADDON, AddOn.onEnableAddOn)
		AddOn:AddMessageHandler(AddOn.Message.DISABLE_ADDON, AddOn.onDisableAddOn)
		AddOn:SendMessage(AddOn.Message.ENABLE_ADDON)
	end)
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
	-- Do nothing stub. Deferring this event until the WorldMapFrame closes maintains the flight master context
	-- Once the WorldMapFrame is closed the TaxiFrame event is invoked and this hook removed.
end
--------------------------------
function AddOn:OnTaxiMapOpened(...)
	-- grab flight master context
	AddOn.flightMasterContext = UnitName("target")
	local hook = AddOn.hooks[TaxiFrame]
	if not hook or hook.OnHide == nil then
		AddOn:RawHookScript(TaxiFrame, "OnHide", "OnHideTaxiFrame")
	end
	-- autoclose map if flight master context is lost
	ToggleWorldMap()
	WorldMapFrame:SetMapID(AddOn:GetPlayerContinentMapID())
	AddOn:EnableDataProviderRefresh(true)
	AddOn:EnableFlightMasterInteractionDistance(true)
end
--------------------------------
function AddOn:EnableFlightMasterInteractionDistance(enable)
	if enable then
		local timeOutMs = 0.25
		AddOn.flightMasterMonitor = AddOn.Timer:ScheduleRepeatingTimer(function()
			if not CheckInteractDistance("target", 3) and UnitName("target") == AddOn.flightMasterContext then
				WorldMapFrame:Hide()
			end
		end, timeOutMs)
	elseif type(AddOn.flightMasterMonitor) == "number" then
		AddOn.Timer:CancelTimer(AddOn.flightMasterMonitor)
		AddOn.flightMasterMonitor = nil
	end
end
--------------------------------
function AddOn:OnHideWorldMapFrame()
	GameTooltip:Hide()
	AddOn:EnableDataProviderRefresh(false)
	AddOn:EnableFlightMasterInteractionDistance(false)
	-- release flight master context
	if AddOn.flightMasterContext then
		if AddOn.hooks[TaxiFrame] and AddOn.hooks[TaxiFrame].OnHide then
			AddOn.hooks[TaxiFrame]:OnHide(TaxiFrame)
			AddOn:Unhook(TaxiFrame, "OnHide")
		end
		AddOn.flightMasterContext = nil
	end
end
--------------------------------
-- tbd deeper understanding of data provider framework may negate this workaround
-- for an issue where some taxi nodes are not rendered properly
function AddOn:EnableDataProviderRefresh(enable)
	if not enable then
		if AddOn.timerId then
			AddOn.Timer:CancelTimer(AddOn.timerId)
			AddOn.timerId = nil
		end
	elseif AddOn.timerId == nil then
		-- pump the data provider
		local timerCount = 10
		local timeOutMs = 0.25
		AddOn.timerId = AddOn.Timer:ScheduleRepeatingTimer(function()
			timerCount = timerCount - 1
			if timerCount > 0 then
				AddOn.dataProvider:RefreshAllData()
			else
				AddOn.Timer:CancelTimer(AddOn.timerId)
				AddOn.timerId = nil
			end
		end, timeOutMs)
	end
end
