# Future Integration Direction

Target developer experience for future projects:

1. add the Zig dependency
2. create `src-zig/commands/mod.zig`
3. register command modules in `registered_modules`
4. wire the core helper in `build.zig`
5. run:
   - `zig build gen-types`
   - `zig build run`

Expected generated frontend files in the consumer app:
- `types-generated/commands.generated.d.ts`
- `types-generated/global.generated.d.ts`
- `lib/invoke.ts`
- `lib/commands.ts`

Expected frontend usage:
- import and use `commands.*`
- do not call `window.__mini_invoke__` directly

Expected runtime behavior:
- Zig command success returns the direct value
- typed domain results stay in the command return type
- runtime failures reject and fall into `try/catch`
