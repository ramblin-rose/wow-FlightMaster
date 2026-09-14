local AddOn = _G[select(1, ...)]
local prefixName = string.upper(AddOn.name) .. "_"
--------------------------------
AddOn.Message = {
	ENABLE_ADDON = prefixName .. "ENABLE",
	DISABLE_ADDON = prefixName .. "DISABLE",
	TAXI_START = prefixName .. "TAXI_START",
}
--------------------------------
local getAddOnInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
local getAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata

AddOn.String = {
	CommandName = AddOn.L.addOnSlashCmd,
	Title = select(2, getAddOnInfo(AddOn.name)),
	SemVer = getAddOnMetadata(AddOn.name, "Version"),
}
