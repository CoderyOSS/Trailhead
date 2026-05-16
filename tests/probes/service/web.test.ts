import { describe, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, seedProject, createJob, createWorker, isRecord } from "../helpers";

describe("dashboard API", () => {
  test("GET /api/v1/jobs returns list matching DB", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Dashboard test job");

    const res = await p.http.send({
      method: "GET",
      path: "/api/v1/jobs",
    });

    expect(res.status).toBe(200);
    if (Array.isArray(res.body)) {
      const found = res.body.some((j: unknown) =>
        isRecord(j) && j["id"] === jobId
      );
      expect(found).toBe(true);
    }

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["description"]).toBe("Dashboard test job");
  });

  test("GET /api/v1/jobs/{id} returns detail matching DB", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Detail test");

    const res = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}`,
    });

    expect(res.status).toBe(200);
    if (isRecord(res.body)) {
      expect(res.body["id"]).toBe(jobId);
      expect(res.body["status"]).toBe("queued");
    }

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("queued");
  });

  test("GET /api/v1/workers returns list matching DB", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Worker list test");
    const workerId = await createWorker(jobId);

    const res = await p.http.send({
      method: "GET",
      path: "/api/v1/workers",
    });

    expect(res.status).toBe(200);
    if (Array.isArray(res.body)) {
      const found = res.body.some((w: unknown) =>
        isRecord(w) && w["id"] === workerId
      );
      expect(found).toBe(true);
    }

    const rows = await p.sql.read({ table: "workers", where: { id: workerId } });
    expect(rows[0]["job_id"]).toBe(jobId);
  });

  test("POST /api/v1/jobs/{id}/cancel changes status in DB", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Cancel via dashboard");

    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/cancel`,
    });

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("cancelled");
  });
});
