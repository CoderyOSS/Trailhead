# Workflow Template Revisions & Stage Snapshots

## Goal

Establish clean separation between **mutable workflow templates** (SQL-backed, free
edit) and **per-job immutable execution records** (revision history + stage outputs),
replacing today's tangled mix of one-way disk seeding, SQL-as-authority confusion,
and inert pause/resume mechanics.

## Why

Today's storage model is incoherent:

- `crates/trailhead-service/src/db.rs:949-957` — `workflows` table stores template
  content in SQL.
- `crates/trailhead-service/src/main.rs:104` — `seed_builtin_workflows` reads YAML
  files from `/opt/codery/trailhead/workflows` into SQL at startup (one-way sync).
- `crates/trailhead-service/src/web.rs:228-235` — `POST /workflows` writes only to
  SQL with `content_hash=""`, so the next seed cycle silently overwrites user edits.
- `crates/trailhead-service/src/db.rs:806-837` — seed is one-way (disk → DB), never
  reverses, never deletes rows whose YAML was removed.
- No mechanism to record what workflow content a running job is actually using.
- `checkpoints` table exists but is not wired to scheduler; "snapshot" terminology
  is overloaded between "structure snapshot" and "stage output."

The user's stated intent: **workflow templates live in SQL** (avoids accidental
deletion), are **mutable** (free edit), and **per-job execution follows an immutable
record** of the template content captured at launch. **Stage outputs are snapshots**
(runtime data, separate concept). **Manual refresh** pulls the current template into
a paused job as a new revision row.

## Scope

### In scope

- `crates/trailhead-service/src/db.rs` — schema changes
- `crates/trailhead-service/src/main.rs` — remove seed call, add config load
- `crates/trailhead-service/src/config.rs` — add `[storage]` section
- `crates/trailhead-service/src/workflow/mod.rs` — read from revisions, not templates
- `crates/trailhead-service/src/scheduler.rs` — refresh-workflow flow, snapshot writes
- `crates/trailhead-service/src/web.rs` — new endpoints (PUT/DELETE workflows,
  refresh-workflow, revisions list)
- `crates/trailhead-service/src/api.rs` — internal API routes
- `crates/trailhead-service/src/mcp.rs` — new MCP tools
- `crates/trailhead-service/src/jobs.rs` — pause-required guard for refresh

### Out of scope (later specs)

- Project materialization (clone-on-add, sync, project state columns)
- Skills runtime injection (mount skills dir, prepend to prompt, MCP skill tool)
- Config consolidation (unified `/opt/codery/trailhead/{config.toml, secrets/}` root)
- Plugin system (WASM / native / scripting — deferred, plugin dir exists but unused)
- Package manager (workflow/skill install, registry client)
- Filesystem watching for templates (manual refresh only)

## Design

### Storage layout

```
SQL DB
├── workflows              mutable templates (free edit, authority)
├── job_workflow_revisions per-job immutable history of template content used
├── stage_snapshots        stage outputs (renamed from `checkpoints`)
├── jobs, workers, projects  unchanged

Disk
├── /opt/codery/trailhead/
│   ├── config.toml
│   ├── skills/*.md         (Phase 2 wiring, dir created now)
│   ├── plugins/            (Phase 3, dir created now)
│   └── secrets/            (one file per credential, path configurable)
└── /opt/codery/workspaces/  (project paths, Phase 2)
```

Templates live in SQL (survive accidental FS deletion, atomic transactions). Skills,
plugins, secrets stay on disk (they are referenced by file path from stages and
workers, not parsed into the binary).

### SQL schema changes

#### `workflows` (modified)

```sql
-- Existing columns kept: id, name, content, created_at, updated_at
-- Dropped: source, content_hash, project_id
-- (source was only used by seed sync; content_hash same; project_id was inert)
```

The `workflows` row is the current authoritative template content. All mutations
go through `PUT /workflows/{name}` (replace) or `POST /workflows` (create). Reads
via `GET /workflows` / `GET /workflows/{name}` return current content.

#### `job_workflow_revisions` (new)

