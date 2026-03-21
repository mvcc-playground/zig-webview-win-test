# Generated Files Policy

This repository keeps the generated TypeScript bridge files versioned on purpose.

Files:
- `example/app/src/types-generated/commands.generated.d.ts`
- `example/app/src/types-generated/global.generated.d.ts`
- `example/app/src/lib/invoke.ts`
- `example/app/src/lib/commands.ts`

Reason:
- keep the example app understandable without running codegen first
- make changes in the Zig command contract visible in diffs
- preserve DX for editors and the example app

Rule:
- do not edit these files manually
- regenerate them with `zig build gen-types`
