local addonName = ...
_G[addonName] = _G[addonName]
	or LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
_G[addonName].L = LibStub("AceLocale-3.0"):GetLocale(addonName)
