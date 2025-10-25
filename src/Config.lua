local AddOn = _G[select(1, ...)]
local L = AddOn.L

local optn = 0
local function optIndex()
	optn = optn + 1
	return optn
end
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
	},
}

local dbDefaults = {
	global = { showUnknownFlightMasters = false, poiPinDimension = 14, autoCancelShapeShift = true },
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
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddOn.name, options.name)
end
--------------------------------
function AddOn:SetDefaultOptions()
	self:SetEnabled(true)
	self:SetShowUnknownFlightMasters(AddOn.db.global.showUnknownFlightMasters)
	self:SetPoiDimension(14)
	self:SetAutoCancelShapeShift(AddOn.db.global.autoCancelShapeShift)
end
--------------------------------
function AddOn:SetEnabled(enable)
	AddOn.enabled = enable
	if enable then
		AddOn:SendMessage(AddOn.Message.ENABLE_ADDON)
	else
		AddOn:SendMessage(AddOn.Message.DISABLE_ADDON)
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
