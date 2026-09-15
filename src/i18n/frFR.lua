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
L.configFlightTimes = "Temps de vol"
L.configShowFlightTimes = "Activer"
L.configShowFlightTimesDesc = "Affiche la durée approximative du vol dans l'infobulle de destination et enregistre les temps en volant"
L.configShowFlightTimerBar = "Barre de temps de vol"
L.configShowFlightTimerBarDesc = "Affiche une barre de progression avec le temps restant pendant le vol"
L.configFlightTimerBarAppearance = "Apparence de la barre"
L.configFlightTimerBarTimeDisplay = "Texte de la barre"
L.configFlightTimerBarTimeDisplayDesc = "Temps restant : durée encore en vol. Heure d'arrivée : heure approximative du serveur à l'atterrissage."
L.configFlightTimerBarDisplayRemaining = "Temps restant"
L.configFlightTimerBarDisplayArrival = "Heure d'arrivée"
L.flightTimerArrivesAt = "Arrivée à %s"
L.flightTimerArrivesAtEstimated = "Arrivée à ~%s"
L.configFlightTimerBarColorMode = "Couleur de la barre"
L.configFlightTimerBarColorModeDesc = "Uni : une couleur. Dégradé : du début à la fin. Temps restant : du vert au rouge."
L.configFlightTimerBarModeSolid = "Uni"
L.configFlightTimerBarModeGradient = "Dégradé"
L.configFlightTimerBarModeRemaining = "Selon le temps restant"
L.configFlightTimerBarColor = "Couleur de remplissage"
L.configFlightTimerBarGradientFrom = "Début du dégradé"
L.configFlightTimerBarGradientTo = "Fin du dégradé"
L.configFlightTimerBarTexture = "Texture de la barre"
L.configFlightTimerBarTextureBlizzard = "Blizzard"
L.configFlightTimerBarTextureSmooth = "Lisse"
L.configFlightTimerBarTextureSkill = "Barre de compétence"
L.configFlightTimerBarTextureFlat = "Plate"
L.configFlightTimerBarBackground = "Arrière-plan"
L.configFlightTimerBarBorder = "Bordure"
L.configFlightTimerBarTimeText = "Texte du temps"
L.configFlightTimerBarNameText = "Texte de destination"
L.configFlightTimerBarDefaults = "Par défaut"
L.configFlightTimerBarDefaultsDesc = "Rétablir l'apparence d'origine de la barre"
L.configFlightTimerBarResetPosition = "Réinitialiser la position"
L.configFlightTimerBarResetPositionDesc = "Remettre la barre à sa position d'origine à l'écran"
L.configFlightTimerBarMoveGroup = "Déplacer"
L.configFlightTimerBarMove = "Déplacer"
L.configFlightTimerBarMoveDesc = "Déverrouiller la barre et afficher le calque de placement"
L.configFlightTimerBarMoveCancel = "Rétablir"
L.configFlightTimerBarMoveCancelDesc = "Annuler les changements de position depuis l'ouverture des options"
L.flightTimerMoveHint = "Glisser pour déplacer"
L.flightTimeLabel = "Temps de vol :"
L.flightTimeUnknown = "Inconnu"
L.configAutoCancelShapeShift = "Annuler automatiquement la métamorphose"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
Annule automatiquement la forme de métamorphose d'un druide ou d'un chaman lors de la sélection d'une destination de vol.

Ce comportement ne s'applique pas en combat.]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"L'option d'icône « Maître de vol » de Questie est activée, ce qui peut diminuer votre expérience avec cet addon."
