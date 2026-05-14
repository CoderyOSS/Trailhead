import { afterAll } from "bun:test";
import { p } from "@codery/probes";

afterAll(() => {
  p.proof.save();
});
