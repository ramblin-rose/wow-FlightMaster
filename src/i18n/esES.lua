local addonName = select(1, ...)
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "esES")
if not L then
	return
end
L.addOnName = "Maestro de vuelo"
L.addOnSlashCmd = "fm"
L.on = "activado"
L.off = "desactivado"
L.configEnableDesc = "Activa o desactiva temporalmente el addon durante esta sesión"
L.configShowUnknown = "Mostrar desconocidos"
L.configShowUnknownDesc = "Muestra u oculta los maestros de vuelo desconocidos"
L.configPOIName = "Tamaño del icono de punto de vuelo"
L.configPOIDesc = "Selecciona el tamaño del icono de punto de vuelo"
L.configFlightTimes = "Tiempos de vuelo"
L.configShowFlightTimes = "Activar"
L.configShowFlightTimesDesc = "Muestra la duración aproximada del vuelo en el tooltip del destino y registra los tiempos al volar"
L.configShowFlightTimerBar = "Barra de tiempo de vuelo"
L.configShowFlightTimerBarDesc = "Muestra una barra de progreso con el tiempo restante durante el vuelo"
L.configFlightTimerBarAppearance = "Apariencia de la barra"
L.configFlightTimerBarTimeDisplay = "Texto de la barra"
L.configFlightTimerBarTimeDisplayDesc = "Tiempo restante es la duración que queda en el aire. Hora de llegada es la hora aproximada del servidor al aterrizar."
L.configFlightTimerBarDisplayRemaining = "Tiempo restante"
L.configFlightTimerBarDisplayArrival = "Hora de llegada"
L.flightTimerArrivesAt = "Llegada a las %s"
L.flightTimerArrivesAtEstimated = "Llegada a las ~%s"
L.configFlightTimerBarColorMode = "Color de la barra"
L.configFlightTimerBarColorModeDesc = "Sólido usa un color. Degradado mezcla inicio y fin. Por tiempo restante pasa de verde a rojo."
L.configFlightTimerBarModeSolid = "Sólido"
L.configFlightTimerBarModeGradient = "Degradado"
L.configFlightTimerBarModeRemaining = "Por tiempo restante"
L.configFlightTimerBarColor = "Color de relleno"
L.configFlightTimerBarGradientFrom = "Inicio del degradado"
L.configFlightTimerBarGradientTo = "Fin del degradado"
L.configFlightTimerBarTexture = "Textura de la barra"
L.configFlightTimerBarTextureBlizzard = "Blizzard"
L.configFlightTimerBarTextureSmooth = "Suave"
L.configFlightTimerBarTextureSkill = "Barra de habilidad"
L.configFlightTimerBarTextureFlat = "Plana"
L.configFlightTimerBarBackground = "Fondo"
L.configFlightTimerBarBorder = "Borde"
L.configFlightTimerBarTimeText = "Texto de tiempo"
L.configFlightTimerBarNameText = "Texto de destino"
L.configFlightTimerBarDefaults = "Predeterminado"
L.configFlightTimerBarDefaultsDesc = "Restaurar la apariencia original de la barra"
L.configFlightTimerBarResetPosition = "Restablecer posición"
L.configFlightTimerBarResetPositionDesc = "Devolver la barra a su posición original en pantalla"
L.configFlightTimerBarMoveGroup = "Mover"
L.configFlightTimerBarMove = "Mover"
L.configFlightTimerBarMoveDesc = "Desbloquear la barra y mostrar el overlay de colocación"
L.configFlightTimerBarMoveCancel = "Revertir"
L.configFlightTimerBarMoveCancelDesc = "Deshacer los cambios de posición desde que se abrieron las opciones"
L.flightTimerMoveHint = "Arrastra para mover"
L.flightTimeLabel = "Tiempo de vuelo:"
L.flightTimeUnknown = "Desconocido"
L.configAutoCancelShapeShift = "Cancelar automáticamente el cambio de forma"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
Cancela automáticamente la forma de druida o chamán al seleccionar un destino de vuelo.

Este comportamiento no se aplica en combate.]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"La opción de icono «Maestro de vuelo» de Questie está activada, lo que puede restar calidad a tu experiencia con este addon."
