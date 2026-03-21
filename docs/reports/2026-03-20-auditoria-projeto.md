# Auditoria do Projeto

Data: 2026-03-20

Objetivo desta auditoria:
- analisar a base atual em modo somente leitura
- identificar arquivos, caminhos, dependencias e codigo potencialmente nao usados
- levantar oportunidades de limpeza, simplificacao e otimizacao
- comparar a integracao atual com a abordagem do projeto `happystraw/zig-webview`
- definir uma lista de tarefas recomendadas para evolucao futura

## Contexto importante do projeto

Este projeto deve ser entendido como uma base inicial e exploratoria.

Ele ainda nao esta em fase de produto consolidado ou arquitetura fechada. O objetivo pratico atual e:
- testar caminhos diferentes para chegar a uma experiencia tipo mini-tauri em Zig
- validar ergonomia de build, bridge nativa, tipagem e frontend
- comparar abordagens para fazer a mesma coisa de modos diferentes
- usar outros projetos, como `happystraw/zig-webview`, como referencia tecnica e fonte de ideias

Isso muda a leitura desta auditoria:
- nem toda redundancia observada e necessariamente erro grave
- parte do codigo duplicado ou legado pode ter surgido como experimento valido
- a comparacao com `happystraw/zig-webview` nao deve ser lida como “trocar tudo”, mas como estudo de alternativas

Em resumo:
- a base atual serve tambem para aprendizado e investigacao arquitetural
- a auditoria abaixo aponta oportunidades de melhoria, mas considerando esse contexto exploratorio

## Escopo analisado

Foram analisados, entre outros:
- [build.zig](C:/Users/mathe/projetos/zig-teste/build.zig)
- [build.zig.zon](C:/Users/mathe/projetos/zig-teste/build.zig.zon)
- [build/bin_steps.zig](C:/Users/mathe/projetos/zig-teste/build/bin_steps.zig)
- [mise.toml](C:/Users/mathe/projetos/zig-teste/mise.toml)
- [package.json](C:/Users/mathe/projetos/zig-teste/package.json)
- [scripts/dev.mjs](C:/Users/mathe/projetos/zig-teste/scripts/dev.mjs)
- [scripts/build.mjs](C:/Users/mathe/projetos/zig-teste/scripts/build.mjs)
- [scripts/build-frontend.mjs](C:/Users/mathe/projetos/zig-teste/scripts/build-frontend.mjs)
- [src-zig/main.zig](C:/Users/mathe/projetos/zig-teste/src-zig/main.zig)
- [src-zig/app_url.zig](C:/Users/mathe/projetos/zig-teste/src-zig/app_url.zig)
- [src-zig/native/webview_bridge.cc](C:/Users/mathe/projetos/zig-teste/src-zig/native/webview_bridge.cc)
- [src-zig/tools/gen_ts_types.zig](C:/Users/mathe/projetos/zig-teste/src-zig/tools/gen_ts_types.zig)
- [src-zig/commands/registry.zig](C:/Users/mathe/projetos/zig-teste/src-zig/commands/registry.zig)
- [src-zig/root.zig](C:/Users/mathe/projetos/zig-teste/src-zig/root.zig)
- [src/routes/Commands.tsx](C:/Users/mathe/projetos/zig-teste/src/routes/Commands.tsx)
- [src/routes/Home.tsx](C:/Users/mathe/projetos/zig-teste/src/routes/Home.tsx)
- [src/lib/invoke.ts](C:/Users/mathe/projetos/zig-teste/src/lib/invoke.ts)
- [src/lib/commands.ts](C:/Users/mathe/projetos/zig-teste/src/lib/commands.ts)
- [tarefas.md](C:/Users/mathe/projetos/zig-teste/tarefas.md)
- [web/index.html](C:/Users/mathe/projetos/zig-teste/web/index.html)
- [.gitmodules](C:/Users/mathe/projetos/zig-teste/.gitmodules)
- [global.d.ts](C:/Users/mathe/projetos/zig-teste/global.d.ts)
- [vite.config.ts](C:/Users/mathe/projetos/zig-teste/vite.config.ts)
- [index.html](C:/Users/mathe/projetos/zig-teste/index.html)

