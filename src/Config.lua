local AddOn = _G[select(1, ...)]
local L = AddOn.L

local optn = 0
local function optIndex()
	optn = optn + 1
	return optn
end

AddOn.NO_ARRIVAL_SOUND = "NO_ARRIVAL_SOUND"
AddOn.ADD_ARRIVAL_SOUND = "ADD_ARRIVAL_SOUND"
AddOn.DEFAULT_ARRIVAL_SOUND = "assets/arrived.ogg"
AddOn.DEFAULT_SOUND_CHANNEL = "MASTER"
local CUSTOM_SOUND_PREFIX = "custom:"
local addingArrivalSound
local draftArrivalSoundName = ""
local draftArrivalSoundFileID = ""
local BUILTIN_ARRIVAL_SOUND_ORDER = {
	AddOn.NO_ARRIVAL_SOUND,
	"assets/arrived.ogg",
	"assets/dang.ogg",
	"assets/frenzy.ogg",
	"assets/joyous.ogg",
	"assets/light.ogg",
	"assets/oring.ogg",
	"assets/ringo.ogg",
	"assets/serious.ogg",
	"assets/smile.ogg",
}
--------------------------------
local function customSoundKey(id)
	return CUSTOM_SOUND_PREFIX .. tostring(id)
end
--------------------------------
local function parseCustomSoundId(key)
	if type(key) ~= "string" then
		return nil
	end
	local id = key:match("^custom:(%d+)$")
	return id and tonumber(id) or nil
end
--------------------------------
local playButtonWidget, saveButtonWidget

local ARRIVAL_SOUND_NAME_MAX = 40
local FILEDATA_ID_MAX = 2147483647

local function sanitizeArrivalSoundName(name)
	if type(name) ~= "string" then
		return ""
	end
	name = strtrim(name)
	name = name:gsub("|", "")
	name = name:gsub("[%c]", "")
	name = strtrim(name)
	if #name > ARRIVAL_SOUND_NAME_MAX then
		name = name:sub(1, ARRIVAL_SOUND_NAME_MAX)
	end
	return name
end
--------------------------------
local function validFileDataID(fileID)
	fileID = tonumber(fileID)
	if not fileID or fileID ~= fileID then
		return nil
	end
	fileID = math.floor(fileID)
	if not (fileID >= 1 and fileID <= FILEDATA_ID_MAX) then
		return nil
	end
	return fileID
end
--------------------------------
local function draftArrivalFileID()
	local raw = strtrim(draftArrivalSoundFileID or "")
	if not raw:match("^%d+$") then
		return nil
	end
	return validFileDataID(raw)
end
--------------------------------
local function syncAddSoundButtons()
	local hasFileID = draftArrivalFileID() ~= nil
	if playButtonWidget then
		playButtonWidget:SetDisabled(not hasFileID)
	end
	if saveButtonWidget then
		local name = sanitizeArrivalSoundName(draftArrivalSoundName)
		saveButtonWidget:SetDisabled(name == "" or not hasFileID)
	end
