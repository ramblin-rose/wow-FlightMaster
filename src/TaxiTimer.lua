local AddOn = _G[select(1, ...)]
--------------------------------
local BAR_WIDTH = 280
local BAR_HEIGHT = 18
local BAR_BORDER = 5
local NAME_HEIGHT = 20
local EDGE_SIZE = 16
local HEADER_OVERLAP = 4
local FILL_SMOOTHING = 12
local BAR_STRATA = "MEDIUM"
local MOVE_STRATA = "TOOLTIP"
local SIDE_ICON_GAP = 4
local BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = EDGE_SIZE,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
--------------------------------
local function isFlightTimerBarEnabled()
	return AddOn:GetEnabled() and AddOn:GetShowFlightTimes() and AddOn:GetShowFlightTimerBar()
end
--------------------------------
local function displayTaxiName(name)
	if type(name) ~= "string" or name == "" then
		return ""
	end
	local short = name:match("^%s*([^,]+)")
	short = short or name
	return (short:match("^%s*(.-)%s*$")) or short
end
--------------------------------
local BAR_TEXTURES = {
	blizzard = "Interface\\TargetingFrame\\UI-StatusBar",
	smooth = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
	skill = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
	flat = "Interface\\Buttons\\WHITE8X8",
}

local function applyRoundedBackdrop(frame, background, border)
	if not frame.SetBackdrop then
		return
	end
	frame:SetBackdrop(BACKDROP)
	background = background or { 0, 0, 0, 0.65 }
	border = border or { 0.75, 0.75, 0.85, 1 }
	frame:SetBackdropColor(background[1], background[2], background[3], background[4] or 1)
	frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end
