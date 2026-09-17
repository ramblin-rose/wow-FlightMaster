local AddOn = _G[select(1, ...)]
local L = AddOn.L

local optn = 0
local function optIndex()
	optn = optn + 1
	return optn
end

AddOn.NO_ARRIVAL_SOUND = "NO_ARRIVAL_SOUND"

local options = {
	name = L.addOnName,

	type = "group",
	args = {
		desc = {
			order = optIndex(),
			type = "description",
			name = GAME_VERSION_LABEL .. " " .. AddOn.String.SemVer,
			image = "Interface\\AddOns\\FlightMaster\\assets\\wings.png",
			imageWidth = 32,
			imageHeight = 32,
		},
		div1 = {
			order = optIndex(),
			type = "header",
			name = "",
		},
		enable = {
			order = optIndex(),
			name = ENABLE,
			desc = L.configEnableDesc,
			type = "toggle",

			set = function(info, val)
				AddOn:SetEnabled(val)
			end,
			get = function(info)
				return AddOn:GetEnabled()
			end,
		},
		showUnknownFlightMasters = {
			order = optIndex(),
			name = L.configShowUnknown,
			desc = L.configShowUnknownDesc,
			type = "toggle",

			set = function(info, val)
				AddOn:SetShowUnknownFlightMasters(val)
			end,
			get = function(info)
				return AddOn:GetShowUnknownFlightMasters()
			end,
		},
		poiPinDimension = {
			order = optIndex(),
			name = L.configPOIName,
			desc = L.configPOIDesc,
			type = "range",
			min = 8,
			max = 24,
			step = 1,
			set = function(info, val)
				AddOn:SetPoiDimension(val)
			end,
			get = function(info)
				return AddOn:GetPoiDimension()
			end,
		},
		autoCancelShapeShift = {
			order = optIndex(),
			name = L.configAutoCancelShapeShift,
			desc = L.configAutoCancelShapeShiftDesc,
			type = "toggle",
			width = "double",
			set = function(info, val)
				AddOn:SetAutoCancelShapeShift(val)
			end,
			get = function(info)
				return AddOn:GetAutoCancelShapeShift()
			end,
		},
		arrivalSound = {
			order = optIndex(),
			name = L.configArrivalSound,
			desc = "",
			type = "select",
			values = {
				[AddOn.NO_ARRIVAL_SOUND] = L.oggNone,
				["assets/arrived.ogg"] = L.oggArrive,
				["assets/dang.ogg"] = L.oggDang,
				["assets/frenzy.ogg"] = L.oggFrenzy,
				["assets/joyous.ogg"] = L.oggJoyous,
				["assets/light.ogg"] = L.oggLight,
				["assets/oring.ogg"] = L.oggOring,
				["assets/ringo.ogg"] = L.oggRingo,
				["assets/serious.ogg"] = L.oggSerious,
				["assets/smile.ogg"] = L.oggSmile,
			},
			disabled = function()
				return false
			end,
			set = function(info, val)
				AddOn:SetArrivalSound(val)
				AddOn:PlayArrivalSound()
			end,
			get = function(info)
				return AddOn:GetArrivalSound()
			end,
		},
		flightTimes = {
			order = optIndex(),
			type = "group",
			inline = true,
			name = L.configFlightTimes,
			args = {
				enabled = {
					order = 1,
					name = L.configShowFlightTimes,
					desc = L.configShowFlightTimesDesc,
					type = "toggle",
					width = "double",
					disabled = function()
						return not AddOn:GetEnabled()
					end,
					set = function(info, val)
						AddOn:SetShowFlightTimes(val)
					end,
					get = function(info)
						return AddOn:GetShowFlightTimes()
					end,
				},
				showFlightTimerBar = {
					order = 2,
					name = L.configShowFlightTimerBar,
					desc = L.configShowFlightTimerBarDesc,
					type = "toggle",
					width = "double",
					disabled = function()
						return not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes()
					end,
					set = function(info, val)
						AddOn:SetShowFlightTimerBar(val)
					end,
					get = function(info)
						return AddOn:GetShowFlightTimerBar()
					end,
				},
				barAppearance = {
					order = 3,
					type = "header",
					name = L.configFlightTimerBarAppearance,
				},
				barTimeDisplay = {
					order = 3.5,
					name = L.configFlightTimerBarTimeDisplay,
					desc = L.configFlightTimerBarTimeDisplayDesc,
					type = "select",
					values = {
						remaining = L.configFlightTimerBarDisplayRemaining,
						arrival = L.configFlightTimerBarDisplayArrival,
					},
					disabled = function()
						return not AddOn:GetEnabled()
							or not AddOn:GetShowFlightTimes()
							or not AddOn:GetShowFlightTimerBar()
					end,
					set = function(info, val)
						AddOn:SetFlightTimerBarStyleValue("timeDisplay", val)
					end,
					get = function(info)
						return AddOn:GetFlightTimerBarStyle().timeDisplay
					end,
				},
				barColorMode = {
					order = 4,
					name = L.configFlightTimerBarColorMode,
					desc = L.configFlightTimerBarColorModeDesc,
					type = "select",
					values = {
						solid = L.configFlightTimerBarModeSolid,
						gradient = L.configFlightTimerBarModeGradient,
						remaining = L.configFlightTimerBarModeRemaining,
					},
					disabled = function()
						return not AddOn:GetEnabled()
							or not AddOn:GetShowFlightTimes()
							or not AddOn:GetShowFlightTimerBar()
					end,
					set = function(info, val)
						AddOn:SetFlightTimerBarStyleValue("colorMode", val)
					end,
					get = function(info)
						return AddOn:GetFlightTimerBarStyle().colorMode
					end,
				},
				barColor = {
					order = 5,
					name = L.configFlightTimerBarColor,
					type = "color",
					hasAlpha = true,
					hidden = function()
						return AddOn:GetFlightTimerBarStyle().colorMode ~= "solid"
					end,
					disabled = function()
						return not AddOn:GetEnabled()
							or not AddOn:GetShowFlightTimes()
							or not AddOn:GetShowFlightTimerBar()
					end,
					set = function(info, r, g, b, a)
						AddOn:SetFlightTimerBarStyleValue("bar", { r, g, b, a or 1 })
					end,
					get = function(info)
						local c = AddOn:GetFlightTimerBarStyle().bar
						return c[1], c[2], c[3], c[4]
					end,
				},
				barGradientFrom = {
					order = 6,
					name = L.configFlightTimerBarGradientFrom,
					type = "color",
					hasAlpha = true,
					hidden = function()
						return AddOn:GetFlightTimerBarStyle().colorMode ~= "gradient"
					end,
					disabled = function()
						return not AddOn:GetEnabled()
							or not AddOn:GetShowFlightTimes()
							or not AddOn:GetShowFlightTimerBar()
					end,
					set = function(info, r, g, b, a)
						AddOn:SetFlightTimerBarStyleValue("gradientFrom", { r, g, b, a or 1 })
					end,
					get = function(info)
						local c = AddOn:GetFlightTimerBarStyle().gradientFrom
						return c[1], c[2], c[3], c[4]
					end,
				},
				barGradientTo = {
					order = 7,
					name = L.configFlightTimerBarGradientTo,
					type = "color",
					hasAlpha = true,
					hidden = function()
						return AddOn:GetFlightTimerBarStyle().colorMode ~= "gradient"
					end,
					disabled = function()
						return not AddOn:GetEnabled()
							or not AddOn:GetShowFlightTimes()
							or not AddOn:GetShowFlightTimerBar()
					end,
					set = function(info, r, g, b, a)
						AddOn:SetFlightTimerBarStyleValue("gradientTo", { r, g, b, a or 1 })
					end,
					get = function(info)
						local c = AddOn:GetFlightTimerBarStyle().gradientTo
						return c[1], c[2], c[3], c[4]
					end,
				},
				barTexture = {
					order = 8,
					name = L.configFlightTimerBarTexture,
					type = "select",
					values = {
						blizzard = L.configFlightTimerBarTextureBlizzard,
						smooth = L.configFlightTimerBarTextureSmooth,
						skill = L.configFlightTimerBarTextureSkill,
						flat = L.configFlightTimerBarTextureFlat,
					},
					disabled = function()
						return not AddOn:GetEnabled()
							or not AddOn:GetShowFlightTimes()
							or not AddOn:GetShowFlightTimerBar()
					end,
					set = function(info, val)
						AddOn:SetFlightTimerBarStyleValue("texture", val)
					end,
					get = function(info)
						return AddOn:GetFlightTimerBarStyle().texture
					end,
				},
				barBackground = {
					order = 9,
					name = L.configFlightTimerBarBackground,
					type = "color",
					hasAlpha = true,
					disabled = function()
						return not AddOn:GetEnabled()
							or not AddOn:GetShowFlightTimes()
							or not AddOn:GetShowFlightTimerBar()
					end,
					set = function(info, r, g, b, a)
						AddOn:SetFlightTimerBarStyleValue("background", { r, g, b, a or 1 })
					end,
					get = function(info)
						local c = AddOn:GetFlightTimerBarStyle().background
						return c[1], c[2], c[3], c[4]
					end,
				},
				barBorder = {
					order = 10,
					name = L.configFlightTimerBarBorder,
					type = "color",
					hasAlpha = true,
					disabled = function()
						return not AddOn:GetEnabled()
							or not AddOn:GetShowFlightTimes()
							or not AddOn:GetShowFlightTimerBar()
					end,
					set = function(info, r, g, b, a)
						AddOn:SetFlightTimerBarStyleValue("border", { r, g, b, a or 1 })
					end,
					get = function(info)
						local c = AddOn:GetFlightTimerBarStyle().border
						return c[1], c[2], c[3], c[4]
					end,
				},
				barTimeText = {
					order = 11,
					name = L.configFlightTimerBarTimeText,
					type = "color",
					hasAlpha = true,
					disabled = function()
						return not AddOn:GetEnabled()
							or not AddOn:GetShowFlightTimes()
							or not AddOn:GetShowFlightTimerBar()
					end,
					set = function(info, r, g, b, a)
						AddOn:SetFlightTimerBarStyleValue("timeText", { r, g, b, a or 1 })
					end,
					get = function(info)
						local c = AddOn:GetFlightTimerBarStyle().timeText
						return c[1], c[2], c[3], c[4]
					end,
				},
				barNameText = {
					order = 12,
					name = L.configFlightTimerBarNameText,
					type = "color",
					hasAlpha = true,
					disabled = function()
						return not AddOn:GetEnabled()
							or not AddOn:GetShowFlightTimes()
							or not AddOn:GetShowFlightTimerBar()
					end,
					set = function(info, r, g, b, a)
						AddOn:SetFlightTimerBarStyleValue("nameText", { r, g, b, a or 1 })
					end,
					get = function(info)
						local c = AddOn:GetFlightTimerBarStyle().nameText
						return c[1], c[2], c[3], c[4]
					end,
				},
				barAppearanceButtons = {
					order = 13,
					type = "group",
					inline = true,
					name = " ",
					args = {
						defaults = {
							order = 1,
							name = L.configFlightTimerBarDefaults,
							desc = L.configFlightTimerBarDefaultsDesc,
							type = "execute",
							width = 1.4,
							disabled = function()
								return not AddOn:GetEnabled()
									or not AddOn:GetShowFlightTimes()
									or not AddOn:GetShowFlightTimerBar()
							end,
							func = function()
								AddOn:ResetFlightTimerBarStyle()
							end,
						},
						resetAppearance = {
							order = 2,
							name = L.configFlightTimerBarResetAppearance,
							desc = L.configFlightTimerBarResetAppearanceDesc,
							type = "execute",
							width = "half",
							disabled = function()
								if
									not AddOn:GetEnabled()
									or not AddOn:GetShowFlightTimes()
									or not AddOn:GetShowFlightTimerBar()
								then
									return true
								end
								return AddOn.IsFlightTimerBarStyleUnchangedSinceOptionsOpen
									and AddOn:IsFlightTimerBarStyleUnchangedSinceOptionsOpen()
							end,
							func = function()
								AddOn:ResetFlightTimerBarStyleToOptionsOpen()
							end,
						},
					},
				},
				barMoveGroup = {
					order = 14,
					type = "group",
					inline = true,
					name = L.configFlightTimerBarMoveGroup,
					args = {
						beginMove = {
							order = 1,
							name = L.configFlightTimerBarMove,
							desc = L.configFlightTimerBarMoveDesc,
							type = "execute",
							width = "half",
							disabled = function()
								return not AddOn:GetEnabled()
									or not AddOn:GetShowFlightTimes()
									or not AddOn:GetShowFlightTimerBar()
									or AddOn.flightTimerMoving
							end,
							func = function()
								AddOn:BeginFlightTimerBarMove()
							end,
						},
						endMove = {
							order = 2,
							name = L.configFlightTimerBarEndMove,
							desc = L.configFlightTimerBarEndMoveDesc,
							type = "execute",
							width = "half",
							disabled = function()
								return not AddOn.flightTimerMoving
							end,
							func = function()
								AddOn:CancelFlightTimerBarMove()
							end,
						},
						cancelMove = {
							order = 4,
							name = L.configFlightTimerBarMoveCancel,
							desc = L.configFlightTimerBarMoveCancelDesc,
							type = "execute",
							width = "half",
							disabled = function()
								if
									not AddOn:GetEnabled()
									or not AddOn:GetShowFlightTimes()
									or not AddOn:GetShowFlightTimerBar()
								then
									return true
								end
								return AddOn.IsFlightTimerBarAtOptionsOpenPosition
									and AddOn:IsFlightTimerBarAtOptionsOpenPosition()
							end,
							func = function()
								AddOn:RevertFlightTimerBarPosition()
							end,
						},
						hCenter = {
							order = 3,
							name = L.configFlightTimerBarHCenter,
							desc = L.configFlightTimerBarHCenterDesc,
							type = "execute",
							width = 1.15,
							disabled = function()
								if
									not AddOn:GetEnabled()
									or not AddOn:GetShowFlightTimes()
									or not AddOn:GetShowFlightTimerBar()
								then
									return true
								end
								return AddOn.IsFlightTimerBarHorizontallyCentered
									and AddOn:IsFlightTimerBarHorizontallyCentered()
							end,
							func = function()
								AddOn:CenterFlightTimerBarHorizontally()
							end,
						},
						resetPosition = {
							order = 5,
							name = L.configFlightTimerBarResetPosition,
							desc = L.configFlightTimerBarResetPositionDesc,
							type = "execute",
							width = 1.15,
							disabled = function()
								if
									not AddOn:GetEnabled()
									or not AddOn:GetShowFlightTimes()
									or not AddOn:GetShowFlightTimerBar()
								then
									return true
								end
								return AddOn.IsFlightTimerBarAtDefaultPosition
									and AddOn:IsFlightTimerBarAtDefaultPosition()
							end,
							func = function()
								AddOn:ResetFlightTimerBarPosition()
							end,
						},
					},
				},
			},
		},
	},
}

