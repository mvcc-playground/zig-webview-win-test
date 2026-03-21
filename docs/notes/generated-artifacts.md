# Generated Artifacts Policy

The files in `src/types-generated/` and the generated runtime files in `src/lib/` are intentionally versioned.

This is a DX choice:

- the frontend can type-check without first running a generator on every clone;
- command surface changes are visible in code review;
- the generated client remains the public frontend entrypoint for Zig commands.

Rules:

- do not edit generated files manually;
- regenerate them with `zig build gen-types`;
- review changes in generated output together with the Zig command changes that produced them.
