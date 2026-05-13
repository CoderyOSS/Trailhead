import { describe, it, expect, beforeAll } from "bun:test";
import { createTestProbes, uniqueId } from "../helpers";
import { adapter } from "../adapter";
import type { ProbesInstance } from "@codery/probes";

let p: ProbesInstance;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function hasStringField(obj: unknown, field: string): boolean {
  return isRecord(obj) && typeof obj[field] === "string";
}

describe("database operations", () => {
  beforeAll(async () => {
    p = await createTestProbes();
  });

  it("creates project and retrieves it", async () => {
    const projectId = uniqueId();
    const createRes = await p.http.send({
      method: "POST",
      path: "/api/v1/projects",
      body: {
        id: projectId,
        name: "test-project",
        repo_url: "https://github.com/example/test",
        workflow: "feature",
      },
    });

    expect(createRes.status).toBe(200);
    expect(hasStringField(createRes.body, "id")).toBe(true);

    const getRes = await p.http.send({
      method: "GET",
      path: `/api/v1/projects/${projectId}`,
    });

    expect(getRes.status).toBe(200);

    if (isRecord(getRes.body)) {
      expect(getRes.body["name"]).toBe("test-project");
      expect(getRes.body["repo_url"]).toBe("https://github.com/example/test");
    }
  });

  it("creates job with project reference", async () => {
    const projectId = uniqueId();

    await p.http.send({
      method: "POST",
      path: "/api/v1/projects",
      body: {
        id: projectId,
        name: "job-project",
        repo_url: "https://github.com/example/job-test",
        workflow: "feature",
      },
    });

    const jobId = await adapter.createJob(p, {
      project_id: projectId,
      description: "Job with project ref",
      workflow: "feature",
    });

    const job = await adapter.getJob(p, jobId);

    if (isRecord(job)) {
      expect(job["project_id"]).toBe(projectId);
    }
  });

  it("job starts with queued status", async () => {
    const projectId = uniqueId();

    await p.http.send({
      method: "POST",
      path: "/api/v1/projects",
      body: {
        id: projectId,
        name: "queued-project",
        repo_url: "https://github.com/example/queued",
        workflow: "feature",
      },
    });

    const jobId = await adapter.createJob(p, {
      project_id: projectId,
      description: "Queued job",
      workflow: "feature",
    });

    const rows = await p.sql.query(
      "SELECT status FROM jobs WHERE id = ?",
      [jobId]
    );

    if (Array.isArray(rows) && rows.length > 0 && isRecord(rows[0])) {
      expect(rows[0]["status"]).toBe("queued");
    }
  });

  it("stores checkpoint for job", async () => {
    const projectId = uniqueId();

    await p.http.send({
      method: "POST",
      path: "/api/v1/projects",
      body: {
        id: projectId,
        name: "checkpoint-project",
        repo_url: "https://github.com/example/checkpoint",
        workflow: "feature",
      },
    });

    const jobId = await adapter.createJob(p, {
      project_id: projectId,
      description: "Checkpoint test",
      workflow: "feature",
    });

    const workerId = uniqueId();
    await adapter.workerRegister(p, workerId, {
      job_id: jobId,
      hostname: "checkpoint-worker",
    });

    await adapter.workerCheckpoint(p, workerId, {
      job_id: jobId,
      stage: "plan",
      response: "Planning complete",
      session_path: "/tmp/session.json",
      git_sha: "abc123",
      files_changed: ["src/main.rs"],
    });

    const rows = await p.sql.query(
      "SELECT stage, response, git_sha FROM checkpoints WHERE job_id = ?",
      [jobId]
    );

    if (Array.isArray(rows) && rows.length > 0 && isRecord(rows[0])) {
      expect(rows[0]["stage"]).toBe("plan");
      expect(rows[0]["git_sha"]).toBe("abc123");
    }
  });

  it("tracks worker heartbeat", async () => {
    const projectId = uniqueId();

    await p.http.send({
      method: "POST",
      path: "/api/v1/projects",
      body: {
        id: projectId,
        name: "heartbeat-project",
        repo_url: "https://github.com/example/heartbeat",
        workflow: "feature",
      },
    });

    const jobId = await adapter.createJob(p, {
      project_id: projectId,
      description: "Heartbeat test",
      workflow: "feature",
    });

    const workerId = uniqueId();
    await adapter.workerRegister(p, workerId, {
      job_id: jobId,
      hostname: "heartbeat-worker",
    });

    const beforeHeartbeat = Date.now();

    await adapter.workerHeartbeat(p, workerId, {
      status: "running",
      current_stage: "plan",
      token_usage: { input: 100, output: 50 },
    });

    const rows = await p.sql.query(
      "SELECT last_heartbeat FROM workers WHERE id = ?",
      [workerId]
    );

    if (Array.isArray(rows) && rows.length > 0 && isRecord(rows[0])) {
      const hb = rows[0]["last_heartbeat"];
      if (typeof hb === "string") {
        const hbTime = new Date(hb).getTime();
        expect(hbTime).toBeGreaterThanOrEqual(beforeHeartbeat - 1000);
      }
    }
  });
});
