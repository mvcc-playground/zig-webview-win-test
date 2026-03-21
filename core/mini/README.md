# mini core

Reusable Zig core extracted from the example app in this repository.

Current responsibilities:
- resolve frontend URL or dist entry
- host the native webview bridge
- dispatch typed Zig commands
- generate TypeScript bridge files for the consumer app
- expose a small build helper for the example app

Current public direction:
- frontend code should use the generated `commands.*` client
- `window.__mini_invoke__` is internal bridge infrastructure
- Zig commands remain the source of truth for TS generation

## Build helper shape

The root `build.zig` currently consumes the core through:
- `core/mini/build_helpers.zig`

The intended future consumer flow is:
1. install the package
2. create `src-zig/`
3. define a command module file with `registered_modules`
4. call the build helper with:
   - frontend dev URL / dist
   - command module path
   - generated TS output paths
   - app title

This repository still uses the example app as the first consumer, but the core
is now separated enough to keep pushing in that direction.
