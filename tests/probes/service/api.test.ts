import { describe, it, expect } from "bun:test";
import { p } from "@codery/probes";
import { uniqueId, proofSection } from "../helpers";
import { adapter } from "../adapter";

proofSection("worker HTTP API");

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

async function createRunningJob(): Promise<{ jobId: string; workerId: string }> {
  const projectId = uniqueId();
  await p.http.send({
    method: "POST",
    path: "/api/v1/projects",
    body: {
      id: projectId,
      name: `api-test-${projectId}`,
      repo_url: "https://github.com/example/api-test",
      workflow: "feature",
    },
  });

  const jobId = await adapter.createJob({
    project_id: projectId,
    description: "API test job",
    workflow: "feature",
  });

  await p.http.send({
    method: "POST",
    path: `/api/v1/jobs/${jobId}/schedule`,
  });

  const workerId = uniqueId();
  await adapter.workerRegister(workerId, {
    job_id: jobId,
    hostname: "api-test-worker",
  });

  return { jobId, workerId };
}

describe("worker HTTP API", () => {
  it("worker register", async () => {
    const { jobId, workerId } = await createRunningJob();

    const res = await p.http.send({
      method: "GET",
      path: `/api/v1/workers/${workerId}`,
    });

    expect(res.status).toBe(200);

    if (isRecord(res.body)) {
      expect(res.body["job_id"]).toBe(jobId);
      expect(res.body["status"]).toBe("running");
    }
  });

  it("worker heartbeat", async () => {
    const { workerId } = await createRunningJob();

    const res = await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/heartbeat`,
      body: {
        status: "running",
        current_stage: "plan",
        token_usage: { input: 500, output: 200 },
      },
    });

    expect(res.status).toBe(200);
  });

  it("worker checkpoint", async () => {
    const { jobId, workerId } = await createRunningJob();

    const res = await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/checkpoint`,
      body: {
        job_id: jobId,
        stage: "plan",
        response: "Checkpoint data",
        session_path: "/tmp/session.json",
        git_sha: "def456",
        files_changed: ["src/lib.rs", "Cargo.toml"],
        tool_call_count: 15,
      },
    });

    expect(res.status).toBe(200);
  });

  it("worker complete", async () => {
    const { jobId, workerId } = await createRunningJob();

    const res = await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/complete`,
      body: {
        job_id: jobId,
        result: "success",
        output: "All stages completed",
        token_usage: { input: 1000, output: 500 },
      },
    });

    expect(res.status).toBe(200);

    const job = await adapter.getJob(jobId);
    if (isRecord(job)) {
      expect(job["status"]).toBe("completed");
    }
  });

  it("worker fail", async () => {
    const { jobId, workerId } = await createRunningJob();

    const res = await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/fail`,
      body: {
        job_id: jobId,
        error: "Build failed: unresolved import",
        retryable: true,
      },
    });

    expect(res.status).toBe(200);

    const job = await adapter.getJob(jobId);
    if (isRecord(job)) {
      expect(job["status"]).toBe("failed_retryable");
    }
  });

  it("get job config", async () => {
    const { jobId } = await createRunningJob();

    const res = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}/config`,
    });

    expect(res.status).toBe(200);

    if (isRecord(res.body)) {
      const stages = res.body["stages"];
      expect(typeof stages === "object" && stages !== null).toBe(true);
    }
  });

  it("get skill content", async () => {
    const { jobId } = await createRunningJob();

    const res = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}/skill/plan`,
    });

    expect(res.status).toBe(200);

    if (isRecord(res.body)) {
      expect(typeof res.body["content"]).toBe("string");
    }
  });

  it("unknown worker returns 404", async () => {
    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workers/nonexistent-id/register",
      body: {
        job_id: "fake-job",
        hostname: "ghost",
      },
    });

    expect(res.status).toBe(404);
  });
});