--------------------------------
local function setTextureGradient(tex, fromColor, toColor)
	if not tex or not tex.SetGradient then
		return false
	end
	local r1, g1, b1, a1 = fromColor[1], fromColor[2], fromColor[3], fromColor[4] or 1
	local r2, g2, b2, a2 = toColor[1], toColor[2], toColor[3], toColor[4] or 1
	if CreateColor then
		local ok = pcall(function()
			tex:SetGradient("HORIZONTAL", CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
		end)
		if ok then
			return true
		end
	end
	return pcall(function()
		tex:SetGradient("HORIZONTAL", r1, g1, b1, r2, g2, b2)
	end)
end
--------------------------------
function AddOn:FormatArrivalClock(remaining)
	remaining = math.max(0, math.floor((remaining or 0) + 0.5))
	local hours, minutes = GetGameTime()
	hours = tonumber(hours) or 0
	minutes = tonumber(minutes) or 0
	local seconds = 0
	if GetServerTime then
		seconds = GetServerTime() % 60
	end
	local arrive = (hours * 3600 + minutes * 60 + seconds + remaining) % 86400
	local h = math.floor(arrive / 3600)
	local m = math.floor((arrive % 3600) / 60)
	local s = math.floor(arrive % 60)
	h = h % 12
	if h == 0 then
		h = 12
	end
	return string.format("%d:%02d:%02d", h, m, s)
end
--------------------------------
local function remainingFillColor(pct)
	if pct > 0.5 then
		local t = (pct - 0.5) / 0.5
		return 0.95 - 0.75 * t, 0.80 + 0.05 * t, 0.15 + 0.10 * t, 1
	end
	local t = pct / 0.5
	return 0.90 + 0.05 * t, 0.15 + 0.65 * t, 0.15, 1
end
--------------------------------
function AddOn:ApplyFlightTimerBarStyle(remainingPct)
	local fill = AddOn.flightTimerFill
	local barFrame = AddOn.flightTimerBarFrame
	local header = AddOn.flightTimerHeader
	if not fill or not barFrame then
		return
	end
	local style = AddOn:GetFlightTimerBarStyle()
	applyRoundedBackdrop(barFrame, style.background, style.border)
	if header then
		applyRoundedBackdrop(header, style.background, style.border)
		if header.nameText then
			local c = style.nameText
			header.nameText:SetTextColor(c[1], c[2], c[3], c[4] or 1)
		end
	end

	local texture = BAR_TEXTURES[style.texture] or BAR_TEXTURES.blizzard
	fill:SetTexture(texture)
	fill:SetHorizTile(false)

	local mode = style.colorMode
	if mode == "gradient" then
		fill:SetVertexColor(1, 1, 1, 1)
		setTextureGradient(fill, style.gradientFrom, style.gradientTo)
	elseif mode == "remaining" then
		fill:SetVertexColor(remainingFillColor(remainingPct or 1))
	else
		local c = style.bar
		fill:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
	end

	if barFrame.timeText then
		local c = style.timeText
		barFrame.timeText:SetTextColor(c[1], c[2], c[3], c[4] or 1)
	end
	if AddOn.flightTimerState and AddOn.flightTimerState.preview then
		AddOn.flightTimerState.arrivalLabel = nil
		AddOn:UpdateFlightTimerBar(0)
	end
end
--------------------------------
function AddOn:SaveFlightTimerBarPosition()
	local frame = AddOn.flightTimerFrame
	if not frame or not AddOn.db then
		return
	end
	local x, y = frame:GetCenter()
	if not x or not y then
		return
	end
	local scale = frame:GetEffectiveScale()
	if not scale or scale == 0 then
		scale = 1
	end
	AddOn.db.global.flightTimerBarPosition = {
		x = x * scale,
		y = y * scale,
	}
end
--------------------------------
local POSITION_EPSILON = 2
--------------------------------
local function scaledCentersNear(x1, y1, x2, y2)
	return x1 and y1 and x2 and y2
		and math.abs(x1 - x2) < POSITION_EPSILON
		and math.abs(y1 - y2) < POSITION_EPSILON
end
--------------------------------
function AddOn:GetFlightTimerBarScaledCenter()
	local frame = AddOn.flightTimerFrame
	if frame then
		local x, y = frame:GetCenter()
		if x and y then
			local scale = frame:GetEffectiveScale() or 1
			if scale == 0 then
				scale = 1
			end
			return x * scale, y * scale
		end
	end
	local pos = AddOn.db and AddOn.db.global and AddOn.db.global.flightTimerBarPosition
	if pos and pos.x and pos.y then
		return pos.x, pos.y
	end
end
--------------------------------
function AddOn:GetFlightTimerBarDefaultScaledCenter()
	local ux, uy = UIParent:GetCenter()
	if not ux or not uy then
		return
	end
	local scale = UIParent:GetEffectiveScale() or 1
	if scale == 0 then
		scale = 1
	end
	return ux * scale, (uy + UIParent:GetHeight() / 3) * scale
end
--------------------------------
function AddOn:IsFlightTimerBarAtDefaultPosition()
	local x, y = AddOn:GetFlightTimerBarScaledCenter()
	if not x then
		return true
	end
	local dx, dy = AddOn:GetFlightTimerBarDefaultScaledCenter()
	if not dx then
		local pos = AddOn.db and AddOn.db.global and AddOn.db.global.flightTimerBarPosition
		return not pos or not pos.x
	end
	return scaledCentersNear(x, y, dx, dy)
end
--------------------------------
function AddOn:IsFlightTimerBarHorizontallyCentered()
	local x = AddOn:GetFlightTimerBarScaledCenter()
	if not x then
		return true
	end
	local ux = UIParent:GetCenter()
	if not ux then
		return true
	end
	local scale = UIParent:GetEffectiveScale() or 1
	if scale == 0 then
		scale = 1
	end
	return math.abs(x - ux * scale) < POSITION_EPSILON
end
--------------------------------
function AddOn:CenterFlightTimerBarHorizontally()
	if not AddOn.flightTimerFrame or not AddOn.flightTimerFrame:IsShown() then
		AddOn:RefreshFlightTimerBarPreview()
	end
	local frame = AddOn.flightTimerFrame
	if not frame then
		return
	end
	local _, y = frame:GetCenter()
	local ux = UIParent:GetCenter()
	if not y or not ux then
		return
	end
	frame:ClearAllPoints()
	frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", ux, y)
	AddOn:SaveFlightTimerBarPosition()
	LibStub("AceConfigRegistry-3.0"):NotifyChange(AddOn.name)
end
--------------------------------
function AddOn:IsFlightTimerBarAtOptionsOpenPosition()
	local snap = AddOn.flightTimerBarPositionSnapshot
	if snap == nil then
		return true
	end
	if snap == false then
		return AddOn:IsFlightTimerBarAtDefaultPosition()
	end
	local x, y = AddOn:GetFlightTimerBarScaledCenter()
	if not x then
		return true
	end
	return scaledCentersNear(x, y, snap.x, snap.y)
end
--------------------------------
function AddOn:ResetFlightTimerBarPosition()
	AddOn.flightTimerMoving = false
	if AddOn.db and AddOn.db.global then
		AddOn.db.global.flightTimerBarPosition = nil
	end
	AddOn:PositionFlightTimerBar()
	AddOn:UpdateFlightTimerMover()
	LibStub("AceConfigRegistry-3.0"):NotifyChange(AddOn.name)
end
--------------------------------
function AddOn:PositionFlightTimerBar()
	local frame = AddOn.flightTimerFrame
	if not frame then
		return
	end
	frame:ClearAllPoints()
	local pos = AddOn.db and AddOn.db.global and AddOn.db.global.flightTimerBarPosition
	if pos and pos.x and pos.y then
		local scale = frame:GetEffectiveScale()
		if scale == 0 then
			scale = 1
		end
		frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x / scale, pos.y / scale)
	else
		frame:SetPoint("CENTER", UIParent, "TOP", 0, -(UIParent:GetHeight() / 6))
	end
