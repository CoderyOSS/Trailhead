/* global */
// ──────────────────────────────────────────────────────────────────────────
// Workflow + job mock data for the Trailhead workflow manager.
// ──────────────────────────────────────────────────────────────────────────

// Each stage is either a `worker` (skills + prompt + schema) or a routing
// operator (`switch` / `branch` / `map` / `loop` / `join`). Positions are
// authored for the n8n-style free graph; the swimlane and tree layouts
// derive their positions from `column` + `lane`.

const WORKFLOW = {
  id: "wf_pr_reviewer",
  name: "pr-reviewer",
  description: "Triages incoming pull requests, performs targeted review, and posts comments.",
  version: 14,
  draft: 15,
  updated: "2 min ago by jen.b",
  inputs: {
    pr_number: "int",
    repo: "string",
    base_sha: "string",
  },
  stages: [
    {
      id: "ingest",
      kind: "worker",
      label: "ingest",
      sub: "fetch PR + diff",
      skills: ["git.fetch_pr", "git.diff", "file.read"],
      prompt:
        "Read PR #{{inputs.pr_number}} from {{inputs.repo}}.\n" +
        "Return the changed files, a one-line title, and the author handle.",
      schema: {
        type: "object",
        properties: {
          files: { type: "array", items: { type: "string" } },
          title: { type: "string" },
          author: { type: "string" },
          additions: { type: "integer" },
          deletions: { type: "integer" },
        },
        required: ["files", "title"],
      },
      pos: { x: 80, y: 320 },
      column: 0, lane: 0,
    },
    {
      id: "classify",
      kind: "worker",
      label: "classify-risk",
      sub: "low · med · high",
      skills: ["reasoning"],
      model: "haiku-4.5",
      prompt:
        "Given {{ingest.files}} ({{ingest.additions}}/-{{ingest.deletions}}),\n" +
        "rate the change risk. Reasons drive routing — be specific.",
      schema: {
        type: "object",
        properties: {
          risk: { enum: ["low", "med", "high"] },
          reasons: { type: "array", items: { type: "string" } },
          security_relevant: { type: "boolean" },
        },
      },
      pos: { x: 300, y: 320 },
      column: 1, lane: 0,
    },
    {
      id: "route_risk",
      kind: "switch",
      label: "switch",
      sub: "on classify.risk",
      on: "{{classify.risk}}",
      cases: [
        { match: "low",  to: ["quick_review"], label: "low" },
        { match: "med",  to: ["full_review"],  label: "med" },
        { match: "high", to: ["full_review", "security_scan"], label: "high" },
      ],
      pos: { x: 520, y: 320 },
      column: 2, lane: 0,
    },
    {
      id: "quick_review",
      kind: "worker",
      label: "quick-review",
      sub: "single-pass lint + suggest",
      skills: ["code.review.lint", "reasoning"],
      model: "haiku-4.5",
      prompt:
        "Do a focused review of {{ingest.files}}. Stick to style and obvious bugs.\n" +
        "Return at most 4 comments.",
      schema: {
        type: "object",
        properties: { comments: { type: "array" } },
      },
      pos: { x: 740, y: 160 },
      column: 3, lane: -1,
    },
    {
      id: "full_review",
      kind: "worker",
      label: "full-review",
      sub: "deep semantic review",
      skills: ["code.review.semantic", "code.search", "reasoning"],
      model: "sonnet-4.5",
      prompt:
        "Review {{ingest.files}} on diff `{{inputs.base_sha}}..HEAD`.\n" +
        "Use code.search to ground claims in existing call sites.\n" +
        "Focus areas: {{classify.reasons}}.",
      schema: {
        type: "object",
        properties: {
          comments: { type: "array" },
          summary: { type: "string" },
          blocking: { type: "boolean" },
        },
      },
      pos: { x: 740, y: 320 },
      column: 3, lane: 0,
    },
    {
      id: "security_scan",
      kind: "worker",
      label: "security-scan",
      sub: "secrets, deps, SAST",
      skills: ["sec.semgrep", "sec.gitleaks", "sec.dep_audit"],
      prompt:
        "Run a scan over {{ingest.files}}. Flag anything CWE-graded med or above.",
      schema: {
        type: "object",
        properties: { findings: { type: "array" } },
      },
      pos: { x: 740, y: 480 },
      column: 3, lane: 1,
    },
    {
      id: "per_file",
      kind: "map",
      label: "for-each",
      sub: "over ingest.files",
      over: "{{ingest.files}}",
      body: "comment_file",
      pos: { x: 960, y: 320 },
      column: 4, lane: 0,
    },
    {
      id: "comment_file",
      kind: "worker",
      label: "comment-file",
      sub: "per-file inline comment",
      skills: ["code.review.inline"],
      model: "haiku-4.5",
      prompt:
        "Write an inline comment for file `{{item}}` using\n" +
        "{{full_review.comments}} as ground truth. Be terse.",
      schema: {
        type: "object",
        properties: { path: "string", line: "integer", body: "string" },
      },
      pos: { x: 960, y: 500 },
      column: 4, lane: 1,
      inside: "per_file",
    },
    {
      id: "join_reviews",
      kind: "join",
      label: "join",
      sub: "wait for 2 / 3",
      waits_for: ["per_file", "full_review", "security_scan"],
      mode: "any-2",
      pos: { x: 1180, y: 320 },
      column: 5, lane: 0,
    },
    {
      id: "critic",
      kind: "worker",
      label: "critic",
      sub: "score the reviewer",
      skills: ["reasoning"],
      model: "sonnet-4.5",
      prompt:
        "Read {{full_review.summary}} and the per-file comments\n" +
        "{{per_file.results}}. Is the review specific, kind, and actionable?\n" +
        "Score 1-5. If <4, request a redo with notes.",
      schema: {
        type: "object",
        properties: {
          score: { type: "integer" },
          notes: { type: "string" },
          accept: { type: "boolean" },
        },
      },
      pos: { x: 1400, y: 320 },
      column: 6, lane: 0,
    },
    {
      id: "satisfied",
      kind: "branch",
      label: "branch",
      sub: "critic.accept",
      cond: "{{critic.accept}}",
      branches: [
        { match: "true",  to: ["post"],          label: "ship" },
        { match: "false", to: ["full_review"],   label: "redo", loop: true },
      ],
      pos: { x: 1620, y: 320 },
      column: 7, lane: 0,
    },
    {
      id: "post",
      kind: "worker",
      label: "post-comment",
      sub: "github.comment",
      skills: ["github.comment", "github.label"],
      prompt:
        "Post the comments from {{per_file.results}} to {{inputs.repo}}#{{inputs.pr_number}}.\n" +
        "Add label `triaged:{{classify.risk}}`.",
      schema: {
        type: "object",
        properties: { posted: { type: "integer" } },
      },
      pos: { x: 1840, y: 320 },
      column: 8, lane: 0,
    },
  ],
  edges: [
    { from: "ingest",        to: "classify"      },
    { from: "classify",      to: "route_risk"    },
    { from: "route_risk",    to: "quick_review",  case: "low"  },
    { from: "route_risk",    to: "full_review",   case: "med · high"  },
    { from: "route_risk",    to: "security_scan", case: "high" },
    { from: "quick_review",  to: "join_reviews"  },
    { from: "full_review",   to: "per_file"      },
    { from: "per_file",      to: "comment_file", kind: "map-body"   },
    { from: "comment_file",  to: "per_file",     kind: "map-return" },
    { from: "per_file",      to: "join_reviews"  },
    { from: "security_scan", to: "join_reviews"  },
    { from: "join_reviews",  to: "critic"        },
    { from: "critic",        to: "satisfied"     },
    { from: "satisfied",     to: "post",         case: "ship" },
    { from: "satisfied",     to: "full_review",  case: "redo", loop: true },
  ],
};

