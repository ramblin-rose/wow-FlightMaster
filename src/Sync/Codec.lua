local AddOn = _G[select(1, ...)]
--------------------------------
local MAX_ENCODED = 254
local COMPRESS_MIN = 64
local MAX_WIRE_POINTS = 16
local MAX_PLAIN = 4096
local MAX_COORD = 100000
local FLAG_RAW = "\000"
local FLAG_DEFLATE = "\001"

local LibSerialize
local LibDeflate
--------------------------------
local function libs()
	if not LibSerialize then
		LibSerialize = LibStub("LibSerialize")
	end
	if not LibDeflate then
		LibDeflate = LibStub("LibDeflate")
	end
	return LibSerialize, LibDeflate
end
--------------------------------
local function u32le(n)
	n = tonumber(n) or 0
	if n < 0 then
		n = 0
	end
	n = n % 4294967296
	local b1 = n % 256
	n = (n - b1) / 256
	local b2 = n % 256
	n = (n - b2) / 256
	local b3 = n % 256
	n = (n - b3) / 256
	local b4 = n % 256
	return string.char(b1, b2, b3, b4)
end
--------------------------------
local function readU32le(s, i)
	local b1, b2, b3, b4 = string.byte(s, i, i + 3)
	if not b4 then
		return nil
	end
	return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end
--------------------------------
function AddOn:SyncMaxEncoded()
	return MAX_ENCODED
end
--------------------------------
function AddOn:SyncAdler32(str)
	local _, deflate = libs()
	if type(str) ~= "string" then
		str = tostring(str or "")
	end
	return deflate:Adler32(str)
end
--------------------------------
function AddOn:HashFlightTimeRecord(originID, destID, seconds, n)
	return AddOn:SyncAdler32(string.format("t:%d:%d:%d:%d", originID, destID, seconds, n or 1))
end
--------------------------------
function AddOn:HashFlightPathPoints(originID, destID, n, instanceID, pts)
	local parts = {
		string.format("p:%d:%d:%d:%d", originID, destID, n or 1, instanceID or 0),
	}
	if type(pts) == "table" then
		for i = 1, #pts do
			local p = pts[i]
			if type(p) == "table" and p.x and p.y then
				parts[#parts + 1] = string.format("%.0f,%.0f", p.x, p.y)
			end
		end
	end
	return AddOn:SyncAdler32(table.concat(parts, ":"))
end
--------------------------------
function AddOn:PackBucketHashes(hashes)
	local chunks = {}
	for i = 1, 32 do
		chunks[i] = u32le(hashes and hashes[i] or 0)
	end
	return table.concat(chunks)
end
--------------------------------
function AddOn:UnpackBucketHashes(blob)
	if type(blob) ~= "string" or #blob ~= 128 then
		return nil
	end
	local hashes = {}
	for i = 1, 32 do
		hashes[i] = readU32le(blob, (i - 1) * 4 + 1)
	end
	return hashes
end
--------------------------------
function AddOn:QuantizePathPoints(samples)
	if type(samples) ~= "table" or #samples < 1 then
		return nil
	end
	local n = #samples
	local picked = {}
	if n <= MAX_WIRE_POINTS then
		for i = 1, n do
			picked[i] = samples[i]
		end
	else
		for i = 0, MAX_WIRE_POINTS - 1 do
			local idx = 1 + math.floor(i * (n - 1) / (MAX_WIRE_POINTS - 1) + 0.5)
			picked[#picked + 1] = samples[idx]
		end
	end
	local pts = {}
	local instanceID
	for i = 1, #picked do
		local s = picked[i]
		if type(s) == "table" and s.x and s.y then
			if instanceID == nil then
				instanceID = s.instanceID
			end
			local x = math.floor(tonumber(s.x) + 0.5)
			local y = math.floor(tonumber(s.y) + 0.5)
			local last = pts[#pts]
			if not last or last.x ~= x or last.y ~= y then
				pts[#pts + 1] = { x = x, y = y }
			end
		end
	end
	if #pts < 1 then
		return nil
	end
	return instanceID, pts
end
--------------------------------
function AddOn:ExpandPathPoints(instanceID, pts)
	if type(pts) ~= "table" or #pts < 1 then
		return nil
	end
	instanceID = tonumber(instanceID)
	if instanceID and (instanceID ~= instanceID or instanceID < 0 or instanceID > 2147483647) then
		instanceID = nil
	end
	local n = #pts
	if n > MAX_WIRE_POINTS then
		n = MAX_WIRE_POINTS
	end
	local samples = {}
	for i = 1, n do
		local p = pts[i]
		if type(p) == "table" then
			local x, y = tonumber(p.x), tonumber(p.y)
			if
				x
				and y
				and x == x
				and y == y
				and x >= -MAX_COORD
				and x <= MAX_COORD
				and y >= -MAX_COORD
				and y <= MAX_COORD
			then
				samples[#samples + 1] = {
					x = x,
					y = y,
					instanceID = instanceID,
				}
			end
		end
	end
	if #samples < 1 then
		return nil
	end
	return samples
end
--------------------------------
function AddOn:SyncEncode(msg, level)
	local serialize, deflate = libs()
	if type(msg) ~= "table" then
		return nil
	end
	msg.v = msg.v or 1
	msg.era = msg.era or self:GetClientFamily()
	msg.fac = msg.fac or self:GetSyncFaction()
	local ok, plain = pcall(serialize.Serialize, serialize, msg)
	if not ok or type(plain) ~= "string" then
		return nil
	end
	local body = plain
	local flag = FLAG_RAW
	if #plain >= COMPRESS_MIN then
		local compressed = deflate:CompressDeflate(plain, { level = level or 1 })
		if type(compressed) == "string" and #compressed < #plain then
			body = compressed
			flag = FLAG_DEFLATE
		end
	end
	local encoded = deflate:EncodeForWoWAddonChannel(flag .. body)
	if type(encoded) ~= "string" or encoded == "" then
		return nil
	end
	return encoded
end
--------------------------------
function AddOn:SyncDecode(encoded)
	local serialize, deflate = libs()
	if type(encoded) ~= "string" or encoded == "" then
		return nil
	end
	local decoded = deflate:DecodeForWoWAddonChannel(encoded)
	if type(decoded) ~= "string" or #decoded < 1 then
		return nil
	end
	local flag = decoded:sub(1, 1)
	local body = decoded:sub(2)
	local plain = body
	if flag == FLAG_DEFLATE then
		local ok, result = pcall(deflate.DecompressDeflate, deflate, body)
		if not ok or type(result) ~= "string" then
			return nil
		end
		plain = result
	elseif flag ~= FLAG_RAW then
		return nil
	end
	if type(plain) ~= "string" or #plain < 1 or #plain > MAX_PLAIN then
		return nil
	end
	local ok, success, msg = pcall(serialize.Deserialize, serialize, plain)
	if not ok or not success or type(msg) ~= "table" then
		return nil
	end
	return msg
end
