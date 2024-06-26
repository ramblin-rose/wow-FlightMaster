local addonName = select(1, ...)
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)
L.addOnName = addonName
L.addOnSlashCmd = "fm"
L.on = "on"
L.off = "off"
L.configEnableDesc = "Temporarily enables / disables the addon for this session"
L.configShowUnknown = "Show Unknown"
L.configShowUnknownDesc = "Show / hide unknown Flight Masters"
L.configPOIName = "Flight Point Icon Size"
L.configPOIDesc = "Select the flight point icon size"
