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
L.configAutoCancelShapeShift = "Cancelar automaticamente a forma transformada"
-- stylua: ignore start
L.configAutoCancelShapeShiftDesc = [[
Cancela automaticamente a forma transformada de um druida ou xamã ao selecionar um destino de voo.

Este comportamento não se aplica em combate.]]
-- stylua: ignore end
L.compatQuestieFlightMaster =
	"A opção de ícone 'Mestre de Voo' do Questie está ativada, o que pode prejudicar sua experiência com este addon."
