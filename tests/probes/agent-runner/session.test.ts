import { describe, expect, beforeAll } from "bun:test";
import { test, p, uniqueId } from "../helpers";

const hasLLMKey = typeof process.env.DEEPSEEK_API_KEY === "string" && process.env.DEEPSEEK_API_KEY.length > 0;

const BUILD_CMD = [
  "/home/gem/.cargo/bin/cargo", "build",
  "-p", "agent-runner", "--release",
];

const BINARY_PATH =
  "/home/gem/projects/CoderyTrailhead/target/release/agent-runner";

interface RunResult {
  exitCode: number;
  stdout: string;
  stderr: string;
}

async function sh(cmd: string[], opts?: { env?: Record<string, string> }): Promise<RunResult> {
  const proc = Bun.spawn(cmd, {
    stdout: "pipe",
    stderr: "pipe",
    env: opts?.env,
  });
  const [out, err] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
  ]);
  const exitCode = await proc.exited;
  return { exitCode, stdout: out, stderr: err };
}

async function buildAgent(): Promise<RunResult> {
  return sh(BUILD_CMD, {
    env: { ...process.env, PATH: `/home/gem/.cargo/bin:${process.env.PATH ?? ""}` },
  });
}

async function runAgent(args: string[]): Promise<RunResult> {
  const env = {
    ...process.env,
    PATH: `/home/gem/.cargo/bin:${process.env.PATH ?? ""}`,
    LLM_API_KEY: process.env.DEEPSEEK_API_KEY ?? "",
    LLM_PROVIDER: "openai-compatible",
    LLM_BASE_URL: "https://api.deepseek.com/v1",
    LLM_MODEL: "deepseek-chat",
  };
  return sh([BINARY_PATH, ...args], { env });
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

describe("agent-runner session", () => {
  beforeAll(async () => {
    const result = await buildAgent();
    expect(result.exitCode).toBe(0);
  });

  test("resume fails when no session file exists", async () => {
    const ws = `/tmp/ar-noresume-${uniqueId()}`;
    const result = await runAgent([
      "resume", "--workspace", ws, "--prompt", "continue", "--max-tokens", "100",
    ]);
    expect(result.exitCode).not.toBe(0);
    expect(result.stderr.toLowerCase()).toContain("session");
  });
});

describe.skipIf(!hasLLMKey)("agent-runner session (requires LLM)", () => {
  beforeAll(async () => {
    const result = await buildAgent();
    expect(result.exitCode).toBe(0);
  });

  test("session file created after run", async () => {
    const ws = `/tmp/ar-session-${uniqueId()}`;
    const prompt = "Use the bash tool to run: echo done";
    const result = await runAgent([
      "run", "--workspace", ws, "--prompt", prompt,
      "--tools", "bash", "--max-tokens", "1024", "--max-tool-calls", "5",
    ]);
    expect(result.exitCode).toBe(0);
    const session = Bun.file(`${ws}/session.json`);
    const text = await session.text();
    expect(text.length).toBeGreaterThan(0);
  });

  test("session file has required fields", async () => {
    const ws = `/tmp/ar-fields-${uniqueId()}`;
    const prompt = "Use the bash tool to run: echo done";
    await runAgent([
      "run", "--workspace", ws, "--prompt", prompt,
      "--tools", "bash", "--max-tokens", "1024", "--max-tool-calls", "5",
    ]);
    const session = JSON.parse(await Bun.file(`${ws}/session.json`).text());
    expect(isObject(session)).toBe(true);
    expect(typeof session["id"]).toBe("string");
    expect(Array.isArray(session["messages"])).toBe(true);
    expect(typeof session["created_at"]).toBe("string");
  });

  test("session contains token usage", async () => {
    const ws = `/tmp/ar-tokens-${uniqueId()}`;
    const prompt = "Use the bash tool to run: echo done";
    await runAgent([
      "run", "--workspace", ws, "--prompt", prompt,
      "--tools", "bash", "--max-tokens", "1024", "--max-tool-calls", "5",
    ]);
    const session = JSON.parse(await Bun.file(`${ws}/session.json`).text());
    if (isObject(session) && isObject(session["token_usage"])) {
      expect(typeof session["token_usage"]["prompt_tokens"]).toBe("number");
      expect(typeof session["token_usage"]["completion_tokens"]).toBe("number");
      expect(typeof session["token_usage"]["total_tokens"]).toBe("number");
    }
  });

  test("resume subcommand loads existing session", async () => {
    const ws = `/tmp/ar-resume-${uniqueId()}`;
    const prompt = "Use the bash tool to run: echo step1";
    await runAgent([
      "run", "--workspace", ws, "--prompt", prompt,
      "--tools", "bash", "--max-tokens", "1024", "--max-tool-calls", "5",
    ]);
    const first = JSON.parse(await Bun.file(`${ws}/session.json`).text());
    const resumeResult = await runAgent([
      "resume", "--workspace", ws,
      "--prompt", "Continue: use the bash tool to run: echo step2",
      "--max-tokens", "1024", "--max-tool-calls", "5",
    ]);
    expect(resumeResult.exitCode).toBe(0);
    expect(resumeResult.stdout).toContain("step2");
    const resumed = JSON.parse(await Bun.file(`${ws}/session.json`).text());
    if (isObject(first) && isObject(resumed) && Array.isArray(first["messages"]) && Array.isArray(resumed["messages"])) {
      expect(resumed["messages"].length).toBeGreaterThan(first["messages"].length);
    }
  });
});
