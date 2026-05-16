import { describe, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, seedProject, createJob, createWorker, isRecord } from "../helpers";

describe("database operations", () => {
  test("creates project via SQL seed and reads via HTTP and SQL", async () => {
    const projectId = await seedProject();

    const res = await p.http.send({
      method: "GET",
      path: "/api/v1/projects",
    });

    expect(res.status).toBe(200);
    if (Array.isArray(res.body)) {
      const found = res.body.some((r: unknown) =>
        isRecord(r) && r["id"] === projectId
      );
      expect(found).toBe(true);
    }

    const rows = await p.sql.read({ table: "projects", where: { id: projectId } });
    expect(rows.length).toBe(1);
    expect(rows[0]["id"]).toBe(projectId);
    expect(rows[0]["branch"]).toBe("main");
  });

  test("creates job via HTTP, verifies via HTTP and SQL", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "DB test job");

    const res = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}`,
    });

    expect(res.status).toBe(200);
    if (isRecord(res.body)) {
      expect(res.body["project_id"]).toBe(projectId);
      expect(res.body["description"]).toBe("DB test job");
      expect(res.body["status"]).toBe("queued");
    }

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["project_id"]).toBe(projectId);
    expect(rows[0]["status"]).toBe("queued");
  });

  test("creates worker record in DB", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Worker DB test");
    const workerId = await createWorker(jobId);

    const rows = await p.sql.read({ table: "workers", where: { id: workerId } });
    expect(rows.length).toBe(1);
    expect(rows[0]["job_id"]).toBe(jobId);
    expect(rows[0]["status"]).toBe("creating");
  });
});