end
--------------------------------
local function addMoverCorner(parent, anchor)
	local size = 10
	local h = parent:CreateTexture(nil, "OVERLAY")
	h:SetColorTexture(1, 0.82, 0, 1)
	h:SetSize(size, 2)
	local v = parent:CreateTexture(nil, "OVERLAY")
	v:SetColorTexture(1, 0.82, 0, 1)
	v:SetSize(2, size)
	if anchor == "TOPLEFT" then
		h:SetPoint("TOPLEFT")
		v:SetPoint("TOPLEFT")
	elseif anchor == "TOPRIGHT" then
		h:SetPoint("TOPRIGHT")
		v:SetPoint("TOPRIGHT")
	elseif anchor == "BOTTOMLEFT" then
		h:SetPoint("BOTTOMLEFT")
		v:SetPoint("BOTTOMLEFT")
	else
		h:SetPoint("BOTTOMRIGHT")
		v:SetPoint("BOTTOMRIGHT")
	end
end
--------------------------------
function AddOn:EnsureFlightTimerMover()
	local frame = AddOn.flightTimerFrame
	if not frame or AddOn.flightTimerMover then
		return AddOn.flightTimerMover
	end
	local template = BackdropTemplateMixin and "BackdropTemplate" or nil
	local overlay = CreateFrame("Frame", nil, frame, template)
	overlay:SetAllPoints()
	overlay:SetFrameLevel(frame:GetFrameLevel() + 20)
	overlay:EnableMouse(true)
	overlay:RegisterForDrag("LeftButton")
	overlay:Hide()
	if overlay.SetBackdrop then
		overlay:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		overlay:SetBackdropColor(0, 0, 0, 0.45)
		overlay:SetBackdropBorderColor(1, 0.82, 0, 1)
	end
	addMoverCorner(overlay, "TOPLEFT")
	addMoverCorner(overlay, "TOPRIGHT")
	addMoverCorner(overlay, "BOTTOMLEFT")
	addMoverCorner(overlay, "BOTTOMRIGHT")

	local label = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("CENTER")
	label:SetText(AddOn.L.flightTimerMoveHint or "Drag to move")
	overlay.label = label

	overlay:SetScript("OnDragStart", function()
		if not AddOn.flightTimerMoving then
			return
		end
		frame:StartMoving()
	end)
	overlay:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		local x, y = frame:GetCenter()
		if x and y then
			frame:ClearAllPoints()
			frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
		end
		AddOn:SaveFlightTimerBarPosition()
		LibStub("AceConfigRegistry-3.0"):NotifyChange(AddOn.name)
	end)
	overlay:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(AddOn.L.flightTimerMoveHint or "Drag to move", 1, 0.82, 0)
		GameTooltip:Show()
	end)
	overlay:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	frame:SetMovable(true)
	AddOn.flightTimerMover = overlay
	return overlay
end
--------------------------------
function AddOn:UpdateFlightTimerMover()
	local overlay = AddOn:EnsureFlightTimerMover()
	local frame = AddOn.flightTimerFrame
	if not overlay or not frame then
		return
	end
	local canMove = AddOn.flightTimerMoving
		and AddOn:IsFlightTimerOptionsOpen()
		and isFlightTimerBarEnabled()
		and frame:IsShown()
	if canMove then
		frame:SetFrameStrata(MOVE_STRATA)
		frame:SetToplevel(true)
		overlay:SetFrameStrata(MOVE_STRATA)
		overlay:SetFrameLevel(frame:GetFrameLevel() + 20)
		overlay.label:SetText(AddOn.L.flightTimerMoveHint or "Drag to move")
		overlay:Show()
	else
		frame:StopMovingOrSizing()
		frame:SetToplevel(false)
		frame:SetFrameStrata(BAR_STRATA)
		overlay:Hide()
	end
end
--------------------------------
function AddOn:BeginFlightTimerBarMove()
	if not isFlightTimerBarEnabled() or not AddOn:IsFlightTimerOptionsOpen() then
		return
	end
	if not AddOn.flightTimerFrame or not AddOn.flightTimerFrame:IsShown() then
		AddOn:RefreshFlightTimerBarPreview()
	end
	if not AddOn.flightTimerFrame or not AddOn.flightTimerFrame:IsShown() then
		return
	end
	if AddOn:IsFlightTimerBarAtDefaultPosition() then
		AddOn.flightTimerBarPositionAtMoveStart = false
	else
		local x, y = AddOn:GetFlightTimerBarScaledCenter()
		if x and y then
			AddOn.flightTimerBarPositionAtMoveStart = { x = x, y = y }
		else
			AddOn.flightTimerBarPositionAtMoveStart = false
		end
	end
	AddOn.flightTimerMoving = true
	AddOn:UpdateFlightTimerMover()
	LibStub("AceConfigRegistry-3.0"):NotifyChange(AddOn.name)
