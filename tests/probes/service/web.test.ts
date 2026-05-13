import { describe, it, expect, beforeAll } from "bun:test";
import { createTestProbes, uniqueId } from "../helpers";
import { adapter } from "../adapter";
import type { ProbesInstance } from "@codery/probes";

let p: ProbesInstance;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isRecordArray(value: unknown): value is Record<string, unknown>[] {
  return Array.isArray(value) && value.every(isRecord);
}

function getStatus(job: unknown): string {
  if (isRecord(job) && typeof job["status"] === "string") {
    return job["status"];
  }
  return "";
}

async function createProjectAndJob(p: ProbesInstance): Promise<string> {
  const projectId = uniqueId();
  await p.http.send({
    method: "POST",
    path: "/api/v1/projects",
    body: {
      id: projectId,
      name: `web-test-${projectId}`,
      repo_url: "https://github.com/example/web-test",
      workflow: "feature",
    },
  });

  return adapter.createJob(p, {
    project_id: projectId,
    description: "Dashboard test job",
    workflow: "feature",
  });
}

async function createRunningJob(p: ProbesInstance): Promise<{ jobId: string; workerId: string }> {
  const jobId = await createProjectAndJob(p);

  await p.http.send({
    method: "POST",
    path: `/api/v1/jobs/${jobId}/schedule`,
  });

  const workerId = uniqueId();
  await adapter.workerRegister(p, workerId, {
    job_id: jobId,
    hostname: "web-test-worker",
  });

  return { jobId, workerId };
}

describe("dashboard API", () => {
  beforeAll(async () => {
    p = await createTestProbes();
  });

  it("GET /api/v1/jobs returns list", async () => {
    const jobId = await createProjectAndJob(p);

    const jobs = await adapter.listJobs(p);

    expect(jobs.length).toBeGreaterThan(0);

    const found = jobs.some((j) => {
      if (isRecord(j) && typeof j["id"] === "string") {
        return j["id"] === jobId;
      }
      return false;
    });

    expect(found).toBe(true);
  });

  it("GET /api/v1/jobs/{id} returns detail", async () => {
    const projectId = uniqueId();
    await p.http.send({
      method: "POST",
      path: "/api/v1/projects",
      body: {
        id: projectId,
        name: "detail-project",
        repo_url: "https://github.com/example/detail",
        workflow: "feature",
      },
    });

    const jobId = await adapter.createJob(p, {
      project_id: projectId,
      description: "Detail retrieval test",
      workflow: "feature",
    });

    const job = await adapter.getJob(p, jobId);

    if (isRecord(job)) {
      expect(typeof job["id"]).toBe("string");
      expect(typeof job["status"]).toBe("string");
      expect(typeof job["project_id"]).toBe("string");
      expect(typeof job["description"]).toBe("string");
      expect(typeof job["workflow"]).toBe("string");
      expect(typeof job["created_at"]).toBe("string");
    }
  });

  it("GET /api/v1/workers returns list", async () => {
    const { workerId } = await createRunningJob(p);

    const workers = await adapter.listWorkers(p);

    expect(workers.length).toBeGreaterThan(0);

    const found = workers.some((w) => {
      if (isRecord(w) && typeof w["id"] === "string") {
        return w["id"] === workerId;
      }
      return false;
    });

    expect(found).toBe(true);
  });

  it("POST /api/v1/jobs/{id}/pause changes status", async () => {
    const { jobId } = await createRunningJob(p);

    await adapter.pauseJob(p, jobId);

    const job = await adapter.getJob(p, jobId);
    expect(getStatus(job)).toBe("paused");
  });

  it("POST /api/v1/jobs/{id}/resume changes status", async () => {
    const { jobId } = await createRunningJob(p);

    await adapter.pauseJob(p, jobId);
    await adapter.resumeJob(p, jobId);

    const job = await adapter.getJob(p, jobId);
    expect(getStatus(job)).toBe("running");
  });

  it("POST /api/v1/jobs/{id}/cancel changes status", async () => {
    const jobId = await createProjectAndJob(p);

    await adapter.cancelJob(p, jobId);

    const job = await adapter.getJob(p, jobId);
    expect(getStatus(job)).toBe("cancelled");
  });
});
