use anyhow::Result;
use chrono::Utc;
use rusqlite::params;

#[derive(Debug, Clone)]
pub struct ProjectRow {
    pub id: String,
    pub repo_url: String,
    pub branch: String,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Clone)]
pub struct JobRow {
    pub id: String,
    pub project_id: String,
    pub description: String,
    pub status: String,
    pub worker_id: Option<String>,
    pub branch: Option<String>,
    pub workflow_name: Option<String>,
    pub current_stage: Option<String>,
    pub stage_history: String,
    pub attempt: i32,
    pub max_attempts: i32,
    pub result: Option<String>,
    pub error: Option<String>,
    pub created_at: String,
    pub updated_at: String,
    pub started_at: Option<String>,
    pub finished_at: Option<String>,
}

#[derive(Debug, Clone)]
pub struct WorkerRow {
    pub id: String,
    pub job_id: Option<String>,
    pub provider: String,
    pub provider_id: Option<String>,
    pub status: String,
    pub ip_address: Option<String>,
    pub workspace_path: Option<String>,
    pub heartbeat_at: Option<String>,
    pub created_at: String,
    pub destroyed_at: Option<String>,
}

#[derive(Debug, Clone)]
pub struct CheckpointRow {
    pub id: String,
    pub job_id: String,
    pub stage: String,
    pub response: String,
    pub session_path: String,
    pub git_sha: String,
    pub token_usage: Option<String>,
    pub files_changed: String,
    pub created_at: String,
}

#[derive(Debug, Clone)]
pub struct WorkflowRow {
    pub name: String,
    pub content: String,
    pub source: String,
    pub project_id: Option<String>,
    pub created_at: String,
    pub updated_at: String,
}

pub struct Database {
    conn: std::sync::Mutex<rusqlite::Connection>,
}

impl Database {
    pub fn open(path: &str) -> Result<Self> {
        let conn = rusqlite::Connection::open(path)?;
        conn.execute_batch("PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON;")?;
        conn.execute_batch(SCHEMA)?;
        Ok(Self {
            conn: std::sync::Mutex::new(conn),
        })
    }

    pub fn create_project(&self, id: &str, repo_url: &str, branch: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        conn.execute(
            "INSERT INTO projects (id, repo_url, branch, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5)",
            params![id, repo_url, branch, now, now],
        )?;
        Ok(())
    }

