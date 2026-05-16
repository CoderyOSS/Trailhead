import { describe, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, seedProject, createJob, isRecord } from "../helpers";

describe("full job lifecycle", () => {
  test("create project → create job → verify via HTTP and SQL", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Full lifecycle test");

    const dbRows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(dbRows[0]["status"]).toBe("queued");

    const httpRes = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}`,
    });
    expect(httpRes.status).toBe(200);
    if (isRecord(httpRes.body)) {
      expect(httpRes.body["status"]).toBe("queued");
      expect(httpRes.body["project_id"]).toBe(projectId);
    }
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