end
--------------------------------
function AddOn:CancelFlightTimerBarMove()
	AddOn.flightTimerMoving = false
	local snap = AddOn.flightTimerBarPositionAtMoveStart
	AddOn.flightTimerBarPositionAtMoveStart = nil
	if AddOn.db and AddOn.db.global then
		if snap == false then
			AddOn.db.global.flightTimerBarPosition = nil
		elseif type(snap) == "table" then
			AddOn.db.global.flightTimerBarPosition = { x = snap.x, y = snap.y }
		end
	end
	AddOn:PositionFlightTimerBar()
	AddOn:UpdateFlightTimerMover()
	LibStub("AceConfigRegistry-3.0"):NotifyChange(AddOn.name)
end
--------------------------------
function AddOn:CaptureFlightTimerBarPositionSnapshot()
	if AddOn.flightTimerBarPositionSnapshot ~= nil then
		return
	end
	local pos = AddOn.db and AddOn.db.global and AddOn.db.global.flightTimerBarPosition
	if pos and pos.x and pos.y then
		AddOn.flightTimerBarPositionSnapshot = { x = pos.x, y = pos.y }
	else
		AddOn.flightTimerBarPositionSnapshot = false
	end
end
--------------------------------
function AddOn:RevertFlightTimerBarPosition()
	local snap = AddOn.flightTimerBarPositionSnapshot
	if AddOn.db and AddOn.db.global then
		if snap == false then
			AddOn.db.global.flightTimerBarPosition = nil
		elseif type(snap) == "table" then
			AddOn.db.global.flightTimerBarPosition = { x = snap.x, y = snap.y }
		end
	end
	AddOn:PositionFlightTimerBar()
	LibStub("AceConfigRegistry-3.0"):NotifyChange(AddOn.name)
end
--------------------------------
function AddOn:LayoutFlightTimerBar()
	local frame = AddOn.flightTimerFrame
	local clip = AddOn.flightTimerHeaderClip
	local barFrame = AddOn.flightTimerBarFrame
	if not frame or not clip or not barFrame then
		return
	end
	local barOuterHeight = BAR_HEIGHT + BAR_BORDER * 2
	local barOuterWidth = BAR_WIDTH + BAR_BORDER * 2
	barFrame:ClearAllPoints()
	barFrame:SetSize(barOuterWidth, barOuterHeight)
	local headerShown = clip:IsShown()
	local headerHeight = headerShown and clip:GetHeight() or 0
	local overlap = headerShown and HEADER_OVERLAP or 0
	clip:ClearAllPoints()
	clip:SetPoint("BOTTOM", barFrame, "TOP", 0, -overlap)

	local extraLeft = 0
	local extraRight = 0
	local headerW = headerShown and clip:GetWidth() or 0
	local earlyBtn = AddOn.flightTimerEarlyLandingButton
	local soundBtn = AddOn.flightTimerSoundButton
	local earlyY = 0
	if earlyBtn and earlyBtn:IsShown() and soundBtn and soundBtn:IsShown() then
		earlyY = (soundBtn:GetHeight() - earlyBtn:GetHeight()) / 2
	end
	if earlyBtn and earlyBtn:IsShown() then
		earlyBtn:ClearAllPoints()
		if headerShown then
			earlyBtn:SetPoint("BOTTOMRIGHT", clip, "LEFT", -SIDE_ICON_GAP, earlyY)
		else
			earlyBtn:SetPoint("BOTTOMRIGHT", barFrame, "TOPLEFT", -SIDE_ICON_GAP, overlap + earlyY)
		end
		extraLeft = math.max(0, headerW / 2 + earlyBtn:GetWidth() + SIDE_ICON_GAP - barOuterWidth / 2)
	end
	if soundBtn and soundBtn:IsShown() then
		soundBtn:ClearAllPoints()
		if headerShown then
			soundBtn:SetPoint("BOTTOMLEFT", clip, "RIGHT", SIDE_ICON_GAP, 0)
		else
			soundBtn:SetPoint("BOTTOMLEFT", barFrame, "TOPRIGHT", SIDE_ICON_GAP, overlap)
		end
		extraRight = math.max(0, headerW / 2 + soundBtn:GetWidth() + SIDE_ICON_GAP - barOuterWidth / 2)
	end
	frame:SetSize(barOuterWidth + extraLeft + extraRight, headerHeight + barOuterHeight - overlap)
	barFrame:SetPoint("BOTTOM", frame, "BOTTOM", (extraLeft - extraRight) / 2, 0)
