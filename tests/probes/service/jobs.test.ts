import { describe, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, seedProject, createJob, createJobWithStatus } from "../helpers";

describe("job state machine", () => {
  test("new job is queued in DB", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "State machine test");

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("queued");
  });

  test("running to paused via HTTP", async () => {
    const projectId = await seedProject();
    const jobId = await createJobWithStatus(projectId, "Pause test", "running");

    const pauseRes = await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/pause`,
    });
    expect(pauseRes.status).toBe(200);

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("paused");
  });

  test("paused to resuming via HTTP", async () => {
    const projectId = await seedProject();
    const jobId = await createJobWithStatus(projectId, "Resume test", "paused");

    const resumeRes = await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/resume`,
    });
    expect(resumeRes.status).toBe(200);

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("resuming");
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
    const jobId = await createJobWithStatus(projectId, "Cancel running", "running");

    const cancelRes = await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/cancel`,
    });
    expect(cancelRes.status).toBe(200);

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("cancelled");
  });

  test("cannot resume cancelled job", async () => {
    const projectId = await seedProject();
    const jobId = await createJobWithStatus(projectId, "Terminal test", "cancelled");

    const res = await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/resume`,
    });

    expect(res.status).toBeGreaterThanOrEqual(400);

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("cancelled");
  });
});
