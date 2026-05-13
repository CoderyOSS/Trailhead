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

async function createProject(suffix?: string): Promise<string> {
  const projectId = uniqueId();
  await p.http.send({
    method: "POST",
    path: "/api/v1/projects",
    body: {
      id: projectId,
      name: `sched-${suffix ?? "test"}-${projectId}`,
      repo_url: "https://github.com/example/sched-test",
      workflow: "feature",
    },
  });
  return projectId;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

describe("scheduler", () => {
  it("picks queued job when capacity available", async () => {
    const projectId = await createProject("pick");

    const jobId = await adapter.createJob({
      project_id: projectId,
      description: "Scheduler pick test",
      workflow: "feature",
    });

    expect(getStatus(await adapter.getJob(jobId))).toBe("queued");

    await sleep(5000);

    const job = await adapter.getJob(jobId);
    const status = getStatus(job);
    expect(status === "scheduled" || status === "running").toBe(true);
  });

  it("respects max global workers", async () => {
    const projectIds = await Promise.all([
      createProject("global-1"),
      createProject("global-2"),
      createProject("global-3"),
      createProject("global-4"),
    ]);

    const jobIds = await Promise.all(
      projectIds.map((pid) =>
        adapter.createJob({
          project_id: pid,
          description: "Global capacity test",
          workflow: "feature",
        })
      )
    );

    await sleep(5000);

    const statuses = await Promise.all(
      jobIds.map((id) => adapter.getJob(id).then(getStatus))
    );

    const activeCount = statuses.filter(
      (s) => s === "scheduled" || s === "running"
    ).length;

    expect(activeCount).toBeLessThanOrEqual(3);
  });

  it("respects max workers per project", async () => {
    const projectId = await createProject("per-project");

    const jobIds = await Promise.all([
      adapter.createJob({
        project_id: projectId,
        description: "Per-project worker test 1",
        workflow: "feature",
      }),
      adapter.createJob({
        project_id: projectId,
        description: "Per-project worker test 2",
        workflow: "feature",
      }),
    ]);

    await sleep(5000);

    const statuses = await Promise.all(
      jobIds.map((id) => adapter.getJob(id).then(getStatus))
    );

    const activeCount = statuses.filter(
      (s) => s === "scheduled" || s === "running"
    ).length;

    expect(activeCount).toBeLessThanOrEqual(1);
  });

  it("detects stuck workers", async () => {
    const projectId = await createProject("stuck");

    const jobId = await adapter.createJob({
      project_id: projectId,
      description: "Stuck worker test",
      workflow: "feature",
    });

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(workerId, {
      job_id: jobId,
      hostname: "stuck-worker",
    });

    const oldTimestamp = new Date(Date.now() - 300_000).toISOString();

    await p.sql.execute(
      "UPDATE workers SET last_heartbeat = ? WHERE id = ?",
      [oldTimestamp, workerId]
    );

    await sleep(5000);

    const job = await adapter.getJob(jobId);
    expect(getStatus(job)).toBe("failed_retryable");
  });

  it("retries failed jobs within limit", async () => {
    const projectId = await createProject("retry");

    const jobId = await adapter.createJob({
      project_id: projectId,
      description: "Retry limit test",
      workflow: "feature",
    });

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/schedule`,
    });

    const workerId = uniqueId();
    await adapter.workerRegister(workerId, {
      job_id: jobId,
      hostname: "retry-worker",
    });

    await adapter.workerFail(workerId, {
      job_id: jobId,
      error: "Retryable failure",
      retryable: true,
    });

    const jobAfterFail = await adapter.getJob(jobId);
    expect(getStatus(jobAfterFail)).toBe("failed_retryable");

    await sleep(5000);

    const jobAfterRetry = await adapter.getJob(jobId);
    const status = getStatus(jobAfterRetry);
    expect(status === "queued" || status === "scheduled").toBe(true);

    if (isRecord(jobAfterRetry)) {
      const retryCount = jobAfterRetry["retry_count"];
      if (typeof retryCount === "number") {
        expect(retryCount).toBeGreaterThan(0);
      }
    }
  });
});
