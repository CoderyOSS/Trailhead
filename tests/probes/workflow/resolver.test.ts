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

describe("workflow resolver", () => {
  beforeAll(async () => {
    p = await createTestProbes();
  });

  it("resolves {{input}} variable", async () => {
    const projectId = uniqueId();
    const jobId = await adapter.createJob(p, {
      project_id: projectId,
      description: "Add a hello world function",
      workflow: "simple",
    });

    const job = await adapter.getJob(p, jobId);

    if (isRecord(job) && isRecord(job["current_stage"])) {
      const prompt = job["current_stage"]["prompt"];
      if (typeof prompt === "string") {
        expect(prompt).toContain("Add a hello world function");
      }
    }
  });

  it("resolves {{stages.*}} variables", async () => {
    const projectId = uniqueId();
    const jobId = await adapter.createJob(p, {
      project_id: projectId,
      description: "Build feature X",
      workflow: "feature",
    });

    const workerId = uniqueId();
    await adapter.workerRegister(p, workerId, {
      job_id: jobId,
      hostname: "test-worker",
    });

    await adapter.workerComplete(p, workerId, {
      job_id: jobId,
      stage: "plan",
      output: "Plan created: implement the thing",
      response: { complexity: "complex" },
    });

    const job = await adapter.getJob(p, jobId);

    if (isRecord(job) && isRecord(job["current_stage"])) {
      const prompt = job["current_stage"]["prompt"];
      if (typeof prompt === "string") {
        expect(prompt).toContain("Plan created: implement the thing");
      }
    }
  });

  it("resolves {{project.*}} variables", async () => {
    const projectId = uniqueId();

    await p.sql.put({
      table: "projects",
      force_schema: true,
      rows: [{ id: projectId, name: "test-project", repo: "org/test-repo", branch: "main" }],
    });

    const jobId = await adapter.createJob(p, {
      project_id: projectId,
      description: "Fix the bug",
      workflow: "simple",
    });

    const job = await adapter.getJob(p, jobId);

    if (isRecord(job) && isRecord(job["current_stage"])) {
      const prompt = job["current_stage"]["prompt"];
      if (typeof prompt === "string") {
        expect(prompt).toContain("test-project");
        expect(prompt).toContain("org/test-repo");
        expect(prompt).toContain("main");
      }
    }
  });
});
