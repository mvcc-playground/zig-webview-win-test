import { spawn } from "node:child_process";
import process from "node:process";

await run("zig", ["build", "gen-types"]);
await run("node", ["./scripts/build-frontend.mjs"]);
await run("zig", ["build"]);

async function run(command, args) {
  const child = spawn(command, args, {
    cwd: process.cwd(),
    stdio: "inherit",
  });

  const code = await new Promise((resolve, reject) => {
    child.on("error", reject);
    child.on("exit", (exitCode) => resolve(exitCode ?? 1));
  });

  if (code !== 0) {
    throw new Error(`${command} ${args.join(" ")} failed with exit code ${code}`);
  }
}