end
--------------------------------
function AddOn:SizeFlightTimerHeader(name)
	local clip = AddOn.flightTimerHeaderClip
	local header = AddOn.flightTimerHeader
	if not clip or not header then
		return
	end
	name = name or ""
	if name == "" then
		clip:Hide()
		AddOn:LayoutFlightTimerBar()
		return
	end

	local nameText = header.nameText
	nameText:SetWidth(1024)
	nameText:SetText("M")
	local letterWidth = nameText:GetStringWidth()
	if not letterWidth or letterWidth < 1 then
		letterWidth = 8
	end
	nameText:SetText(name)
	local textWidth = nameText:GetStringWidth() or 0
	local innerWidth = math.min(BAR_WIDTH, textWidth + letterWidth * 2)
	local width = innerWidth + BAR_BORDER * 2
	local visibleHeight = NAME_HEIGHT + BAR_BORDER
	clip:SetSize(width, visibleHeight)
	header:SetSize(width, visibleHeight + EDGE_SIZE)
	nameText:SetWidth(innerWidth)
	clip:SetVerticalScroll(0)
	clip:Show()
	AddOn:LayoutFlightTimerBar()
end
--------------------------------
function AddOn:UpdateFlightTimerEarlyLandingButton()
	local btn = AddOn.flightTimerEarlyLandingButton
	local state = AddOn.flightTimerState
	if state and state.earlyLandingRequested and not state.preview then
		AddOn:HideFlightTimerBar()
		return
	end
	if not btn then
		return
	end
	local hops = state and tonumber(state.numHops)
	local show = state
		and (state.preview or (hops and hops > 1 and UnitOnTaxi("player")))
	if show then
		btn:Show()
	else
		btn:Hide()
	end
	AddOn:LayoutFlightTimerBar()
	AddOn:UpdateFlightTimerSoundButton()
end
--------------------------------
function AddOn:UpdateFlightTimerSoundButton()
	local btn = AddOn.flightTimerSoundButton
	if not btn then
		return
	end
	local clip = AddOn.flightTimerHeaderClip
	local show = AddOn.flightTimerFrame
		and AddOn.flightTimerFrame:IsShown()
		and clip
		and clip:IsShown()
	if show then
		btn:Show()
	else
		btn:Hide()
	end
	AddOn:LayoutFlightTimerBar()
