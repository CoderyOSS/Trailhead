import { describe, it, expect } from "bun:test";
import { p } from "@codery/probes";
import { uniqueId } from "../helpers";
import { adapter } from "../adapter";

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

async function createProjectAndJob(): Promise<string> {
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

  return adapter.createJob({
    project_id: projectId,
    description: "Dashboard test job",
    workflow: "feature",
  });
}

async function createRunningJob(): Promise<{ jobId: string; workerId: string }> {
  const jobId = await createProjectAndJob();

  await p.http.send({
    method: "POST",
    path: `/api/v1/jobs/${jobId}/schedule`,
  });

  const workerId = uniqueId();
  await adapter.workerRegister(workerId, {
    job_id: jobId,
    hostname: "web-test-worker",
  });

  return { jobId, workerId };
}

describe("dashboard API", () => {
  it("GET /api/v1/jobs returns list", async () => {
    const jobId = await createProjectAndJob();

    const jobs = await adapter.listJobs();

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

    const jobId = await adapter.createJob({
      project_id: projectId,
      description: "Detail retrieval test",
      workflow: "feature",
    });

    const job = await adapter.getJob(jobId);

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
    const { workerId } = await createRunningJob();

    const workers = await adapter.listWorkers();

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
    const { jobId } = await createRunningJob();

    await adapter.pauseJob(jobId);

    const job = await adapter.getJob(jobId);
    expect(getStatus(job)).toBe("paused");
  });

  it("POST /api/v1/jobs/{id}/resume changes status", async () => {
    const { jobId } = await createRunningJob();

    await adapter.pauseJob(jobId);
    await adapter.resumeJob(jobId);

    const job = await adapter.getJob(jobId);
    expect(getStatus(job)).toBe("running");
  });

  it("POST /api/v1/jobs/{id}/cancel changes status", async () => {
    const jobId = await createProjectAndJob();

    await adapter.cancelJob(jobId);

    const job = await adapter.getJob(jobId);
    expect(getStatus(job)).toBe("cancelled");
  });
});
