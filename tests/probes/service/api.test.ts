import { describe, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, seedProject, setupRunningJob, isRecord } from "../helpers";

describe("worker HTTP API", () => {
  test("worker register sets job to running in DB", async () => {
    const { workerId, jobId } = await setupRunningJob();

    const jobRows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(jobRows[0]["status"]).toBe("running");

    const workerRows = await p.sql.read({ table: "workers", where: { id: workerId } });
    expect(workerRows[0]["status"]).toBe("running");
    expect(workerRows[0]["job_id"]).toBe(jobId);
  });

  test("worker heartbeat updates timestamp in DB", async () => {
    const { workerId } = await setupRunningJob();

    const res = await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/heartbeat`,
      body: {
        status: "running",
        current_stage: "plan",
        token_usage: { prompt_tokens: 500, completion_tokens: 200 },
        files_changed: 0,
        tool_calls_made: 5,
        message: "working",
      },
    });

    expect(res.status).toBe(200);

    const rows = await p.sql.read({ table: "workers", where: { id: workerId } });
    expect(rows[0]["heartbeat_at"]).not.toBeNull();
  });

  test("worker checkpoint writes to jobs and checkpoints tables", async () => {
    const { workerId, jobId } = await setupRunningJob();

    const res = await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/checkpoint`,
      body: {
        stage: "plan",
        response: { complexity: "simple" },
        session_path: "/tmp/session.json",
        git_sha: "def456",
        token_usage: { prompt_tokens: 100, completion_tokens: 50 },
        files_changed: ["src/lib.rs"],
        next_stage: "implement",
      },
    });

    expect(res.status).toBe(200);

    const jobRows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(jobRows[0]["current_stage"]).toBe("implement");

    const cpRows = await p.sql.read({ table: "checkpoints", where: { job_id: jobId } });
    expect(cpRows.length).toBe(1);
    expect(cpRows[0]["stage"]).toBe("plan");
    expect(cpRows[0]["git_sha"]).toBe("def456");
  });

  test("worker complete sets result and destroys worker", async () => {
    const { workerId, jobId } = await setupRunningJob();

    const res = await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/complete`,
      body: { result: "success" },
    });

    expect(res.status).toBe(200);

    const jobRows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(jobRows[0]["status"]).toBe("completed");
    expect(jobRows[0]["result"]).toBe("success");

    const workerRows = await p.sql.read({ table: "workers", where: { id: workerId } });
    expect(workerRows.length).toBe(1);
    expect(workerRows[0]["status"]).toBe("stopped");
  });

  test("worker fail sets error in DB", async () => {
    const { workerId, jobId } = await setupRunningJob();

    const res = await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/fail`,
      body: { error: "build failed" },
    });

    expect(res.status).toBe(200);

    const jobRows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(jobRows[0]["status"]).toBe("failed_retryable");
    expect(jobRows[0]["error"]).toBe("build failed");

    const workerRows = await p.sql.read({ table: "workers", where: { id: workerId } });
    expect(workerRows.length).toBe(1);
    expect(workerRows[0]["status"]).toBe("stopped");
  });

  test("get job config returns resolved stage info", async () => {
    const { jobId } = await setupRunningJob();

    const res = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}/config`,
    });

    expect(res.status).toBe(200);
    if (isRecord(res.body)) {
      expect(typeof res.body["stage"]).toBe("string");
      expect(typeof res.body["prompt"]).toBe("string");
      expect(Array.isArray(res.body["tools"])).toBe(true);
      expect(typeof res.body["max_tokens"]).toBe("number");
      expect(typeof res.body["model"]).toBe("string");
      expect(typeof res.body["provider"]).toBe("string");
      expect(typeof res.body["base_url"]).toBe("string");
      expect(typeof res.body["api_key"]).toBe("string");
    }
  });

  test("get skill content returns markdown", async () => {
    const { jobId } = await setupRunningJob();

    const res = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}/skill/plan`,
    });

    expect(res.status).toBe(200);
    if (isRecord(res.body)) {
      expect(typeof res.body["content"]).toBe("string");
      expect(res.body["content"].length).toBeGreaterThan(0);
    }
  });

  test("unknown worker returns 404", async () => {
    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workers/nonexistent-id/register",
      body: { job_id: "fake-job" },
    });

    expect(res.status).toBe(404);
  });
});
