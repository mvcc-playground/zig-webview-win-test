# Secao 4 - Erros, limites e seguranca

## Objetivo

Tratar erros do MVP e garantir comportamento previsivel.

## Tarefas

- [ ] Adicionar feedback para falha de registro da hotkey global
- [ ] Adicionar feedback para falha de colagem no input ativo
- [ ] Adicionar fallback para falha de persistencia (manter em memoria e avisar)
- [ ] Ignorar `Alt+R` durante estados bloqueantes com aviso curto
- [ ] Adicionar debounce no hotkey para evitar duplo toggle
- [ ] Expor acao de limpeza de historico local no painel
- [ ] Implementar recuperacao segura apos crash (reiniciar em `idle` com sessao anterior marcada como interrompida)
- [ ] Tratar conflito de hotkey (atalho em uso) com mensagem e fallback configuravel
- [ ] Garantir comportamento correto de foco e z-order da `MiniBar` sem roubo de foco indevido

## Testes a Implementar

- [ ] Teste unitario de debounce da hotkey
- [ ] Teste unitario de fallback de persistencia quando I/O falhar
- [ ] Teste de integracao para erro de insercao sem perder sessao
- [ ] Teste manual de UX de erro (mensagens claras em cada falha)
- [ ] Teste de recuperacao de crash durante `recording` e `processing`
- [ ] Teste manual de conflito de hotkey com outro aplicativo
- [ ] Teste manual de foco/z-order em setup com multiplos monitores
- [ ] Teste de log de erro com localizacao exata: modulo, funcao e etapa

## Pronto Quando

- [ ] Falhas criticas nao travam o app
- [ ] Usuario sempre recebe feedback claro de sucesso ou erro
- [ ] Testes obrigatorios da secao executados