local dbDefaults = {
	global = {
		showUnknownFlightMasters = false,
		poiPinDimension = 14,
		autoCancelShapeShift = true,
		showFlightTimes = true,
		showFlightTimerBar = true,
		arrivalSound = AddOn.NO_ARRIVAL_SOUND,
		flightTimerBarStyle = {
			colorMode = "solid",
			timeDisplay = "remaining",
			texture = "blizzard",
			bar = { 0.25, 0.55, 0.95, 1 },
			gradientFrom = { 0.15, 0.75, 0.25, 1 },
			gradientTo = { 0.90, 0.20, 0.15, 1 },
			background = { 0, 0, 0, 0.65 },
			border = { 0.75, 0.75, 0.85, 1 },
			timeText = { 1, 1, 1, 1 },
			nameText = { 1, 0.82, 0, 1 },
		},
	},
}
function AddOn:InitConfig()
	AddOn.db = LibStub("AceDB-3.0"):New(AddOn.name .. "DB", dbDefaults, true)
	AddOn.enabled = true
	-- correct lack of serialization versioning
	if AddOn.db.global.version == nil then
		AddOn.db.global.version = 1
	end
	AddOn.enabled = true

	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(AddOn.name, options, true)
	LibStub("AceConfigRegistry-3.0"):NotifyChange(AddOn.name)
	LibStub("AceConfigDialog-3.0"):SetDefaultSize(AddOn.name, 730, 580)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddOn.name, options.name)
	AddOn:RegisterChatCommand(AddOn.String.CommandName, "OnSlashCommand")
