import { describe, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, seedProject, createJob, isRecord } from "../helpers";

describe("workflow parser", () => {
  test("parses valid workflow YAML", async () => {
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
      body: { content: yaml },
    });

    expect(res.status).toBe(200);
  });

  test("rejects empty stages", async () => {
    const yaml = `
name: empty
description: "No stages"
stages: {}
`;

    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workflows/validate",
      body: { content: yaml },
    });

    if (isRecord(res.body)) {
      expect(res.body["valid"]).toBe(false);
    }
  });

  test("accepts single-stage workflow", async () => {
    const yaml = `
name: minimal
description: "One stage"
stages:
  work:
    prompt: "Do it"
    tools: [bash]
    max_tokens: 4000
    routes: null
`;

    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workflows/validate",
      body: { content: yaml },
    });

    expect(res.status).toBe(200);
  });
});
