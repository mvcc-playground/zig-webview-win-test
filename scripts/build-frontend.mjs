import { spawn } from "node:child_process";
import { access } from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const rootDir = process.cwd();

await ensureFrontendDeps(rootDir);
await run("bun", ["run", "build"], rootDir);

async function ensureFrontendDeps(dir) {
  try {
    await access(path.join(dir, "node_modules", "vite"));
  } catch {
    await run("bun", ["install"], dir);
  }
}

function waitForExit(child) {
  return new Promise((resolve, reject) => {
    child.on("error", reject);
    child.on("exit", (code) => resolve(code ?? 1));
  });
}

async function run(command, args, cwd) {
  const child = spawn(command, args, {
    cwd,
    stdio: "inherit",
  });
  const code = await waitForExit(child);
  if (code !== 0) {
    throw new Error(`${command} ${args.join(" ")} failed with exit code ${code}`);
  }
}