end
--------------------------------
function AddOn:OpenOptions()
	local dialog = LibStub("AceConfigDialog-3.0")
	dialog:Open(AddOn.name)
	local f = dialog.OpenFrames and dialog.OpenFrames[AddOn.name]
	if f and f.frame and not f._flightMasterCloseHooked then
		f._flightMasterCloseHooked = true
		f.frame:HookScript("OnHide", function()
			if AddOn.OnFlightTimerOptionsClosed then
				AddOn:OnFlightTimerOptionsClosed()
			end
		end)
	end
	if AddOn.RefreshFlightTimerBarPreview then
		AddOn:RefreshFlightTimerBarPreview()
	end
end
--------------------------------
function AddOn:OnSlashCommand()
	AddOn:OpenOptions()
end
--------------------------------
function AddOn:SetDefaultOptions()
	self:SetEnabled(true)
	self:SetShowUnknownFlightMasters(AddOn.db.global.showUnknownFlightMasters)
	self:SetPoiDimension(14)
	self:SetAutoCancelShapeShift(AddOn.db.global.autoCancelShapeShift)
	self:SetArrivalSound(AddOn.db.global.arrivalSound)
	self:SetShowFlightTimes(true)
	self:SetShowFlightTimerBar(true)
	self:ResetFlightTimerBarStyle()
