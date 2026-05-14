import { describe, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, seedProject, createJob, createWorker, isRecord } from "../helpers";

describe("database operations", () => {
  test("creates project via SQL seed and reads via HTTP and SQL", async () => {
    const projectId = await seedProject();

    const res = await p.http.send({
      method: "GET",
      path: "/api/v1/projects",
    });

    expect(res.status).toBe(200);
    if (Array.isArray(res.body)) {
      const found = res.body.some((r: unknown) =>
        isRecord(r) && r["id"] === projectId
      );
      expect(found).toBe(true);
    }

    const rows = await p.sql.read({ table: "projects", where: { id: projectId } });
    expect(rows.length).toBe(1);
    expect(rows[0]["id"]).toBe(projectId);
    expect(rows[0]["branch"]).toBe("main");
  });

  test("creates job via HTTP, verifies via HTTP and SQL", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "DB test job");

    const res = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}`,
    });

    expect(res.status).toBe(200);
    if (isRecord(res.body)) {
      expect(res.body["project_id"]).toBe(projectId);
      expect(res.body["description"]).toBe("DB test job");
      expect(res.body["status"]).toBe("queued");
    }

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["project_id"]).toBe(projectId);
    expect(rows[0]["status"]).toBe("queued");
  });

  test("stores checkpoint and verifies via SQL", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Checkpoint test");
    const workerId = await createWorker(jobId);

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/register`,
      body: { job_id: jobId },
    });

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/checkpoint`,
      body: {
        stage: "plan",
        response: { complexity: "simple" },
        session_path: "/tmp/session.json",
        git_sha: "abc123",
        token_usage: { prompt_tokens: 100, completion_tokens: 50 },
        files_changed: ["src/main.rs"],
        next_stage: "done",
      },
    });

    const jobRows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(jobRows[0]["current_stage"]).toBe("done");

    const cpRows = await p.sql.read({ table: "checkpoints", where: { job_id: jobId } });
    expect(cpRows.length).toBe(1);
    expect(cpRows[0]["stage"]).toBe("plan");
    expect(cpRows[0]["git_sha"]).toBe("abc123");
  });

  test("tracks worker heartbeat in DB", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Heartbeat test");
    const workerId = await createWorker(jobId);

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/register`,
      body: { job_id: jobId },
    });

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/heartbeat`,
      body: {
        status: "running",
        current_stage: "plan",
        token_usage: { prompt_tokens: 100, completion_tokens: 50 },
        files_changed: 0,
        tool_calls_made: 3,
        message: "working",
      },
    });

    const rows = await p.sql.read({ table: "workers", where: { id: workerId } });
    expect(rows[0]["heartbeat_at"]).not.toBeNull();
  });

  test("destroyed workers removed from DB", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Destroy test");
    const workerId = await createWorker(jobId);

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/register`,
      body: { job_id: jobId },
    });

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/complete`,
      body: { result: "done" },
    });

    const rows = await p.sql.read({ table: "workers", where: { id: workerId } });
    expect(rows.length).toBe(1);
    expect(rows[0]["status"]).toBe("stopped");
  });
});