// ──────────────────────────────────────────────────────────────────────────
// Job snapshot — a workflow inflight. Each stage gets a status; edges that
// have actually been taken light up. This represents a "high risk" run.
// ──────────────────────────────────────────────────────────────────────────

const JOB = {
  id: "job_r8f2a91c",
  workflowId: "wf_pr_reviewer",
  workflowVersion: 14,
  state: "running",         // running | paused | passed | failed | cancelled
  startedAt: "2026-05-23T14:18:32Z",
  elapsedSec: 247,
  costUsd: 0.42,
  tokens: 184_233,
  inputs: { pr_number: 1428, repo: "acme/ledger", base_sha: "a3f912e" },
  // status by stage id
  stageStatus: {
    ingest:        { status: "passed",    durMs: 1200, tokens: 8400  },
    classify:      { status: "passed",    durMs:  900, tokens: 3100, value: "high" },
    route_risk:    { status: "passed",    durMs:   12, tokens:    0, chose: ["full_review", "security_scan"] },
    quick_review:  { status: "skipped",   durMs:    0, tokens:    0 },
    full_review:   { status: "running",   durMs:  ~~(0), progress: 0.62, tokens: 38_400 },
    security_scan: { status: "running",   durMs:  ~~(0), progress: 0.81, tokens: 14_900 },
    per_file:      { status: "queued",    durMs:    0, tokens:    0, items: 7, done: 0 },
    comment_file:  { status: "queued",    durMs:    0, tokens:    0 },
    join_reviews:  { status: "queued",    durMs:    0, tokens:    0 },
    critic:        { status: "queued",    durMs:    0, tokens:    0 },
    satisfied:     { status: "queued",    durMs:    0, tokens:    0 },
    post:          { status: "queued",    durMs:    0, tokens:    0 },
  },
  // which edges have actually been traversed / are flowing tokens now
  edgeStatus: {
    "ingest→classify":        "done",
    "classify→route_risk":    "done",
    "route_risk→quick_review":"skipped",
    "route_risk→full_review": "active",
    "route_risk→security_scan":"active",
    "full_review→per_file":   "pending",
    "per_file→comment_file":  "pending",
    "comment_file→per_file":  "pending",
    "quick_review→join_reviews":"skipped",
    "per_file→join_reviews":  "pending",
    "security_scan→join_reviews":"pending",
    "join_reviews→critic":    "pending",
    "critic→satisfied":       "pending",
    "satisfied→post":         "pending",
    "satisfied→full_review":  "pending",
  },
};

