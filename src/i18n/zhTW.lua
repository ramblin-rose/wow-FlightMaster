local addonName = select(1, ...)
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "zhTW")
if not L then
	return
end
L.addOnName = "飛行管理員"
L.addOnSlashCmd = "fm"
L.on = "開啟"
L.off = "關閉"
L.configEnableDesc = "在本次登入期間暫時啟用/停用本插件"
L.configShowUnknown = "顯示未知"
L.configShowUnknownDesc = "顯示/隱藏未知的飛行管理員"
L.configPOIName = "飛行點圖示大小"
L.configPOIDesc = "選擇飛行點圖示的大小"
L.configAutoCancelShapeShift = "自動取消變形形態"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
選擇飛行目的地時，自動取消德魯伊或薩滿的變形形態。

戰鬥中不會生效。]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"Questie 的「飛行管理員」圖示選項已啟用，可能會影響本插件的使用體驗。"
