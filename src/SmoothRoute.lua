local AddOn = _G[select(1, ...)]
--------------------------------
local MAX_SMOOTH_SEGMENTS = 200
local MIN_PIXELS_PER_STEP = 10
--------------------------------
local function catmullRom(p0, p1, p2, p3, t)
	local t2 = t * t
	local t3 = t2 * t
	return 0.5
		* (
			(2 * p1)
			+ (-p0 + p2) * t
			+ (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
			+ (-p0 + 3 * p1 - 3 * p2 + p3) * t3
		)
end
--------------------------------
local function isOnMap(x, y)
	return x and y and x >= -0.05 and x <= 1.05 and y >= -0.05 and y <= 1.05
end
--------------------------------
local function segmentVisible(a, b)
	if isOnMap(a.x, a.y) or isOnMap(b.x, b.y) then
		return true
	end
	if (a.x < 0 and b.x > 1) or (a.x > 1 and b.x < 0) or (a.y < 0 and b.y > 1) or (a.y > 1 and b.y < 0) then
		return true
	end
	return false
end
--------------------------------
local function samplesToMapPoints(samples, mapID)
	local points = {}
	for i = 1, #samples do
		local s = samples[i]
		if type(s) == "table" and s.x and s.y then
			local mx, my = AddOn:WorldToMapXY(s.x, s.y, s.instanceID, mapID)
			if mx and my then
				points[#points + 1] = { x = mx, y = my }
			end
		end
	end
	return points
end
--------------------------------
local function splinePoints(points, w, h)
	local n = #points
	if n <= 2 then
		return points
	end
	local out = {}
	local function emit(x, y)
		local last = out[#out]
		if last and last.x == x and last.y == y then
			return
		end
		out[#out + 1] = { x = x, y = y }
	end
	for i = 1, n - 1 do
		local p0 = points[math.max(1, i - 1)]
		local p1 = points[i]
		local p2 = points[i + 1]
		local p3 = points[math.min(n, i + 2)]
		local dx = (p2.x - p1.x) * w
		local dy = (p2.y - p1.y) * h
		local pixels = math.sqrt(dx * dx + dy * dy)
		local steps = math.max(1, math.min(16, math.floor(pixels / MIN_PIXELS_PER_STEP + 0.5)))
		if #out + steps > MAX_SMOOTH_SEGMENTS then
			steps = math.max(1, MAX_SMOOTH_SEGMENTS - #out)
		end
		for s = 0, steps - 1 do
			local t = s / steps
			emit(catmullRom(p0.x, p1.x, p2.x, p3.x, t), catmullRom(p0.y, p1.y, p2.y, p3.y, t))
		end
		if #out >= MAX_SMOOTH_SEGMENTS then
			break
		end
	end
	local last = points[n]
	emit(last.x, last.y)
	return out
end
--------------------------------
local function drawPolyline(points, frame, startIndex)
	local w, h = AddOn:GetFrameDim(frame)
	if not w or not h or w <= 0 or h <= 0 then
		return 0
	end
	local used = 0
	local lineFactor = TAXIROUTE_LINEFACTOR or 1
	for i = 1, #points - 1 do
		local a = points[i]
		local b = points[i + 1]
		if segmentVisible(a, b) then
			used = used + 1
			local line = AddOn:GetRouteLine(startIndex + used - 1)
			if line then
				DrawLine(
					line,
					frame,
					a.x * w,
					(1.0 - a.y) * h,
					b.x * w,
					(1.0 - b.y) * h,
					32,
					lineFactor
				)
				line:Show()
			end
		end
	end
	return used
end
--------------------------------
function AddOn:DrawSmoothFlightPath(originNodeID, destNodeID, frame, startIndex)
	if not AddOn:GetShowSmoothRoutes() then
		return 0
	end
	if not originNodeID or not destNodeID or not frame or not startIndex then
		return 0
	end
	if not AddOn.GetFlightPath then
		return 0
	end
	local samples = AddOn:GetFlightPath(originNodeID, destNodeID)
	if type(samples) ~= "table" or #samples < 2 then
		return 0
	end
	local mapID = AddOn.mapInfo and AddOn.mapInfo.mapID
	if not mapID then
		return 0
	end
	local w, h = AddOn:GetFrameDim(frame)
	if not w or not h or w <= 0 or h <= 0 then
		return 0
	end
	local mapPoints = samplesToMapPoints(samples, mapID)
	if #mapPoints < 2 then
		return 0
	end
	local ok, used = pcall(drawPolyline, splinePoints(mapPoints, w, h), frame, startIndex)
	if ok and type(used) == "number" and used > 0 then
		return used
	end
	return 0
end
