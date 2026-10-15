local AddOn = _G[select(1, ...)]
local L = AddOn.L
--------------------------------
local FRAME_WIDTH = 640
local FRAME_HEIGHT = 420
local ROW_HEIGHT = 20
local HEADER_HEIGHT = 22
local LIST_INSET = 12
local SCROLLBAR_WIDTH = 22
local PATH_ICON_SIZE = 16
local PATH_KNOWN_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Ready"
local PATH_UNKNOWN_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-NotReady"
local COLS = {
	{ key = "origin", width = 220 },
	{ key = "dest", width = 210 },
	{ key = "time", width = 80 },
	{ key = "path", width = 70 },
}

local viewFrame
local countLabel
local listFrame
local listChild
local headerRow
local rows = {}
--------------------------------
local function displayName(nodeID)
	local name = AddOn:GetTaxiNodeName(nodeID)
	if type(name) ~= "string" or name == "" then
		return tostring(nodeID)
	end
	local short = name:match("^%s*([^,]+)")
	if short then
		short = short:match("^%s*(.-)%s*$")
	end
	if short and short ~= "" then
		return short
	end
	return name
end

local function columnText(pair, key)
	if key == "origin" then
		return displayName(pair.originNodeID)
	end
	if key == "dest" then
		return displayName(pair.destNodeID)
	end
	if key == "time" then
		if pair.seconds then
			return AddOn:FormatFlightTime(pair.seconds)
		end
		return L.flightTimeUnknown
	end
end

local function columnLeft(colIndex)
	local x = 4
	for i = 1, colIndex - 1 do
		x = x + COLS[i].width
	end
	return x
end

local function applyColumnPoints(fs, colIndex, parent)
	local x = columnLeft(colIndex)
	fs:ClearAllPoints()
	fs:SetPoint("LEFT", parent, "LEFT", x, 0)
	fs:SetSize(COLS[colIndex].width - 4, ROW_HEIGHT)
end

local function applyPathIconPoints(tex, colIndex, parent)
	local x = columnLeft(colIndex) + (COLS[colIndex].width - PATH_ICON_SIZE) / 2
	tex:ClearAllPoints()
	tex:SetSize(PATH_ICON_SIZE, PATH_ICON_SIZE)
	tex:SetPoint("LEFT", parent, "LEFT", x, 0)
end

local function setPathIcon(tex, hasPath)
	if hasPath then
		tex:SetTexture(PATH_KNOWN_TEXTURE)
	else
		tex:SetTexture(PATH_UNKNOWN_TEXTURE)
	end
	tex:SetVertexColor(1, 1, 1, 1)
end

local function createHeader(parent)
	local header = CreateFrame("Frame", nil, parent)
	header:SetHeight(HEADER_HEIGHT)
	local labels = {
		origin = L.flightDataViewOrigin,
		dest = L.flightDataViewDestination,
		time = L.flightDataViewTime,
		path = L.flightDataViewPath,
	}
	for i, col in ipairs(COLS) do
		local fs = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		applyColumnPoints(fs, i, header)
		fs:SetJustifyH(col.key == "path" and "CENTER" or "LEFT")
		fs:SetJustifyV("MIDDLE")
		fs:SetText(labels[col.key])
	end
	return header
end

local function createRow(index)
	local row = CreateFrame("Frame", nil, listChild)
	row:SetHeight(ROW_HEIGHT)
	row.cells = {}
	if index % 2 == 0 then
		local bg = row:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetTexture("Interface\\Buttons\\WHITE8X8")
		bg:SetVertexColor(1, 1, 1, 0.04)
	end
	for i, col in ipairs(COLS) do
		if col.key == "path" then
			local tex = row:CreateTexture(nil, "ARTWORK")
			applyPathIconPoints(tex, i, row)
			row.cells[col.key] = tex
		else
			local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			applyColumnPoints(fs, i, row)
			fs:SetJustifyH("LEFT")
			fs:SetJustifyV("MIDDLE")
			fs:SetWordWrap(false)
			row.cells[col.key] = fs
		end
	end
	rows[index] = row
	return row
end

local function listContentWidth()
	local width = listFrame:GetWidth()
	if width and width > 0 then
		return width
	end
	local total = 8
	for i = 1, #COLS do
		total = total + COLS[i].width
	end
	return total