    pub fn get_project(&self, id: &str) -> Result<Option<ProjectRow>> {
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        let mut stmt = conn.prepare(
            "SELECT id, repo_url, branch, created_at, updated_at FROM projects WHERE id = ?1",
        )?;
        let row = stmt.query_row(params![id], |row| {
            Ok(ProjectRow {
                id: row.get(0)?,
                repo_url: row.get(1)?,
                branch: row.get(2)?,
                created_at: row.get(3)?,
                updated_at: row.get(4)?,
            })
        });
        match row {
            Ok(r) => Ok(Some(r)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    pub fn list_projects(&self) -> Result<Vec<ProjectRow>> {
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        let mut stmt = conn.prepare(
            "SELECT id, repo_url, branch, created_at, updated_at FROM projects ORDER BY created_at",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(ProjectRow {
                id: row.get(0)?,
                repo_url: row.get(1)?,
                branch: row.get(2)?,
                created_at: row.get(3)?,
                updated_at: row.get(4)?,
            })
        })?;
        let mut result = Vec::new();
        for r in rows {
            result.push(r?);
        }
        Ok(result)
    }

    pub fn create_job(
        &self,
        id: &str,
        project_id: &str,
        description: &str,
        workflow_name: Option<&str>,
        branch: Option<&str>,
    ) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        conn.execute(
            "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
            params![id, project_id, description, workflow_name, branch, now, now],
        )?;
        Ok(())
    }

    pub fn get_job(&self, id: &str) -> Result<Option<JobRow>> {
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        let row = conn.query_row(
            "SELECT id, project_id, description, status, worker_id, branch, workflow_name, current_stage, stage_history, attempt, max_attempts, result, error, created_at, updated_at, started_at, finished_at FROM jobs WHERE id = ?1",
            params![id],
            |row| {
                Ok(JobRow {
                    id: row.get(0)?,
                    project_id: row.get(1)?,
                    description: row.get(2)?,
                    status: row.get(3)?,
                    worker_id: row.get(4)?,
                    branch: row.get(5)?,
                    workflow_name: row.get(6)?,
                    current_stage: row.get(7)?,
                    stage_history: row.get(8)?,
                    attempt: row.get(9)?,
                    max_attempts: row.get(10)?,
                    result: row.get(11)?,
                    error: row.get(12)?,
                    created_at: row.get(13)?,
                    updated_at: row.get(14)?,
                    started_at: row.get(15)?,
                    finished_at: row.get(16)?,
                })
            },
        );
        match row {
            Ok(r) => Ok(Some(r)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    pub fn list_jobs(&self) -> Result<Vec<JobRow>> {
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        let mut stmt = conn.prepare(
            "SELECT id, project_id, description, status, worker_id, branch, workflow_name, current_stage, stage_history, attempt, max_attempts, result, error, created_at, updated_at, started_at, finished_at FROM jobs ORDER BY created_at",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(JobRow {
                id: row.get(0)?,
                project_id: row.get(1)?,
                description: row.get(2)?,
                status: row.get(3)?,
                worker_id: row.get(4)?,
                branch: row.get(5)?,
                workflow_name: row.get(6)?,
                current_stage: row.get(7)?,
                stage_history: row.get(8)?,
                attempt: row.get(9)?,
                max_attempts: row.get(10)?,
                result: row.get(11)?,
                error: row.get(12)?,
                created_at: row.get(13)?,
                updated_at: row.get(14)?,
                started_at: row.get(15)?,
                finished_at: row.get(16)?,
            })
        })?;
        let mut result = Vec::new();
        for r in rows {
            result.push(r?);
        }
        Ok(result)
    }

    pub fn update_job_status(&self, id: &str, status: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        conn.execute(
            "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
            params![status, now, id],
        )?;
        Ok(())
    }

    pub fn update_job_stage(&self, id: &str, stage: &str, stage_history: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        conn.execute(
            "UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4",
            params![stage, stage_history, now, id],
        )?;
        Ok(())
    }

    pub fn assign_worker(&self, job_id: &str, worker_id: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        conn.execute(
            "UPDATE jobs SET worker_id = ?1, updated_at = ?2 WHERE id = ?3",
            params![worker_id, now, job_id],
        )?;
        Ok(())
    }

    pub fn get_queued_jobs(&self) -> Result<Vec<JobRow>> {
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        let mut stmt = conn.prepare(
            "SELECT id, project_id, description, status, worker_id, branch, workflow_name, current_stage, stage_history, attempt, max_attempts, result, error, created_at, updated_at, started_at, finished_at FROM jobs WHERE status = 'queued' ORDER BY created_at ASC",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(JobRow {
                id: row.get(0)?,
                project_id: row.get(1)?,
                description: row.get(2)?,
                status: row.get(3)?,
                worker_id: row.get(4)?,
                branch: row.get(5)?,
                workflow_name: row.get(6)?,
                current_stage: row.get(7)?,
                stage_history: row.get(8)?,
                attempt: row.get(9)?,
                max_attempts: row.get(10)?,
                result: row.get(11)?,
                error: row.get(12)?,
                created_at: row.get(13)?,
                updated_at: row.get(14)?,
                started_at: row.get(15)?,
                finished_at: row.get(16)?,
            })
        })?;
        let mut result = Vec::new();
        for r in rows {
            result.push(r?);
        }
        Ok(result)
    }

    pub fn get_active_jobs(&self) -> Result<Vec<JobRow>> {
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        let mut stmt = conn.prepare(
            "SELECT id, project_id, description, status, worker_id, branch, workflow_name, current_stage, stage_history, attempt, max_attempts, result, error, created_at, updated_at, started_at, finished_at FROM jobs WHERE status IN ('scheduled', 'provisioning', 'running', 'checkpointing')",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(JobRow {
                id: row.get(0)?,
                project_id: row.get(1)?,
                description: row.get(2)?,
                status: row.get(3)?,
                worker_id: row.get(4)?,
                branch: row.get(5)?,
                workflow_name: row.get(6)?,
                current_stage: row.get(7)?,
                stage_history: row.get(8)?,
                attempt: row.get(9)?,
                max_attempts: row.get(10)?,
                result: row.get(11)?,
                error: row.get(12)?,
                created_at: row.get(13)?,
                updated_at: row.get(14)?,
                started_at: row.get(15)?,
                finished_at: row.get(16)?,
            })
        })?;
        let mut result = Vec::new();
        for r in rows {
            result.push(r?);
        }
        Ok(result)
    }

    pub fn fail_job(&self, id: &str, error: &str, status: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        conn.execute(
            "UPDATE jobs SET error = ?1, status = ?2, finished_at = ?3, updated_at = ?4 WHERE id = ?5",
            params![error, status, now, now, id],
        )?;
        Ok(())
    }

    pub fn complete_job(&self, id: &str, result: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        conn.execute(
            "UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4",
            params![result, now, now, id],
        )?;
        Ok(())
    }

    pub fn create_worker(&self, id: &str, job_id: &str, provider: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        conn.execute(
            "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
            params![id, job_id, provider, now],
        )?;
        Ok(())
    }

    pub fn get_worker(&self, id: &str) -> Result<Option<WorkerRow>> {
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        let row = conn.query_row(
            "SELECT id, job_id, provider, provider_id, status, ip_address, workspace_path, heartbeat_at, created_at, destroyed_at FROM workers WHERE id = ?1",
            params![id],
            |row| {
                Ok(WorkerRow {
                    id: row.get(0)?,
                    job_id: row.get(1)?,
                    provider: row.get(2)?,
                    provider_id: row.get(3)?,
                    status: row.get(4)?,
                    ip_address: row.get(5)?,
                    workspace_path: row.get(6)?,
                    heartbeat_at: row.get(7)?,
                    created_at: row.get(8)?,
                    destroyed_at: row.get(9)?,
                })
            },
        );
        match row {
            Ok(r) => Ok(Some(r)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    pub fn list_workers(&self) -> Result<Vec<WorkerRow>> {
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        let mut stmt = conn.prepare(
            "SELECT id, job_id, provider, provider_id, status, ip_address, workspace_path, heartbeat_at, created_at, destroyed_at FROM workers ORDER BY created_at",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(WorkerRow {
                id: row.get(0)?,
                job_id: row.get(1)?,
                provider: row.get(2)?,
                provider_id: row.get(3)?,
                status: row.get(4)?,
                ip_address: row.get(5)?,
                workspace_path: row.get(6)?,
                heartbeat_at: row.get(7)?,
                created_at: row.get(8)?,
                destroyed_at: row.get(9)?,
            })
        })?;
        let mut result = Vec::new();
        for r in rows {
            result.push(r?);
        }
        Ok(result)
    }

    pub fn update_worker_status(&self, id: &str, status: &str) -> Result<()> {
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        conn.execute(
            "UPDATE workers SET status = ?1 WHERE id = ?2",
            params![status, id],
        )?;
        Ok(())
    }

    pub fn update_worker_heartbeat(&self, id: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        conn.execute(
            "UPDATE workers SET heartbeat_at = ?1 WHERE id = ?2",
            params![now, id],
        )?;
        Ok(())
    }

    pub fn get_workers_by_job(&self, job_id: &str) -> Result<Vec<WorkerRow>> {
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        let mut stmt = conn.prepare(
            "SELECT id, job_id, provider, provider_id, status, ip_address, workspace_path, heartbeat_at, created_at, destroyed_at FROM workers WHERE job_id = ?1 ORDER BY created_at",
        )?;
        let rows = stmt.query_map(params![job_id], |row| {
            Ok(WorkerRow {
                id: row.get(0)?,
                job_id: row.get(1)?,
                provider: row.get(2)?,
                provider_id: row.get(3)?,
                status: row.get(4)?,
                ip_address: row.get(5)?,
                workspace_path: row.get(6)?,
                heartbeat_at: row.get(7)?,
                created_at: row.get(8)?,
                destroyed_at: row.get(9)?,
            })
        })?;
        let mut result = Vec::new();
        for r in rows {
            result.push(r?);
        }
        Ok(result)
    }

    pub fn destroy_worker(&self, id: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        conn.execute(
            "UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2",
            params![now, id],
        )?;
        Ok(())
    }

    pub fn save_checkpoint(
        &self,
        id: &str,
        job_id: &str,
        stage: &str,
        response: &str,
        session_path: &str,
        git_sha: &str,
        token_usage: &str,
        files_changed: &str,
    ) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        conn.execute(
            "INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
            params![id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, now],
        )?;
        Ok(())
    }

    pub fn get_checkpoints(&self, job_id: &str) -> Result<Vec<CheckpointRow>> {
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        let mut stmt = conn.prepare(
            "SELECT id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at FROM checkpoints WHERE job_id = ?1 ORDER BY created_at",
        )?;
        let rows = stmt.query_map(params![job_id], |row| {
            Ok(CheckpointRow {
                id: row.get(0)?,
                job_id: row.get(1)?,
                stage: row.get(2)?,
                response: row.get(3)?,
                session_path: row.get(4)?,
                git_sha: row.get(5)?,
                token_usage: row.get(6)?,
                files_changed: row.get(7)?,
                created_at: row.get(8)?,
            })
        })?;
        let mut result = Vec::new();
        for r in rows {
            result.push(r?);
        }
        Ok(result)
    }

    pub fn save_workflow(
        &self,
        name: &str,
        content: &str,
        source: &str,
        project_id: Option<&str>,
    ) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        conn.execute(
            "INSERT OR REPLACE INTO workflows (name, content, source, project_id, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            params![name, content, source, project_id, now, now],
        )?;
        Ok(())
    }

    pub fn get_workflow(&self, name: &str) -> Result<Option<WorkflowRow>> {
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        let row = conn.query_row(
            "SELECT name, content, source, project_id, created_at, updated_at FROM workflows WHERE name = ?1",
            params![name],
            |row| {
                Ok(WorkflowRow {
                    name: row.get(0)?,
                    content: row.get(1)?,
                    source: row.get(2)?,
                    project_id: row.get(3)?,
                    created_at: row.get(4)?,
                    updated_at: row.get(5)?,
                })
            },
        );
        match row {
            Ok(r) => Ok(Some(r)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    pub fn list_workflows(&self) -> Result<Vec<WorkflowRow>> {
        let conn = self.conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}"))?;
        let mut stmt = conn.prepare(
            "SELECT name, content, source, project_id, created_at, updated_at FROM workflows ORDER BY name",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(WorkflowRow {
                name: row.get(0)?,
                content: row.get(1)?,
                source: row.get(2)?,
                project_id: row.get(3)?,
                created_at: row.get(4)?,
                updated_at: row.get(5)?,
            })
        })?;
        let mut result = Vec::new();
        for r in rows {
            result.push(r?);
        }
        Ok(result)
    }
}

const SCHEMA: &str = r#"
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
"#;
