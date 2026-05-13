import { probes, type ProbesInstance } from "@codery/probes";

export async function createTestProbes(): Promise<ProbesInstance> {
  return probes({
    sql: { path: "./data/test.db", reset_on_start: true },
    http: { client: { base_url: "http://localhost:4050" } },
    fs: { root: "./test-workspace", reset_on_start: true },
  });
}

export function uniqueId(): string {
  return `test-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}
