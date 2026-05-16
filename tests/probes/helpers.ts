import { test as bunTest, afterAll, beforeEach } from "bun:test";
import { p } from "@codery/probes";

export { p };

afterAll(() => {
  p.proof.save();
});

beforeEach(async () => {
  await p.sql.clear({ all: true });
  await p.sql.put({ file: "fixtures/seed.yaml" });
});

export const test = (name: string, fn: () => Promise<void> | void) => {
  bunTest(name, async () => {
    p.proof.begin(name);
    try { await fn(); } finally { p.proof.end(); }
  });
};

export function uniqueId(): string {
  return `test-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export async function seedProject(): Promise<string> {
  const id = uniqueId();
  const now = new Date().toISOString();
  await p.sql.put({
    table: "projects",
    rows: [{
      id,
      repo_url: `https://github.com/test/${id}`,
      branch: "main",
      created_at: now,
      updated_at: now,
    }],
  });
  return id;
}

export async function createJob(projectId: string, description: string, workflow?: string): Promise<string> {
  const res = await p.http.send({
    method: "POST",
    path: "/api/v1/jobs",
    body: { project_id: projectId, description, workflow },
  });
  if (isRecord(res.body) && typeof res.body["job_id"] === "string") {
    return res.body["job_id"];
  }
  throw new Error(`createJob failed: ${JSON.stringify(res.body)}`);
}

export async function createWorker(jobId: string): Promise<string> {
  const res = await p.http.send({
    method: "POST",
    path: "/api/v1/workers",
    body: { job_id: jobId, provider: "test" },
  });
  if (isRecord(res.body) && typeof res.body["worker_id"] === "string") {
    return res.body["worker_id"];
  }
  throw new Error(`createWorker failed: ${JSON.stringify(res.body)}`);
}

export async function createJobWithStatus(projectId: string, description: string, status: string, workflow?: string): Promise<string> {
  const id = uniqueId();
  const now = new Date().toISOString();
  await p.sql.put({
    table: "jobs",
    rows: [{
      id,
      project_id: projectId,
      description,
      status,
      workflow_name: workflow ?? null,
      stage_history: "[]",
      attempt: 1,
      max_attempts: 3,
      created_at: now,
      updated_at: now,
    }],
  });
  return id;
}
