local AddOn = _G[select(1, ...)]
--------------------------------
local function getItemIdFromLink(link)
	if type(link) == "string" then
		local match = link:match("|Hitem:(%d+):")
		if match == nil then
			match = link:match("|Hspell:(%d+):")
		end
		if match == nil then
			match = link:match("|Hcurrency:(%d+):")
		end
		return tonumber(match or 0)
	end
	return 0
end
--------------------------------
local function getItemNameFromLink(link)
	if type(link) == "string" then
		local match = link:match("|h[(%w+)]h|")
		return tostring(match or 0)
	end
	return 0
end
--------------------------------
local function pack(...)
	return { n = select("#", ...), ... }
end
--------------------------------
local function unpack(t, i, j)
	i = i or 1
	j = j or #t
	if i <= j then
		return t[i], unpack(t, i + 1, j)
	end
end
--------------------------------
local function getPrintableLink(link)
	return link:gsub("\124", "\124\124")
end
--------------------------------
local function split(text, separator)
	local parts = {}
	for part in string.gmatch(text, "[^" .. separator .. "]+") do
		table.insert(parts, part)
	end
	return unpack(parts)
end
--------------------------------
local function filter(tabl, matchFn)
	local result = {}
	for key, value in pairs(tabl) do
		if matchFn(key, value) then
			result[key] = value
		end
	end
	return result
end
local function ifilter(
	tabl,
	matchFn --[[(index,value)]]
)
	local result = {}
	for index, value in ipairs(tabl) do
		if matchFn(index, value) then
			table.insert(result, value)
		end
	end
	return result
end
--------------------------------
local function copy(obj, seen)
	if type(obj) ~= "table" then
		return obj
	end
	if seen and seen[obj] then
		return seen[obj]
	end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do
		res[copy(k, s)] = copy(v, s)
	end
	return res
end
--------------------------------
local function printTable(table, color)
	color = color or ""
	print(color .. tostring(table) .. "\n")
	for index, value in pairs(table) do
		print(color .. "    " .. tostring(index) .. " : " .. tostring(value) .. "\n")
	end
end
--------------------------------
local function round(a)
	return math.floor(a + 0.5)
end
--------------------------------
AddOn.Utility = {
	getItemIdFromLink = getItemIdFromLink,
	getItemNameFromLink = getItemNameFromLink,
	pack = pack,
	unpack = unpack,
	filter = filter,
	ifilter = ifilter,
	copy = copy,
	getPrintableLink = getPrintableLink,
	split = split,
	printTable = printTable,
	round = round,
}
