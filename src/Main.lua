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
		AddOn:InitCompatibility()
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
local function getFlightMasterUnit()
	local context = AddOn.flightMasterContext
	if not context then
		return
	end
	-- Classic taxi UI tracks the flight master as "npc"; "target" is cleared when
	-- the fullscreen world map blacks out the 3D world.
	if UnitExists("npc") and UnitName("npc") == context then
		return "npc"
	end
	if UnitExists("target") and UnitName("target") == context then
		return "target"
	end
end
--------------------------------
local function isFlightMasterInRange()
	local unit = getFlightMasterUnit()
	if not unit then
		return false
	end
	local ok, inRange = pcall(CheckInteractDistance, unit, 3)
	if not ok then
		return true
	end
	return not not inRange
end
--------------------------------
function AddOn:OnTaxiMapOpened(...)
	-- grab flight master context
	AddOn.flightMasterContext = UnitName("npc") or UnitName("target")
	local hook = AddOn.hooks[TaxiFrame]
	if not hook or hook.OnHide == nil then
		AddOn:RawHookScript(TaxiFrame, "OnHide", "OnHideTaxiFrame")
	end

	if not WorldMapFrame:IsShown() then
		ToggleWorldMap()
	end
	local continentMapID = AddOn:GetPlayerContinentMapID()
	if continentMapID then
		WorldMapFrame:SetMapID(continentMapID)
	end
	AddOn:EnableDataProviderRefresh(true)
	AddOn:EnableFlightMasterInteractionDistance(true)
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
--------------------------------
-- autoclose map if interactive distance with flight master is beyond ~7 yards.
function AddOn:EnableFlightMasterInteractionDistance(enable)
	if not enable then
		if AddOn.flightMasterMonitor then
			AddOn.Timer:CancelTimer(AddOn.flightMasterMonitor)
			AddOn.flightMasterMonitor = nil
			if WorldMapFrame:IsVisible() then
				ToggleWorldMap()
			end
		end
	elseif AddOn.flightMasterMonitor == nil then
		local timeOutMs = 0.25
		AddOn.flightMasterMonitor = AddOn.Timer:ScheduleRepeatingTimer(function()
			if not isFlightMasterInRange() then
				AddOn.Timer:CancelTimer(AddOn.flightMasterMonitor)
				AddOn.flightMasterMonitor = nil
				if WorldMapFrame:IsVisible() then
					ToggleWorldMap()
				end
			end
		end, timeOutMs)
	end
end