end
--------------------------------
function AddOn:SetEnabled(enable)
	AddOn.enabled = enable
	if enable then
		AddOn:SendMessage(AddOn.Message.ENABLE_ADDON)
	else
		AddOn:SendMessage(AddOn.Message.DISABLE_ADDON)
		AddOn:AbortFlightTimeSample()
	end
	LibStub("AceConfigRegistry-3.0"):NotifyChange(AddOn.name)
	if AddOn.RefreshFlightTimerBarPreview then
		AddOn:RefreshFlightTimerBarPreview()
	end
end
--------------------------------
function AddOn:GetEnabled()
	return AddOn.enabled
end
--------------------------------
function AddOn:SetShowUnknownFlightMasters(enable)
	AddOn.db.global.showUnknownFlightMasters = enable
end
--------------------------------
function AddOn:GetShowUnknownFlightMasters()
	return AddOn.db.global.showUnknownFlightMasters
end
--------------------------------
function AddOn:SetPoiDimension(val)
	AddOn.db.global.poiPinDimension = val
end
--------------------------------
function AddOn:GetPoiDimension()
	return AddOn.db.global.poiPinDimension
end
--------------------------------
function AddOn:SetAutoCancelShapeShift(val)
	AddOn.db.global.autoCancelShapeShift = val