end
--------------------------------
do
	local AceGUI = LibStub("AceGUI-3.0")

	local function EditBox_OnEnter(frame)
		frame.obj:Fire("OnEnter")
	end
	local function EditBox_OnLeave(frame)
		frame.obj:Fire("OnLeave")
	end
	local function EditBox_OnEscapePressed(frame)
		AceGUI:ClearFocus()
	end
	local function EditBox_OnEnterPressed(frame)
		frame.obj:Fire("OnEnterPressed", frame:GetText())
	end
	local function EditBox_OnTextChanged(frame)
		local self = frame.obj
		local value = frame:GetText()
		if tostring(value) ~= tostring(self.lasttext) then
			self.lasttext = value
			self:Fire("OnTextChanged", value)
		end
	end
	local function EditBox_OnFocusGained(frame)
		AceGUI:SetFocus(frame.obj)
	end

	AceGUI:RegisterWidgetType("FMEditBox", function()
		local num = AceGUI:GetNextWidgetNum("FMEditBox")
		local frame = CreateFrame("Frame", nil, UIParent)
		frame:Hide()

		local editbox = CreateFrame("EditBox", "AceGUI-3.0FMEditBox" .. num, frame, "InputBoxTemplate")
		editbox:SetAutoFocus(false)
		editbox:SetFontObject(ChatFontNormal)
		editbox:SetScript("OnEnter", EditBox_OnEnter)
		editbox:SetScript("OnLeave", EditBox_OnLeave)
		editbox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)
		editbox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
		editbox:SetScript("OnTextChanged", EditBox_OnTextChanged)
		editbox:SetScript("OnEditFocusGained", EditBox_OnFocusGained)
		editbox:SetTextInsets(0, 0, 3, 3)
		editbox:SetMaxLetters(256)
		editbox:SetPoint("BOTTOMLEFT", 6, 0)
		editbox:SetPoint("BOTTOMRIGHT")
		editbox:SetHeight(19)

		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", 0, -2)
		label:SetPoint("TOPRIGHT", 0, -2)
		label:SetJustifyH("LEFT")
		label:SetHeight(18)

		local widget = {
			alignoffset = 30,
			editbox = editbox,
			label = label,
			frame = frame,
			type = "FMEditBox",
		}

		function widget:OnAcquire()
			self:SetWidth(200)
			self:SetDisabled(false)
			self:SetLabel()
			self:SetText()
			self:SetMaxLetters(0)
			self.fmField = nil
			self:SetCallback("OnTextChanged", function(w, _, text)
				if w.fmField == "name" then
					draftArrivalSoundName = sanitizeArrivalSoundName(text)
				elseif w.fmField == "fileID" then
					draftArrivalSoundFileID = strtrim(text or "")
				else
					return
				end
				syncAddSoundButtons()
			end)
		end

		function widget:OnRelease()
			self:ClearFocus()
			self.fmField = nil
		end

		function widget:SetCustomData(field)
			self.fmField = field
		end

		function widget:SetDisabled(disabled)
			self.disabled = disabled
			if disabled then
				self.editbox:EnableMouse(false)
				self.editbox:ClearFocus()
				self.editbox:SetTextColor(0.5, 0.5, 0.5)
				self.label:SetTextColor(0.5, 0.5, 0.5)
			else
				self.editbox:EnableMouse(true)
				self.editbox:SetTextColor(1, 1, 1)
				self.label:SetTextColor(1, 0.82, 0)
			end
		end

		function widget:SetText(text)
			self.lasttext = text or ""
			self.editbox:SetText(text or "")
			self.editbox:SetCursorPosition(0)
		end

		function widget:GetText()
			return self.editbox:GetText()
		end

		function widget:SetLabel(text)
			if text and text ~= "" then
				self.label:SetText(text)
				self.label:Show()
				self.editbox:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 7, -18)
				self:SetHeight(44)
				self.alignoffset = 30
			else
				self.label:SetText("")
				self.label:Hide()
				self.editbox:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 7, 0)
				self:SetHeight(26)
				self.alignoffset = 12
			end
		end

		function widget:SetMaxLetters(num)
			self.editbox:SetMaxLetters(num or 0)
		end

		function widget:ClearFocus()
			self.editbox:ClearFocus()
		end

		function widget:SetFocus()
			self.editbox:SetFocus()
		end

		editbox.obj = widget
		return AceGUI:RegisterAsWidget(widget)
	end, 1)

	AceGUI:RegisterWidgetType("FMButton", function()
		local name = "AceGUI30FMButton" .. AceGUI:GetNextWidgetNum("FMButton")
		local frame = CreateFrame("Button", name, UIParent, "UIPanelButtonTemplate")
		frame:Hide()
		frame:EnableMouse(true)
		frame:SetScript("OnClick", function(btn, ...)
			AceGUI:ClearFocus()
			PlaySound(852)
			btn.obj:Fire("OnClick", ...)
		end)
		frame:SetScript("OnEnter", function(btn)
			btn.obj:Fire("OnEnter")
		end)
		frame:SetScript("OnLeave", function(btn)
			btn.obj:Fire("OnLeave")
		end)

		local text = frame:GetFontString()
		text:ClearAllPoints()
		text:SetPoint("TOPLEFT", 15, -1)
		text:SetPoint("BOTTOMRIGHT", -15, 1)
		text:SetJustifyV("MIDDLE")

		local widget = {
			text = text,
			frame = frame,
			type = "FMButton",
		}

		function widget:OnAcquire()
			self:SetHeight(24)
			self:SetWidth(200)
			self:SetDisabled(false)
			self:SetText()
			self.fmKind = nil
		end

		function widget:OnRelease()
			if playButtonWidget == self then
				playButtonWidget = nil
			end
			if saveButtonWidget == self then
				saveButtonWidget = nil
			end
			self.fmKind = nil
		end

		function widget:SetCustomData(kind)
			self.fmKind = kind
			if kind == "play" then
				playButtonWidget = self
			elseif kind == "save" then
				saveButtonWidget = self
			end
			syncAddSoundButtons()
		end

		function widget:SetText(value)
			self.text:SetText(value)
		end

		function widget:SetDisabled(disabled)
			self.disabled = disabled
			if disabled then
				self.frame:Disable()
			else
				self.frame:Enable()
			end
		end

		return AceGUI:RegisterAsWidget(widget)
	end, 1)
