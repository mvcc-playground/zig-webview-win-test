import { spawn } from "node:child_process";
import { access } from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const rootDir = process.cwd();
const frontendDir = path.join(rootDir, "frontend");
const devUrl = process.env.FRONTEND_URL ?? "http://127.0.0.1:5173";
const vitePort = new URL(devUrl).port || "5173";

await ensureFrontendDeps(frontendDir);

const vite = spawn("bun", ["run", "dev"], {
  cwd: frontendDir,
  stdio: "inherit",
});

let cleaned = false;
const cleanup = () => {
  if (cleaned) return;
  cleaned = true;
  if (!vite.killed) {
    vite.kill("SIGTERM");
  }
};

process.on("SIGINT", cleanup);
process.on("SIGTERM", cleanup);
process.on("exit", cleanup);

try {
  await waitForServer(devUrl, 20_000);

  const zig = spawn("zig", ["build", "run"], {
    cwd: rootDir,
    stdio: "inherit",
    env: {
      ...process.env,
      FRONTEND_URL: devUrl,
    },
  });

  const exitCode = await waitForExit(zig);
  cleanup();
  process.exit(exitCode);
} catch (error) {
  cleanup();
  console.error(String(error));
  process.exit(1);
}

async function ensureFrontendDeps(dir) {
  try {
    await access(path.join(dir, "node_modules", "vite"));
  } catch {
    await run("bun", ["install"], dir);
  }
}

async function waitForServer(url, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      const res = await fetch(url);
      if (res.ok || res.status < 500) return;
    } catch {}
    await delay(250);
  }
  throw new Error(`Vite dev server did not start at ${url} within ${timeoutMs}ms`);
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
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
