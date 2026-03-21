# Development Setup

## Native app prerequisites

- The native app build expects the `webview/webview` submodule under `deps/webview/`.
- If native app targets fail with a missing `deps/webview` message, run:

```powershell
git submodule update --init --recursive
```

## Frontend prerequisites

- Frontend checks and builds expect installed Bun dependencies.
- If `bun run check` fails because React, Vite or Wouter types are missing, run:

```powershell
bun install
```

## Validation sequence

```powershell
zig build gen-types
bun run check
zig build test
```
