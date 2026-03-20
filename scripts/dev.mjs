import { spawn } from "node:child_process";
import { access } from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const rootDir = process.cwd();
const devUrl = process.env.FRONTEND_URL ?? "http://127.0.0.1:5173";
const devPort = resolvePort(devUrl);

await ensureFrontendDeps(rootDir);
await run("zig", ["build", "gen-types"], rootDir);
await terminateExistingListener(devPort);

const vite = spawn("bun", ["run", "dev"], {
  cwd: rootDir,
  stdio: "inherit",
});

let cleaned = false;
let zig = null;

const cleanup = async () => {
  if (cleaned) return;
  cleaned = true;
  await Promise.allSettled([
    terminateProcessTree(zig),
    terminateProcessTree(vite),
  ]);
};

process.on("SIGINT", async () => {
  await cleanup();
  process.exit(130);
});

process.on("SIGTERM", async () => {
  await cleanup();
  process.exit(143);
});

try {
  await waitForServer(devUrl, 20_000);

  zig = spawn("zig", ["build", "run"], {
    cwd: rootDir,
    stdio: "inherit",
    env: {
      ...process.env,
      FRONTEND_URL: devUrl,
    },
  });

  vite.once("exit", async (code) => {
    if (!cleaned) {
      await terminateProcessTree(zig);
      process.exit(code ?? 1);
    }
  });

  const exitCode = await waitForExit(zig);
  await cleanup();
  process.exit(exitCode);
} catch (error) {
  await cleanup();
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
    if (await canReachServer(url)) return;
    await delay(250);
  }
  throw new Error(`Vite dev server did not start at ${url} within ${timeoutMs}ms`);
}

async function canReachServer(url) {
  try {
    const res = await fetch(url);
    return res.ok || res.status < 500;
  } catch {
    return false;
  }
}

function resolvePort(url) {
  const parsed = new URL(url);
  if (parsed.port) return Number(parsed.port);
  return parsed.protocol === "https:" ? 443 : 80;
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function waitForExit(child) {
  return new Promise((resolve, reject) => {
    if (!child) {
      resolve(0);
      return;
    }
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

async function terminateExistingListener(port) {
  const pid = await findListeningPid(port);
  if (!pid || pid === process.pid) {
    return;
  }

  console.log(`[dev] Terminating existing process on port ${port} (PID ${pid})`);
  await terminateProcessTree({ pid, exitCode: null, killed: false });
}

async function findListeningPid(port) {
  if (process.platform === "win32") {
    const stdout = await capture(
      "powershell",
      [
        "-NoProfile",
        "-Command",
        `(Get-NetTCPConnection -LocalPort ${port} -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique)`,
      ],
      rootDir,
    );
    const match = stdout.trim().match(/\d+/);
    return match ? Number(match[0]) : null;
  }

  const stdout = await capture("sh", ["-lc", `lsof -ti tcp:${port} -sTCP:LISTEN || true`], rootDir);
  const match = stdout.trim().match(/\d+/);
  return match ? Number(match[0]) : null;
}

async function capture(command, args, cwd) {
  const child = spawn(command, args, {
    cwd,
    stdio: ["ignore", "pipe", "pipe"],
  });

  let stdout = "";
  let stderr = "";
  child.stdout.on("data", (chunk) => {
    stdout += String(chunk);
  });
  child.stderr.on("data", (chunk) => {
    stderr += String(chunk);
  });

  const code = await waitForExit(child);
  if (code !== 0) {
    throw new Error(stderr || `${command} ${args.join(" ")} failed with exit code ${code}`);
  }
  return stdout;
}

async function terminateProcessTree(child) {
  if (!child || child.exitCode !== null || child.killed || child.pid == null) {
    return;
  }

  if (process.platform === "win32") {
    await run("taskkill", ["/PID", String(child.pid), "/T", "/F"], rootDir).catch(() => {});
    return;
  }

  child.kill("SIGTERM");
  const graceful = await Promise.race([
    waitForExit(child).then(() => true),
    delay(1_500).then(() => false),
  ]);

  if (!graceful && child.exitCode === null) {
    child.kill("SIGKILL");
    await waitForExit(child).catch(() => {});
  }
}
