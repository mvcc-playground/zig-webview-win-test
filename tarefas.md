# Tarefas - Mini Tauri em Zig

Como vamos trabalhar:
- Eu implemento **uma tarefa por vez**.
- Você testa e responde: **funcionou** ou **não funcionou**.
- Se precisar instalar algo, eu **te aviso antes** e explico.

## T1 - Janela + WebView local (primeira etapa)
- Objetivo: abrir uma janela desktop e renderizar `web/index.html`.
- Mínimo viável:
  - Janela abre.
  - HTML/CSS/JS simples renderiza.
  - Um botão JS executa no navegador embutido.
- Validação (você preenche): `pendente`

## T2 - Estrutura base mini-tauri
- Objetivo: organizar base para evoluir sem quebrar.
- Mínimo viável:
  - Criar `src/commands/`.
  - Criar bootstrap de bridge JS <-> Zig.
  - Carregamento de `web/index.html` centralizado.
- Validação (você preenche): `pendente`

## T3 - Comandos Zig tipados (lado nativo)
- Objetivo: padrão de comandos públicos Zig em `src/commands/`.
- Mínimo viável:
  - Registrar comando `ping`.
  - Entrada e saída tipadas no Zig.
  - Log de execução no nativo.
- Validação (você preenche): `pendente`

## T4 - Invoke JS -> Zig
- Objetivo: chamar comando Zig a partir do frontend.
- Mínimo viável:
  - `window.invoke("ping", payload)` funcionando.
  - Resposta retornando para o JS.
- Validação (você preenche): `pendente`

## T5 - Tipagem no frontend
- Objetivo: chamadas com contrato previsível no frontend.
- Mínimo viável:
  - Camada de tipos para o comando `ping`.
  - Uso no frontend sem chamada “solta”.
- Validação (você preenche): `pendente`

## T6 - Preparação para Vite (futuro próximo)
- Objetivo: manter HTML simples hoje e permitir Vite depois.
- Mínimo viável:
  - Modo dev apontando para URL (futuro Vite dev server).
  - Modo prod carregando arquivo local.
- Validação (você preenche): `pendente`

