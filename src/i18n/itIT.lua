local addonName = select(1, ...)
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "itIT")
if not L then
	return
end
L.addOnName = "Maestro di volo"
L.addOnSlashCmd = "fm"
L.on = "attivo"
L.off = "disattivo"
L.configEnableDesc = "Attiva / disattiva temporaneamente l'addon per questa sessione"
L.configShowUnknown = "Mostra sconosciuti"
L.configShowUnknownDesc = "Mostra / nascondi i maestri di volo sconosciuti"
L.configPOIName = "Dimensione icona punto di volo"
L.configPOIDesc = "Seleziona la dimensione dell'icona del punto di volo"
L.configAutoCancelShapeShift = "Annulla automaticamente la mutaforma"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
Annulla automaticamente la mutaforma di un druido o di uno sciamano quando si seleziona una destinazione di volo.

Questo comportamento non si applica in combattimento.]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"L'opzione icona 'Maestro di volo' di Questie è attiva, il che potrebbe ridurre la qualità della tua esperienza con questo addon."
