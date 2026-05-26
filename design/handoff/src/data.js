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
// Snapshots — captured at every stage boundary (auto) plus user-initiated
// markers (manual). Each snapshot is the full state of one stage execution:
// what came in, what came out, how long it took, what tools were called,
// and the error if it failed. The filmstrip card surfaces those directly.
// ──────────────────────────────────────────────────────────────────────────

const SNAPSHOTS = [
  {
    id: "s0",
    at: "+00:00",
    stageId: "ingest",
    stageLabel: "ingest",
    kind: "auto",
    status: "passed",
    durMs: 1240,
    tokens: 8_412,
    tools: ["git.fetch_pr", "git.diff", "file.read"],
    input: { pr_number: 1428, repo: "acme/ledger" },
    result: { files: 7, title: "Add audit log to ledger writes", author: "@li-wei", additions: 412, deletions: 118 },
  },
  {
    id: "s1",
    at: "+00:21",
    stageId: "classify",
    stageLabel: "classify-risk",
    kind: "auto",
    status: "passed",
    durMs: 924,
    tokens: 3_110,
    tools: ["reasoning"],
    input: "7 files · 412+/-118 · auth + db migration touched",
    result: { risk: "high", reasons: ["db migration", "auth touched", "no tests added"], security_relevant: true },
  },
  {
    id: "s2",
    at: "+00:34",
    stageId: "route_risk",
    stageLabel: "switch · route_risk",
    kind: "auto",
    status: "passed",
    durMs: 12,
    tokens: 0,
    tools: [],
    input: 'classify.risk = "high"',
    result: { chose: ["full_review", "security_scan"], skipped: ["quick_review"] },
  },
  {
    id: "s3",
    at: "+01:48",
    stageId: "security_scan",
    stageLabel: "security-scan",
    kind: "auto",
    status: "failed",
    durMs: 71_300,
    tokens: 14_902,
    tools: ["sec.semgrep", "sec.gitleaks", "sec.dep_audit"],
    input: "7 files · diff a3f912e..HEAD",
    error: {
      code: "TOOL_TIMEOUT",
      message: "sec.dep_audit exceeded 60s timeout on lockfile resolution",
      retryable: true,
    },
  },
  {
    id: "s4",
    at: "+02:18",
    stageId: "full_review",
    stageLabel: "full-review",
    kind: "manual",
    status: "passed",
    durMs: 96_400,
    tokens: 38_402,
    tools: ["code.review.semantic", "code.search", "reasoning"],
    note: "jen.b pinned — promising review draft, want to rerun from here",
    input: "7 files · focus: db migration, auth touched, no tests added",
    result: {
      comments: 11,
      summary: "Solid migration with proper rollback. Auth changes need a test for the new role flag — found 2 missing cases.",
      blocking: false,
    },
  },
  {
    id: "s5",
    at: "+04:07",
    stageId: "full_review",
    stageLabel: "full-review",
    kind: "live",
    status: "running",
    progress: 0.62,
    durMs: 145_200,
    tokens: 38_402,
    tools: ["code.review.semantic", "code.search"],
    input: "retry — re-running after security_scan timeout",
    streaming: "reading src/auth/middleware.ts · line 47 …",
  },
];

// ──────────────────────────────────────────────────────────────────────────
// Per-stage executions for the current job. A stage can have multiple
// executions in one job from retries (failed → re-run) or map iterations.
// The Job drawer is a read-only log viewer over these.
// ──────────────────────────────────────────────────────────────────────────

