CREATE TABLE IF NOT EXISTS projects (
    id          TEXT PRIMARY KEY,
    repo_url    TEXT NOT NULL,
    branch      TEXT NOT NULL DEFAULT 'main',
    created_at  TEXT NOT NULL,
    updated_at  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS jobs (
    id              TEXT PRIMARY KEY,
    project_id      TEXT NOT NULL REFERENCES projects(id),
    description     TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'queued',
    worker_id       TEXT,
    branch          TEXT,
    workflow_name   TEXT,
    current_stage   TEXT,
    stage_history   TEXT DEFAULT '[]',
    attempt         INTEGER NOT NULL DEFAULT 1,
    max_attempts    INTEGER NOT NULL DEFAULT 3,
    result          TEXT,
    error           TEXT,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL,
    started_at      TEXT,
    finished_at     TEXT
);

CREATE TABLE IF NOT EXISTS workers (
    id              TEXT PRIMARY KEY,
    job_id          TEXT REFERENCES jobs(id),
    provider        TEXT NOT NULL,
    provider_id     TEXT,
    status          TEXT NOT NULL DEFAULT 'creating',
    ip_address      TEXT,
    workspace_path  TEXT,
    heartbeat_at    TEXT,
    created_at      TEXT NOT NULL,
    destroyed_at    TEXT
);

CREATE TABLE IF NOT EXISTS checkpoints (
    id              TEXT PRIMARY KEY,
    job_id          TEXT NOT NULL REFERENCES jobs(id),
    stage           TEXT NOT NULL,
    response        TEXT NOT NULL,
    session_path    TEXT NOT NULL,
    git_sha         TEXT NOT NULL,
    token_usage     TEXT,
    files_changed   TEXT DEFAULT '[]',
    created_at      TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS prompt_history (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    job_id          TEXT NOT NULL REFERENCES jobs(id),
    stage           TEXT NOT NULL,
    role            TEXT NOT NULL,
    content         TEXT NOT NULL,
    tool_calls      TEXT,
    tool_results    TEXT,
    token_usage     TEXT,
    created_at      TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS workflows (
    name            TEXT PRIMARY KEY,
    content         TEXT NOT NULL,
    source          TEXT NOT NULL,
    project_id      TEXT REFERENCES projects(id),
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_project ON jobs(project_id);
CREATE INDEX IF NOT EXISTS idx_workers_job ON workers(job_id);
CREATE INDEX IF NOT EXISTS idx_checkpoints_job ON checkpoints(job_id);
