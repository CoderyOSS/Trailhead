import { describe, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, seedProject, createJob } from "../helpers";

describe("workflow engine", () => {
  test("new job is queued in DB", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Start at first stage");

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["status"]).toBe("queued");
    expect(rows[0]["project_id"]).toBe(projectId);
  });

  test("job with workflow has workflow_name set", async () => {
    const projectId = await seedProject();
    const jobId = await createJob(projectId, "Workflow job", "feature");

    const rows = await p.sql.read({ table: "jobs", where: { id: jobId } });
    expect(rows[0]["workflow_name"]).toBe("feature");
  });
});
