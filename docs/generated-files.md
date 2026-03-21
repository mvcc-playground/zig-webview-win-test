# Generated Files Policy

This repository keeps the generated TypeScript bridge files versioned on purpose.

Files:
- `example/desktop-example/src/types-generated/commands.generated.d.ts`
- `example/desktop-example/src/types-generated/global.generated.d.ts`
- `example/desktop-example/src/lib/invoke.ts`
- `example/desktop-example/src/lib/commands.ts`

Reason:
- keep the example app understandable without running codegen first
- make changes in the Zig command contract visible in diffs
- preserve DX for editors and the example app

Rule:
- do not edit these files manually
- regenerate them with `zig build gen-types`
