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
L.configFlightTimes = "Tempi di volo"
L.configShowFlightTimes = "Attiva"
L.configShowFlightTimesDesc = "Mostra la durata approssimativa del volo nel tooltip di destinazione e registra i tempi in volo"
L.configShowFlightTimerBar = "Barra del tempo di volo"
L.configShowFlightTimerBarDesc = "Mostra una barra di avanzamento con il tempo restante durante il volo"
L.configFlightTimerBarAppearance = "Aspetto della barra"
L.configFlightTimerBarTimeDisplay = "Testo della barra"
L.configFlightTimerBarTimeDisplayDesc = "Tempo restante è la durata ancora in volo. Orario di arrivo è l'ora approssimativa del server all'atterraggio."
L.configFlightTimerBarDisplayRemaining = "Tempo restante"
L.configFlightTimerBarDisplayArrival = "Orario di arrivo"
L.flightTimerArrivesAt = "Arrivo alle %s"
L.flightTimerArrivesAtEstimated = "Arrivo alle ~%s"
L.configFlightTimerBarColorMode = "Colore della barra"
L.configFlightTimerBarColorModeDesc = "Tinta unita: un colore. Sfumatura: da inizio a fine. Tempo restante: da verde a rosso."
L.configFlightTimerBarModeSolid = "Tinta unita"
L.configFlightTimerBarModeGradient = "Sfumatura"
L.configFlightTimerBarModeRemaining = "In base al tempo restante"
L.configFlightTimerBarColor = "Colore di riempimento"
L.configFlightTimerBarGradientFrom = "Inizio sfumatura"
L.configFlightTimerBarGradientTo = "Fine sfumatura"
L.configFlightTimerBarTexture = "Texture della barra"
L.configFlightTimerBarTextureBlizzard = "Blizzard"
L.configFlightTimerBarTextureSmooth = "Liscia"
L.configFlightTimerBarTextureSkill = "Barra abilità"
L.configFlightTimerBarTextureFlat = "Piatta"
L.configFlightTimerBarBackground = "Sfondo"
L.configFlightTimerBarBorder = "Bordo"
L.configFlightTimerBarTimeText = "Testo del tempo"
L.configFlightTimerBarNameText = "Testo della destinazione"
L.configFlightTimerBarDefaults = "Predefiniti"
L.configFlightTimerBarDefaultsDesc = "Ripristina l'aspetto originale della barra"
L.configFlightTimerBarResetPosition = "Reimposta posizione"
L.configFlightTimerBarResetPositionDesc = "Riporta la barra alla posizione originale sullo schermo"
L.configFlightTimerBarMoveGroup = "Sposta"
L.configFlightTimerBarMove = "Sposta"
L.configFlightTimerBarMoveDesc = "Sblocca la barra e mostra l'overlay di posizionamento"
L.configFlightTimerBarMoveCancel = "Ripristina"
L.configFlightTimerBarMoveCancelDesc = "Annulla le modifiche di posizione dall'apertura delle opzioni"
L.flightTimerMoveHint = "Trascina per spostare"
L.flightTimeLabel = "Tempo di volo:"
L.flightTimeUnknown = "Sconosciuto"
L.configAutoCancelShapeShift = "Annulla automaticamente la mutaforma"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
Annulla automaticamente la mutaforma di un druido o di uno sciamano quando si seleziona una destinazione di volo.

Questo comportamento non si applica in combattimento.]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"L'opzione icona 'Maestro di volo' di Questie è attiva, il che potrebbe ridurre la qualità della tua esperienza con questo addon."
