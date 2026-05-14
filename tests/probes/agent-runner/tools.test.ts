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

describe("agent-runner tools", () => {
  beforeAll(async () => {
    const result = await buildAgent();
    expect(result.exitCode).toBe(0);
  });

  test("prints help with --help flag", async () => {
    const result = await runAgent(["--help"]);
    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("agent-runner");
    expect(result.stdout).toContain("run");
    expect(result.stdout).toContain("resume");
  });

  test("rejects unknown subcommand", async () => {
    const result = await runAgent(["nonexistent"]);
    expect(result.exitCode).not.toBe(0);
    expect(result.stderr).toContain("error");
  });

  test("rejects run without required --workspace arg", async () => {
    const result = await runAgent(["run", "--prompt", "test", "--tools", "bash"]);
    expect(result.exitCode).not.toBe(0);
  });

  test("rejects run without required --prompt arg", async () => {
    const result = await runAgent(["run", "--workspace", "/tmp/test", "--tools", "bash"]);
    expect(result.exitCode).not.toBe(0);
  });

  test("rejects --tools with invalid tool name", async () => {
    const ws = `/tmp/ar-invalid-${uniqueId()}`;
    const result = await runAgent([
      "run", "--workspace", ws, "--prompt", "test",
      "--tools", "invalid_tool", "--max-tokens", "100",
    ]);
    expect(result.exitCode).not.toBe(0);
    expect(result.stderr.toLowerCase()).toContain("invalid");
  });
});

describe.skipIf(!hasLLMKey)("agent-runner tools (requires LLM)", () => {
  beforeAll(async () => {
    const result = await buildAgent();
    expect(result.exitCode).toBe(0);
  });

  test("bash tool: executes command and returns output", async () => {
    const ws = `/tmp/ar-test-${uniqueId()}`;
    const prompt = 'Use the bash tool to run: echo "hello world"';
    const result = await runAgent([
      "run", "--workspace", ws, "--prompt", prompt,
      "--tools", "bash", "--max-tokens", "1024", "--max-tool-calls", "5",
    ]);
    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("hello world");
  });

  test("read tool: reads file content", async () => {
    const ws = `/tmp/ar-read-${uniqueId()}`;
    await Bun.spawn(["mkdir", "-p", ws]).exited;
    await Bun.spawn(["sh", "-c", `printf 'line one\nline two\nline three' > ${ws}/sample.txt`]).exited;
    const prompt = "Read the file sample.txt using the read tool.";
    const result = await runAgent([
      "run", "--workspace", ws, "--prompt", prompt,
      "--tools", "read", "--max-tokens", "1024", "--max-tool-calls", "5",
    ]);
    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("line one");
  });

  test("write tool: creates file with content", async () => {
    const ws = `/tmp/ar-write-${uniqueId()}`;
    const prompt = 'Use the write tool to create output.txt with content "written by agent"';
    const result = await runAgent([
      "run", "--workspace", ws, "--prompt", prompt,
      "--tools", "write", "--max-tokens", "1024", "--max-tool-calls", "5",
    ]);
    expect(result.exitCode).toBe(0);
    const file = Bun.file(`${ws}/output.txt`);
    expect(await file.text()).toBe("written by agent");
  });

  test("edit tool: replaces string in file", async () => {
    const ws = `/tmp/ar-edit-${uniqueId()}`;
    await Bun.spawn(["mkdir", "-p", ws]).exited;
    await Bun.spawn(["sh", "-c", `printf 'The quick brown fox jumps over the lazy dog' > ${ws}/editme.txt`]).exited;
    const prompt = "Use the edit tool to replace 'lazy' with 'sleepy' in editme.txt";
    const result = await runAgent([
      "run", "--workspace", ws, "--prompt", prompt,
      "--tools", "edit", "--max-tokens", "1024", "--max-tool-calls", "5",
    ]);
    expect(result.exitCode).toBe(0);
    const file = Bun.file(`${ws}/editme.txt`);
    const content = await file.text();
    expect(content).toContain("sleepy");
    expect(content).not.toContain("lazy dog");
  });

  test("glob tool: finds files matching pattern", async () => {
    const ws = `/tmp/ar-glob-${uniqueId()}`;
    await Bun.spawn(["mkdir", "-p", `${ws}/src`]).exited;
    await Promise.all([
      Bun.spawn(["sh", "-c", `printf 'fn main() {}' > ${ws}/src/main.rs`]).exited,
      Bun.spawn(["sh", "-c", `printf 'pub fn lib() {}' > ${ws}/src/lib.rs`]).exited,
      Bun.spawn(["sh", "-c", `printf '# test' > ${ws}/README.md`]).exited,
    ]);
    const prompt = "Use the glob tool to find all .rs files";
    const result = await runAgent([
      "run", "--workspace", ws, "--prompt", prompt,
      "--tools", "glob", "--max-tokens", "1024", "--max-tool-calls", "5",
    ]);
    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("main.rs");
    expect(result.stdout).toContain("lib.rs");
  });

  test("grep tool: searches file contents", async () => {
    const ws = `/tmp/ar-grep-${uniqueId()}`;
    await Bun.spawn(["mkdir", "-p", ws]).exited;
    await Promise.all([
      Bun.spawn(["sh", "-c", `printf 'fn hello() -> String {\n  "hello".to_string()\n}' > ${ws}/code.rs`]).exited,
      Bun.spawn(["sh", "-c", `printf 'fn world() -> i32 {\n  42\n}' > ${ws}/other.rs`]).exited,
    ]);
    const prompt = "Use the grep tool to search for 'hello' in the workspace";
    const result = await runAgent([
      "run", "--workspace", ws, "--prompt", prompt,
      "--tools", "grep", "--max-tokens", "1024", "--max-tool-calls", "5",
    ]);
    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("code.rs");
    expect(result.stdout).toContain("hello");
  });
});
