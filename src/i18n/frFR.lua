local addonName = select(1, ...)
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "frFR")
if not L then
	return
end
L.addOnName = "Maître de vol"
L.addOnSlashCmd = "fm"
L.on = "activé"
L.off = "désactivé"
L.configEnableDesc = "Active / désactive temporairement l'addon pour cette session"
L.configShowUnknown = "Afficher les inconnus"
L.configShowUnknownDesc = "Affiche / masque les maîtres de vol inconnus"
L.configPOIName = "Taille de l'icône de point de vol"
L.configPOIDesc = "Sélectionnez la taille de l'icône des points de vol"
L.configAutoCancelShapeShift = "Annuler automatiquement la métamorphose"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
Annule automatiquement la forme de métamorphose d'un druide ou d'un chaman lors de la sélection d'une destination de vol.

Ce comportement ne s'applique pas en combat.]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"L'option d'icône « Maître de vol » de Questie est activée, ce qui peut diminuer votre expérience avec cet addon."
