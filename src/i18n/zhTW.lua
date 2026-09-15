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
L.configFlightTimes = "飛行時間"
L.configShowFlightTimes = "啟用"
L.configShowFlightTimesDesc = "在目的地圖示提示中顯示大約飛行時間，並在飛行時記錄時間"
L.configShowFlightTimerBar = "飛行時間進度條"
L.configShowFlightTimerBarDesc = "飛行時顯示剩餘時間進度條"
L.configFlightTimerBarAppearance = "進度條外觀"
L.configFlightTimerBarTimeDisplay = "進度條文字"
L.configFlightTimerBarTimeDisplayDesc = "剩餘時間為仍在空中的時長。抵達時間為大約落地時的伺服器時鐘。"
L.configFlightTimerBarDisplayRemaining = "剩餘時間"
L.configFlightTimerBarDisplayArrival = "抵達時間"
L.flightTimerArrivesAt = "%s 抵達"
L.flightTimerArrivesAtEstimated = "約 %s 抵達"
L.configFlightTimerBarColorMode = "進度條顏色"
L.configFlightTimerBarColorModeDesc = "單色使用一種填滿色。漸層從起點過渡到終點。依剩餘時間從綠變紅。"
L.configFlightTimerBarModeSolid = "單色"
L.configFlightTimerBarModeGradient = "漸層"
L.configFlightTimerBarModeRemaining = "依剩餘時間"
L.configFlightTimerBarColor = "填滿顏色"
L.configFlightTimerBarGradientFrom = "漸層起點"
L.configFlightTimerBarGradientTo = "漸層終點"
L.configFlightTimerBarTexture = "進度條材質"
L.configFlightTimerBarTextureBlizzard = "暴雪"
L.configFlightTimerBarTextureSmooth = "平滑"
L.configFlightTimerBarTextureSkill = "技能條"
L.configFlightTimerBarTextureFlat = "純色"
L.configFlightTimerBarBackground = "背景"
L.configFlightTimerBarBorder = "邊框"
L.configFlightTimerBarTimeText = "時間文字"
L.configFlightTimerBarNameText = "目的地文字"
L.configFlightTimerBarDefaults = "預設"
L.configFlightTimerBarDefaultsDesc = "將進度條恢復為初始外觀"
L.configFlightTimerBarResetPosition = "重設位置"
L.configFlightTimerBarResetPositionDesc = "將進度條移回原來的螢幕位置"
L.configFlightTimerBarMoveGroup = "移動"
L.configFlightTimerBarMove = "移動"
L.configFlightTimerBarMoveDesc = "解鎖進度條並顯示放置覆蓋層"
L.configFlightTimerBarMoveCancel = "還原"
L.configFlightTimerBarMoveCancelDesc = "復原開啟設定後的位置變更"
L.flightTimerMoveHint = "拖曳以移動"
L.flightTimeLabel = "飛行時間："
L.flightTimeUnknown = "未知"
L.configAutoCancelShapeShift = "自動取消變形形態"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
選擇飛行目的地時，自動取消德魯伊或薩滿的變形形態。

戰鬥中不會生效。]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"Questie 的「飛行管理員」圖示選項已啟用，可能會影響本插件的使用體驗。"
