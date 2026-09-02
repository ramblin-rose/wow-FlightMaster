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
L.configAutoCancelShapeShift = "Cancelar automáticamente el cambio de forma"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
Cancela automáticamente la forma de druida o chamán al seleccionar un destino de vuelo.

Este comportamiento no se aplica en combate.]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"La opción de icono «Maestro de vuelo» de Questie está activada, lo que puede restar calidad a tu experiencia con este addon."
