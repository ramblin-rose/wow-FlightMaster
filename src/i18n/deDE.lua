local addonName = select(1, ...)
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "deDE")
if not L then
	return
end
L.addOnName = "Flugmeister"
L.addOnSlashCmd = "fm"
L.on = "an"
L.off = "aus"
L.configEnableDesc = "Aktiviert / deaktiviert das Addon vorübergehend für diese Sitzung"
L.configShowUnknown = "Unbekannte anzeigen"
L.configShowUnknownDesc = "Unbekannte Flugmeister anzeigen / ausblenden"
L.configPOIName = "Flugpunkt-Symbolgröße"
L.configPOIDesc = "Wähle die Symbolgröße der Flugpunkte"
L.configFlightTimes = "Flugzeiten"
L.configShowFlightTimes = "Aktivieren"
L.configShowFlightTimesDesc = "Ungefähre Flugdauer im Tooltip des Ziel-Flugpunkts anzeigen und Zeiten während des Flugs aufzeichnen"
L.configShowFlightTimerBar = "Flug-Zeitleiste"
L.configShowFlightTimerBarDesc = "Fortschrittsbalken mit verbleibender Flugzeit während des Flugs anzeigen"
L.configFlightTimerBarAppearance = "Aussehen der Zeitleiste"
L.configFlightTimerBarTimeDisplay = "Balkentext"
L.configFlightTimerBarTimeDisplayDesc = "Restzeit ist die verbleibende Flugdauer. Ankunftszeit ist die ungefähre Serveruhrzeit der Landung."
L.configFlightTimerBarDisplayRemaining = "Restzeit"
L.configFlightTimerBarDisplayArrival = "Ankunftszeit"
L.flightTimerArrivesAt = "Ankunft um %s"
L.flightTimerArrivesAtEstimated = "Ankunft um ~%s"
L.configFlightTimerBarColorMode = "Balkenfarbe"
L.configFlightTimerBarColorModeDesc = "Einfarbig verwendet eine Füllfarbe. Verlauf blendet von Start zu Ende. Verbleibende Zeit wechselt von Grün zu Rot."
L.configFlightTimerBarModeSolid = "Einfarbig"
L.configFlightTimerBarModeGradient = "Verlauf"
L.configFlightTimerBarModeRemaining = "Nach Restzeit"
L.configFlightTimerBarColor = "Füllfarbe"
L.configFlightTimerBarGradientFrom = "Verlaufsstart"
L.configFlightTimerBarGradientTo = "Verlaufsende"
L.configFlightTimerBarTexture = "Balkentextur"
L.configFlightTimerBarTextureBlizzard = "Blizzard"
L.configFlightTimerBarTextureSmooth = "Glatt"
L.configFlightTimerBarTextureSkill = "Fertigkeitsbalken"
L.configFlightTimerBarTextureFlat = "Flach"
L.configFlightTimerBarBackground = "Hintergrund"
L.configFlightTimerBarBorder = "Rahmen"
L.configFlightTimerBarTimeText = "Zeittext"
L.configFlightTimerBarNameText = "Zieltext"
L.configFlightTimerBarDefaults = "Standard"
L.configFlightTimerBarDefaultsDesc = "Ursprüngliches Aussehen der Zeitleiste wiederherstellen"
L.configFlightTimerBarResetPosition = "Position zurücksetzen"
L.configFlightTimerBarResetPositionDesc = "Zeitleiste an die ursprüngliche Bildschirmposition zurücksetzen"
L.configFlightTimerBarMoveGroup = "Verschieben"
L.configFlightTimerBarMove = "Verschieben"
L.configFlightTimerBarMoveDesc = "Zeitleiste entsperren und das Platzierungs-Overlay anzeigen"
L.configFlightTimerBarMoveCancel = "Zurück"
L.configFlightTimerBarMoveCancelDesc = "Positionsänderungen seit dem Öffnen der Optionen rückgängig machen"
L.flightTimerMoveHint = "Zum Verschieben ziehen"
L.flightTimeLabel = "Flugzeit:"
L.flightTimeUnknown = "Unbekannt"
L.configAutoCancelShapeShift = "Gestaltwandel automatisch aufheben"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
Hebt die Gestaltwandelform von Druiden oder Schamanen automatisch auf, wenn ein Flugziel ausgewählt wird.

Dieses Verhalten greift nicht im Kampf.]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"Die Questie-Option „Flugmeister“-Symbol ist aktiviert, was deine Erfahrung mit diesem Addon beeinträchtigen kann."