end
--------------------------------
function AddOn:GetAutoCancelShapeShift()
	return AddOn.db.global.autoCancelShapeShift
end
--------------------------------
function AddOn:SetArrivalSound(val)
	AddOn.db.global.arrivalSound = val
	if AddOn.RefreshFlightTimerBarPreview then
		AddOn:UpdateFlightTimerSoundButton()
	end
end
--------------------------------
function AddOn:GetArrivalSound()
	return AddOn.db.global.arrivalSound
end
--------------------------------
function AddOn:PlayArrivalSound()
	if AddOn.db.global.arrivalSound ~= AddOn.NO_ARRIVAL_SOUND then
		PlaySoundFile("Interface\\AddOns\\" .. AddOn.name .. "\\" .. AddOn.db.global.arrivalSound, "MASTER")
	end
end
--------------------------------
function AddOn:SetShowFlightTimes(val)
	AddOn.db.global.showFlightTimes = not not val
	if not val then
		AddOn:AbortFlightTimeSample()
		AddOn:HideFlightTimerBar()
	end
	if AddOn.RefreshFlightTimerBarPreview then
		AddOn:RefreshFlightTimerBarPreview()
	end
end
--------------------------------
function AddOn:GetShowFlightTimes()
	local val = AddOn.db.global.showFlightTimes
	if val == nil then
		return true
	end
	return val
end
--------------------------------
function AddOn:SetShowFlightTimerBar(val)
	AddOn.db.global.showFlightTimerBar = not not val
	if not val then
		AddOn:HideFlightTimerBar()
	end
	if AddOn.RefreshFlightTimerBarPreview then
		AddOn:RefreshFlightTimerBarPreview()
	end
end
--------------------------------
function AddOn:GetShowFlightTimerBar()
	local val = AddOn.db.global.showFlightTimerBar
	if val == nil then
		return true
	end
	return val
