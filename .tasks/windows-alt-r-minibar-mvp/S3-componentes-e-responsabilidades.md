# Secao 3 - Componentes e responsabilidades

## Objetivo

Separar responsabilidades entre backend Zig e frontend React.

## Tarefas

- [ ] Implementar `hotkey_manager` para `Alt+R` global no Windows
- [ ] Implementar `window_manager` para ciclo de vida de `MiniBar` e `ControlPanel`
- [ ] Implementar `orchestrator` como coordenador da maquina de estados
- [ ] Implementar `session_store` para historico local
- [ ] Implementar `insert_service` para colagem no campo ativo
- [ ] Implementar bridge TS com comandos: `toggle_recording`, `open_control_panel`, `list_sessions`, `set_mock_model`, `clear_sessions`
- [ ] Implementar `log_service` central com escrita estruturada e correlacao por `session_id` e `trace_id`
- [ ] Instrumentar todos os modulos para logar entrada, saida, latencia e erro

## Testes a Implementar

- [ ] Teste unitario para `session_store` (append, load, clear, rotacao)
- [ ] Teste unitario para `orchestrator` (sequencia de comandos e eventos)
- [ ] Teste de integracao backend/frontend para comandos da bridge
- [ ] Teste manual de modulo por modulo com logs de diagnostico
- [ ] Teste unitario do `log_service` (formato, niveis, rotacao, correlacao)
- [ ] Teste de integracao validando propagacao de `trace_id` entre backend e frontend

## Pronto Quando

- [ ] Cada modulo tem responsabilidade unica
- [ ] Comandos e eventos estao estaveis entre Zig e React
- [ ] Testes obrigatorios da secao executados
