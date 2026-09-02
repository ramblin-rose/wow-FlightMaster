local addonName = select(1, ...)
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "esMX")
if not L then
	return
end
L.addOnName = "Maestro de vuelo"
L.addOnSlashCmd = "fm"
L.on = "activado"
L.off = "desactivado"
L.configEnableDesc = "Activa o desactiva temporalmente el addon para esta sesión"
L.configShowUnknown = "Mostrar desconocidos"
L.configShowUnknownDesc = "Muestra u oculta los maestros de vuelo desconocidos"
L.configPOIName = "Tamaño del ícono de punto de vuelo"
L.configPOIDesc = "Selecciona el tamaño del ícono de punto de vuelo"
L.configAutoCancelShapeShift = "Cancelar automáticamente el cambio de forma"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
Cancela automáticamente la forma de druida o chamán al seleccionar un destino de vuelo.

Este comportamiento no aplica si estás en combate.]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"La opción de ícono 'Maestro de vuelo' de Questie está habilitada, lo que puede restarle calidad a tu experiencia con este addon."
