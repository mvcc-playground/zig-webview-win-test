# Direcao Atual do Projeto

Base exploratoria para experimentar uma experiencia mini-tauri em Zig sem perder a camada de produto ja validada:

- comandos Zig tipados;
- geracao de tipos TypeScript;
- client gerado consumido pelo frontend;
- infraestrutura webview modularizada por baixo.

## Estado atual

- frontend Vite/React/TypeScript na raiz;
- codigo Zig em `src-zig/`;
- comandos registrados em `src-zig/commands/registry.zig`;
- tipos e client gerados por `zig build gen-types`;
- bridge global interna exposta como `window.__invoke__`;
- frontend publico consumindo `src/lib/commands.ts`.

## Limites intencionais

- `happystraw/zig-webview` e referencia tecnica, nao dependencia direta neste momento;
- a camada de comandos tipados continua sendo o nucleo do produto;
- a migracao de `deps/webview` para dependencia Zig declarada fica para uma fase posterior.

## Operacao basica

- gerar artefatos: `zig build gen-types`
- subir em dev: `mise run dev`
- build completo: `mise run build`

## Documentacao complementar

- setup e validacao: `docs/notes/dev-setup.md`
- politica de artefatos gerados: `docs/notes/generated-artifacts.md`
