import { test as bunTest, afterAll } from "bun:test";
import { p } from "@codery/probes";

export { p };

afterAll(() => {
  p.proof.save();
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
