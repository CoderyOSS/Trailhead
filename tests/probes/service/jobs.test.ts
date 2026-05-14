import { describe, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, seedProject, createJob, createWorker } from "../helpers";

describe("job state machine", () => {
  test("new job is queued in DB", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "State machine test");

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("queued");
  });

  test("running to paused via HTTP, verified in DB", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Pause test");
    const workerId = await createWorker(jobId);

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/register`,
      body: { job_id: jobId },
    });

    const pauseRes = await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/pause`,
    });
    expect(pauseRes.status).toBe(200);

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("paused");
  });

  test("paused to resuming via HTTP, verified in DB", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Resume test");
    const workerId = await createWorker(jobId);

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/register`,
      body: { job_id: jobId },
    });

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/pause`,
    });

    const resumeRes = await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/resume`,
    });
    expect(resumeRes.status).toBe(200);

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("resuming");
  });

  test("running to completed, verified in DB", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Complete test");
    const workerId = await createWorker(jobId);

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/register`,
      body: { job_id: jobId },
    });

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/complete`,
      body: { result: "success" },
    });

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("completed");
    expect(rows[0]["result"]).toBe("success");
  });

  test("running to failed_retryable, verified in DB", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Fail test");
    const workerId = await createWorker(jobId);

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/register`,
      body: { job_id: jobId },
    });

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/fail`,
      body: { error: "transient failure" },
    });

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("failed_retryable");
    expect(rows[0]["error"]).toBe("transient failure");
  });

  test("cannot resume completed job", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Terminal test");
    const workerId = await createWorker(jobId);

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/register`,
      body: { job_id: jobId },
    });

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/complete`,
      body: { result: "done" },
    });

    const res = await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/resume`,
    });

    expect(res.status).toBeGreaterThanOrEqual(400);

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("completed");
  });

  test("cancel from queued state", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Cancel queued");

    const cancelRes = await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/cancel`,
    });
    expect(cancelRes.status).toBe(200);

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("cancelled");
  });

  test("cancel from running state", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Cancel running");
    const workerId = await createWorker(jobId);

    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/register`,
      body: { job_id: jobId },
    });

    const cancelRes = await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/cancel`,
    });
    expect(cancelRes.status).toBe(200);

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("cancelled");
  });
});