Tambem foi feita comparacao com:
- [happystraw/zig-webview](https://github.com/happystraw/zig-webview)
- [webview/webview](https://github.com/webview/webview)

## Estrutura atual observada

O projeto hoje esta organizado assim, em termos práticos:
- frontend Vite/React/TypeScript na raiz, com `src/`, `index.html`, `vite.config.ts` e saida em `dist/`
- codigo Zig em `src-zig/`
- bridge nativa em C++ em `src-zig/native/webview_bridge.cc`
- comandos Zig registrados centralmente em `src-zig/commands/registry.zig`
- geracao de tipos e client TS feita por `src-zig/tools/gen_ts_types.zig`
- tarefas de desenvolvimento orquestradas por `mise.toml` e scripts Node em `scripts/`

Em paralelo, ainda existem restos de estrutura anterior:
- pasta `web/` ainda rastreada no Git
- pasta `frontend-legacy/` fora do fluxo atual
- arquivo `tarefas.md` descrevendo uma arquitetura antiga

## Achados detalhados

### 1. `web/` esta morto e ainda rastreado no Git

Arquivos identificados:
- [web/index.html](C:/Users/mathe/projetos/zig-teste/web/index.html)
- [web/invoke.js](C:/Users/mathe/projetos/zig-teste/web/invoke.js)
- [web/types/commands.generated.d.ts](C:/Users/mathe/projetos/zig-teste/web/types/commands.generated.d.ts)
- [web/types/global.generated.d.ts](C:/Users/mathe/projetos/zig-teste/web/types/global.generated.d.ts)

Observacao:
- a base real hoje usa `src/`, `index.html`, `vite.config.ts` e `dist/`
- nao foi encontrada referencia de uso desses arquivos legados no fluxo atual

Impacto:
- aumenta ruído em buscas com `rg`
- aumenta ruído no LSP
- dificulta manutencao
- pode confundir futuras geracoes de tipos

Conclusao:
- forte candidato a remocao do repositorio

### 2. `tarefas.md` esta desatualizado e com encoding quebrado

Arquivo:
- [tarefas.md](C:/Users/mathe/projetos/zig-teste/tarefas.md)

Problemas observados:
- ainda fala em `web/index.html`
- ainda fala em `src/commands/`
- descreve fases antigas do projeto
- apresenta texto com encoding quebrado

Impacto:
- documentacao incorreta
- pode induzir decisao tecnica errada
- gera confusao para futuras retomadas do projeto

Conclusao:
- deve ser reescrito, arquivado ou removido

### 3. `src-zig/root.zig` ainda e praticamente o skeleton do `zig init`

Arquivo:
- [src-zig/root.zig](C:/Users/mathe/projetos/zig-teste/src-zig/root.zig)

Itens identificados:
- `bufferedPrint`
- `add`
- teste `basic add functionality`

Nao foi encontrado uso real dessas funcoes no app.

Impacto:
- ruido no modulo raiz
- teste sem valor para o produto
- parece base inacabada ou parcialmente migrada

Conclusao:
- esse arquivo deve virar um root real do projeto Zig ou ser reduzido ao minimo util

### 4. `zigwin32` esta acoplado mais do que precisa

Arquivos relevantes:
- [build.zig](C:/Users/mathe/projetos/zig-teste/build.zig)
- [build/bin_steps.zig](C:/Users/mathe/projetos/zig-teste/build/bin_steps.zig)
- [src-zig/bin/get-mouse-position-2.zig](C:/Users/mathe/projetos/zig-teste/src-zig/bin/get-mouse-position-2.zig)

Achado:
- o modulo `win32` e adicionado ao exe principal no build
- [src-zig/main.zig](C:/Users/mathe/projetos/zig-teste/src-zig/main.zig) nao usa `win32`
- o uso real encontrado foi no binario auxiliar `get-mouse-position-2.zig`

Impacto:
- acoplamento desnecessario do app principal a dependencia Windows
- piora a clareza do build
- atrapalha o objetivo de base cross-platform limpa

Conclusao:
- `win32` deveria ficar restrito aos bins ou a modulos que realmente precisem dele

### 5. Existem binarios duplicados com a mesma finalidade

Arquivos:
- [src-zig/bin/get-mouse-position.zig](C:/Users/mathe/projetos/zig-teste/src-zig/bin/get-mouse-position.zig)
- [src-zig/bin/get-mouse-position-2.zig](C:/Users/mathe/projetos/zig-teste/src-zig/bin/get-mouse-position-2.zig)

Diferenca principal:
- um usa `extern "user32"`
- outro usa `zigwin32`

Impacto:
- duplicacao funcional
- manutencao desnecessaria
- ruído no menu de bins

Conclusao:
- deveria existir apenas um exemplo canonical

### 6. O projeto ainda nao esta empacotado no padrao Zig mais reutilizavel

Arquivos:
- [build.zig.zon](C:/Users/mathe/projetos/zig-teste/build.zig.zon)
- [.gitmodules](C:/Users/mathe/projetos/zig-teste/.gitmodules)

Achado:
- `zigwin32` esta em `build.zig.zon`
- `webview` esta vindo via submodule em `deps/webview`

Impacto:
- a reproducao do ambiente fica misturada entre `.zon` e submodule Git
- piora a manutencao e onboarding
- reduz a clareza do build para outros projetos

Conclusao:
- funcional, mas inferior a uma dependencia Zig declarada diretamente no `.zon`

### 7. A camada webview atual e funcional, mas muito manual

Arquivo:
- [src-zig/native/webview_bridge.cc](C:/Users/mathe/projetos/zig-teste/src-zig/native/webview_bridge.cc)

Achado:
- a integracao esta concentrada em um `bind("invoke")` manual
- o contrato JS/Zig esta sendo mantido por codigo customizado do projeto

Impacto:
- boa flexibilidade local
- baixa reutilizacao
- mais custo para evoluir bindings nativos
- maior dificuldade para testar separadamente a camada webview

Conclusao:
- a camada funciona, mas nao esta modularizada como uma biblioteca Zig de WebView

### 8. O gerador TS ainda produz pequenas sobras

Arquivo:
- [src/lib/commands.ts](C:/Users/mathe/projetos/zig-teste/src/lib/commands.ts)

Achado:
- o arquivo gerado importa tipos que nao usa

Impacto:
- baixo
- nao quebra o build
- mas indica que o gerador ainda pode ser refinado

Conclusao:
- melhoria pequena, porem valida

### 9. Scripts Node repetem utilidades

Arquivos:
- [scripts/dev.mjs](C:/Users/mathe/projetos/zig-teste/scripts/dev.mjs)
- [scripts/build.mjs](C:/Users/mathe/projetos/zig-teste/scripts/build.mjs)
- [scripts/build-frontend.mjs](C:/Users/mathe/projetos/zig-teste/scripts/build-frontend.mjs)

Duplicacoes observadas:
- `spawn`
- `waitForExit`
- `run`
- `ensureFrontendDeps`

Impacto:
- manutencao mais cara
- mais pontos para inconsistencias futuras

Conclusao:
- vale extrair utilitarios compartilhados

### 10. Texto da UI ja esta parcialmente defasado

Arquivo:
- [src/routes/Home.tsx](C:/Users/mathe/projetos/zig-teste/src/routes/Home.tsx)

Achado:
- menciona so `ping`, `sum` e `sub`
- hoje o projeto ja expoe tambem `echo`, `health`, `multiplication`, `soma`, `multiply`, `getLastName`, `getFullName`

Impacto:
- baixo, mas evidencia drift entre implementacao e interface

### 11. A politica de artefatos gerados no Git nao esta documentada

Arquivos:
- [src/types-generated/commands.generated.d.ts](C:/Users/mathe/projetos/zig-teste/src/types-generated/commands.generated.d.ts)
- [src/types-generated/global.generated.d.ts](C:/Users/mathe/projetos/zig-teste/src/types-generated/global.generated.d.ts)

Achado:
- os arquivos gerados estao versionados
- isso pode ser uma boa decisao de DX
- mas nao foi encontrada documentacao dizendo que isso e intencional

Impacto:
- discussoes repetidas em revisoes futuras
- risco de inconsistencias caso alguem edite o gerado manualmente

Conclusao:
- precisa de decisao explicita e documentada

## Analise do build atual

### Pontos positivos

- [build.zig](C:/Users/mathe/projetos/zig-teste/build.zig) ja suporta:
  - build do app principal
  - `gen-types`
  - bins auxiliares em `src-zig/bin`
  - teste do modulo e do exe
- [build/bin_steps.zig](C:/Users/mathe/projetos/zig-teste/build/bin_steps.zig) isolou bem a logica de bins
- [src-zig/app_url.zig](C:/Users/mathe/projetos/zig-teste/src-zig/app_url.zig) centralizou corretamente resolucao de URL/dist

### Pontos fracos

- linkagem de webview esta toda embutida em `linkMiniWebview`
- o app principal ainda carrega detalhes de plataforma que poderiam estar encapsulados
- o build ainda esta mais proximo de “app custom com C++ embutido” do que de “pacote Zig com binding limpo”

## Comparacao com `happystraw/zig-webview`

Repositorio analisado:
- [happystraw/zig-webview](https://github.com/happystraw/zig-webview)

Base citada do usuario:
- `build.zig.zon`
- `build.zig`
- `src/c.zig`
- `src/root.zig`

### O que esse projeto faz melhor

#### 1. Empacotamento Zig mais idiomatico

Pelo README e pelo `build.zig` mostrado:
- a dependencia `webview/webview` entra como dependencia Zig
- o projeto expoe um modulo `webview`
- o consumidor importa isso via `b.dependency("webview", ...)`

Isso e melhor do que:
- manter `webview` como submodule Git externo
- linkar tudo manualmente no build principal da aplicacao

#### 2. API Zig tipada para a WebView

O `root.zig` deles expoe uma API mais idiomatica:
- `Webview.create`
- `destroy`
- `run`
- `terminate`
- `setTitle`
- `setSize`
- `navigate`
- `setHtml`
- `addInitScript`
- `eval`
- `bind`
- `respond`

Isso e melhor do que depender diretamente de um bridge C++ estreito com um unico `invoke`.

#### 3. Melhor tratamento de cross-platform

No `build.zig` deles ha pontos relevantes:
- controle explicito de macOS SDK para cross-compilation
- selecao de versao de `WebKitGTK`
- tratamento mais explicito de Windows, macOS e Linux

Isso e superior ao estado atual da sua base, que hoje ainda tem uma integracao funcional, mas artesanal.

#### 4. Melhor reaproveitamento como biblioteca

A arquitetura deles e mais facil de:
- reutilizar em outros projetos
- testar
- publicar
- importar como dependencia

O seu projeto hoje esta mais focado em ser aplicacao final do que base reutilizavel.

### O que esse projeto nao resolve diretamente no seu caso

Ele nao substitui a sua camada especifica de:
- descoberta de comandos Zig
- geracao automatica de tipos TS
- client `commands.*`
- contrato de retorno direto do Zig para o frontend

Ou seja:
- ele melhora a camada de binding/build/webview
- ele nao resolve sozinho o seu mini-tauri tipado

### Recomendacao pratica sobre esse projeto

Nao recomendacao de momento:
- reescrever tudo em cima dele imediatamente

Recomendacao correta:
- usar esse repositorio como referencia de arquitetura para a camada webview
- absorver ideias de:
  - empacotamento Zig
  - encapsulamento de C API
  - build cross-platform mais explicito
- manter por enquanto a sua camada de comandos e geracao TS

### Conclusao comparativa

`happystraw/zig-webview` esta melhor organizado como binding/reuso.

Sua base atual esta mais avancada na parte de:
- comandos Zig tipados
- geracao TS
- fluxo app/frontend integrado

Logo:
- ele e melhor modelo de binding
- voce ja tem a camada de produto mais especifica
- o melhor caminho e absorver arquitetura, nao trocar tudo no escuro

## Lista de tarefas recomendadas

### T1. Limpeza de legado morto

Objetivo:
- remover da base tudo que nao participa mais do fluxo atual

Itens:
- remover `web/` do repositorio
- decidir destino de `frontend-legacy/`
- revisar ou remover [tarefas.md](C:/Users/mathe/projetos/zig-teste/tarefas.md)

Impacto esperado:
- menos ruido
- melhor LSP
- menos confusao arquitetural

### T2. Limpeza de skeleton e codigo irrelevante

Objetivo:
- transformar a base Zig em algo aderente ao produto real

Itens:
- revisar [src-zig/root.zig](C:/Users/mathe/projetos/zig-teste/src-zig/root.zig)
- remover `bufferedPrint`
- remover ou substituir `add`
- trocar teste placeholder por testes do runtime real

Impacto esperado:
- maior coerencia do projeto
- testes com valor real

### T3. Reducao de dependencias e acoplamentos opcionais

Objetivo:
- deixar o build do app principal mais limpo

Itens:
- tirar `win32` do exe principal se nao for usado
- escolher entre [get-mouse-position.zig](C:/Users/mathe/projetos/zig-teste/src-zig/bin/get-mouse-position.zig) e [get-mouse-position-2.zig](C:/Users/mathe/projetos/zig-teste/src-zig/bin/get-mouse-position-2.zig)
- manter apenas um exemplo canonical

Impacto esperado:
- menor acoplamento
- mais clareza no build

### T4. Consolidar politica de geracao

Objetivo:
- evitar ambiguidade sobre artefatos gerados

Itens:
- decidir oficialmente se `src/types-generated/` fica versionado
- documentar essa decisao
- impedir edicoes manuais em arquivos gerados

Impacto esperado:
- DX mais previsivel
- menos debate futuro

### T5. Refatorar scripts Node

Objetivo:
- reduzir repeticao nos scripts de automacao

Itens:
- extrair helpers compartilhados para um modulo em `scripts/`
- unificar `run`, `waitForExit`, `ensureFrontendDeps`

Impacto esperado:
- menor custo de manutencao
- menos risco de divergencia

### T6. Endurecer o build cross-platform

Objetivo:
- aproximar o build de uma base realmente portavel

Itens:
- revisar [build.zig](C:/Users/mathe/projetos/zig-teste/build.zig) com base em praticas como as do `zig-webview`
- separar melhor responsabilidades por plataforma
- preparar caminho real para macOS/Linux

Impacto esperado:
- base mais solida para multiplataforma

### T7. Reavaliar a camada webview

Objetivo:
- reduzir dependencia de bridge manual em C++

Itens:
- estudar wrapper Zig proprio para WebView
- avaliar absorcao parcial do modelo do `zig-webview`
- manter o contrato de comandos tipados como camada acima

Impacto esperado:
- arquitetura mais modular
- menor atrito para evolucoes nativas

## Priorizacao sugerida

### Prioridade alta

- T1. Limpeza de legado morto
- T2. Limpeza de skeleton e codigo irrelevante
- T3. Reducao de dependencias e acoplamentos opcionais

Motivo:
- sao mudancas de alto retorno e baixo risco

### Prioridade media

- T4. Consolidar politica de geracao
- T5. Refatorar scripts Node

Motivo:
- melhoram previsibilidade e manutencao

### Prioridade estrategica

- T6. Endurecer o build cross-platform
- T7. Reavaliar a camada webview

Motivo:
- tem maior impacto arquitetural
- exigem mais cuidado

## Conclusao final

A base esta funcional e ja tem um diferencial importante:
- comandos Zig tipados
- geracao TS
- retorno direto do Zig para o frontend

Os principais problemas encontrados nao sao de funcionalidade critica, mas de:
- ruído estrutural
- restos de migracao
- duplicacao
- acoplamentos desnecessarios
- falta de consolidacao do modelo cross-platform

A melhor evolucao imediata nao e trocar tudo.

A melhor evolucao imediata e:
- limpar legado
- reduzir ruído
- consolidar o build
- depois avaliar uma camada webview mais idiomatica em Zig

Sobre o `happystraw/zig-webview`:
- ele parece melhor organizado como binding e pacote Zig
- ele e uma boa referencia tecnica
- mas nao substitui sozinho a camada de comandos tipados que voce ja construiu

Tambem e importante registrar explicitamente:
- este projeto atual nao precisa ser lido como “produto pronto”
- ele e valido como laboratorio para experimentar meios diferentes de fazer a mesma integracao
- nesse contexto, usar `happystraw/zig-webview` como fonte de ideias faz sentido tecnico
- portanto, parte das sugestoes desta auditoria deve ser interpretada como direcao de consolidacao futura, e nao como correcao urgente de algo “errado”

Portanto, a direcao mais forte e:
- manter a arquitetura de comandos e geracao TS
- melhorar a base de webview/build inspirando-se no modelo dele
