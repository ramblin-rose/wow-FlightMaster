local addonName = select(1, ...)
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "ptBR")
if not L then
	return
end
L.addOnName = "Mestre de Voo"
L.addOnSlashCmd = "fm"
L.on = "ligado"
L.off = "desligado"
L.configEnableDesc = "Ativa / desativa temporariamente o addon nesta sessão"
L.configShowUnknown = "Mostrar desconhecidos"
L.configShowUnknownDesc = "Mostra / oculta mestres de voo desconhecidos"
L.configPOIName = "Tamanho do ícone de ponto de voo"
L.configPOIDesc = "Selecione o tamanho do ícone de ponto de voo"
L.configFlightTimes = "Tempos de voo"
L.configShowFlightTimes = "Ativar"
L.configShowFlightTimesDesc = "Mostra a duração aproximada do voo na dica do destino e registra os tempos ao voar"
L.configShowFlightTimerBar = "Barra de tempo de voo"
L.configShowFlightTimerBarDesc = "Mostra uma barra de progresso com o tempo restante durante o voo"
L.configFlightTimerBarAppearance = "Aparência da barra"
L.configFlightTimerBarTimeDisplay = "Texto da barra"
L.configFlightTimerBarTimeDisplayDesc = "Tempo restante é a duração ainda no ar. Horário de chegada é o horário aproximado do servidor ao pousar."
L.configFlightTimerBarDisplayRemaining = "Tempo restante"
L.configFlightTimerBarDisplayArrival = "Horário de chegada"
L.flightTimerArrivesAt = "Chega às %s"
L.flightTimerArrivesAtEstimated = "Chega às ~%s"
L.configFlightTimerBarColorMode = "Cor da barra"
L.configFlightTimerBarColorModeDesc = "Sólida usa uma cor. Degradê mistura início e fim. Por tempo restante vai de verde a vermelho."
L.configFlightTimerBarModeSolid = "Sólida"
L.configFlightTimerBarModeGradient = "Degradê"
L.configFlightTimerBarModeRemaining = "Por tempo restante"
L.configFlightTimerBarColor = "Cor de preenchimento"
L.configFlightTimerBarGradientFrom = "Início do degradê"
L.configFlightTimerBarGradientTo = "Fim do degradê"
L.configFlightTimerBarTexture = "Textura da barra"
L.configFlightTimerBarTextureBlizzard = "Blizzard"
L.configFlightTimerBarTextureSmooth = "Suave"
L.configFlightTimerBarTextureSkill = "Barra de perícia"
L.configFlightTimerBarTextureFlat = "Plana"
L.configFlightTimerBarBackground = "Fundo"
L.configFlightTimerBarBorder = "Borda"
L.configFlightTimerBarTimeText = "Texto do tempo"
L.configFlightTimerBarNameText = "Texto do destino"
L.configFlightTimerBarDefaults = "Padrão"
L.configFlightTimerBarDefaultsDesc = "Restaurar a aparência original da barra"
L.configFlightTimerBarResetPosition = "Redefinir posição"
L.configFlightTimerBarResetPositionDesc = "Devolver a barra à posição original na tela"
L.configFlightTimerBarMoveGroup = "Mover"
L.configFlightTimerBarMove = "Mover"
L.configFlightTimerBarMoveDesc = "Desbloquear a barra e mostrar o overlay de posicionamento"
L.configFlightTimerBarMoveCancel = "Reverter"
L.configFlightTimerBarMoveCancelDesc = "Desfazer alterações de posição desde que as opções foram abertas"
L.flightTimerMoveHint = "Arraste para mover"
L.flightTimeLabel = "Tempo de voo:"
L.flightTimeUnknown = "Desconhecido"
L.configAutoCancelShapeShift = "Cancelar automaticamente a forma transformada"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
Cancela automaticamente a forma transformada de um druida ou xamã ao selecionar um destino de voo.

Este comportamento não se aplica em combate.]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"A opção de ícone 'Mestre de Voo' do Questie está ativada, o que pode prejudicar sua experiência com este addon."