// ──────────────────────────────────────────────────────────────────────────
// Snapshots — captured automatically and on-demand. The filmstrip scrubs
// through them; clicking one switches the canvas into "viewing snapshot".
// ──────────────────────────────────────────────────────────────────────────

const SNAPSHOTS = [
  { id: "s0", at: "+00:00", label: "started",       cursor: "ingest",        kind: "auto",   note: "" },
  { id: "s1", at: "+00:19", label: "ingest passed", cursor: "classify",      kind: "auto",   note: "7 files, 412+/118-" },
  { id: "s2", at: "+00:34", label: "classified",    cursor: "route_risk",    kind: "auto",   note: "risk=high" },
  { id: "s3", at: "+00:35", label: "fan-out",       cursor: "full_review",   kind: "auto",   note: "→ full + security" },
  { id: "s4", at: "+02:18", label: "pinned",        cursor: "full_review",   kind: "manual", note: "jen.b — looks promising" },
  { id: "s5", at: "+04:07", label: "now",           cursor: "full_review",   kind: "live",   note: "running · 62%" },
];

// ──────────────────────────────────────────────────────────────────────────
// Other workflows (sidebar nav)
// ──────────────────────────────────────────────────────────────────────────

const WORKFLOWS_LIST = [
  { id: "wf_pr_reviewer", name: "pr-reviewer",        runs: 1284, last: "2m",  active: 2 },
  { id: "wf_eval_harness", name: "eval-harness",      runs:  412, last: "11m", active: 0 },
  { id: "wf_release_notes", name: "release-notes",    runs:   38, last: "1h",  active: 0 },
  { id: "wf_flake_tracker", name: "flake-tracker",    runs:  906, last: "8m",  active: 1 },
  { id: "wf_changelog_summ", name: "changelog-summary",runs:  142, last: "3h", active: 0 },
  { id: "wf_doc_indexer",   name: "doc-indexer",      runs:   77, last: "1d",  active: 0 },
];

