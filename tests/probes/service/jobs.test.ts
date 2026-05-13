import { describe, it, expect, beforeAll } from "bun:test";
import { createTestProbes, uniqueId } from "../helpers";
import { adapter } from "../adapter";
import type { ProbesInstance } from "@codery/probes";

let p: ProbesInstance;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function getStatus(job: unknown): string {
  if (isRecord(job) && typeof job["status"] === "string") {
    return job["status"];
  }
  return "";
}

async function createProjectJob(p: ProbesInstance): Promise<string> {
  const projectId = uniqueId();
  await p.http.send({
    method: "POST",
    path: "/api/v1/projects",
    body: {
      id: projectId,
      name: `job-test-${projectId}`,
      repo_url: "https://github.com/example/job-test",
      workflow: "feature",
    },
  });

  return adapter.createJob(p, {
    project_id: projectId,
    description: "Job state machine test",
    workflow: "feature",
  });
}

describe("job state machine", () => {
  beforeAll(async () => {
    p = await createTestProbes();
  });

  it("new job is queued", async () => {
    const jobId = await createProjectJob(p);
    const job = await adapter.getJob(p, jobId);
    expect(getStatus(job)).toBe("queued");
  });

  it("queued to scheduled", async () => {
    const jobId = await createProjectJob(p);

    const res = await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    expect(res.status).toBe(200);

    const job = await adapter.getJob(p, jobId);
    expect(getStatus(job)).toBe("scheduled");
  });

  it("scheduled to running", async () => {
    const jobId = await createProjectJob(p);

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(p, workerId, {
      job_id: jobId,
      hostname: "test-worker",
    });

    const job = await adapter.getJob(p, jobId);
    expect(getStatus(job)).toBe("running");
  });

  it("running to paused", async () => {
    const jobId = await createProjectJob(p);

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(p, workerId, {
      job_id: jobId,
      hostname: "pause-worker",
    });

    await adapter.pauseJob(p, jobId);

    const job = await adapter.getJob(p, jobId);
    expect(getStatus(job)).toBe("paused");
  });

  it("paused to running", async () => {
    const jobId = await createProjectJob(p);

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(p, workerId, {
      job_id: jobId,
      hostname: "resume-worker",
    });

    await adapter.pauseJob(p, jobId);
    await adapter.resumeJob(p, jobId);

    const job = await adapter.getJob(p, jobId);
    expect(getStatus(job)).toBe("running");
  });

  it("running to completed", async () => {
    const jobId = await createProjectJob(p);

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(p, workerId, {
      job_id: jobId,
      hostname: "complete-worker",
    });

    await adapter.workerComplete(p, workerId, {
      job_id: jobId,
      result: "success",
      output: "Job completed successfully",
    });

    const job = await adapter.getJob(p, jobId);
    expect(getStatus(job)).toBe("completed");
  });

  it("running to failed_retryable", async () => {
    const jobId = await createProjectJob(p);

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(p, workerId, {
      job_id: jobId,
      hostname: "fail-worker",
    });

    await adapter.workerFail(p, workerId, {
      job_id: jobId,
      error: "Transient failure",
      retryable: true,
    });

    const job = await adapter.getJob(p, jobId);
    expect(getStatus(job)).toBe("failed_retryable");
  });

  it("cannot transition completed to running", async () => {
    const jobId = await createProjectJob(p);

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(p, workerId, {
      job_id: jobId,
      hostname: "transition-worker",
    });

    await adapter.workerComplete(p, workerId, {
      job_id: jobId,
      result: "success",
      output: "Done",
    });

    const res = await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/resume`,
    });

    expect(res.status).toBeGreaterThanOrEqual(400);
  });

  it("cancel from queued state", async () => {
    const jobId = await createProjectJob(p);
    await adapter.cancelJob(p, jobId);
    const job = await adapter.getJob(p, jobId);
    expect(getStatus(job)).toBe("cancelled");
  });

  it("cancel from running state", async () => {
    const jobId = await createProjectJob(p);

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(p, workerId, {
      job_id: jobId,
      hostname: "cancel-worker",
    });

    await adapter.cancelJob(p, jobId);
    const job = await adapter.getJob(p, jobId);
    expect(getStatus(job)).toBe("cancelled");
  });

  it("cancel from paused state", async () => {
    const jobId = await createProjectJob(p);

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(p, workerId, {
      job_id: jobId,
      hostname: "cancel-paused-worker",
    });

    await adapter.pauseJob(p, jobId);
    await adapter.cancelJob(p, jobId);

    const job = await adapter.getJob(p, jobId);
    expect(getStatus(job)).toBe("cancelled");
  });
});
