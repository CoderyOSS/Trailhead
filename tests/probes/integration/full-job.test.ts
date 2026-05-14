import { describe, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, seedProject, createJob, createWorker, isRecord } from "../helpers";

describe("full job lifecycle", () => {
  test("create project → create job → register worker → complete", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Full lifecycle test");

    const dbRows1 = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(dbRows1[0]["status"]).toBe("queued");

    const workerId = await createWorker(jobId);

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/register`,
      body: { job_id: jobId },
    });

    const dbRows2 = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(dbRows2[0]["status"]).toBe("running");

    const dbWorker = await p.sql.read({ table: "workers", where: { id: workerId } });
    expect(dbWorker[0]["status"]).toBe("running");

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/heartbeat`,
      body: {
        status: "running",
        current_stage: "plan",
        token_usage: { prompt_tokens: 100, completion_tokens: 50 },
        files_changed: 0,
        tool_calls_made: 1,
        message: "Planning",
      },
    });

    const workerAfterHb = await p.sql.read({ table: "workers", where: { id: workerId } });
    expect(workerAfterHb[0]["heartbeat_at"]).not.toBeNull();

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/checkpoint`,
      body: {
        stage: "plan",
        response: { complexity: "simple" },
        session_path: "/workspace/.codery/session.json",
        git_sha: "abc123",
        token_usage: { prompt_tokens: 100, completion_tokens: 50 },
        files_changed: [],
        next_stage: "done",
      },
    });

    const jobAfterCp = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(jobAfterCp[0]["current_stage"]).toBe("done");

    const checkpoints = await p.sql.read({ table: "checkpoints", where: { job_id: jobId } });
    expect(checkpoints.length).toBe(1);
    expect(checkpoints[0]["git_sha"]).toBe("abc123");

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/complete`,
      body: { result: "Job completed successfully" },
    });

    const finalJob = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(finalJob[0]["status"]).toBe("completed");
    expect(finalJob[0]["result"]).toBe("Job completed successfully");

    const finalWorker = await p.sql.read({ table: "workers", where: { id: workerId } });
    expect(finalWorker.length).toBe(1);
    expect(finalWorker[0]["status"]).toBe("stopped");
  });

  test("lists jobs and workers via HTTP matches DB", async () => {
    const jobsRes = await p.http.send({
      method: "GET",
      path: "/api/v1/jobs",
    });
    expect(jobsRes.status).toBe(200);

    const dbJobs = await p.sql.read({ table: "jobs" });
    if (Array.isArray(jobsRes.body)) {
      expect(jobsRes.body.length).toBe(dbJobs.length);
    }

    const workersRes = await p.http.send({
      method: "GET",
      path: "/api/v1/workers",
    });
    expect(workersRes.status).toBe(200);

    const dbWorkers = await p.sql.read({ table: "workers" });
    if (Array.isArray(workersRes.body)) {
      expect(workersRes.body.length).toBe(dbWorkers.length);
    }
  });

  test("validates workflow YAML", async () => {
    const yaml = `
name: test
stages:
  plan:
    skill: plan
    prompt: "Plan: {{input}}"
    tools: [bash]
    routes: null
`;
    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workflows/validate",
      body: { content: yaml },
    });
    expect(res.status).toBe(200);
  });

  test("rejects invalid workflow YAML", async () => {
    const yaml = "name: bad\nstages: {}\n";
    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workflows/validate",
      body: { content: yaml },
    });
    if (isRecord(res.body)) {
      expect(res.body["valid"]).toBe(false);
    }
  });
});
