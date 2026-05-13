import type { ProbesInstance } from "@codery/probes";

export interface ServiceAdapter {
  createJob(p: ProbesInstance, params: { project_id: string; description: string; workflow: string }): Promise<string>;
  getJob(p: ProbesInstance, jobId: string): Promise<Record<string, unknown>>;
  listJobs(p: ProbesInstance): Promise<Record<string, unknown>[]>;
  cancelJob(p: ProbesInstance, jobId: string): Promise<void>;
  pauseJob(p: ProbesInstance, jobId: string): Promise<void>;
  resumeJob(p: ProbesInstance, jobId: string): Promise<void>;
  listWorkers(p: ProbesInstance): Promise<Record<string, unknown>[]>;
  workerRegister(p: ProbesInstance, workerId: string, body: Record<string, unknown>): Promise<void>;
  workerHeartbeat(p: ProbesInstance, workerId: string, body: Record<string, unknown>): Promise<void>;
  workerCheckpoint(p: ProbesInstance, workerId: string, body: Record<string, unknown>): Promise<void>;
  workerComplete(p: ProbesInstance, workerId: string, body: Record<string, unknown>): Promise<void>;
  workerFail(p: ProbesInstance, workerId: string, body: Record<string, unknown>): Promise<void>;
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
  async createJob(p, params) {
    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/jobs",
      body: params,
    });
    return extractId(res.body);
  },

  async getJob(p, jobId) {
    const res = await p.http.send({
      method: "GET",
      path: `/api/v1/jobs/${jobId}`,
    });
    if (isRecord(res.body)) return res.body;
    throw new Error("Expected record response");
  },

  async listJobs(p) {
    const res = await p.http.send({
      method: "GET",
      path: "/api/v1/jobs",
    });
    if (isRecordArray(res.body)) return res.body;
    throw new Error("Expected record array response");
  },

  async cancelJob(p, jobId) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/cancel`,
    });
  },

  async pauseJob(p, jobId) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/pause`,
    });
  },

  async resumeJob(p, jobId) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/jobs/${jobId}/resume`,
    });
  },

  async listWorkers(p) {
    const res = await p.http.send({
      method: "GET",
      path: "/api/v1/workers",
    });
    if (isRecordArray(res.body)) return res.body;
    throw new Error("Expected record array response");
  },

  async workerRegister(p, workerId, body) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/register`,
      body,
    });
  },

  async workerHeartbeat(p, workerId, body) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/heartbeat`,
      body,
    });
  },

  async workerCheckpoint(p, workerId, body) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/checkpoint`,
      body,
    });
  },

  async workerComplete(p, workerId, body) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/complete`,
      body,
    });
  },

  async workerFail(p, workerId, body) {
    await p.http.send({
      method: "POST",
      path: `/api/v1/workers/${workerId}/fail`,
      body,
    });
  },
};