end
--------------------------------
function AddOn:EnsureFlightTimerBar()
	if AddOn.flightTimerBar then
		return AddOn.flightTimerBar
	end

	local template = BackdropTemplateMixin and "BackdropTemplate" or nil
	local frame = CreateFrame("Frame", "FlightMasterFlightTimerBar", UIParent)
	frame:SetFrameStrata(BAR_STRATA)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(false)
	frame:Hide()

	local barFrame = CreateFrame("Frame", nil, frame, template)
	barFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
	barFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
	barFrame:EnableMouse(false)
	applyRoundedBackdrop(barFrame)
	barFrame:SetFrameLevel(frame:GetFrameLevel() + 3)

	local clip = CreateFrame("ScrollFrame", nil, frame)
	clip:EnableMouse(false)
	clip:SetFrameLevel(frame:GetFrameLevel() + 1)

	local header = CreateFrame("Frame", nil, clip, template)
	header:EnableMouse(false)
	applyRoundedBackdrop(header)
	clip:SetScrollChild(header)

	local nameText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	nameText:SetPoint("TOP", header, "TOP", 0, -4)
	nameText:SetHeight(NAME_HEIGHT)
	nameText:SetJustifyH("CENTER")
	nameText:SetJustifyV("MIDDLE")
	nameText:SetWordWrap(false)
	header.nameText = nameText

	local earlyBtn = CreateFrame("Button", nil, frame)
	earlyBtn:SetSize(28, 28)
	earlyBtn:SetNormalTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up")
	earlyBtn:SetPushedTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
	earlyBtn:SetHighlightTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down", "ADD")
	earlyBtn:SetFrameLevel(frame:GetFrameLevel() + 6)
	earlyBtn:Hide()
	earlyBtn:SetScript("OnClick", function()
		if AddOn.flightTimerState and AddOn.flightTimerState.preview then
			return
		end
		if TaxiRequestEarlyLanding then
			TaxiRequestEarlyLanding()
		end
		if AddOn.flightTimerState then
			AddOn.flightTimerState.earlyLandingRequested = true
		end
		AddOn:UpdateFlightTimerEarlyLandingButton()
	end)
	earlyBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(AddOn.L.flightTimerEarlyLanding or "Early Landing", 1, 1, 1)
		GameTooltip:AddLine(AddOn.L.flightTimerEarlyLandingTip or "Land at the next flight master", 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	earlyBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	AddOn.flightTimerEarlyLandingButton = earlyBtn

	local soundBtn = CreateFrame("Button", nil, frame)
	soundBtn:SetSize(20, 20)
	soundBtn:SetFrameLevel(frame:GetFrameLevel() + 6)
	soundBtn:EnableMouse(false)
	soundBtn:Hide()
	local speaker = soundBtn:CreateTexture(nil, "ARTWORK")
	speaker:SetAllPoints()
	speaker:SetTexture("Interface\\Common\\VoiceChat-Speaker")
	local speakerOn = soundBtn:CreateTexture(nil, "OVERLAY")
	speakerOn:SetAllPoints()
	speakerOn:SetTexture("Interface\\Common\\VoiceChat-On")
	AddOn.flightTimerSoundButton = soundBtn

	local fillClip = CreateFrame("ScrollFrame", nil, barFrame)
	fillClip:SetPoint("TOPLEFT", BAR_BORDER, -BAR_BORDER)
	fillClip:SetPoint("BOTTOMLEFT", BAR_BORDER, BAR_BORDER)
	fillClip:SetWidth(0.001)
	fillClip:EnableMouse(false)

	local fillChild = CreateFrame("Frame", nil, fillClip)
	fillChild:SetSize(BAR_WIDTH, BAR_HEIGHT)
	fillClip:SetScrollChild(fillChild)

	local fill = fillChild:CreateTexture(nil, "ARTWORK")
	fill:SetAllPoints()
	fill:SetHorizTile(false)
	fill:SetTexture(BAR_TEXTURES.blizzard)
	fillClip:SetFrameLevel(barFrame:GetFrameLevel() + 1)

	local textFrame = CreateFrame("Frame", nil, barFrame)
	textFrame:SetAllPoints()
	textFrame:EnableMouse(false)
	textFrame:SetFrameLevel(barFrame:GetFrameLevel() + 5)

	local text = textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	text:SetPoint("CENTER")
	text:SetJustifyH("CENTER")
	barFrame.timeText = text

	frame:SetScript("OnUpdate", function(_, dt)
		AddOn:UpdateFlightTimerBar(dt)
	end)
	frame:SetScript("OnEvent", function()
		AddOn:PositionFlightTimerBar()
	end)
	frame:RegisterEvent("DISPLAY_SIZE_CHANGED")
	frame:RegisterEvent("UI_SCALE_CHANGED")

	AddOn.flightTimerFrame = frame
	AddOn.flightTimerHeaderClip = clip
	AddOn.flightTimerHeader = header
	AddOn.flightTimerBarFrame = barFrame
	AddOn.flightTimerBar = fillClip
	AddOn.flightTimerFill = fill
	AddOn:LayoutFlightTimerBar()
	AddOn:PositionFlightTimerBar()
	AddOn:ApplyFlightTimerBarStyle(1)
	return fillClip
end
--------------------------------
function AddOn:ShowFlightCancelledMessage()
	local msg = AddOn.L.flightTimerCancelled or "Flight Cancelled"
	pcall(UIParentLoadAddOn, "Blizzard_CombatText")
	local f = AddOn.flightCancelledFloater
	if not f then
		f = CreateFrame("Frame", nil, UIParent)
		f:SetSize(600, 48)
		f:SetFrameStrata("HIGH")
		f:SetFrameLevel(100)
		local fs = f:CreateFontString(nil, "OVERLAY")
		fs:SetFontObject(CombatTextFont or GameFontNormalHuge)
		fs:SetAllPoints()
		fs:SetTextColor(1, 1, 0)
		f.text = fs
		AddOn.flightCancelledFloater = f
	end
	f.text:SetText(msg)
	local cx, cy = UIParent:GetCenter()
	f.startX = cx or 0
	f.startY = cy or 0
	f.elapsed = 0
	f:ClearAllPoints()
	f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", f.startX, f.startY)
	f:SetAlpha(1)
	f:Show()
	f:SetScript("OnUpdate", function(self, dt)
		self.elapsed = (self.elapsed or 0) + dt
		local duration = 1.8
		if self.elapsed >= duration then
			self:Hide()
			self:SetScript("OnUpdate", nil)
			return
		end
		self:ClearAllPoints()
		self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", self.startX, self.startY + 80 * self.elapsed)
		if self.elapsed > duration * 0.45 then
			self:SetAlpha(1 - (self.elapsed - duration * 0.45) / (duration * 0.55))
		end
	end)
end
--------------------------------
function AddOn:HideFlightTimerBar()
	local cancelled = AddOn.flightTimerState
		and AddOn.flightTimerState.earlyLandingRequested
		and not AddOn.flightTimerState.preview
	if AddOn.flightTimerFrame then
		AddOn.flightTimerFrame:StopMovingOrSizing()
		AddOn.flightTimerFrame:Hide()
	end
	if AddOn.flightTimerMover then
		AddOn.flightTimerMover:Hide()
	end
	AddOn.flightTimerState = nil
	if cancelled then
		AddOn:ShowFlightCancelledMessage()
	end
end
--------------------------------
function AddOn:StartFlightTimerBar(originID, destID, duration, destName, estimated, elapsedAlready, arrivalClock, numHops)
	duration = tonumber(duration)
	if not isFlightTimerBarEnabled() or not duration or duration < 1 then
		AddOn:HideFlightTimerBar()
		return
	end
	elapsedAlready = tonumber(elapsedAlready) or 0
	if elapsedAlready < 0 then
		elapsedAlready = 0
	end
	if type(arrivalClock) ~= "string" or arrivalClock == "" then
		arrivalClock = AddOn:FormatArrivalClock(math.max(0, duration - elapsedAlready))
	end
	AddOn.flightTimerState = {
		startTime = GetTime() - elapsedAlready,
		duration = duration,
		originID = originID,
		destID = destID,
		destName = displayTaxiName(destName),
		displayedElapsed = math.min(elapsedAlready, duration),
		estimated = not not estimated,
		arrivalClock = arrivalClock,
		numHops = tonumber(numHops),
	}
	AddOn:EnsureFlightTimerBar()
	AddOn:SizeFlightTimerHeader(AddOn.flightTimerState.destName)
	AddOn:PositionFlightTimerBar()
	AddOn:ApplyFlightTimerBarStyle(1)
	AddOn.flightTimerFrame:Show()
	AddOn:UpdateFlightTimerBar(0)
	AddOn:UpdateFlightTimerMover()
	AddOn:UpdateFlightTimerEarlyLandingButton()
end
--------------------------------
function AddOn:UpdateFlightTimerBar(dt)
	local bar = AddOn.flightTimerBar
	local fill = AddOn.flightTimerFill
	local state = AddOn.flightTimerState
	local frame = AddOn.flightTimerFrame
	if not bar or not fill or not frame or not state or not frame:IsShown() then
		return
	end
	if not isFlightTimerBarEnabled() then
		AddOn:HideFlightTimerBar()
		return
	end
	if not state.preview and not UnitOnTaxi("player") then
		AddOn:HideFlightTimerBar()
		return
	end
	if state.earlyLandingRequested then
		AddOn:HideFlightTimerBar()
		return
	end

	local duration = state.duration
	if not duration or duration < 1 then
		AddOn:HideFlightTimerBar()
		return
	end
	dt = dt or 0
	if state.preview then
		dt = 0
	end
	local elapsed = GetTime() - state.startTime
	if elapsed < 0 then
		elapsed = 0
	elseif elapsed > duration then
		elapsed = duration
	end
	state.displayedElapsed = state.displayedElapsed or 0
	if state.displayedElapsed > elapsed then
		state.displayedElapsed = elapsed
	else
		local factor = 1 - math.exp(-dt * FILL_SMOOTHING)
		state.displayedElapsed = state.displayedElapsed + (elapsed - state.displayedElapsed) * factor
	end

	local pct = state.displayedElapsed / duration
	if pct < 0 then
		pct = 0
	elseif pct > 1 then
		pct = 1
	end
	bar:SetWidth(math.max(0.001, BAR_WIDTH * pct))

	local remaining = math.max(0, duration - elapsed)
	local timeText = AddOn.flightTimerBarFrame and AddOn.flightTimerBarFrame.timeText
	local style = AddOn:GetFlightTimerBarStyle()
	if timeText then
		if style.timeDisplay == "arrival" then
			if not state.arrivalLabel then
				local clock = state.arrivalClock or AddOn:FormatArrivalClock(duration)
				state.arrivalClock = clock
				local L = AddOn.L
				if state.estimated then
					state.arrivalLabel = string.format(L.flightTimerArrivesAtEstimated, clock)
				else
					state.arrivalLabel = string.format(L.flightTimerArrivesAt, clock)
				end
			end
			if timeText:GetText() ~= state.arrivalLabel then
				timeText:SetText(state.arrivalLabel)
			end
		else
			timeText:SetText(AddOn:FormatFlightTime(remaining))
		end
	end
	if style.colorMode == "remaining" then
		fill:SetVertexColor(remainingFillColor(1 - pct))
	elseif timeText then
		local c = style.timeText
		timeText:SetTextColor(c[1], c[2], c[3], c[4] or 1)
	end
end
--------------------------------
local PREVIEW_DURATION = 90
local PREVIEW_ELAPSED = 36
--------------------------------
function AddOn:IsFlightTimerOptionsOpen()
	local dialog = LibStub("AceConfigDialog-3.0", true)
	if not dialog then
		return false
	end
	local standalone = dialog.OpenFrames and dialog.OpenFrames[AddOn.name]
	if standalone then
		local closing = dialog.frame and dialog.frame.closing and dialog.frame.closing[AddOn.name]
		if not closing then
			return true
		end
	end
	local groups = dialog.BlizOptions and dialog.BlizOptions[AddOn.name]
	if groups then
		for _, group in pairs(groups) do
			local frame = group.frame
			if frame and frame:IsVisible() then
				return true
			end
		end
	end
	return false
end
--------------------------------
function AddOn:OnFlightTimerOptionsClosed()
	if AddOn:IsFlightTimerOptionsOpen() then
		AddOn:UpdateFlightTimerMover()
		return
	end
	AddOn.flightTimerMoving = false
	AddOn.flightTimerBarPositionSnapshot = nil
	AddOn.flightTimerBarStyleSnapshot = nil
	local inRealFlight = UnitOnTaxi("player") and AddOn.flightTimerState and not AddOn.flightTimerState.preview
	if not inRealFlight then
		AddOn:HideFlightTimerBar()
	else
		AddOn:UpdateFlightTimerMover()
	end
end
--------------------------------
function AddOn:RefreshFlightTimerBarPreview()
	if AddOn:IsFlightTimerOptionsOpen() then
		AddOn:CaptureFlightTimerBarPositionSnapshot()
		if AddOn.CaptureFlightTimerBarStyleSnapshot then
			AddOn:CaptureFlightTimerBarStyleSnapshot()
		end
	end
	if AddOn.flightTimerState and not AddOn.flightTimerState.preview then
		AddOn:UpdateFlightTimerMover()
		return
	end
	if not AddOn:IsFlightTimerOptionsOpen() or not isFlightTimerBarEnabled() or UnitOnTaxi("player") then
		if AddOn.flightTimerState and AddOn.flightTimerState.preview then
			AddOn:HideFlightTimerBar()
		end
		AddOn:UpdateFlightTimerMover()
		return
	end
	if AddOn.flightTimerState and AddOn.flightTimerState.preview and AddOn.flightTimerFrame and AddOn.flightTimerFrame:IsShown() then
		AddOn:ApplyFlightTimerBarStyle(1 - PREVIEW_ELAPSED / PREVIEW_DURATION)
		AddOn:UpdateFlightTimerBar(0)
		AddOn:UpdateFlightTimerMover()
		return
	end
	local destName = AddOn.L.flightTimerPreviewDest or "Stormwind"
	AddOn.flightTimerState = {
		preview = true,
		startTime = GetTime() - PREVIEW_ELAPSED,
		duration = PREVIEW_DURATION,
		destName = destName,
		displayedElapsed = PREVIEW_ELAPSED,
		estimated = false,
		arrivalClock = AddOn:FormatArrivalClock(PREVIEW_DURATION - PREVIEW_ELAPSED),
		arrivalLabel = nil,
	}
	AddOn:EnsureFlightTimerBar()
	AddOn:SizeFlightTimerHeader(destName)
	AddOn:PositionFlightTimerBar()
	AddOn:ApplyFlightTimerBarStyle(1 - PREVIEW_ELAPSED / PREVIEW_DURATION)
	AddOn.flightTimerFrame:Show()
	AddOn:UpdateFlightTimerBar(0)
	AddOn:UpdateFlightTimerMover()
	AddOn:UpdateFlightTimerEarlyLandingButton()
end
--------------------------------
function AddOn:InitTaxiTimer()
	AddOn:AddMessageHandler(AddOn.Message.TAXI_START, function(originID, destID, duration, destName, estimated, arrivalClock, numHops)
		AddOn:StartFlightTimerBar(originID, destID, duration, destName, estimated, nil, arrivalClock, numHops)
	end)
	AddOn:AddMessageHandler(AddOn.Message.TAXI_END, function()
		AddOn:HideFlightTimerBar()
		AddOn:RefreshFlightTimerBarPreview()
	end)
	local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
	if AceConfigDialog then
		hooksecurefunc(AceConfigDialog, "Close", function(_, appName)
			if appName == AddOn.name or appName == nil then
				AddOn:OnFlightTimerOptionsClosed()
			end
		end)
		hooksecurefunc(AceConfigDialog, "CloseAll", function()
			AddOn:OnFlightTimerOptionsClosed()
		end)
		hooksecurefunc(AceConfigDialog, "Open", function(_, appName)
			if appName == AddOn.name then
				AddOn:RefreshFlightTimerBarPreview()
			end
		end)
		local groups = AceConfigDialog.BlizOptions and AceConfigDialog.BlizOptions[AddOn.name]
		if groups then
			for _, group in pairs(groups) do
				local frame = group.frame
				if frame and not frame._flightMasterPreviewHooked then
					frame._flightMasterPreviewHooked = true
					frame:HookScript("OnShow", function()
						AddOn:RefreshFlightTimerBarPreview()
					end)
					frame:HookScript("OnHide", function()
						AddOn:OnFlightTimerOptionsClosed()
					end)
				end
			end
		end
	end
	AddOn:RestoreInFlightSession()
end
