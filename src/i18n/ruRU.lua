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
L.configFlightTimes = "Время полёта"
L.configShowFlightTimes = "Включить"
L.configShowFlightTimesDesc = "Показывать примерную длительность полёта в подсказке пункта назначения и записывать время во время полёта"
L.configShowFlightTimerBar = "Индикатор времени полёта"
L.configShowFlightTimerBarDesc = "Показывать полосу прогресса с оставшимся временем во время полёта"
L.configFlightTimerBarAppearance = "Внешний вид индикатора"
L.configFlightTimerBarTimeDisplay = "Текст на полосе"
L.configFlightTimerBarTimeDisplayDesc = "Оставшееся время — длительность полёта. Время прибытия — примерное серверное время посадки."
L.configFlightTimerBarDisplayRemaining = "Оставшееся время"
L.configFlightTimerBarDisplayArrival = "Время прибытия"
L.flightTimerArrivesAt = "Прибытие в %s"
L.flightTimerArrivesAtEstimated = "Прибытие в ~%s"
L.configFlightTimerBarColorMode = "Цвет полосы"
L.configFlightTimerBarColorModeDesc = "Сплошной — один цвет. Градиент — от начала к концу. По оставшемуся времени — от зелёного к красному."
L.configFlightTimerBarModeSolid = "Сплошной"
L.configFlightTimerBarModeGradient = "Градиент"
L.configFlightTimerBarModeRemaining = "По оставшемуся времени"
L.configFlightTimerBarColor = "Цвет заполнения"
L.configFlightTimerBarGradientFrom = "Начало градиента"
L.configFlightTimerBarGradientTo = "Конец градиента"
L.configFlightTimerBarTexture = "Текстура полосы"
L.configFlightTimerBarTextureBlizzard = "Blizzard"
L.configFlightTimerBarTextureSmooth = "Гладкая"
L.configFlightTimerBarTextureSkill = "Полоса навыка"
L.configFlightTimerBarTextureFlat = "Плоская"
L.configFlightTimerBarBackground = "Фон"
L.configFlightTimerBarBorder = "Рамка"
L.configFlightTimerBarTimeText = "Текст времени"
L.configFlightTimerBarNameText = "Текст пункта назначения"
L.configFlightTimerBarDefaults = "По умолчанию"
L.configFlightTimerBarDefaultsDesc = "Восстановить исходный вид индикатора"
L.configFlightTimerBarResetPosition = "Сбросить положение"
L.configFlightTimerBarResetPositionDesc = "Вернуть индикатор на исходное место на экране"
L.configFlightTimerBarMoveGroup = "Перемещение"
L.configFlightTimerBarMove = "Переместить"
L.configFlightTimerBarMoveDesc = "Разблокировать индикатор и показать слой размещения"
L.configFlightTimerBarMoveCancel = "Вернуть"
L.configFlightTimerBarMoveCancelDesc = "Отменить изменения положения с момента открытия настроек"
L.flightTimerMoveHint = "Перетащите, чтобы переместить"
L.flightTimeLabel = "Время полёта:"
L.flightTimeUnknown = "Неизвестно"
L.configAutoCancelShapeShift = "Автоматически отменять смену облика"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
Автоматически отменяет облик друида или шамана при выборе пункта назначения полёта.

Это действие не применяется в бою.]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"В Questie включена опция значка «Распорядитель полетов», что может ухудшить работу этого аддона."
