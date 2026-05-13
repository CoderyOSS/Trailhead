import { describe, it, expect } from "bun:test";
import { p } from "@codery/probes";
import { uniqueId } from "../helpers";

describe("full job lifecycle", () => {
  it("creates project then job then runs to completion", async () => {
    const projectId = uniqueId();
    const createProjectRes = await p.http.send({
      method: "POST",
      path: "/api/v1/projects",
      body: {
        name: projectId,
        repo_url: "https://github.com/test/integration",
        branch: "main",
      },
    });
    expect(createProjectRes.status).toBe(200);

    const createJobRes = await p.http.send({
      method: "POST",
      path: "/api/v1/jobs",
      body: {
        project_id: projectId,
        description: "Integration test job",
        workflow: "quick-fix",
      },
    });
    expect(createJobRes.status).toBe(200);

    const body = createJobRes.body;
    const isObj = (v: unknown): v is Record<string, unknown> =>
      typeof v === "object" && v !== null && !Array.isArray(v);
    const jobId = isObj(body) && typeof body["id"] === "string" ? body["id"] : "";

    const jobRes = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}`,
    });
    expect(jobRes.status).toBe(200);
    const job = jobRes.body;
    if (isObj(job)) {
      expect(job["status"]).toBe("queued");
    }

    await new Promise((resolve) => setTimeout(resolve, 2000));

    const jobAfterSchedule = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}`,
    });
    expect(jobAfterSchedule.status).toBe(200);

    const workerId = uniqueId();
    const registerRes = await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/register`,
      body: { job_id: jobId, status: "running" },
    });
    expect(registerRes.status).toBe(200);

    const heartbeatRes = await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/heartbeat`,
      body: {
        status: "running",
        current_stage: "plan",
        token_usage: { input_tokens: 100, output_tokens: 50 },
        files_changed: 0,
        tool_calls_made: 1,
        message: "Planning",
      },
    });
    expect(heartbeatRes.status).toBe(200);

    const checkpointRes = await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/checkpoint`,
      body: {
        stage: "plan",
        response: { complexity: "simple", plan: "do the thing" },
        session_path: "/workspace/.codery/session.json",
        git_sha: "abc123",
        token_usage: { input_tokens: 100, output_tokens: 50 },
        files_changed: [],
        next_stage: "done",
      },
    });
    expect(checkpointRes.status).toBe(200);

    const completeRes = await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/complete`,
      body: { result: "Job completed successfully" },
    });
    expect(completeRes.status).toBe(200);

    const finalJobRes = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}`,
    });
    expect(finalJobRes.status).toBe(200);
    const finalJob = finalJobRes.body;
    if (isObj(finalJob)) {
      expect(finalJob["status"]).toBe("completed");
    }

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows.length).toBe(1);
    if (isObj(rows[0])) {
      expect(rows[0]["status"]).toBe("completed");
    }
  });

  it("lists jobs and workers after activity", async () => {
    const jobsRes = await p.http.send({
      method: "GET",
      path: "/api/v1/jobs",
    });
    expect(jobsRes.status).toBe(200);

    const workersRes = await p.http.send({
      method: "GET",
      path: "/api/v1/workers",
    });
    expect(workersRes.status).toBe(200);
  });

  it("validates workflow YAML", async () => {
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
      body: { yaml },
    });
    expect(res.status).toBe(200);
  });

  it("rejects invalid workflow YAML", async () => {
    const yaml = "name: bad\nstages: {}\n";
    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workflows/validate",
      body: { yaml },
    });
    expect(res.status).toBe(400);
  });
});
