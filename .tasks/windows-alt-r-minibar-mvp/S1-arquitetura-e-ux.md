# Secao 1 - Arquitetura e UX

## Objetivo

Definir e montar a base de duas janelas (`MiniBar` e `ControlPanel`) no Windows.

## Tarefas

- [ ] Criar arquitetura de runtime com duas janelas WebView
- [ ] Definir comportamento visual da `MiniBar` (compacta, translucida, sempre no topo)
- [ ] Definir abertura do `ControlPanel` via botao da `MiniBar`
- [ ] Expor estados visuais base: `Pronto`, `Gravando`, `Processando`, `Colado`
- [ ] Garantir backend como fonte unica de estado para as duas janelas
- [ ] Criar sistema de log base desde o inicio com `session_id`, `trace_id`, modulo, acao, erro e stack
- [ ] Definir destino de logs no Windows e rotacao de arquivos (ex.: `%AppData%/<app>/logs`)
- [ ] Padronizar niveis de log: `DEBUG`, `INFO`, `WARN`, `ERROR`

## Testes a Implementar

- [ ] Teste de inicializacao: cria `MiniBar` e `ControlPanel` sem falha
- [ ] Teste de contrato de estado: mesmo estado entregue para ambas as UIs
- [ ] Teste visual/manual: `MiniBar` aparece pequena, fixa e transludida
- [ ] Teste de log de bootstrap: inicializacao gera eventos de log com contexto completo

## Pronto Quando

- [ ] As duas janelas existem e podem ser abertas de forma previsivel
- [ ] A `MiniBar` tem visual de barrinha fixa e pequena
- [ ] Logs de inicializacao permitem identificar exatamente modulo e ponto de falha
- [ ] Testes obrigatorios da secao executados