end
--------------------------------
local function ensureCustomSoundList()
	local db = AddOn.db and AddOn.db.global
	if not db then
		return nil
	end
	if type(db.customArrivalSounds) ~= "table" then
		db.customArrivalSounds = {}
	end
	if type(db.customArrivalSoundSeq) ~= "number" then
		db.customArrivalSoundSeq = 0
	end
	return db
end
--------------------------------
function AddOn:GetCustomArrivalSound(id)
	id = tonumber(id)
	local db = ensureCustomSoundList()
	if not id or not db then
		return nil
	end
	for i = 1, #db.customArrivalSounds do
		local rec = db.customArrivalSounds[i]
		if rec and rec.id == id then
			return rec
		end
	end
end
--------------------------------
function AddOn:AddCustomArrivalSound(name, fileID)
	name = sanitizeArrivalSoundName(name)
	fileID = validFileDataID(fileID)
	if name == "" or not fileID then
		return nil
	end
	local db = ensureCustomSoundList()
	if not db then
		return nil
	end
	db.customArrivalSoundSeq = db.customArrivalSoundSeq + 1
	local id = db.customArrivalSoundSeq
	db.customArrivalSounds[#db.customArrivalSounds + 1] = {
		id = id,
		name = name,
		fileID = fileID,
	}
	return id
end
--------------------------------
function AddOn:RemoveCustomArrivalSound(key)
	local id = parseCustomSoundId(key)
	local db = ensureCustomSoundList()
	if not id or not db then
		return
	end
	for i = 1, #db.customArrivalSounds do
		local rec = db.customArrivalSounds[i]
		if rec and rec.id == id then
			table.remove(db.customArrivalSounds, i)
			break
		end
	end
	if db.arrivalSound == key then
		AddOn:SetArrivalSound(AddOn.DEFAULT_ARRIVAL_SOUND)
		AddOn:PlayArrivalSound()
	end
end
--------------------------------
function AddOn:GetArrivalSoundValues()
	local values = {
		[AddOn.NO_ARRIVAL_SOUND] = L.oggNone,
		[AddOn.ADD_ARRIVAL_SOUND] = L.oggAddSound,
		["assets/arrived.ogg"] = L.oggArrive,
		["assets/dang.ogg"] = L.oggDang,
		["assets/frenzy.ogg"] = L.oggFrenzy,
		["assets/joyous.ogg"] = L.oggJoyous,
		["assets/light.ogg"] = L.oggLight,
		["assets/oring.ogg"] = L.oggOring,
		["assets/ringo.ogg"] = L.oggRingo,
		["assets/serious.ogg"] = L.oggSerious,
		["assets/smile.ogg"] = L.oggSmile,
	}
	local db = AddOn.db and AddOn.db.global
	if db and type(db.customArrivalSounds) == "table" then
		for i = 1, #db.customArrivalSounds do
			local rec = db.customArrivalSounds[i]
			if rec and rec.id then
				local label = sanitizeArrivalSoundName(rec.name)
				if label == "" then
					label = tostring(rec.fileID or rec.id)
				end
				values[customSoundKey(rec.id)] = label
			end
		end
	end
	return values
