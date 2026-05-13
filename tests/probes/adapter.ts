import { p } from "@codery/probes";

export interface ServiceAdapter {
  createJob(params: { project_id: string; description: string; workflow: string }): Promise<string>;
  getJob(jobId: string): Promise<Record<string, unknown>>;
  listJobs(): Promise<Record<string, unknown>[]>;
  cancelJob(jobId: string): Promise<void>;
  pauseJob(jobId: string): Promise<void>;
  resumeJob(jobId: string): Promise<void>;
  listWorkers(): Promise<Record<string, unknown>[]>;
  workerRegister(workerId: string, body: Record<string, unknown>): Promise<void>;
  workerHeartbeat(workerId: string, body: Record<string, unknown>): Promise<void>;
  workerCheckpoint(workerId: string, body: Record<string, unknown>): Promise<void>;
  workerComplete(workerId: string, body: Record<string, unknown>): Promise<void>;
  workerFail(workerId: string, body: Record<string, unknown>): Promise<void>;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isRecordArray(value: unknown): value is Record<string, unknown>[] {
  return Array.isArray(value) && value.every(isRecord);
}

function extractId(body: unknown): string {
  if (isRecord(body) && typeof body["id"] === "string") {
    return body["id"];
  }
  throw new Error("Expected response with string id");
}

export const adapter: ServiceAdapter = {
  async createJob(params) {
    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/jobs",
      body: params,
    });
    return extractId(res.body);
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

  async listWorkers() {
    const res = await p.http.send({
      method: "GET",
      path: "/api/v1/workers",
    });
    if (isRecordArray(res.body)) return res.body;
    throw new Error("Expected record array response");
  },

  async workerRegister(workerId, body) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/register`,
      body,
    });
  },

  async workerHeartbeat(workerId, body) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/heartbeat`,
      body,
    });
  },

  async workerCheckpoint(workerId, body) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/checkpoint`,
      body,
    });
  },

  async workerComplete(workerId, body) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/complete`,
      body,
    });
  },

  async workerFail(workerId, body) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/fail`,
      body,
    });
  },
};
