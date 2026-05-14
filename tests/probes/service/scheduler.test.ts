import { describe, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, seedProject, createJob, isRecord } from "../helpers";

describe("scheduler endpoints", () => {
  test("lists jobs via HTTP matching DB count", async () => {
    const projectId = await seedProject();
    const job1 = await createJob(projectId, "Job 1");
    const job2 = await createJob(projectId, "Job 2");

    const res = await p.http.send({
      method: "GET",
      path: "/api/v1/jobs",
    });

    expect(res.status).toBe(200);

    const dbJobs = await p.sql.read({ table: "jobs" });
    if (Array.isArray(res.body)) {
      expect(res.body.length).toBe(dbJobs.length);
    }

    const dbJob1 = await p.sql.read({ table: "jobs", where: { id: job1 } });
    expect(dbJob1[0]["status"]).toBe("queued");

    const dbJob2 = await p.sql.read({ table: "jobs", where: { id: job2 } });
    expect(dbJob2[0]["status"]).toBe("queued");
  });

  test("list workers via HTTP matching DB", async () => {
    const res = await p.http.send({
      method: "GET",
      path: "/api/v1/workers",
    });

    expect(res.status).toBe(200);

    const dbWorkers = await p.sql.read({ table: "workers" });
    if (Array.isArray(res.body)) {
      expect(res.body.length).toBe(dbWorkers.length);
    }
  });
});
