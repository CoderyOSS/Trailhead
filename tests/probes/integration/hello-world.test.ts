import { describe, expect, beforeAll } from "bun:test";
import { p } from "@codery/probes";
import { test, seedProject, createJob, isRecord } from "../helpers";

describe("hello-world pipeline", () => {
  let projectId: string;
  let jobId: string;

  beforeAll(async () => {
    projectId = await seedProject();
    jobId = await createJob(projectId, "Hello world test");
  });

  test("creates a job with hello-world workflow", async () => {
    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("queued");
    expect(rows[0]["description"]).toBe("Hello world test");
  });

  test("job config returns resolved stage info", async () => {
    const res = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}/config`,
    });
    expect(res.status).toBe(200);
    if (isRecord(res.body)) {
      expect(typeof res.body["prompt"]).toBe("string");
      expect(typeof res.body["max_tokens"]).toBe("number");
      expect(typeof res.body["model"]).toBe("string");
      expect(typeof res.body["provider"]).toBe("string");
    }
  });
});
