local AddOn = _G[select(1, ...)]
local prefixName = string.upper(AddOn.name) .. "_"
--------------------------------
AddOn.Message = {
	ENABLE_ADDON = prefixName .. "ENABLE",
	DISABLE_ADDON = prefixName .. "DISABLE",
}
--------------------------------
AddOn.String = {
	CommandName = AddOn.L.addOnSlashCmd,
	Title = select(2, GetAddOnInfo(AddOn:GetName())),
}
