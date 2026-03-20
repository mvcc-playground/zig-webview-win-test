## Windows Dev Shutdown Fix

Problema corrigido no commit que ajusta `scripts/dev.mjs`.

- Sintoma: ao fechar a janela do app no `X`, o processo Zig podia encerrar, mas o `bun`/`vite` continuava vivo e o terminal não terminava corretamente.
- Causa: no Windows, `vite.kill("SIGTERM")` não encerrava de forma confiável toda a arvore de processos iniciada por `bun run dev`.
- Correcao: o script de desenvolvimento passou a encerrar explicitamente a arvore de processos no Windows com `taskkill /PID <pid> /T /F`, alem de tratar melhor o desligamento coordenado entre o processo Zig e o servidor Vite.
- Resultado esperado: ao fechar a janela do app, o terminal encerra e o servidor de desenvolvimento nao fica órfão.
