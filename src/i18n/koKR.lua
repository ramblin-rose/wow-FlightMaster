local addonName = select(1, ...)
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "koKR")
if not L then
	return
end
L.addOnName = "비행 조련사"
L.addOnSlashCmd = "fm"
L.on = "켬"
L.off = "끔"
L.configEnableDesc = "이번 접속 동안 애드온을 일시적으로 켜거나 끕니다"
L.configShowUnknown = "미확인 표시"
L.configShowUnknownDesc = "모르는 비행 조련사를 표시하거나 숨깁니다"
L.configPOIName = "비행 지점 아이콘 크기"
L.configPOIDesc = "비행 지점 아이콘 크기를 선택합니다"
L.configAutoCancelShapeShift = "변신 형상 자동 해제"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
비행 목적지를 선택할 때 드루이드 또는 주술사의 변신 형상을 자동으로 해제합니다.

전투 중에는 적용되지 않습니다.]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"Questie의 '비행 조련사' 아이콘 옵션이 켜져 있어 이 애드온 사용 경험이 저하될 수 있습니다."
