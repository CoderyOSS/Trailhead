import { afterAll, afterEach, beforeEach } from "bun:test";
import { p } from "@codery/probes";

export { p };

afterAll(() => {
  p.proof.save();
});

export function proofSection(name: string) {
  beforeEach(() => {
    p.proof.begin(name);
  });
  afterEach(() => {
    p.proof.end();
  });
}

export function uniqueId(): string {
  return `test-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}
