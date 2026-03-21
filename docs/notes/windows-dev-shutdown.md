## Windows Dev Shutdown Fix

O fluxo de desenvolvimento em Windows agora e orquestrado por `zig build dev`.

- Sintoma tratado: ao fechar a janela do app no `X`, o processo do app podia encerrar, mas o `bun`/`vite` continuava vivo e o terminal nao terminava corretamente.
- Causa: no Windows, o servidor iniciado por `bun run dev` precisa de encerramento explicito da arvore de processos.
- Correcao: o step `zig build dev` passou a iniciar o Vite, aguardar a porta ficar pronta, executar o binario nativo com `FRONTEND_URL` e encerrar o processo do Vite com `taskkill /PID <pid> /T /F` no bloco de cleanup.
- Resultado esperado: ao fechar a janela do app, o terminal encerra e o servidor de desenvolvimento nao fica orfao.
