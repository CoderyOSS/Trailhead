import { describe, expect, beforeAll } from "bun:test";
import { p } from "@codery/probes";
import { test, uniqueId } from "../helpers";

const BASE_URL = process.env.TRAILHEAD_URL ?? "http://localhost:4050";

describe("hello-world pipeline", () => {
  let projectId: string;
  let jobId: string;

  beforeAll(async () => {
    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/projects",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        name: `test-${uniqueId()}`,
        repo_url: "https://github.com/example/test",
        branch: "main",
      }),
    });
    expect(res.status).toBe(200);
    const data = JSON.parse(res.body as string);
    projectId = data.project_id;
  });

  test("creates a job with hello-world workflow", async () => {
    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/jobs",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        project_id: projectId,
        description: "Hello world test",
        workflow: "hello-world",
      }),
    });
    expect(res.status).toBe(200);
    const data = JSON.parse(res.body as string);
    jobId = data.job_id;
    expect(jobId).toBeDefined();
  });

  test("job config returns resolved workflow stage", async () => {
    const res = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}/config`,
    });
    expect(res.status).toBe(200);
    const data = JSON.parse(res.body as string);
    expect(data.stage).toBe("greet");
    expect(data.prompt).toContain("Hello from Trailhead");
    expect(data.max_tokens).toBe(256);
    expect(data.timeout_secs).toBe(60);
    expect(data.model).toBeDefined();
    expect(data.provider).toBeDefined();
    expect(data.api_key).toBeDefined();
  });
});
