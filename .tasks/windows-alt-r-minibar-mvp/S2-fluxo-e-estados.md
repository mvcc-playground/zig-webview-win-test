# Secao 2 - Fluxo de dados e estados

## Objetivo

Implementar a maquina de estados do toggle `Alt+R` com pipeline mock.

## Tarefas

- [ ] Criar maquina de estados: `idle`, `recording`, `processing`, `inserting`, `done`
- [ ] Implementar transicao `idle -> recording` no primeiro `Alt+R`
- [ ] Implementar transicao `recording -> processing` no segundo `Alt+R`
- [ ] Gerar texto mock com timestamp durante `processing`
- [ ] Executar insercao no input ativo durante `inserting`
- [ ] Emitir feedback e voltar para `idle` apos `done`
- [ ] Logar cada transicao de estado com `from_state`, `to_state`, motivo e timestamp
- [ ] Versionar payload de evento (`event_version`) para compatibilidade bridge

## Testes a Implementar

- [ ] Teste unitario de transicoes validas da maquina de estados
- [ ] Teste unitario de rejeicao de evento em estado bloqueante
- [ ] Teste de integracao do fluxo completo de toggle com mock
- [ ] Teste manual do fluxo ponta a ponta com UI visivel
- [ ] Teste de contrato de evento para `event_version` e campos obrigatorios
- [ ] Teste de log de transicao garantindo rastreio ponta a ponta por `session_id`

## Pronto Quando

- [ ] O toggle completo funciona de ponta a ponta com texto mock
- [ ] O estado mostrado na UI corresponde ao estado real do backend
- [ ] Testes obrigatorios da secao executados
