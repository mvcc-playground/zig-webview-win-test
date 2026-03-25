# MiniBar White Background - Investigacao, Causa Raiz e Solucao

Data: 2026-03-25  
Escopo: App desktop Windows (Zig + webview + WebView2), UI da MiniBar

## Resumo do problema

Durante a evolucao da MiniBar (janela flutuante sem moldura, estilo Wispr-like), a interface apresentava:

- faixa/retangulo branco ao redor da barra
- cantos visivelmente retos no container externo
- inconsistencias visuais entre o que o CSS definia e o que era renderizado no host nativo

Comportamentos funcionais como `Alt+R` e `Open Settings` podiam funcionar, mas a apresentacao visual ainda quebrava a experiencia.

## O que inicialmente nao resolvia (e por que)

### 1. Ajustes apenas de CSS

Tentativas:

- `background: transparent` em `html`, `body`, `#root`
- remocao de margens
- ajuste de `padding`, `border-radius`, `box-shadow`

Por que nao foi suficiente:

- o branco residual nao vinha apenas da arvore React/CSS; parte vinha da composicao do host WebView2/Win32
- havia frame inicial com fundo padrao antes do CSS carregar

### 2. Ajustes apenas no tamanho/layout da barra

Tentativas:

- aumentar/reduzir dimensoes da janela
- ocupar 100% da area com o container da barra

Por que nao foi suficiente:

- melhorava proporcao, mas nao eliminava o artefato de fundo em todos os estados de renderizacao

### 3. Mudancas visuais agressivas sem isolamento de causa

Tentativas:

- escalas grandes e alteracoes de tipografia/espacamento no mesmo ciclo

Por que nao foi suficiente:

- introduziu regressao de UX (barra “estranha”/desproporcional) sem atacar de forma precisa a origem do branco

## Processo logico de diagnostico (identificar -> isolar -> validar)

### Fase A - Identificacao

- Confirmado por captura que havia retangulo branco externo ao pill
- Confirmado que nao era apenas “tema” da barra, pois persistia mesmo com estilos transparentes no CSS

### Fase B - Isolamento

Hipoteses consideradas:

1. branco do DOM/CSS (conteudo web)
2. branco do frame inicial do WebView2 (antes do CSS)
3. recorte/forma da janela nativa (Win32) sem clipping arredondado real

Validacoes feitas:

- preservar funcionalidade e mexer somente em camada visual (evitar confundir regressao funcional)
- comparar resultado de ajustes em CSS vs ajustes em Win32 (janela)

### Fase C - Pesquisa tecnica direcionada

Foram feitas buscas tecnicas sobre:

- `WebView2 DefaultBackgroundColor`
- `WEBVIEW2_DEFAULT_BACKGROUND_COLOR`
- `webview_get_native_handle` e handles nativos (window/controller)
- clipping de janela Win32 (`SetWindowRgn`)

Referencias usadas no processo:

- https://learn.microsoft.com/en-us/answers/questions/1221624/how-to-set-webview2-defaultbackgroundcolor-in-a-wi
- https://github.com/webview/webview/blob/master/core/include/webview/api.h
- https://github.com/webview/webview/blob/master/core/include/webview/types.h

Observacao: parte da pesquisa inicial com COM direto (`ICoreWebView2Controller2`) foi descartada no caminho final por incompatibilidade de link no toolchain mingw usado no projeto.

## Causa raiz consolidada

A artefatacao branca era uma composicao de 2 efeitos:

1. fundo padrao do host WebView2 no ciclo inicial (boot frame)
2. formato da janela nativa sem recorte real em todos os estados

Conclusao: somente CSS nao era suficiente. Era necessario combinar correcoes em HTML/CSS + host Win32/WebView2.

## Solucao implantada

### 1) Camada nativa (Win32/WebView2)

- MiniBar sem moldura via `WS_POPUP` e flags apropriadas
- recorte arredondado real da janela com `CreateRoundRectRgn` + `SetWindowRgn`
- posicionamento fixo no rodape central
- configuracao de tamanho por ambiente:
  - `MINIBAR_WIDTH`
  - `MINIBAR_HEIGHT`
- definicao de `WEBVIEW2_DEFAULT_BACKGROUND_COLOR=00FFFFFF` antes da criacao da webview

Arquivo principal:

- `src-zig/native/webview_bridge.cc`

### 2) Camada HTML/CSS (primeiro frame + render final)

- transparencia inline em `minibar.html` para `html/body/#root` (evita flash branco pre-CSS)
- barra ocupando 100% da area da janela para nao sobrar “faixa” interna
- remocao de borda clara no pill (reduz halo visual)

Arquivos:

- `minibar.html`
- `src/minibar/styles.css`
- `src/minibar/MiniBarApp.tsx` (mantendo estrutura UI prevista)

### 3) Build/link

- adicao de `gdi32` no linking do Windows para suportar APIs de regiao (`CreateRoundRectRgn`)

Arquivo:

- `build/webview_steps.zig`

## Problemas encontrados durante a implantacao

1. `CreateRoundRectRgn` sem `gdi32` -> erro de link  
Resolucao: incluir `gdi32` no build step do Windows.

2. Tentativa com `ICoreWebView2Controller2` (QueryInterface) no toolchain atual -> erro de link GUID  
Resolucao: retirar esse caminho nesta iteracao e manter abordagem estavel com env var + recorte nativo + transparencia inline.

3. `AccessDenied` no `zig build` ao substituir exe em uso  
Resolucao: finalizar processo `zig_teste.exe` antes do build.

## Validacao executada

- `bun run check` (TypeScript) -> OK
- `zig build` (build completo) -> OK

## Resultado final

- barra voltou a comportamento visual correto sem regressao funcional
- fluxo de abertura de configuracoes permaneceu funcional
- arquitetura ficou com ajuste facil de tamanho via env vars
- base pronta para proximo refinamento visual (blur/borda/acoes futuras) sem reacender o problema de fundo branco

## Proximos passos recomendados

1. consolidar tokens visuais da MiniBar (padding, radius, sombra) em variaveis centralizadas
2. criar checklist visual para Windows (densidade de escala 100/125/150%)
3. incluir teste manual padrao antes de commit para:
   - fundo externo da barra
   - cantos da janela
   - comportamento com `Alt+R` e `Open Settings`