end
--------------------------------
local FLIGHT_TIMER_BAR_STYLE_DEFAULTS = {
	colorMode = "solid",
	timeDisplay = "remaining",
	texture = "blizzard",
	bar = { 0.25, 0.55, 0.95, 1 },
	gradientFrom = { 0.15, 0.75, 0.25, 1 },
	gradientTo = { 0.90, 0.20, 0.15, 1 },
	background = { 0, 0, 0, 0.65 },
	border = { 0.75, 0.75, 0.85, 1 },
	timeText = { 1, 1, 1, 1 },
	nameText = { 1, 0.82, 0, 1 },
}

local function copyColor(color)
	return { color[1], color[2], color[3], color[4] or 1 }
end
--------------------------------
local function copyFlightTimerBarStyle(style)
	local copy = {}
	for key, value in pairs(style) do
		if type(value) == "table" then
			copy[key] = copyColor(value)
		else
			copy[key] = value
		end
	end
	return copy
end
--------------------------------
local function flightTimerBarStylesEqual(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for key, value in pairs(a) do
		local other = b[key]
		if type(value) == "table" then
			if type(other) ~= "table" then
				return false
			end
			for i = 1, 4 do
				if math.abs((value[i] or 1) - (other[i] or 1)) > 0.001 then
					return false
				end
			end
		elseif value ~= other then
			return false
		end
	end
	for key in pairs(b) do
		if a[key] == nil then
			return false
		end
	end
	return true
end
--------------------------------
function AddOn:GetFlightTimerBarStyle()
	local style = AddOn.db.global.flightTimerBarStyle
	if type(style) ~= "table" then
		style = {}
		AddOn.db.global.flightTimerBarStyle = style
	end
	for key, value in pairs(FLIGHT_TIMER_BAR_STYLE_DEFAULTS) do
		if style[key] == nil then
			if type(value) == "table" then
				style[key] = copyColor(value)
			else
				style[key] = value
			end
		end
	end
	return style
end
--------------------------------
function AddOn:SetFlightTimerBarStyleValue(key, value)
	local style = AddOn:GetFlightTimerBarStyle()
	style[key] = value
	if AddOn.ApplyFlightTimerBarStyle then
		AddOn:ApplyFlightTimerBarStyle()
	end
	LibStub("AceConfigRegistry-3.0"):NotifyChange(AddOn.name)
end
--------------------------------
function AddOn:CaptureFlightTimerBarStyleSnapshot()
	if AddOn.flightTimerBarStyleSnapshot ~= nil then
		return
	end
	AddOn.flightTimerBarStyleSnapshot = copyFlightTimerBarStyle(AddOn:GetFlightTimerBarStyle())
end
--------------------------------
function AddOn:IsFlightTimerBarStyleUnchangedSinceOptionsOpen()
	local snap = AddOn.flightTimerBarStyleSnapshot
	if type(snap) ~= "table" then
		return true
	end
	return flightTimerBarStylesEqual(snap, AddOn:GetFlightTimerBarStyle())
end
--------------------------------
function AddOn:ResetFlightTimerBarStyleToOptionsOpen()
	local snap = AddOn.flightTimerBarStyleSnapshot
	if type(snap) ~= "table" then
		return
	end
	AddOn.db.global.flightTimerBarStyle = copyFlightTimerBarStyle(snap)
	if AddOn.ApplyFlightTimerBarStyle then
		AddOn:ApplyFlightTimerBarStyle()
	end
	LibStub("AceConfigRegistry-3.0"):NotifyChange(AddOn.name)
end
--------------------------------
function AddOn:ResetFlightTimerBarStyle()
	local style = {}
	for key, value in pairs(FLIGHT_TIMER_BAR_STYLE_DEFAULTS) do
		if type(value) == "table" then
			style[key] = copyColor(value)
		else
			style[key] = value
		end
	end
	AddOn.db.global.flightTimerBarStyle = style
	if AddOn.ApplyFlightTimerBarStyle then
		AddOn:ApplyFlightTimerBarStyle()
	end
	AddOn.flightTimerMoving = false
	if AddOn.UpdateFlightTimerMover then
		AddOn:UpdateFlightTimerMover()
	end
	LibStub("AceConfigRegistry-3.0"):NotifyChange(AddOn.name)
end
--------------------------------