const STAGE_EXECUTIONS = {
  ingest: [
    {
      id: "ex_ingest_1",
      label: "execution",
      status: "passed",
      startedAt: "+00:00",
      durMs: 1200,
      tokens: 8_412,
      tools: [
        { name: "git.fetch_pr",  args: "pr=1428, repo=acme/ledger", ok: true, ms:  340 },
        { name: "git.diff",      args: "base=a3f912e..HEAD",        ok: true, ms:  180 },
        { name: "file.read",     args: "7 paths",                    ok: true, ms:  610 },
      ],
      renderedPrompt:
        "Read PR #1428 from acme/ledger.\n" +
        "Return the changed files, a one-line title, and the author handle.",
      result: {
        files: [
          "src/ledger/migrate_20260518.sql",
          "src/ledger/writes.ts",
          "src/auth/middleware.ts",
          "src/auth/roles.ts",
          "src/cli/audit_log.ts",
          "tests/ledger.test.ts",
          "package.json",
        ],
        title: "Add audit log to ledger writes",
        author: "@li-wei",
        additions: 412,
        deletions: 118,
      },
    },
  ],
  classify: [
    {
      id: "ex_classify_1",
      label: "execution",
      status: "passed",
      startedAt: "+00:19",
      durMs: 924,
      tokens: 3_110,
      tools: [{ name: "reasoning", args: "", ok: true, ms: 924 }],
      renderedPrompt:
        "Given [src/ledger/migrate_20260518.sql, src/ledger/writes.ts, src/auth/middleware.ts, " +
        "src/auth/roles.ts, src/cli/audit_log.ts, tests/ledger.test.ts, package.json] (412/-118),\n" +
        "rate the change risk. Reasons drive routing — be specific.",
      result: {
        risk: "high",
        reasons: ["db migration", "auth middleware touched", "no new tests for auth path"],
        security_relevant: true,
      },
    },
  ],
  route_risk: [
    {
      id: "ex_route_1",
      label: "execution",
      status: "passed",
      startedAt: "+00:34",
      durMs: 12,
      tokens: 0,
      tools: [],
      renderedPrompt: null,    // routing operator
      result: { chose: ["full_review", "security_scan"], skipped: ["quick_review"] },
    },
  ],
  full_review: [
    {
      id: "ex_full_1",
      label: "attempt 1",
      status: "failed",
      startedAt: "+00:35",
      durMs: 73_400,
      tokens: 18_002,
      tools: [
        { name: "code.search",       args: "audit_log",          ok: true,  ms: 1_200 },
        { name: "code.review.semantic", args: "src/auth/*.ts",   ok: false, ms: 70_000 },
      ],
      renderedPrompt:
        "Review [src/ledger/migrate_20260518.sql, src/ledger/writes.ts, src/auth/middleware.ts, " +
        "src/auth/roles.ts, src/cli/audit_log.ts, tests/ledger.test.ts, package.json] on diff `a3f912e..HEAD`.\n" +
        "Use code.search to ground claims in existing call sites.\n" +
        "Focus areas: [db migration, auth middleware touched, no new tests for auth path].",
      error: {
        code: "MODEL_TIMEOUT",
        message: "sonnet-4.5 did not return within 60s. Retrying with the same prompt.",
      },
    },
    {
      id: "ex_full_2",
      label: "attempt 2",
      status: "running",
      startedAt: "+02:02",
      durMs: 125_200,
      tokens: 38_402,
      progress: 0.62,
      tools: [
        { name: "code.search",          args: "audit_log",      ok: true,  ms:  860 },
        { name: "code.review.semantic", args: "src/auth/*.ts",  ok: null,  ms: 0, running: true },
      ],
      renderedPrompt:
        "Review [src/ledger/migrate_20260518.sql, src/ledger/writes.ts, src/auth/middleware.ts, " +
        "src/auth/roles.ts, src/cli/audit_log.ts, tests/ledger.test.ts, package.json] on diff `a3f912e..HEAD`.\n" +
        "Use code.search to ground claims in existing call sites.\n" +
        "Focus areas: [db migration, auth middleware touched, no new tests for auth path].",
      streaming: "reading src/auth/middleware.ts · drafting comment on line 47…",
    },
  ],
  security_scan: [
    {
      id: "ex_sec_1",
      label: "execution",
      status: "running",
      startedAt: "+00:35",
      durMs: 211_600,
      tokens: 14_902,
      progress: 0.81,
      tools: [
        { name: "sec.semgrep",   args: "rulepack=core",          ok: true, ms: 12_400 },
        { name: "sec.gitleaks",  args: "scan",                    ok: true, ms:  3_100 },
        { name: "sec.dep_audit", args: "lockfile=package-lock", ok: null, ms: 60_000, running: true },
      ],
      renderedPrompt: null,
      streaming: "sec.dep_audit · resolving 412 transitive deps…",
    },
  ],
  quick_review: [
    { id: "ex_quick_0", label: "execution", status: "skipped", startedAt: "+00:35", durMs: 0, tokens: 0, tools: [], skipReason: "route_risk chose [full_review, security_scan]" },
  ],
  per_file: [
    { id: "ex_map_iter", label: "fan-out · 0/7 iterations done", status: "queued", startedAt: "—", durMs: 0, tokens: 0, tools: [] },
  ],
  comment_file: [
    { id: "ex_cf_q", label: "map body · queued", status: "queued", startedAt: "—", durMs: 0, tokens: 0, tools: [] },
  ],
  join_reviews: [
    { id: "ex_join_q", label: "execution", status: "queued", startedAt: "—", durMs: 0, tokens: 0, tools: [], waitsFor: ["full_review", "security_scan", "per_file"] },
  ],
  critic:    [{ id: "ex_critic_q",    label: "execution", status: "queued", startedAt: "—", durMs: 0, tokens: 0, tools: [] }],
  satisfied: [{ id: "ex_satisfied_q", label: "execution", status: "queued", startedAt: "—", durMs: 0, tokens: 0, tools: [] }],
  post:      [{ id: "ex_post_q",      label: "execution", status: "queued", startedAt: "—", durMs: 0, tokens: 0, tools: [] }],
};