```sql
CREATE TABLE IF NOT EXISTS job_workflow_revisions (
    id           TEXT PRIMARY KEY,
    job_id       TEXT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    ordinal      INTEGER NOT NULL,
    workflow_name TEXT NOT NULL,
    content      TEXT NOT NULL,
    content_hash TEXT NOT NULL,
    source       TEXT NOT NULL,   -- "launch" | "refresh" | "rollback"
    created_at   TEXT NOT NULL,
    UNIQUE(job_id, ordinal)
);
CREATE INDEX idx_job_workflow_revisions_job_id ON job_workflow_revisions(job_id);
```

- Written at job launch (ordinal=0, source="launch") — copies current template
  content into the row, snapshotting what the job started with.
- Appended on `POST /jobs/{id}/refresh-workflow` (source="refresh") — copies
  current template content at refresh time.
- Appended on rollback (source="rollback") — see Rollback below.
- `content_hash` is SHA-256 of normalized content (whitespace-stable), used for
  change detection and dedup (consecutive identical refreshes are no-ops).

#### `jobs` (modified)

```sql
ALTER TABLE jobs ADD COLUMN current_revision_id TEXT REFERENCES job_workflow_revisions(id);
ALTER TABLE jobs ADD COLUMN current_stage_index INTEGER DEFAULT 0;
```

- `current_revision_id` — points to the revision row the scheduler is currently
  executing against. Updated on launch and on successful refresh.
- `current_stage_index` — explicit stage cursor (0-based) for resume-after-pause.
  Replaces ad-hoc `current_stage` string lookup; survives stage renames in
  refreshed revisions (stage is identified by index in the stages map, with a
  fallback name-match check at resume time — see Stage resolution below).

#### `stage_snapshots` (renamed from `checkpoints`)

```sql
-- Rename: checkpoints → stage_snapshots
-- Existing columns kept: id, job_id, stage_name, git_sha, commit_message, created_at
-- Added:
ALTER TABLE stage_snapshots ADD COLUMN output TEXT;
ALTER TABLE stage_snapshots ADD COLUMN revision_id TEXT REFERENCES job_workflow_revisions(id);
ALTER TABLE stage_snapshots ADD COLUMN stage_index INTEGER;
```

- `output` — the stage's result text (LLM completion, tool output, etc.). This is
  the "snapshot" in user terminology.
- `revision_id` — which workflow revision was in effect when this snapshot was
  produced. Provides full audit trail.
- `stage_index` — the stage's position in the revision's stages map. Survives
  renames between revisions.

#### Migration order (additive, idempotent)

```sql
-- 1. Create new table
CREATE TABLE IF NOT EXISTS job_workflow_revisions ( ... );

-- 2. Add jobs columns
ALTER TABLE jobs ADD COLUMN current_revision_id TEXT;
ALTER TABLE jobs ADD COLUMN current_stage_index INTEGER DEFAULT 0;

-- 3. Rename checkpoints (SQLite ≥ 3.25 supports ALTER TABLE RENAME)
ALTER TABLE checkpoints RENAME TO stage_snapshots;

-- 4. Add stage_snapshots columns
ALTER TABLE stage_snapshots ADD COLUMN output TEXT;
ALTER TABLE stage_snapshots ADD COLUMN revision_id TEXT;
ALTER TABLE stage_snapshots ADD COLUMN stage_index INTEGER;

-- 5. Drop obsolete workflows columns (SQLite supports since 3.35)
--    Done in a follow-up migration once backfill is verified.
--    For now: leave columns, ignore in reads/writes.

-- (Backfill is a code function, not in the MIGRATIONS array — see below.)
```

All schema migrations are added to the `MIGRATIONS` array in `db.rs` and executed
individually (per AGENTS.md convention). Each is wrapped in `IF NOT EXISTS` /
guarded by column-existence probe to be idempotent.

**Backfill** (data migration, not schema) runs as a separate function
`backfill_job_revisions(db) -> Result<()>` invoked once at daemon startup after
schema migrations complete. Logic:

