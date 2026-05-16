import { describe, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, seedProject, createJob, isRecord } from "../helpers";

describe("worker HTTP API", () => {
  test("create worker returns worker_id", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Worker create test");

    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workers",
      body: { job_id: jobId, provider: "test" },
    });

    expect(res.status).toBe(200);
    if (isRecord(res.body)) {
      expect(typeof res.body["worker_id"]).toBe("string");
    }
  });

  test("get job config returns resolved stage info", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Config test");

    const res = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}/config`,
    });

    expect(res.status).toBe(200);
    if (isRecord(res.body)) {
      expect(typeof res.body["stage"]).toBe("string");
      expect(typeof res.body["prompt"]).toBe("string");
      expect(Array.isArray(res.body["tools"])).toBe(true);
      expect(typeof res.body["max_tokens"]).toBe("number");
      expect(typeof res.body["model"]).toBe("string");
      expect(typeof res.body["provider"]).toBe("string");
      expect(typeof res.body["base_url"]).toBe("string");
      expect(typeof res.body["api_key"]).toBe("string");
    }
  });

  test("get skill content returns markdown", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Skill test");

    const res = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}/skill/plan`,
    });

    expect(res.status).toBe(200);
    if (isRecord(res.body)) {
      expect(typeof res.body["content"]).toBe("string");
      expect(res.body["content"].length).toBeGreaterThan(0);
    }
  });
});
