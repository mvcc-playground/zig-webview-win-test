# Desktop Example Layout Design

Date: 2026-03-20

## Goal

Move the example application to a self-contained project layout so the frontend and Zig code live together under the example root.

Target layout:

- `example/desktop-example/src`
- `example/desktop-example/src-zig`
- `example/desktop-example/build.zig`
- `example/desktop-example/build.zig.zon`
- `example/desktop-example/package.json`
- `example/desktop-example/vite.config.ts`
- `example/desktop-example/tsconfig.json`

## Decision

The reusable runtime remains in `core/mini`.

The example becomes an actual consumer project instead of a half-shared folder tree. The root `build.zig` remains as a thin monorepo orchestrator. The example gets its own `build.zig` so it can be entered directly and built from inside its folder.

## Consequences

- Paths in the build helper must stop assuming a single repository layout.
- Generated TypeScript files stay inside the example project under `src/`.
- The root workspace can keep `mise` and monorepo convenience commands without forcing the example to depend on ad hoc scripts.

## Implementation Outline

1. Rename `example/app` to `example/desktop-example`.
2. Move `example/src-zig` into `example/desktop-example/src-zig`.
3. Add a `build.zig` and `build.zig.zon` inside `example/desktop-example`.
4. Generalize `core/mini/build_helpers.zig` so both the monorepo root and the example build can reuse it.
5. Update root build, scripts, docs, and generated-file paths to the new layout.
6. Re-run `zig build gen-types`, `zig build`, `zig build test`, and frontend typecheck/build.