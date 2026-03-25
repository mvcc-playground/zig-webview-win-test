# Secao 5 - Criterios de aceite e execucao

## Objetivo

Concluir o MVP com validacao manual no Windows.

## Tarefas

- [ ] Validar inicializacao com `MiniBar` e `ControlPanel`
- [ ] Validar hotkey global `Alt+R` fora de foco do app
- [ ] Validar pipeline completo: toggle, mock, salvar, colar
- [ ] Validar persistencia apos reiniciar o app
- [ ] Validar limpeza de historico
- [ ] Executar checklist manual em apps alvo: bloco de notas, navegador e editor
- [ ] Registrar bugs restantes e classificar bloqueantes
- [ ] Medir latencia `stop -> colado` e comparar com alvo do MVP mock
- [ ] Consolidar relatorio final com logs e evidencias de testes

## Testes a Implementar

- [ ] Script/checklist de smoke test para fluxo principal
- [ ] Checklist manual com evidencias por ambiente (app alvo e resultado)
- [ ] Regressao basica apos correcoes de bug
- [ ] Teste de desempenho do mock: `Alt+R (stop) -> colado` com meta `< 400ms`
- [ ] Teste de taxa de sucesso de colagem por app alvo

## Criterios de Aceite do MVP

- [ ] `Alt+R` inicia e encerra em modo toggle sem foco no app
- [ ] Texto mock e colado no input ativo ao encerrar
- [ ] Sessao salva em persistencia local e visivel no historico
- [ ] Historico permanece apos reiniciar
- [ ] Limpeza de historico funciona
- [ ] Logs permitem identificar exatamente onde ocorreu qualquer erro do fluxo principal
- [ ] Latencia `stop -> colado` dentro da meta definida
- [ ] Sem bug bloqueante aberto
