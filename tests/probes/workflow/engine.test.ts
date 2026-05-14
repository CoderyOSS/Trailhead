import { describe, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, seedProject, createJob, createWorker } from "../helpers";

describe("workflow engine", () => {
  test("new job is queued in DB", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Start at first stage");

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("queued");
    expect(rows[0]["project_id"]).toBe(projectId);
  });

  test("checkpoint advances to next stage", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Advance stages", "feature");
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
        files_changed: [],
        next_stage: "implement",
      },
    });

    const jobRows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(jobRows[0]["current_stage"]).toBe("implement");

    const cpRows = await p.sql.read({ table: "checkpoints", where: { job_id: jobId } });
    expect(cpRows.length).toBe(1);
    expect(cpRows[0]["stage"]).toBe("plan");
    expect(cpRows[0]["git_sha"]).toBe("abc123");
  });

  test("multi-stage progression through feature workflow", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Multi-stage", "feature");
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
        session_path: "/tmp/s1.json",
        git_sha: "aaa111",
        token_usage: { prompt_tokens: 100, completion_tokens: 50 },
        files_changed: [],
        next_stage: "implement",
      },
    });

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/checkpoint`,
      body: {
        stage: "implement",
        response: { success: true },
        session_path: "/tmp/s2.json",
        git_sha: "bbb222",
        token_usage: { prompt_tokens: 200, completion_tokens: 100 },
        files_changed: ["src/main.rs"],
        next_stage: "done",
      },
    });

    const jobRows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(jobRows[0]["current_stage"]).toBe("done");

    const cpRows = await p.sql.read({ table: "checkpoints", where: { job_id: jobId } });
    expect(cpRows.length).toBe(2);
  });

  test("complete finishes the job", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Complete workflow", "simple");
    const workerId = await createWorker(jobId);

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/register`,
      body: { job_id: jobId },
    });

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/complete`,
      body: { result: "all done" },
    });

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("completed");
    expect(rows[0]["result"]).toBe("all done");

    const workerRows = await p.sql.read({ table: "workers", where: { id: workerId } });
    expect(workerRows.length).toBe(1);
    expect(workerRows[0]["status"]).toBe("stopped");
  });
});