```rust
fn backfill_job_revisions(db: &Db) -> Result<()> {
    let jobs_missing_revision = db.query(
        "SELECT j.id, j.workflow_name FROM jobs j
         LEFT JOIN job_workflow_revisions r ON r.job_id = j.id
         WHERE r.id IS NULL"
    )?;
    for (job_id, workflow_name) in jobs_missing_revision {
        let workflow = db.get_workflow(&workflow_name)?;
        let hash = normalize_and_hash(&workflow.content);
        let rev_id = new_id();
        db.execute(
            "INSERT INTO job_workflow_revisions
             (id, job_id, ordinal, workflow_name, content, content_hash, source, created_at)
             VALUES (?, ?, 0, ?, ?, ?, 'launch', ?)",
            params![rev_id, job_id, workflow_name, workflow.content, hash, now()]
        )?;
        db.execute(
            "UPDATE jobs SET current_revision_id = ? WHERE id = ?",
            params![rev_id, job_id]
        )?;
    }
    Ok(())
}
```

Function is idempotent: the `LEFT JOIN ... IS NULL` guard means subsequent
startup runs are no-ops once all jobs have at least one revision row.

### API changes

#### Workflows (templates)

| Method | Path | Behavior |
|---|---|---|
| `GET` | `/api/v1/workflows` | List template names (unchanged) |
| `GET` | `/api/v1/workflows/{name}` | Get current template content (unchanged) |
| `POST` | `/api/v1/workflows` | Create template (unchanged, but sets `content_hash` correctly) |
| `PUT` | `/api/v1/workflows/{name}` | **NEW** — replace template content |
| `DELETE` | `/api/v1/workflows/{name}` | **NEW** — remove template |
| `POST` | `/api/v1/workflows/validate` | Validate YAML (unchanged) |
| `POST` | `/api/v1/workflows/seed` | **REMOVED** — seeding was one-way sync, no longer needed |

#### Jobs

| Method | Path | Behavior |
|---|---|---|
| `POST` | `/api/v1/jobs` | At launch, writes `job_workflow_revisions[0]` row, sets `current_revision_id`. Body unchanged. |
| `POST` | `/api/v1/jobs/{id}/pause` | Unchanged. Required before `refresh-workflow`. |
| `POST` | `/api/v1/jobs/{id}/resume` | Picks up from `current_stage_index` against `current_revision_id`. |
| `POST` | `/api/v1/jobs/{id}/refresh-workflow` | **NEW** — see below |
| `GET` | `/api/v1/jobs/{id}/revisions` | **NEW** — list revision history |
| `POST` | `/api/v1/jobs/{id}/rollback` | **NEW** — set `current_revision_id` back to a prior revision; append a synthetic revision row with `source="rollback"` for auditability. |

#### `POST /api/v1/jobs/{id}/refresh-workflow`