const JOBS_LOG = [
  { id: "r_8f2a91c", workflow: "pr-reviewer",    status: "running",   started: "14:18", dur: "4m07s", cost: "$0.42", input: "PR #1428",  by: "webhook" },
  { id: "r_8f29442", workflow: "pr-reviewer",    status: "passed",    started: "14:12", dur: "3m44s", cost: "$0.31", input: "PR #1427",  by: "webhook" },
  { id: "r_8f28a01", workflow: "eval-harness",   status: "failed",    started: "14:07", dur: "8m12s", cost: "$1.84", input: "suite/all", by: "jen.b" },
  { id: "r_8f27b3d", workflow: "flake-tracker",  status: "passed",    started: "14:03", dur: "0m48s", cost: "$0.04", input: "ci-main",   by: "cron"  },
  { id: "r_8f26108", workflow: "pr-reviewer",    status: "passed",    started: "13:58", dur: "2m18s", cost: "$0.22", input: "PR #1426",  by: "webhook" },
  { id: "r_8f25fa2", workflow: "pr-reviewer",    status: "retrying",  started: "13:54", dur: "5m10s", cost: "$0.38", input: "PR #1425",  by: "webhook" },
  { id: "r_8f24c0e", workflow: "release-notes",  status: "passed",    started: "13:01", dur: "1m12s", cost: "$0.09", input: "v0.42.1",   by: "jen.b" },
  { id: "r_8f23911", workflow: "pr-reviewer",    status: "cancelled", started: "12:55", dur: "0m22s", cost: "$0.02", input: "PR #1424",  by: "jen.b" },
];

// Compose the YAML representation programmatically so it can't desync.
function workflowToYaml(wf) {
  const lines = [];
  lines.push(`name: ${wf.name}`);
  lines.push(`version: ${wf.version}`);
  lines.push(`# ${wf.description}`);
  lines.push(`inputs:`);
  for (const [k, v] of Object.entries(wf.inputs)) lines.push(`  ${k}: ${v}`);
  lines.push(`stages:`);
  for (const s of wf.stages) {
    lines.push(`  - id: ${s.id}`);
    lines.push(`    kind: ${s.kind}`);
    if (s.kind === "worker") {
      lines.push(`    skills: [${(s.skills || []).join(", ")}]`);
      if (s.model) lines.push(`    model: ${s.model}`);
      lines.push(`    prompt: |`);
      for (const ln of s.prompt.split("\n")) lines.push(`      ${ln}`);
      lines.push(`    schema:`);
      lines.push(`      type: ${s.schema.type}`);
      lines.push(`      properties:`);
      for (const [k, v] of Object.entries(s.schema.properties || {})) {
        const t = typeof v === "string" ? v : (v.type || (v.enum ? `enum[${v.enum.join("|")}]` : ""));
        lines.push(`        ${k}: ${t}`);
      }
    } else if (s.kind === "switch") {
      lines.push(`    on: "${s.on}"`);
      lines.push(`    cases:`);
      for (const c of s.cases) lines.push(`      ${c.match}: [${c.to.join(", ")}]`);
    } else if (s.kind === "branch") {
      lines.push(`    cond: "${s.cond}"`);
      lines.push(`    branches:`);
      for (const b of s.branches) lines.push(`      - if: ${b.match}\n        to: [${b.to.join(", ")}]${b.loop ? "  # loops back" : ""}`);
    } else if (s.kind === "map") {
      lines.push(`    over: "${s.over}"`);
      lines.push(`    body: ${s.body}`);
    } else if (s.kind === "join") {
      lines.push(`    waits_for: [${s.waits_for.join(", ")}]`);
      lines.push(`    mode: ${s.mode}`);
    }
  }
  return lines.join("\n");
}

Object.assign(window, { WORKFLOW, JOB, SNAPSHOTS, WORKFLOWS_LIST, JOBS_LOG, workflowToYaml });
