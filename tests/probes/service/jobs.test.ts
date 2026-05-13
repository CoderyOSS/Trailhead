import { describe, it, expect } from "bun:test";
import { p } from "@codery/probes";
import { uniqueId } from "../helpers";
import { adapter } from "../adapter";

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function getStatus(job: unknown): string {
  if (isRecord(job) && typeof job["status"] === "string") {
    return job["status"];
  }
  return "";
}

async function createProjectJob(): Promise<string> {
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

  return adapter.createJob({
    project_id: projectId,
    description: "Job state machine test",
    workflow: "feature",
  });
}

describe("job state machine", () => {
  it("new job is queued", async () => {
    const jobId = await createProjectJob();
    const job = await adapter.getJob(jobId);
    expect(getStatus(job)).toBe("queued");
  });

  it("queued to scheduled", async () => {
    const jobId = await createProjectJob();

    const res = await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    expect(res.status).toBe(200);

    const job = await adapter.getJob(jobId);
    expect(getStatus(job)).toBe("scheduled");
  });

  it("scheduled to running", async () => {
    const jobId = await createProjectJob();

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(workerId, {
      job_id: jobId,
      hostname: "test-worker",
    });

    const job = await adapter.getJob(jobId);
    expect(getStatus(job)).toBe("running");
  });

  it("running to paused", async () => {
    const jobId = await createProjectJob();

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(workerId, {
      job_id: jobId,
      hostname: "pause-worker",
    });

    await adapter.pauseJob(jobId);

    const job = await adapter.getJob(jobId);
    expect(getStatus(job)).toBe("paused");
  });

  it("paused to running", async () => {
    const jobId = await createProjectJob();

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(workerId, {
      job_id: jobId,
      hostname: "resume-worker",
    });

    await adapter.pauseJob(jobId);
    await adapter.resumeJob(jobId);

    const job = await adapter.getJob(jobId);
    expect(getStatus(job)).toBe("running");
  });

  it("running to completed", async () => {
    const jobId = await createProjectJob();

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(workerId, {
      job_id: jobId,
      hostname: "complete-worker",
    });

    await adapter.workerComplete(workerId, {
      job_id: jobId,
      result: "success",
      output: "Job completed successfully",
    });

    const job = await adapter.getJob(jobId);
    expect(getStatus(job)).toBe("completed");
  });

  it("running to failed_retryable", async () => {
    const jobId = await createProjectJob();

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(workerId, {
      job_id: jobId,
      hostname: "fail-worker",
    });

    await adapter.workerFail(workerId, {
      job_id: jobId,
      error: "Transient failure",
      retryable: true,
    });

    const job = await adapter.getJob(jobId);
    expect(getStatus(job)).toBe("failed_retryable");
  });

  it("cannot transition completed to running", async () => {
    const jobId = await createProjectJob();

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(workerId, {
      job_id: jobId,
      hostname: "transition-worker",
    });

    await adapter.workerComplete(workerId, {
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
    const jobId = await createProjectJob();
    await adapter.cancelJob(jobId);
    const job = await adapter.getJob(jobId);
    expect(getStatus(job)).toBe("cancelled");
  });

  it("cancel from running state", async () => {
    const jobId = await createProjectJob();

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(workerId, {
      job_id: jobId,
      hostname: "cancel-worker",
    });

    await adapter.cancelJob(jobId);
    const job = await adapter.getJob(jobId);
    expect(getStatus(job)).toBe("cancelled");
  });

  it("cancel from paused state", async () => {
    const jobId = await createProjectJob();

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(workerId, {
      job_id: jobId,
      hostname: "cancel-paused-worker",
    });

    await adapter.pauseJob(jobId);
    await adapter.cancelJob(jobId);

    const job = await adapter.getJob(jobId);
    expect(getStatus(job)).toBe("cancelled");
  });
});
