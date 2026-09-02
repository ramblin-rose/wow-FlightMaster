local addonName = select(1, ...)
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "ruRU")
if not L then
	return
end
L.addOnName = "Распорядитель полетов"
L.addOnSlashCmd = "fm"
L.on = "вкл"
L.off = "выкл"
L.configEnableDesc = "Временно включает / отключает аддон на эту игровую сессию"
L.configShowUnknown = "Показывать неизвестных"
L.configShowUnknownDesc = "Показать / скрыть неизвестных распорядителей полетов"
L.configPOIName = "Размер значка точки полёта"
L.configPOIDesc = "Выберите размер значка точки полёта"
L.configAutoCancelShapeShift = "Автоматически отменять смену облика"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
Автоматически отменяет облик друида или шамана при выборе пункта назначения полёта.

Это действие не применяется в бою.]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"В Questie включена опция значка «Распорядитель полетов», что может ухудшить работу этого аддона."
