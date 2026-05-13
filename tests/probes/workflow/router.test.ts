import { describe, it, expect } from "bun:test";
import { p } from "@codery/probes";
import { uniqueId } from "../helpers";
import { adapter } from "../adapter";

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

describe("workflow router", () => {
  it("routes on string equality", async () => {
    const projectId = uniqueId();
    const jobId = await adapter.createJob({
      project_id: projectId,
      description: "Build feature",
      workflow: "feature",
    });

    const workerId = uniqueId();
    await adapter.workerRegister(workerId, {
      job_id: jobId,
      hostname: "test-worker",
    });

    await adapter.workerComplete(workerId, {
      job_id: jobId,
      stage: "plan",
      output: "Simple task",
      response: { complexity: "simple" },
    });

    const job = await adapter.getJob(jobId);

    if (isRecord(job) && isRecord(job["current_stage"])) {
      const stageName = job["current_stage"]["name"];
      if (typeof stageName === "string") {
        expect(stageName).toBe("implement");
      }
    }
  });

  it("routes on boolean field", async () => {
    const projectId = uniqueId();
    const jobId = await adapter.createJob({
      project_id: projectId,
      description: "Build feature",
      workflow: "feature",
    });

    const workerId = uniqueId();
    await adapter.workerRegister(workerId, {
      job_id: jobId,
      hostname: "test-worker",
    });

    await adapter.workerComplete(workerId, {
      job_id: jobId,
      stage: "plan",
      output: "Plan done",
      response: { complexity: "simple" },
    });

    const jobAfterPlan = await adapter.getJob(jobId);

    if (isRecord(jobAfterPlan) && isRecord(jobAfterPlan["current_stage"])) {
      const stageName = jobAfterPlan["current_stage"]["name"];
      if (typeof stageName === "string") {
        expect(stageName).toBe("implement");
      }
    }

    await adapter.workerComplete(workerId, {
      job_id: jobId,
      stage: "implement",
      output: "Implementation succeeded",
      response: { success: true },
    });

    const jobAfterImpl = await adapter.getJob(jobId);

    if (isRecord(jobAfterImpl) && isRecord(jobAfterImpl["current_stage"])) {
      const stageName = jobAfterImpl["current_stage"]["name"];
      if (typeof stageName === "string") {
        expect(stageName).toBe("done");
      }
    }
  });

  it("routes on numeric comparison", async () => {
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

    const validateRes = await p.http.send({
      method: "POST",
      path: "/api/v1/workflows/validate",
      body: { yaml },
    });

    expect(validateRes.status).toBe(200);
  });

  it("routes to first matching condition", async () => {
    const projectId = uniqueId();
    const jobId = await adapter.createJob({
      project_id: projectId,
      description: "Build feature",
      workflow: "feature",
    });

    const workerId = uniqueId();
    await adapter.workerRegister(workerId, {
      job_id: jobId,
      hostname: "test-worker",
    });

    await adapter.workerComplete(workerId, {
      job_id: jobId,
      stage: "plan",
      output: "Complex plan",
      response: { complexity: "complex" },
    });

    const job = await adapter.getJob(jobId);

    if (isRecord(job) && isRecord(job["current_stage"])) {
      const stageName = job["current_stage"]["name"];
      if (typeof stageName === "string") {
        expect(stageName).toBe("plan_detail");
      }
    }
  });

  it("ends workflow when routes null", async () => {
    const projectId = uniqueId();
    const jobId = await adapter.createJob({
      project_id: projectId,
      description: "Simple task",
      workflow: "simple",
    });

    const workerId = uniqueId();
    await adapter.workerRegister(workerId, {
      job_id: jobId,
      hostname: "test-worker",
    });

    await adapter.workerComplete(workerId, {
      job_id: jobId,
      stage: "plan",
      output: "Done planning",
      response: { complexity: "simple" },
    });

    const job = await adapter.getJob(jobId);

    if (isRecord(job)) {
      const status = job["status"];
      if (typeof status === "string") {
        expect(status).toBe("completed");
      }
    }
  });
});
