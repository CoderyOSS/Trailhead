import { p } from "@codery/probes";

export interface ServiceAdapter {
  createProject(params: { repo_url: string; branch?: string }): Promise<string>;
  createJob(params: { project_id: string; description: string; workflow?: string }): Promise<string>;
  getJob(jobId: string): Promise<Record<string, unknown>>;
  listJobs(): Promise<Record<string, unknown>[]>;
  cancelJob(jobId: string): Promise<void>;
  pauseJob(jobId: string): Promise<void>;
  resumeJob(jobId: string): Promise<void>;
  createWorker(params: { job_id: string; provider?: string }): Promise<string>;
  listWorkers(): Promise<Record<string, unknown>[]>;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isRecordArray(value: unknown): value is Record<string, unknown>[] {
  return Array.isArray(value) && value.every(isRecord);
}

function extractField(body: unknown, field: string): string {
  if (isRecord(body) && typeof body[field] === "string") {
    return body[field];
  }
  throw new Error(`Expected response with string ${field}, got: ${JSON.stringify(body)}`);
}

export const adapter: ServiceAdapter = {
  async createProject(params) {
    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/projects",
      body: { name: `test-${Date.now()}`, ...params },
    });
    return extractField(res.body, "project_id");
  },

  async createJob(params) {
    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/jobs",
      body: params,
    });
    return extractField(res.body, "job_id");
  },

  async getJob(jobId) {
    const res = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}`,
    });
    if (isRecord(res.body)) return res.body;
    throw new Error("Expected record response");
  },

  async listJobs() {
    const res = await p.http.send({
      method: "GET",
      path: "/api/v1/jobs",
    });
    if (isRecordArray(res.body)) return res.body;
    throw new Error("Expected record array response");
  },

  async cancelJob(jobId) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/cancel`,
    });
  },

  async pauseJob(jobId) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/pause`,
    });
  },

  async resumeJob(jobId) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/resume`,
    });
  },

  async createWorker(params) {
    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workers",
      body: params,
    });
    return extractField(res.body, "worker_id");
  },

  async listWorkers() {
    const res = await p.http.send({
      method: "GET",
      path: "/api/v1/workers",
    });
    if (isRecordArray(res.body)) return res.body;
    throw new Error("Expected record array response");
  },
};
