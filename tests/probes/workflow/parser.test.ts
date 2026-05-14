import { describe, it, expect } from "bun:test";
import { p } from "@codery/probes";
import { proofSection } from "../helpers";

proofSection("workflow parser");

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function hasStatus(res: { status: number }, expected: number): boolean {
  return res.status === expected;
}

describe("workflow parser", () => {
  it("parses valid workflow YAML", async () => {
    const yaml = `
name: simple
description: "Simple workflow"
stages:
  plan:
    skill: plan
    prompt: "Plan: {{input}}"
    tools: [bash, read]
    max_tokens: 8000
    routes:
      - when: 'true'
        next: done
  done:
    skill: pause
    prompt: "Done"
    routes: null
`;

    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workflows/validate",
      body: { yaml },
    });

    expect(hasStatus(res, 200)).toBe(true);

    if (isRecord(res.body)) {
      const stages = res.body["stages"];
      if (isRecord(stages)) {
        expect("plan" in stages).toBe(true);
        expect("done" in stages).toBe(true);
      }
    }
  });

  it("rejects empty stages", async () => {
    const yaml = `
name: empty
description: "No stages"
stages: {}
`;

    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workflows/validate",
      body: { yaml },
    });

    expect(hasStatus(res, 400)).toBe(true);
  });

  it("rejects unknown route target", async () => {
    const yaml = `
name: bad-route
description: "Routes to nonexistent stage"
stages:
  plan:
    skill: plan
    prompt: "Plan"
    tools: [bash]
    max_tokens: 8000
    routes:
      - when: 'true'
        next: nonexistent_stage
`;

    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workflows/validate",
      body: { yaml },
    });

    expect(hasStatus(res, 400)).toBe(true);
  });

  it("rejects missing skill", async () => {
    const yaml = `
name: no-skill
description: "Stage without skill"
stages:
  plan:
    prompt: "Plan"
    tools: [bash]
    max_tokens: 8000
    routes:
      - when: 'true'
        next: done
  done:
    skill: pause
    prompt: "Done"
    routes: null
`;

    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workflows/validate",
      body: { yaml },
    });

    expect(hasStatus(res, 400)).toBe(true);
  });
});
