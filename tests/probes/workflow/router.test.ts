import { describe, expect } from "bun:test";
import { p } from "@codery/probes";
import { test, isRecord } from "../helpers";

describe("workflow router", () => {
  test("validates numeric routing workflow", async () => {
    const yaml = `
name: numeric-route
description: "Numeric routing"
stages:
  check:
    skill: plan
    prompt: "Check"
    tools: [bash]
    max_tokens: 8000
    routes:
      - when: 'response.count > 5'
        next: many
      - when: 'true'
        next: few
  many:
    skill: pause
    prompt: "Many"
    routes: null
  few:
    skill: pause
    prompt: "Few"
    routes: null
`;

    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workflows/validate",
      body: { content: yaml },
    });

    expect(res.status).toBe(200);
  });

  test("rejects workflow with empty stages", async () => {
    const yaml = "name: bad\nstages: {}\n";
    const res = await p.http.send({
      method: "POST",
      path: "/api/v1/workflows/validate",
      body: { content: yaml },
    });
    if (isRecord(res.body)) {
      expect(res.body["valid"]).toBe(false);
    }
  });
});
