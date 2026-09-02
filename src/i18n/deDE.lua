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
L.configAutoCancelShapeShift = "Gestaltwandel automatisch aufheben"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
Hebt die Gestaltwandelform von Druiden oder Schamanen automatisch auf, wenn ein Flugziel ausgewählt wird.

Dieses Verhalten greift nicht im Kampf.]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"Die Questie-Option „Flugmeister“-Symbol ist aktiviert, was deine Erfahrung mit diesem Addon beeinträchtigen kann."