end

local function layoutRows(pairCount)
	local width = listContentWidth()
	listChild:SetWidth(width)
	for i = 1, pairCount do
		local row = rows[i]
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", listChild, "TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))
		row:SetPoint("RIGHT", listChild, "RIGHT", 0, 0)
		row:Show()
	end
	for i = pairCount + 1, #rows do
		rows[i]:Hide()
	end
	local height = math.max(listFrame:GetHeight() or 0, pairCount * ROW_HEIGHT)
	listChild:SetHeight(height)
	if listFrame.UpdateScrollChildRect then
		listFrame:UpdateScrollChildRect()
	end
	listFrame:SetVerticalScroll(0)
end

local function sortPairs(list)
	table.sort(list, function(a, b)
		local ao, bo = displayName(a.originNodeID), displayName(b.originNodeID)
		if ao ~= bo then
			return ao < bo
		end
		local ad, bd = displayName(a.destNodeID), displayName(b.destNodeID)
		if ad ~= bd then
			return ad < bd
		end
		return a.originNodeID < b.originNodeID
	end)
end

local function refreshList()
	if not viewFrame then
		return
	end
	AddOn:RefreshTaxiNodeNameCache()
	local known = AddOn:GetKnownFlightPairs()
	sortPairs(known)
	countLabel:SetText(string.format(L.flightDataViewPathsKnown, #known))
	for i, pair in ipairs(known) do
		local row = rows[i] or createRow(i)
		for _, col in ipairs(COLS) do
			if col.key == "path" then
				setPathIcon(row.cells.path, pair.hasPath)
			else
				row.cells[col.key]:SetText(columnText(pair, col.key))
			end
		end
	end
	layoutRows(#known)
end

local function backdropTemplate()
	return BackdropTemplateMixin and "BackdropTemplate" or nil
end

local function applyBackdrop(frame)
	if not frame.SetBackdrop then
		return
	end
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})
	frame:SetBackdropColor(0, 0, 0, 1)
end

local function ensureView()
	if viewFrame then
		return viewFrame
	end

	local frame = CreateFrame("Frame", "FlightMasterDataView", UIParent, backdropTemplate())
	frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetScript("OnShow", refreshList)
	frame:Hide()
	applyBackdrop(frame)

	tinsert(UISpecialFrames, "FlightMasterDataView")

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -16)
	title:SetText(L.flightDataViewTitle)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)

	countLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	countLabel:SetPoint("TOPLEFT", LIST_INSET + 4, -42)
	countLabel:SetJustifyH("LEFT")

	headerRow = createHeader(frame)
	headerRow:SetPoint("TOPLEFT", LIST_INSET, -62)
	headerRow:SetPoint("TOPRIGHT", -(LIST_INSET + SCROLLBAR_WIDTH), -62)

	viewFrame = frame

	local list = CreateFrame("ScrollFrame", "FlightMasterDataViewList", frame, "UIPanelScrollFrameTemplate")
	list:SetPoint("TOPLEFT", headerRow, "BOTTOMLEFT", 0, -4)
	list:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(LIST_INSET + SCROLLBAR_WIDTH), LIST_INSET)
	list:EnableMouse(true)
	list:EnableMouseWheel(true)
	list:SetScript("OnMouseWheel", function(self, delta)
		local range = 0
		if self.GetVerticalScrollRange then
			range = self:GetVerticalScrollRange() or 0
		else
			local child = self:GetScrollChild()
			local viewHeight = self:GetHeight() or 0
			local childHeight = child and child:GetHeight() or 0
			range = math.max(0, childHeight - viewHeight)
		end
		local nextScroll = (self:GetVerticalScroll() or 0) - delta * ROW_HEIGHT * 3
		if nextScroll < 0 then
			nextScroll = 0
		elseif nextScroll > range then
			nextScroll = range
		end
		self:SetVerticalScroll(nextScroll)
	end)

	local child = CreateFrame("Frame", nil, list)
	child:SetSize(1, 1)
	list:SetScrollChild(child)

	listFrame = list
	listChild = child
	return frame
end
--------------------------------
function AddOn:ShowFlightDataView()
	ensureView():Show()
	refreshList()
end
--------------------------------
function AddOn:HideFlightDataView()
	if viewFrame then
		viewFrame:Hide()
	end
end
