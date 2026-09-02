local addonName = select(1, ...)
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "zhCN")
if not L then
	return
end
L.addOnName = "飞行管理员"
L.addOnSlashCmd = "fm"
L.on = "开启"
L.off = "关闭"
L.configEnableDesc = "在本次登录期间临时启用/禁用本插件"
L.configShowUnknown = "显示未知"
L.configShowUnknownDesc = "显示/隐藏未知的飞行管理员"
L.configPOIName = "飞行点图标大小"
L.configPOIDesc = "选择飞行点图标的大小"
L.configAutoCancelShapeShift = "自动取消变形形态"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
选择飞行目的地时，自动取消德鲁伊或萨满祭司的变形形态。

战斗中不会生效。]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"Questie 的“飞行管理员”图标选项已启用，可能会影响本插件的使用体验。"
