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
L.configFlightTimes = "飞行时间"
L.configShowFlightTimes = "启用"
L.configShowFlightTimesDesc = "在目的地图钉提示中显示大致飞行时长，并在飞行时记录时间"
L.configShowFlightTimerBar = "飞行时间进度条"
L.configShowFlightTimerBarDesc = "飞行时显示剩余时间进度条"
L.configFlightTimerBarAppearance = "进度条外观"
L.configFlightTimerBarTimeDisplay = "进度条文字"
L.configFlightTimerBarTimeDisplayDesc = "剩余时间为仍在空中的时长。抵达时间为大约落地时的服务器时钟。"
L.configFlightTimerBarDisplayRemaining = "剩余时间"
L.configFlightTimerBarDisplayArrival = "抵达时间"
L.flightTimerArrivesAt = "%s 抵达"
L.flightTimerArrivesAtEstimated = "约 %s 抵达"
L.configFlightTimerBarColorMode = "进度条颜色"
L.configFlightTimerBarColorModeDesc = "单色使用一种填充色。渐变从起点过渡到终点。按剩余时间从绿变红。"
L.configFlightTimerBarModeSolid = "单色"
L.configFlightTimerBarModeGradient = "渐变"
L.configFlightTimerBarModeRemaining = "按剩余时间"
L.configFlightTimerBarColor = "填充颜色"
L.configFlightTimerBarGradientFrom = "渐变起点"
L.configFlightTimerBarGradientTo = "渐变终点"
L.configFlightTimerBarTexture = "进度条材质"
L.configFlightTimerBarTextureBlizzard = "暴雪"
L.configFlightTimerBarTextureSmooth = "平滑"
L.configFlightTimerBarTextureSkill = "技能条"
L.configFlightTimerBarTextureFlat = "纯色"
L.configFlightTimerBarBackground = "背景"
L.configFlightTimerBarBorder = "边框"
L.configFlightTimerBarTimeText = "时间文字"
L.configFlightTimerBarNameText = "目的地文字"
L.configFlightTimerBarDefaults = "默认"
L.configFlightTimerBarDefaultsDesc = "将进度条恢复为初始外观"
L.configFlightTimerBarResetPosition = "重置位置"
L.configFlightTimerBarResetPositionDesc = "将进度条移回原来的屏幕位置"
L.configFlightTimerBarMoveGroup = "移动"
L.configFlightTimerBarMove = "移动"
L.configFlightTimerBarMoveDesc = "解锁进度条并显示放置覆盖层"
L.configFlightTimerBarMoveCancel = "还原"
L.configFlightTimerBarMoveCancelDesc = "撤销打开设置后的位置更改"
L.flightTimerMoveHint = "拖动以移动"
L.flightTimeLabel = "飞行时间："
L.flightTimeUnknown = "未知"
L.configAutoCancelShapeShift = "自动取消变形形态"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
选择飞行目的地时，自动取消德鲁伊或萨满祭司的变形形态。

战斗中不会生效。]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"Questie 的“飞行管理员”图标选项已启用，可能会影响本插件的使用体验。"
