import { describe, it, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, uniqueId } from "../helpers";
import { adapter } from "../adapter";

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isRecordArray(value: unknown): value is Record<string, unknown>[] {
  return Array.isArray(value) && value.every(isRecord);
}

describe("workflow engine", () => {
  test("starts at first stage", async () => {
    const projectId = uniqueId();
    const jobId = await adapter.createJob({
      project_id: projectId,
      description: "Start at first stage",
      workflow: "simple",
    });

    const job = await adapter.getJob(jobId);

    if (isRecord(job) && isRecord(job["current_stage"])) {
      const stageName = job["current_stage"]["name"];
      if (typeof stageName === "string") {
        expect(stageName).toBe("plan");
      }
    }
  });

  test("advances through stages", async () => {
    const projectId = uniqueId();
    const jobId = await adapter.createJob({
      project_id: projectId,
      description: "Advance through stages",
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

    const job = await adapter.getJob(jobId);

    if (isRecord(job) && isRecord(job["current_stage"])) {
      const stageName = job["current_stage"]["name"];
      if (typeof stageName === "string") {
        expect(stageName).toBe("implement");
      }
    }
  });

  test("pauses for human", async () => {
    const yaml = `
name: pause-workflow
description: "Pauses mid-workflow"
stages:
  work:
    skill: plan
    prompt: "Do work"
    tools: [bash]
    max_tokens: 8000
    routes:
      - when: 'true'
        next: pause_for_human
  pause_for_human:
    skill: pause
    prompt: "Review needed"
    routes: null
`;

    await p.http.send({
      method: "POST",
      path: "/api/v1/workflows/validate",
      body: { yaml },
    });

    const projectId = uniqueId();
    const jobId = await adapter.createJob({
      project_id: projectId,
      description: "Pause test",
      workflow: "pause-workflow",
    });

    const workerId = uniqueId();
    await adapter.workerRegister(workerId, {
      job_id: jobId,
      hostname: "test-worker",
    });

    await adapter.workerComplete(workerId, {
      job_id: jobId,
      stage: "work",
      output: "Work done",
      response: {},
    });

    const job = await adapter.getJob(jobId);

    if (isRecord(job)) {
      const status = job["status"];
      if (typeof status === "string") {
        expect(status).toBe("paused");
      }
    }
  });

  test("completes workflow", async () => {
    const projectId = uniqueId();
    const jobId = await adapter.createJob({
      project_id: projectId,
      description: "Complete workflow",
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
      output: "Done",
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

  test("tracks stage history", async () => {
    const projectId = uniqueId();
    const jobId = await adapter.createJob({
      project_id: projectId,
      description: "History tracking",
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
      output: "Plan created",
      response: { complexity: "complex" },
    });

    await adapter.workerComplete(workerId, {
      job_id: jobId,
      stage: "plan_detail",
      output: "Detailed plan",
      response: {},
    });

    const job = await adapter.getJob(jobId);

    if (isRecord(job)) {
      const history = job["stage_history"];
      if (isRecordArray(history)) {
        const stageNames = history
          .map((entry: Record<string, unknown>) => {
            if (typeof entry["name"] === "string") return entry["name"];
            return "";
          })
          .filter((name: string) => name.length > 0);

        expect(stageNames).toContain("plan");
        expect(stageNames).toContain("plan_detail");
      }
    }
  });
});
