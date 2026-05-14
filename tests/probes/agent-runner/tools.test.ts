import { describe, it, expect, beforeAll } from "bun:test";
import { p, uniqueId, proofSection } from "../helpers";

proofSection("agent-runner tools");

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

function sshWriteFile(path: string, content: string): Promise<SshResult> {
  const escaped = content.replace(/'/g, "'\\''");
  return ssh(`mkdir -p $(dirname '${path}') && printf '%s' '${escaped}' > '${path}'`);
}

describe("agent-runner tools", () => {
  beforeAll(async () => {
    const result = await ssh(SSH_BUILD);
    expect(result.exitCode).toBe(0);
  });

  it("prints help with --help flag", async () => {
    const result = await runAgent("--help");
    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("agent-runner");
    expect(result.stdout).toContain("run");
    expect(result.stdout).toContain("resume");
  });

  it("rejects unknown subcommand", async () => {
    const result = await runAgent("nonexistent");
    expect(result.exitCode).not.toBe(0);
    expect(result.stderr).toContain("error");
  });

  it("bash tool: executes command and returns output", async () => {
    const ws = `/tmp/ar-test-${uniqueId()}`;
    const prompt = 'Use the bash tool to run: echo "hello world"';

    const result = await runAgent(
      `run --workspace ${ws} --prompt '${prompt}' --tools bash --max-tokens 1024 --max-tool-calls 5`
    );

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("hello world");
  });

  it("read tool: reads file content with line numbers", async () => {
    const ws = `/tmp/ar-read-${uniqueId()}`;
    await sshWriteFile(`${ws}/sample.txt`, "line one\nline two\nline three");

    const prompt = "Read the file sample.txt using the read tool.";

    const result = await runAgent(
      `run --workspace ${ws} --prompt '${prompt}' --tools read --max-tokens 1024 --max-tool-calls 5`
    );

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("line one");
    expect(result.stdout).toContain("line two");
  });

  it("write tool: creates file with content", async () => {
    const ws = `/tmp/ar-write-${uniqueId()}`;
    const prompt = 'Use the write tool to create output.txt with content "written by agent"';

    const result = await runAgent(
      `run --workspace ${ws} --prompt '${prompt}' --tools write --max-tokens 1024 --max-tool-calls 5`
    );

    expect(result.exitCode).toBe(0);

    const check = await ssh(`cat ${ws}/output.txt`);
    expect(check.stdout.trim()).toBe("written by agent");
  });

  it("edit tool: replaces unique string in file", async () => {
    const ws = `/tmp/ar-edit-${uniqueId()}`;
    await sshWriteFile(`${ws}/editme.txt`, "The quick brown fox jumps over the lazy dog");

    const prompt = "Use the edit tool to replace 'lazy' with 'sleepy' in editme.txt";

    const result = await runAgent(
      `run --workspace ${ws} --prompt '${prompt}' --tools edit --max-tokens 1024 --max-tool-calls 5`
    );

    expect(result.exitCode).toBe(0);

    const verify = await ssh(`cat ${ws}/editme.txt`);
    expect(verify.stdout).toContain("sleepy");
    expect(verify.stdout).not.toContain("lazy dog");
  });

  it("glob tool: finds files matching pattern", async () => {
    const ws = `/tmp/ar-glob-${uniqueId()}`;
    await sshWriteFile(`${ws}/src/main.rs`, "fn main() {}");
    await sshWriteFile(`${ws}/src/lib.rs`, "pub fn lib() {}");
    await sshWriteFile(`${ws}/README.md`, "# test");

    const prompt = "Use the glob tool to find all .rs files";

    const result = await runAgent(
      `run --workspace ${ws} --prompt '${prompt}' --tools glob --max-tokens 1024 --max-tool-calls 5`
    );

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("main.rs");
    expect(result.stdout).toContain("lib.rs");
  });

  it("grep tool: searches file contents", async () => {
    const ws = `/tmp/ar-grep-${uniqueId()}`;
    await sshWriteFile(`${ws}/code.rs`, 'fn hello() -> String {\n  "hello".to_string()\n}');
    await sshWriteFile(`${ws}/other.rs`, "fn world() -> i32 {\n  42\n}");

    const prompt = "Use the grep tool to search for 'hello' in the workspace";

    const result = await runAgent(
      `run --workspace ${ws} --prompt '${prompt}' --tools grep --max-tokens 1024 --max-tool-calls 5`
    );

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("code.rs");
    expect(result.stdout).toContain("hello");
  });

  it("rejects --tools with invalid tool name", async () => {
    const ws = `/tmp/ar-invalid-${uniqueId()}`;
    const result = await runAgent(
      `run --workspace ${ws} --prompt "test" --tools invalid_tool --max-tokens 100`
    );

    expect(result.exitCode).not.toBe(0);
    expect(result.stderr.toLowerCase()).toContain("invalid");
  });

  it("rejects run without required --workspace arg", async () => {
    const result = await runAgent('run --prompt "test" --tools bash');
    expect(result.exitCode).not.toBe(0);
  });

  it("rejects run without required --prompt arg", async () => {
    const result = await runAgent("run --workspace /tmp/test --tools bash");
    expect(result.exitCode).not.toBe(0);
  });
});