Request body: empty (uses job's `workflow_name` to look up current template) or
optional `{"workflow_name": "..."}` to switch templates entirely.

Preconditions:
- Job must be in `paused` status. Returns `409 Conflict` if not.
- Workflow template must exist. Returns `404` if missing.

Behavior:
1. Look up current template content from `workflows` table.
2. Compute `content_hash`.
3. Compare to `current_revision_id`'s `content_hash`. If identical, return `204 No Content` (no-op).
4. Insert new `job_workflow_revisions` row with `ordinal = max+1`, `source = "refresh"`.
5. Update `jobs.current_revision_id` to new row.
6. Return `200 OK` with `{"revision_id": "...", "ordinal": N, "content_hash": "..."}`.

#### `POST /api/v1/jobs/{id}/rollback`

Request body: `{"to_revision_id": "..."}` or `{"to_ordinal": N}`.

Preconditions:
- Job must be `paused`.
- Target revision must belong to this job.

Behavior:
1. Validate target revision exists for this job.
2. Append a new `job_workflow_revisions` row copying the target's content with
   `source = "rollback"`, `ordinal = max+1`. (Append-only audit trail; rollback
   does not delete later revisions.)
3. Update `jobs.current_revision_id` to new row.
4. Caller may also reset `current_stage_index` via separate param
   `{"to_stage_index": N}` to rewind execution position.
5. Return `200 OK` with summary.

### MCP tools

| Tool | Behavior |
|---|---|
| `workflows_refresh_job(job_id, workflow_name?)` | Wraps `POST /jobs/{id}/refresh-workflow` |
| `jobs_list_revisions(job_id)` | Wraps `GET /jobs/{id}/revisions` |
| `jobs_rollback(job_id, to_revision_id \| to_ordinal, to_stage_index?)` | Wraps `POST /jobs/{id}/rollback` |

Existing `workflows_create` is unchanged. Add `workflows_replace` and
`workflows_delete` mirroring PUT/DELETE.

### Job lifecycle

```
LAUNCH (POST /api/v1/jobs)
  1. Validate workflow_name exists in `workflows` table.
  2. Read current template content.
  3. INSERT job_workflow_revisions[id, job_id, ordinal=0, content, hash,
                                   source="launch", created_at]
  4. UPDATE jobs SET current_revision_id = ^, current_stage_index = 0
  5. Schedule.

STAGE EXECUTION (scheduler.rs)
  1. Fetch jobs.current_revision_id → revision row → content.
  2. parse_workflow(content) → Workflow.
  3. workflow.stages[current_stage_index] → Stage.
  4. Resolve prompt (skill content injected — Phase 2; today: prompt only).
  5. Send to worker.
  6. Receive output.
  7. INSERT stage_snapshots[id, job_id, revision_id, stage_index,
                            stage_name, output, git_sha?, commit_message?].
  8. UPDATE jobs SET current_stage_index = current_stage_index + 1.
  9. Determine next stage via Stage.routes evaluation.
     - If next stage exists, loop.
     - If no next stage, mark job completed.

PAUSE (POST /jobs/{id}/pause)
  1. If currently running a stage, wait for stage to complete or timeout.
  2. Update jobs.status = "paused".
  3. Persist current_stage_index.

REFRESH (POST /jobs/{id}/refresh-workflow)
  1. Require status = "paused" (409 if not).
  2. Read latest template content.
  3. Hash-compare to current revision. No-op if identical.
  4. Append new revision row (source="refresh").
  5. Update jobs.current_revision_id.

RESUME (POST /jobs/{id}/resume)
  1. Require status = "paused".
  2. Read jobs.current_revision_id, current_stage_index.
  3. Update status = "running".
  4. Scheduler picks up: continues from current_stage_index against current
     revision's content.

EDIT TEMPLATE (PUT /api/v1/workflows/{name})
  1. Validate YAML.
  2. Compute content_hash.
  3. UPDATE workflows SET content = $1, content_hash = $2, updated_at = now
     WHERE name = $3.
  4. Does NOT touch any jobs. Jobs continue running against their current
     revision until user explicitly refreshes.

DELETE TEMPLATE (DELETE /api/v1/workflows/{name})
  1. Allowed even if jobs reference the template (jobs have their own copy
     in job_workflow_revisions).
  2. DELETE FROM workflows WHERE name = $1.
```

### Stage resolution on resume

When `current_stage_index` was set against a prior revision and the user has
since refreshed to a revision with different stage structure:

1. Try `current_stage_index` directly in the new revision's stages map.
2. If the index is out of bounds (new revision is shorter), fall back to:
   - Match by stage name from the prior revision's stage at that index.
   - If found at a different index, use the new index and update
     `current_stage_index`.
   - If not found (stage deleted), resume at the closest earlier index
     that exists in both. Log a warning.
3. If new revision is longer (stages appended), `current_stage_index` is
   valid and execution continues; new stages will be reached normally.

This logic lives in `scheduler.rs::resume_job`.

### Config keys (new in `config.toml`)

```toml
[storage]
skills_dir  = "/opt/codery/trailhead/skills"
plugins_dir = "/opt/codery/trailhead/plugins"
secrets_dir = "/opt/codery/trailhead/secrets"
```

- `workflows_dir` is **not** a config key (workflows live in SQL).
- `projects_dir` / `project_base` already exists as `PROJECT_BASE` env var;
  promoting to config is Phase 2.
- All defaults point under `/opt/codery/trailhead/` (the existing install root).
- Hardcoded paths in `main.rs:105`, `scheduler.rs:179`, `docker.rs:62`,
  `mcp.rs:283/303/319`, `api.rs:112-114, 161-163` are replaced with config
  reads. Single source of truth.

### Removal of `seed_builtin_workflows`

The function at `db.rs:806-837` and its call at `main.rs:104` are deleted.
The 6 YAML files currently in `crates/trailhead-service/workflows/` are
migrated into SQL via a one-time migration script (run on first deploy of
this change):

```bash
# scripts/migrate-seed-workflows.sh (run once per install)
for f in /opt/codery/trailhead/workflows/*.yaml; do
  name=$(basename "$f" .yaml)
  content=$(cat "$f")
  curl -X POST http://localhost:4050/api/v1/workflows \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$name\", \"content\": $(jq -Rs . <<<"$content")}"
done
```

Future workflow additions happen via API/CLI, not file placement.

## Risks

### Risk: Existing paused/running jobs at migration time

**Mitigation**: Migration backfills `job_workflow_revisions[0]` for every
existing job by joining `jobs.workflow_name → workflows.content`. Even paused
jobs get a valid revision row. The `current_stage_index` defaults to 0; if
the job had progressed, manual fixup via `POST /jobs/{id}/rollback` with
`to_stage_index` is available.

### Risk: Silent workflow template deletion while jobs reference it

**Mitigation**: Deletion is allowed (jobs have their own copy in
`job_workflow_revisions`), but `GET /jobs/{id}/revisions` always shows the
template name and content at capture time. No data is lost.

### Risk: Hash drift between launch and refresh if YAML normalization changes

**Mitigation**: `normalize_and_hash` (already in `db.rs:839-855`) is kept as
the canonical hashing function. Tests cover round-trip stability.

### Risk: Stage index instability across refresh

**Mitigation**: Stage resolution fallback (above) handles renames, deletions,
and appends. New revisions with reordered stages are a known gap — user
must `rollback` to recover.

### Risk: PAUSE blocks indefinitely if worker is hung mid-stage

**Mitigation**: Existing pause flow already has a timeout. Refresh requires
pause, so hung jobs block refresh indefinitely. Acceptable for v1; Phase 2
will add force-cancel-then-refresh.

## Testing

### Unit tests

- `db.rs` — round-trip `create_workflow` / `replace_workflow` / `delete_workflow`
- `db.rs` — `create_job_with_revision` writes `job_workflow_revisions[0]`
- `db.rs` — `refresh_job_workflow` dedups identical content
- `db.rs` — `rollback_job_workflow` appends synthetic revision row
- `db.rs` — stage_snapshots writes with revision_id and stage_index
- `scheduler.rs` — stage resolution fallback (rename, delete, append, reorder)
- `web.rs` — refresh returns 409 if job not paused
- `web.rs` — refresh returns 204 if content unchanged

### Integration tests (`tests/probes/`)

- Launch job → pause → edit template → refresh → resume → new structure applies
- Launch job → pause → refresh with no-op content → resume → no spurious revision
- Launch job → complete → rollback to revision 0 → verify audit row appended
- Migration test: existing DB with `workflows` rows + `jobs` rows backfills
  revisions correctly

### E2E test

- Use `test-workspace/` as project_path.
- Create workflow with single stage.
- Launch job, wait for stage to write snapshot.
- Pause, edit workflow to add second stage, refresh.
- Resume, verify second stage runs and consumes first stage's snapshot.

## Open questions (non-blocking)

1. **Stage output size**: should `stage_snapshots.output` be TEXT (unbounded) or
   BLOB with size cap + spill-to-file for large outputs? Defer to first
   encounter of a >1MB output.
2. **Concurrent refresh attempts**: two clients call refresh simultaneously.
   SQLite serialization handles this naturally but should be tested.
3. **Template deletion UI affordance**: should `DELETE /workflows/{name}` require
   a `?force=true` if any jobs reference the template name? Probably not —
   jobs have their own copy — but UX may want a warning.