// Connection identifiers used by the workflow editor — these are the single
// "provider/model connection" tokens you'd see in a real settings panel.
const CONNECTIONS = [
  { id: "anthropic-haiku-4.5",  label: "Anthropic · haiku-4.5",  hint: "fast" },
  { id: "anthropic-sonnet-4.5", label: "Anthropic · sonnet-4.5", hint: "balanced" },
  { id: "anthropic-opus-4.1",   label: "Anthropic · opus-4.1",   hint: "best" },
  { id: "openai-gpt-5",         label: "OpenAI · gpt-5",         hint: "balanced" },
  { id: "openai-gpt-5-mini",    label: "OpenAI · gpt-5-mini",    hint: "fast" },
  { id: "google-gemini-2.5",    label: "Google · gemini-2.5-pro",hint: "balanced" },
  { id: "local-llama-3.1-70b",  label: "Local · llama-3.1-70b",  hint: "self-hosted" },
];

// Mock attached configs — structured objects associated with workers.
// In a real system these live outside the editor and are referenced by id.
const ATTACHED_CONFIGS = {
  full_review: [
    { id: "cfg_review_rubric_v3", name: "review_rubric.json",  size: "1.2 kB" },
    { id: "cfg_blocking_paths",   name: "blocking_paths.yaml", size: "320 B"  },
  ],
  classify: [
    { id: "cfg_risk_buckets", name: "risk_buckets.yaml", size: "180 B" },
  ],
  security_scan: [
    { id: "cfg_semgrep_pack",  name: "semgrep_rules.tar", size: "44 kB" },
    { id: "cfg_dep_allowlist", name: "dep_allowlist.txt", size: "812 B" },
  ],
  ingest: [],
  post:   [],
  quick_review: [],
  comment_file: [],
};

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
  { id: "r_8f2a4b1", workflow: "eval-harness",   status: "running",   started: "14:16", dur: "5m51s", cost: "$1.12", input: "suite/regress", by: "jen.b" },
  { id: "r_8f2a103", workflow: "flake-tracker",  status: "paused",    started: "14:14", dur: "8m02s", cost: "$0.08", input: "ci-main",   by: "cron" },
  { id: "r_8f29d52", workflow: "pr-reviewer",    status: "queued",    started: "14:13", dur: "—",     cost: "—",     input: "PR #1429",  by: "webhook" },
  { id: "r_8f29442", workflow: "pr-reviewer",    status: "passed",    started: "14:12", dur: "3m44s", cost: "$0.31", input: "PR #1427",  by: "webhook" },
  { id: "r_8f28a01", workflow: "eval-harness",   status: "failed",    started: "14:07", dur: "8m12s", cost: "$1.84", input: "suite/all", by: "jen.b" },
  { id: "r_8f27b3d", workflow: "flake-tracker",  status: "passed",    started: "14:03", dur: "0m48s", cost: "$0.04", input: "ci-main",   by: "cron"  },
  { id: "r_8f26108", workflow: "pr-reviewer",    status: "passed",    started: "13:58", dur: "2m18s", cost: "$0.22", input: "PR #1426",  by: "webhook" },
  { id: "r_8f25fa2", workflow: "pr-reviewer",    status: "retrying",  started: "13:54", dur: "5m10s", cost: "$0.38", input: "PR #1425",  by: "webhook" },
  { id: "r_8f24c0e", workflow: "release-notes",  status: "passed",    started: "13:01", dur: "1m12s", cost: "$0.09", input: "v0.42.1",   by: "jen.b" },
  { id: "r_8f23911", workflow: "pr-reviewer",    status: "cancelled", started: "12:55", dur: "0m22s", cost: "$0.02", input: "PR #1424",  by: "jen.b" },
  { id: "r_8f22a05", workflow: "doc-indexer",    status: "passed",    started: "12:11", dur: "12m04s", cost: "$0.91", input: "snapshot",  by: "cron" },
  { id: "r_8f21338", workflow: "changelog-summary", status: "passed", started: "11:42", dur: "0m38s", cost: "$0.05", input: "v0.42.0",   by: "jen.b" },
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

Object.assign(window, { WORKFLOW, JOB, SNAPSHOTS, WORKFLOWS_LIST, JOBS_LOG, STAGE_EXECUTIONS, CONNECTIONS, ATTACHED_CONFIGS, workflowToYaml });
