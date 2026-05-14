import { describe, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, seedProject, createJob, createWorker } from "../helpers";

describe("workflow router", () => {
  test("routes based on string equality in response", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Build feature", "feature");
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

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["current_stage"]).toBe("implement");

    const cpRows = await p.sql.read({ table: "checkpoints", where: { job_id: jobId } });
    expect(cpRows.length).toBe(1);
    expect(cpRows[0]["stage"]).toBe("plan");
  });

  test("routes to plan_detail on complex response", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Complex feature", "feature");
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
        response: { complexity: "complex" },
        session_path: "/tmp/session.json",
        git_sha: "abc123",
        token_usage: { prompt_tokens: 100, completion_tokens: 50 },
        files_changed: [],
        next_stage: "plan_detail",
      },
    });

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["current_stage"]).toBe("plan_detail");
  });

  test("completes workflow when routes is null", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Simple task", "simple");
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

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("completed");
    expect(rows[0]["result"]).toBe("done");

    const workerRows = await p.sql.read({ table: "workers", where: { id: workerId } });
    expect(workerRows.length).toBe(1);
    expect(workerRows[0]["status"]).toBe("stopped");
  });

  test("validates numeric routing workflow", async () => {
    const yaml = `
name: numeric-route
description: "Numeric routing"
stages:
  check:
    skill: plan
    prompt: "Check"
    tools: [bash]
    max_tokens: 8000
    routes:
      - when: 'response.count > 5'
        next: many
      - when: 'true'
        next: few
  many:
    skill: pause
    prompt: "Many"
    routes: null
  few:
    skill: pause
    prompt: "Few"
    routes: null
`;

    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workflows/validate",
      body: { content: yaml },
    });

    expect(res.status).toBe(200);
  });
});