end
--------------------------------
function AddOn:GetArrivalSoundSorting()
	local order = {}
	for i = 1, #BUILTIN_ARRIVAL_SOUND_ORDER do
		order[i] = BUILTIN_ARRIVAL_SOUND_ORDER[i]
	end
	local db = AddOn.db and AddOn.db.global
	if db and type(db.customArrivalSounds) == "table" then
		for i = 1, #db.customArrivalSounds do
			local rec = db.customArrivalSounds[i]
			if rec and rec.id then
				order[#order + 1] = customSoundKey(rec.id)
			end
		end
	end
	order[#order + 1] = AddOn.ADD_ARRIVAL_SOUND
	return order
end
--------------------------------
function AddOn:MigrateArrivalSound()
	local db = ensureCustomSoundList()
	if not db then
		return
	end
	local sound = db.arrivalSound
	if type(sound) == "number" then
		local id = AddOn:AddCustomArrivalSound(tostring(sound), sound)
		if id then
			db.arrivalSound = customSoundKey(id)
		else
			db.arrivalSound = AddOn.DEFAULT_ARRIVAL_SOUND
		end
	elseif sound == "CUSTOM_ARRIVAL_SOUND" or sound == AddOn.ADD_ARRIVAL_SOUND then
		db.arrivalSound = AddOn.DEFAULT_ARRIVAL_SOUND
	end
	for i = 1, #db.customArrivalSounds do
		local rec = db.customArrivalSounds[i]
		if rec then
			if rec.fileID then
				rec.fileID = validFileDataID(rec.fileID)
			end
			local label = sanitizeArrivalSoundName(rec.name)
			if rec.name == "Custom" or label == "" then
				label = rec.fileID and tostring(rec.fileID) or ""
			end
			rec.name = label
		end
	end
end

local options = {
	name = L.addOnName,

	type = "group",
	args = {
		desc = {
			order = optIndex(),
			type = "description",
			name = GAME_VERSION_LABEL .. " " .. AddOn.String.SemVer,
			image = "Interface\\AddOns\\FlightMaster\\assets\\icon.tga",
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
		showSmoothRoutes = {
			order = optIndex(),
			name = L.configShowSmoothRoutes,
			desc = L.configShowSmoothRoutesDesc,
			type = "toggle",
			width = "double",
			set = function(info, val)
				AddOn:SetShowSmoothRoutes(val)
			end,
			get = function(info)
				return AddOn:GetShowSmoothRoutes()
			end,
		},
		shareFlightData = {
			order = optIndex(),
			name = L.configShareFlightData,
			desc = L.configShareFlightDataDesc,
			type = "toggle",
			width = "double",
			disabled = function()
				return not AddOn:GetEnabled()
			end,
			set = function(info, val)
				AddOn:SetShareFlightData(val)
			end,
			get = function(info)
				return AddOn:GetShareFlightData()
			end,
		},
		shareFlightPaths = {
			order = optIndex(),
			name = L.configShareFlightPaths,
			desc = L.configShareFlightPathsDesc,
			type = "toggle",
			width = "double",
			disabled = function()
				return not AddOn:GetEnabled() or not AddOn:GetShareFlightData()
			end,
			set = function(info, val)
				AddOn:SetShareFlightPaths(val)
			end,
			get = function(info)
				return AddOn:GetShareFlightPaths()
			end,
		},
		arrival = {
			order = optIndex(),
			type = "group",
			inline = true,
			name = "Arrival Notification",
			args = {
				arrivalSound = {
					order = optIndex(),
					name = L.configArrivalSound,
					desc = "",
					type = "select",
					values = function()
						return AddOn:GetArrivalSoundValues()
					end,
					sorting = function()
						return AddOn:GetArrivalSoundSorting()
					end,
					set = function(info, val)
						if val == AddOn.ADD_ARRIVAL_SOUND then
							addingArrivalSound = true
							draftArrivalSoundName = ""
							draftArrivalSoundFileID = ""
							return
						end
						addingArrivalSound = false
						AddOn:SetArrivalSound(val)
						AddOn:PlayArrivalSound()
					end,
					get = function(info)
						if addingArrivalSound then
							return AddOn.ADD_ARRIVAL_SOUND
						end
						return AddOn:GetArrivalSound()
					end,
				},
				arrivalSoundName = {
					order = optIndex(),
					name = L.configArrivalSoundName,
					type = "input",
					dialogControl = "FMEditBox",
					arg = "name",
					width = "normal",
					hidden = function()
						return not addingArrivalSound
					end,
					get = function()
						return draftArrivalSoundName
					end,
					validate = function(info, val)
						if sanitizeArrivalSoundName(val) == "" then
							return L.configArrivalSoundNameInvalid
						end
						return true
					end,
					set = function(info, val)
						draftArrivalSoundName = sanitizeArrivalSoundName(val)
						syncAddSoundButtons()
					end,
				},
				arrivalSoundFileID = {
					order = optIndex(),
					name = L.configArrivalSoundFileID,
					desc = L.configArrivalSoundFileIDDesc,
					type = "input",
					dialogControl = "FMEditBox",
					arg = "fileID",
					width = "normal",
					hidden = function()
						return not addingArrivalSound
					end,
					get = function()
						return draftArrivalSoundFileID
					end,
					validate = function(info, val)
						if type(val) ~= "string" then
							return L.configArrivalSoundFileIDInvalid
						end
						val = strtrim(val)
						if val == "" then
							return true
						end
						if not val:match("^%d+$") then
							return L.configArrivalSoundFileIDInvalid
						end
						if not validFileDataID(val) then
							return L.configArrivalSoundFileIDInvalid
						end
						return true
					end,
					set = function(info, val)
						draftArrivalSoundFileID = strtrim(val or "")
						syncAddSoundButtons()
					end,
				},
				arrivalSoundPlay = {
					order = optIndex(),
					name = L.configArrivalSoundPlay,
					type = "execute",
					dialogControl = "FMButton",
					arg = "play",
					width = "half",
					hidden = function()
						return not addingArrivalSound
					end,
					disabled = function()
						return draftArrivalFileID() == nil
					end,
					func = function()
						local id = draftArrivalFileID()
						if not id then
							return
						end
						local played = PlaySoundFile(id, AddOn.DEFAULT_SOUND_CHANNEL)
						if not played then
							AddOn:Print(L.configArrivalSoundFileIDMissing)
						end
					end,
				},
				arrivalSoundSave = {
					order = optIndex(),
					name = L.configArrivalSoundSave,
					type = "execute",
					dialogControl = "FMButton",
					arg = "save",
					width = "half",
					hidden = function()
						return not addingArrivalSound
					end,
					disabled = function()
						return sanitizeArrivalSoundName(draftArrivalSoundName) == "" or draftArrivalFileID() == nil
					end,
					func = function()
						local id = AddOn:AddCustomArrivalSound(draftArrivalSoundName, draftArrivalSoundFileID)
						if not id then
							return
						end
						addingArrivalSound = false
						draftArrivalSoundName = ""
						draftArrivalSoundFileID = ""
						AddOn:SetArrivalSound(customSoundKey(id))
						AddOn:PlayArrivalSound()
						LibStub("AceConfigRegistry-3.0"):NotifyChange(AddOn.name)
					end,
				},
				arrivalSoundRemove = {
					order = optIndex(),
					name = L.configArrivalSoundRemove,
					type = "execute",
					width = "half",
					hidden = function()
						if addingArrivalSound then
							return true
						end
						return parseCustomSoundId(AddOn:GetArrivalSound()) == nil
					end,
					func = function()
						AddOn:RemoveCustomArrivalSound(AddOn:GetArrivalSound())
						LibStub("AceConfigRegistry-3.0"):NotifyChange(AddOn.name)
					end,
				},
			},
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
						return not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes()
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
						return not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes()
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
						return not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes()
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
						return not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes()
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
						return not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes()
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
						return not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes()
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
						return not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes()
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
						return not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes()
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
						return not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes()
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
						return not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes()
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
								return not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes()
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
								if not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes() then
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
								if not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes() then
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
								if not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes() then
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
								if not AddOn:GetEnabled() or not AddOn:GetShowFlightTimes() then
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
	faction = {},
	global = {
		showUnknownFlightMasters = false,
		poiPinDimension = 14,
		autoCancelShapeShift = true,
		showFlightTimes = true,
		showSmoothRoutes = true,
		shareFlightData = true,
		shareFlightPaths = true,
		arrivalSound = AddOn.DEFAULT_ARRIVAL_SOUND,
		customArrivalSounds = {},
		customArrivalSoundSeq = 0,
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
	AddOn:MigrateArrivalSound()
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
function AddOn:OnSlashCommand(...)
	local arg1 = ...
	if type(arg1) == "string" then
		arg1 = arg1:match("^(%S+)") or arg1
		arg1 = arg1:lower()
	end
	if arg1 == "w" then
		if AddOn.WipeFactionFlightTimes then
			AddOn:WipeFactionFlightTimes()
		end
	elseif arg1 == "sync" then
		if AddOn.PrintSyncStatus then
			AddOn:PrintSyncStatus()
		end
	elseif arg1 == "count" then
		AddOn:PrintFlightDataCount()
	elseif arg1 == "view" then
		AddOn:ShowFlightDataView()
	elseif arg1 == "syncinfo" then
		AddOn:ToggleSyncInfo()
	elseif arg1 == "synctest" then
		if AddOn.RunSyncConvergeTest then
			AddOn:RunSyncConvergeTest()
		end
	else
		AddOn:OpenOptions()
	end
end
--------------------------------
function AddOn:SetDefaultOptions()
	self:SetEnabled(true)
	self:SetShowUnknownFlightMasters(AddOn.db.global.showUnknownFlightMasters)
	self:SetPoiDimension(14)
	self:SetAutoCancelShapeShift(AddOn.db.global.autoCancelShapeShift)
	self:SetArrivalSound(AddOn.db.global.arrivalSound)
	self:SetShowSmoothRoutes(true)
	self:SetShowFlightTimes(true)
	self:SetShareFlightData(true)
	self:SetShareFlightPaths(true)
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
	if type(val) ~= "string" then
		return
	end
	local customId = parseCustomSoundId(val)
	if customId then
		if not AddOn:GetCustomArrivalSound(customId) then
			return
		end
	elseif val ~= AddOn.NO_ARRIVAL_SOUND and val ~= AddOn.DEFAULT_ARRIVAL_SOUND then
		local known
		for i = 1, #BUILTIN_ARRIVAL_SOUND_ORDER do
			if BUILTIN_ARRIVAL_SOUND_ORDER[i] == val then
				known = true
				break
			end
		end
		if not known and not val:match("^assets/[%w%-]+%.ogg$") then
			return
		end
	end
	AddOn.db.global.arrivalSound = val
	local inRealFlight = AddOn.flightTimerState and not AddOn.flightTimerState.preview
	if not inRealFlight then
		AddOn.playArrivalSoundThisFlight = val ~= AddOn.NO_ARRIVAL_SOUND
	end
	if AddOn.UpdateFlightTimerSoundButton then
		AddOn:UpdateFlightTimerSoundButton()
	end
end
--------------------------------
function AddOn:GetArrivalSound()
	return AddOn.db.global.arrivalSound
end
--------------------------------
function AddOn:PlayArrivalSound()
	local sound = AddOn.db.global.arrivalSound
	if sound == AddOn.NO_ARRIVAL_SOUND then
		if AddOn.playArrivalSoundThisFlight then
			sound = AddOn.DEFAULT_ARRIVAL_SOUND
		else
			return
		end
	end
	if not sound or sound == AddOn.NO_ARRIVAL_SOUND or sound == AddOn.ADD_ARRIVAL_SOUND then
		return
	end
	local customId = parseCustomSoundId(sound)
	if customId then
		local rec = AddOn:GetCustomArrivalSound(customId)
		local fileID = rec and validFileDataID(rec.fileID)
		if not fileID then
			return
		end
		local played = PlaySoundFile(fileID, AddOn.DEFAULT_SOUND_CHANNEL)
		if not played then
			AddOn:Print(AddOn.L.configArrivalSoundFileIDMissing)
		end
		return
	end
	local fileID = validFileDataID(sound)
	if fileID then
		local played = PlaySoundFile(fileID, AddOn.DEFAULT_SOUND_CHANNEL)
		if not played then
			AddOn:Print(AddOn.L.configArrivalSoundFileIDMissing)
		end
		return
	end
	if type(sound) ~= "string" or not sound:match("^assets/[%w%-]+%.ogg$") then
		return
	end
	PlaySoundFile("Interface\\AddOns\\" .. AddOn.name .. "\\" .. sound, AddOn.DEFAULT_SOUND_CHANNEL)
end
--------------------------------
function AddOn:SetShowFlightTimes(val)
	AddOn.db.global.showFlightTimes = not not val
	if not val then
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
function AddOn:SetShowSmoothRoutes(val)
	AddOn.db.global.showSmoothRoutes = not not val
	if AddOn.flightMasterContext and AddOn.dataProvider then
		AddOn.dataProvider:RefreshAllData()
	end
end
--------------------------------
function AddOn:SetShareFlightData(val)
	self.db.global.shareFlightData = not not val
	if val then
		if self.StartFlightSync then
			self:StartFlightSync()
		end
	elseif self.StopFlightSync then
		self:StopFlightSync()
	end
end
--------------------------------
function AddOn:GetShareFlightData()
	local val = self.db and self.db.global and self.db.global.shareFlightData
	if val == nil then
		return true
	end
	return val
end
--------------------------------
function AddOn:SetShareFlightPaths(val)
	self.db.global.shareFlightPaths = not not val
end
--------------------------------
function AddOn:GetShareFlightPaths()
	local val = self.db and self.db.global and self.db.global.shareFlightPaths
	if val == nil then
		return true
	end
	return val
end
--------------------------------
function AddOn:GetShowSmoothRoutes()
	local val = AddOn.db.global.showSmoothRoutes
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
