import { describe, it, expect, beforeAll } from "bun:test";
import { test, p, uniqueId } from "../helpers";

const SSH_BUILD =
  "export PATH=\"$HOME/.cargo/bin:$PATH\" && cd /home/gem/projects/CoderyTrailhead && cargo build -p agent-runner --release 2>&1";

const BINARY_PATH =
  "/home/gem/projects/CoderyTrailhead/target/release/agent-runner";

interface SshResult {
  exitCode: number;
  stdout: string;
  stderr: string;
}

function ssh(cmd: string): Promise<SshResult> {
  const proc = Bun.spawn(["ssh", "gem@apps", cmd], {
    stdout: "pipe",
    stderr: "pipe",
  });
  return new Promise((resolve) => {
    proc.exited.then((code) => {
      Promise.all([proc.stdout.text(), proc.stderr.text()]).then(([out, err]) => {
        resolve({ exitCode: code, stdout: out, stderr: err });
      });
    });
  });
}

function runAgent(args: string): Promise<SshResult> {
  return ssh(`export PATH="$HOME/.cargo/bin:$PATH" && ${BINARY_PATH} ${args}`);
}

function parseJson(text: string): unknown {
  return JSON.parse(text);
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function hasStringField(obj: unknown, field: string): boolean {
  return isObject(obj) && typeof obj[field] === "string";
}

function hasNumberField(obj: unknown, field: string): boolean {
  return isObject(obj) && typeof obj[field] === "number";
}

function hasArrayField(obj: unknown, field: string): boolean {
  return isObject(obj) && Array.isArray(obj[field]);
}

describe("agent-runner session", () => {
  beforeAll(async () => {
    const result = await ssh(SSH_BUILD);
    expect(result.exitCode).toBe(0);
  });

  test("session file created after run", async () => {
    const ws = `/tmp/ar-session-${uniqueId()}`;
    const prompt = "Use the bash tool to run: echo done";

    const result = await runAgent(
      `run --workspace ${ws} --prompt '${prompt}' --tools bash --max-tokens 1024 --max-tool-calls 5`
    );

    expect(result.exitCode).toBe(0);

    const session = await ssh(`cat ${ws}/session.json`);
    expect(session.exitCode).toBe(0);
    expect(session.stdout.length).toBeGreaterThan(0);
  });

  test("session file has required fields", async () => {
    const ws = `/tmp/ar-fields-${uniqueId()}`;
    const prompt = "Use the bash tool to run: echo done";

    await runAgent(
      `run --workspace ${ws} --prompt '${prompt}' --tools bash --max-tokens 1024 --max-tool-calls 5`
    );

    const raw = await ssh(`cat ${ws}/session.json`);
    expect(raw.exitCode).toBe(0);

    const session = parseJson(raw.stdout);

    expect(hasStringField(session, "id")).toBe(true);
    expect(hasArrayField(session, "messages")).toBe(true);
    expect(hasStringField(session, "created_at")).toBe(true);
  });

  test("session contains token usage", async () => {
    const ws = `/tmp/ar-tokens-${uniqueId()}`;
    const prompt = "Use the bash tool to run: echo done";

    await runAgent(
      `run --workspace ${ws} --prompt '${prompt}' --tools bash --max-tokens 1024 --max-tool-calls 5`
    );

    const raw = await ssh(`cat ${ws}/session.json`);
    expect(raw.exitCode).toBe(0);

    const session = parseJson(raw.stdout);

    expect(isObject(session)).toBe(true);
    if (isObject(session)) {
      expect(isObject(session["token_usage"])).toBe(true);
      if (isObject(session["token_usage"])) {
        expect(hasNumberField(session["token_usage"], "prompt_tokens")).toBe(true);
        expect(hasNumberField(session["token_usage"], "completion_tokens")).toBe(true);
        expect(hasNumberField(session["token_usage"], "total_tokens")).toBe(true);
      }
    }
  });

  test("session messages include user and assistant entries", async () => {
    const ws = `/tmp/ar-msgs-${uniqueId()}`;
    const prompt = "Use the bash tool to run: echo done";

    await runAgent(
      `run --workspace ${ws} --prompt '${prompt}' --tools bash --max-tokens 1024 --max-tool-calls 5`
    );

    const raw = await ssh(`cat ${ws}/session.json`);
    expect(raw.exitCode).toBe(0);

    const session = parseJson(raw.stdout);

    expect(isObject(session)).toBe(true);
    if (isObject(session) && Array.isArray(session["messages"])) {
      const messages = session["messages"] as unknown[];
      const roles = messages.map((m: unknown) => {
        if (isObject(m) && typeof m["role"] === "string") return m["role"];
        return "";
      });
      expect(roles).toContain("user");
      expect(roles).toContain("assistant");
    }
  });

  test("resume subcommand loads existing session", async () => {
    const ws = `/tmp/ar-resume-${uniqueId()}`;
    const prompt = "Use the bash tool to run: echo step1";

    await runAgent(
      `run --workspace ${ws} --prompt '${prompt}' --tools bash --max-tokens 1024 --max-tool-calls 5`
    );

    const sessionAfterFirst = await ssh(`cat ${ws}/session.json`);
    expect(sessionAfterFirst.exitCode).toBe(0);

    const resumePrompt = "Continue: use the bash tool to run: echo step2";
    const result = await runAgent(
      `resume --workspace ${ws} --prompt '${resumePrompt}' --max-tokens 1024 --max-tool-calls 5`
    );

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("step2");

    const sessionAfterResume = await ssh(`cat ${ws}/session.json`);
    const resumed = parseJson(sessionAfterResume.stdout);

    const firstSession = parseJson(sessionAfterFirst.stdout);
    if (isObject(firstSession) && Array.isArray(firstSession["messages"]) && isObject(resumed) && Array.isArray(resumed["messages"])) {
      expect((resumed["messages"] as unknown[]).length).toBeGreaterThan((firstSession["messages"] as unknown[]).length);
    }
  });

  test("resume fails when no session file exists", async () => {
    const ws = `/tmp/ar-noresume-${uniqueId()}`;
    const result = await runAgent(
      `resume --workspace ${ws} --prompt "continue" --max-tokens 100`
    );

    expect(result.exitCode).not.toBe(0);
    expect(result.stderr.toLowerCase()).toContain("session");
  });
});
