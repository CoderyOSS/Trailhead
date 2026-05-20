use anyhow::Result;
use chrono::Utc;
use rusqlite::params;
use serde::de::DeserializeOwned;
use serde::{Deserialize, Serialize};
use std::sync::Mutex;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProjectRow {
    pub id: String,
    pub repo_url: String,
    pub branch: String,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
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
    pub workspace_path: Option<String>,
    pub created_at: String,
    pub updated_at: String,
    pub started_at: Option<String>,
    pub finished_at: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
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

#[derive(Debug, Clone, Serialize, Deserialize)]
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
pub struct CheckpointParams {
    pub job_id: String,
    pub stage: String,
    pub response: String,
    pub session_path: String,
    pub git_shas: String,
    pub commit_messages: String,
    pub token_usage: Option<String>,
    pub files_changed: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkflowRow {
    pub name: String,
    pub content: String,
    pub content_hash: Option<String>,
    pub source: String,
    pub project_id: Option<String>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug)]
enum Backend {
    Local(Mutex<rusqlite::Connection>),
    Remote { url: String },
}

#[derive(Debug)]
pub struct Database {
    backend: Backend,
}

impl Database {
    pub fn open(path: &str) -> Result<Self> {
        if path.starts_with("http://") || path.starts_with("https://") {
            let db = Self {
                backend: Backend::Remote { url: path.to_string() },
            };
            db.remote_batch(SCHEMA)?;
            Ok(db)
        } else {
            let conn = rusqlite::Connection::open(path)?;
            conn.execute_batch("PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON; PRAGMA busy_timeout=5000;")?;
            conn.execute_batch(SCHEMA)?;
            for migration in MIGRATIONS {
                let _ = conn.execute(migration, []);
            }
            Ok(Self {
                backend: Backend::Local(Mutex::new(conn)),
            })
        }
    }

    fn remote_url(&self) -> Result<&str> {
        match &self.backend {
            Backend::Remote { url } => Ok(url),
            _ => anyhow::bail!("not a remote backend"),
        }
    }

    fn remote_query<T: DeserializeOwned>(&self, sql: &str, p: Vec<serde_json::Value>) -> Result<Vec<T>> {
        let url = self.remote_url()?;
        let resp: serde_json::Value = ureq::post(url)
            .send_json(serde_json::json!({ "sql": sql, "params": p }))?
            .into_json()?;
        let rows: Vec<T> = serde_json::from_value(resp["rows"].clone())?;
        Ok(rows)
    }

    fn remote_query_one<T: DeserializeOwned>(&self, sql: &str, p: Vec<serde_json::Value>) -> Result<Option<T>> {
        let rows = self.remote_query::<T>(sql, p)?;
        Ok(rows.into_iter().next())
    }

    fn remote_exec(&self, sql: &str, p: Vec<serde_json::Value>) -> Result<()> {
        let url = self.remote_url()?;
        ureq::post(url)
            .send_json(serde_json::json!({ "sql": sql, "params": p }))?;
        Ok(())
    }

    fn remote_batch(&self, sql: &str) -> Result<()> {
        let url = self.remote_url()?;
        ureq::post(url)
            .send_json(serde_json::json!({ "sql": sql, "type": "batch" }))?;
        Ok(())
    }

    fn local_conn(&self) -> Result<std::sync::MutexGuard<'_, rusqlite::Connection>> {
        match &self.backend {
            Backend::Local(conn) => conn.lock().map_err(|e| anyhow::anyhow!("lock: {e}")),
            _ => anyhow::bail!("not a local backend"),
        }
    }

    pub fn create_project(&self, id: &str, repo_url: &str, branch: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                conn.execute(
                    "INSERT INTO projects (id, repo_url, branch, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5)",
                    params![id, repo_url, branch, now, now],
                )?;
            }
            Backend::Remote { .. } => {
                self.remote_exec(
                    "INSERT INTO projects (id, repo_url, branch, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5)",
                    vec![serde_json::json!(id), serde_json::json!(repo_url), serde_json::json!(branch), serde_json::json!(now), serde_json::json!(now)],
                )?;
            }
        }
        Ok(())
    }

    pub fn get_project(&self, id: &str) -> Result<Option<ProjectRow>> {
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
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
            Backend::Remote { .. } => {
                self.remote_query_one(
                    "SELECT id, repo_url, branch, created_at, updated_at FROM projects WHERE id = ?1",
                    vec![serde_json::json!(id)],
                )
            }
        }
    }

    pub fn list_projects(&self) -> Result<Vec<ProjectRow>> {
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
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
            Backend::Remote { .. } => {
                self.remote_query(
                    "SELECT id, repo_url, branch, created_at, updated_at FROM projects ORDER BY created_at",
                    vec![],
                )
            }
        }
    }

    pub fn create_job(
        &self,
        id: &str,
        project_id: &str,
        description: &str,
        workflow_name: Option<&str>,
        branch: Option<&str>,
        workspace_path: Option<&str>,
    ) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                conn.execute(
                    "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, workspace_path, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7, ?8)",
                    params![id, project_id, description, workflow_name, branch, workspace_path, now, now],
                )?;
            }
            Backend::Remote { .. } => {
                self.remote_exec(
                    "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, workspace_path, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7, ?8)",
                    vec![serde_json::json!(id), serde_json::json!(project_id), serde_json::json!(description), serde_json::json!(workflow_name), serde_json::json!(branch), serde_json::json!(workspace_path), serde_json::json!(now), serde_json::json!(now)],
                )?;
            }
        }
        Ok(())
    }

    pub fn get_job(&self, id: &str) -> Result<Option<JobRow>> {
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                let row = conn.query_row(
                    "SELECT id, project_id, description, status, worker_id, branch, workflow_name, current_stage, stage_history, attempt, max_attempts, result, error, workspace_path, created_at, updated_at, started_at, finished_at FROM jobs WHERE id = ?1",
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
                            workspace_path: row.get(13)?,
                            created_at: row.get(14)?,
                            updated_at: row.get(15)?,
                            started_at: row.get(16)?,
                            finished_at: row.get(17)?,
                        })
                    },
                );
                match row {
                    Ok(r) => Ok(Some(r)),
                    Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
                    Err(e) => Err(e.into()),
                }
            }
            Backend::Remote { .. } => {
                self.remote_query_one(
                    "SELECT id, project_id, description, status, worker_id, branch, workflow_name, current_stage, stage_history, attempt, max_attempts, result, error, created_at, updated_at, started_at, finished_at FROM jobs WHERE id = ?1",
                    vec![serde_json::json!(id)],
                )
            }
        }
    }

    pub fn list_jobs(&self) -> Result<Vec<JobRow>> {
        const SQL: &str = "SELECT id, project_id, description, status, worker_id, branch, workflow_name, current_stage, stage_history, attempt, max_attempts, result, error, workspace_path, created_at, updated_at, started_at, finished_at FROM jobs ORDER BY created_at";
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                let mut stmt = conn.prepare(SQL)?;
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
                        workspace_path: row.get(13)?,
                        created_at: row.get(14)?,
                        updated_at: row.get(15)?,
                        started_at: row.get(16)?,
                        finished_at: row.get(17)?,
                    })
                })?;
                let mut result = Vec::new();
                for r in rows {
                    result.push(r?);
                }
                Ok(result)
            }
            Backend::Remote { .. } => self.remote_query(SQL, vec![]),
        }
    }

    pub fn update_job_status(&self, id: &str, status: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                conn.execute(
                    "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
                    params![status, now, id],
                )?;
            }
            Backend::Remote { .. } => {
                self.remote_exec(
                    "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
                    vec![serde_json::json!(status), serde_json::json!(now), serde_json::json!(id)],
                )?;
            }
        }
        Ok(())
    }

    pub fn update_job_stage(&self, id: &str, stage: &str, stage_history: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                conn.execute(
                    "UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4",
                    params![stage, stage_history, now, id],
                )?;
            }
            Backend::Remote { .. } => {
                self.remote_exec(
                    "UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4",
                    vec![serde_json::json!(stage), serde_json::json!(stage_history), serde_json::json!(now), serde_json::json!(id)],
                )?;
            }
        }
        Ok(())
    }

    pub fn assign_worker(&self, job_id: &str, worker_id: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                conn.execute(
                    "UPDATE jobs SET worker_id = ?1, updated_at = ?2 WHERE id = ?3",
                    params![worker_id, now, job_id],
                )?;
            }
            Backend::Remote { .. } => {
                self.remote_exec(
                    "UPDATE jobs SET worker_id = ?1, updated_at = ?2 WHERE id = ?3",
                    vec![serde_json::json!(worker_id), serde_json::json!(now), serde_json::json!(job_id)],
                )?;
            }
        }
        Ok(())
    }

    pub fn get_queued_jobs(&self) -> Result<Vec<JobRow>> {
        const SQL: &str = "SELECT id, project_id, description, status, worker_id, branch, workflow_name, current_stage, stage_history, attempt, max_attempts, result, error, workspace_path, created_at, updated_at, started_at, finished_at FROM jobs WHERE status = 'queued' ORDER BY created_at ASC";
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                let mut stmt = conn.prepare(SQL)?;
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
                        workspace_path: row.get(13)?,
                        created_at: row.get(14)?,
                        updated_at: row.get(15)?,
                        started_at: row.get(16)?,
                        finished_at: row.get(17)?,
                    })
                })?;
                let mut result = Vec::new();
                for r in rows {
                    result.push(r?);
                }
                Ok(result)
            }
            Backend::Remote { .. } => self.remote_query(SQL, vec![]),
        }
    }

    pub fn get_active_jobs(&self) -> Result<Vec<JobRow>> {
        const SQL: &str = "SELECT id, project_id, description, status, worker_id, branch, workflow_name, current_stage, stage_history, attempt, max_attempts, result, error, workspace_path, created_at, updated_at, started_at, finished_at FROM jobs WHERE status IN ('scheduled', 'provisioning', 'running', 'checkpointing')";
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                let mut stmt = conn.prepare(SQL)?;
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
                        workspace_path: row.get(13)?,
                        created_at: row.get(14)?,
                        updated_at: row.get(15)?,
                        started_at: row.get(16)?,
                        finished_at: row.get(17)?,
                    })
                })?;
                let mut result = Vec::new();
                for r in rows {
                    result.push(r?);
                }
                Ok(result)
            }
            Backend::Remote { .. } => self.remote_query(SQL, vec![]),
        }
    }

    pub fn fail_job(&self, id: &str, error: &str, status: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                conn.execute(
                    "UPDATE jobs SET error = ?1, status = ?2, finished_at = ?3, updated_at = ?4 WHERE id = ?5",
                    params![error, status, now, now, id],
                )?;
            }
            Backend::Remote { .. } => {
                self.remote_exec(
                    "UPDATE jobs SET error = ?1, status = ?2, finished_at = ?3, updated_at = ?4 WHERE id = ?5",
                    vec![serde_json::json!(error), serde_json::json!(status), serde_json::json!(now), serde_json::json!(now), serde_json::json!(id)],
                )?;
            }
        }
        Ok(())
    }

    pub fn complete_job(&self, id: &str, result: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                conn.execute(
                    "UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4",
                    params![result, now, now, id],
                )?;
            }
            Backend::Remote { .. } => {
                self.remote_exec(
                    "UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4",
                    vec![serde_json::json!(result), serde_json::json!(now), serde_json::json!(now), serde_json::json!(id)],
                )?;
            }
        }
        Ok(())
    }

    pub fn save_checkpoint(&self, params: &CheckpointParams) -> Result<()> {
        let id = uuid::Uuid::new_v4().to_string();
        let now = Utc::now().to_rfc3339();
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                conn.execute(
                    "INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, commit_message, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)",
                    params![id, params.job_id, params.stage, params.response, params.session_path, params.git_shas, params.commit_messages, params.token_usage, params.files_changed, now],
                )?;
            }
            Backend::Remote { .. } => {
                self.remote_exec(
                    "INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, commit_message, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)",
                    vec![serde_json::json!(id), serde_json::json!(params.job_id), serde_json::json!(params.stage), serde_json::json!(params.response), serde_json::json!(params.session_path), serde_json::json!(params.git_shas), serde_json::json!(params.commit_messages), serde_json::json!(params.token_usage), serde_json::json!(params.files_changed), serde_json::json!(now)],
                )?;
            }
        }
        Ok(())
    }

    pub fn create_worker(&self, id: &str, job_id: &str, provider: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                conn.execute(
                    "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
                    params![id, job_id, provider, now],
                )?;
            }
            Backend::Remote { .. } => {
                self.remote_exec(
                    "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
                    vec![serde_json::json!(id), serde_json::json!(job_id), serde_json::json!(provider), serde_json::json!(now)],
                )?;
            }
        }
        Ok(())
    }

    pub fn list_workers(&self) -> Result<Vec<WorkerRow>> {
        const SQL: &str = "SELECT id, job_id, provider, provider_id, status, ip_address, workspace_path, heartbeat_at, created_at, destroyed_at FROM workers ORDER BY created_at";
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                let mut stmt = conn.prepare(SQL)?;
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
            Backend::Remote { .. } => self.remote_query(SQL, vec![]),
        }
    }

    pub fn destroy_worker(&self, id: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                conn.execute(
                    "UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2",
                    params![now, id],
                )?;
            }
            Backend::Remote { .. } => {
                self.remote_exec(
                    "UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2",
                    vec![serde_json::json!(now), serde_json::json!(id)],
                )?;
            }
        }
        Ok(())
    }

    pub fn save_workflow(
        &self,
        name: &str,
        content: &str,
        content_hash: &str,
        source: &str,
        project_id: Option<&str>,
    ) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                conn.execute(
                    "INSERT OR REPLACE INTO workflows (name, content, content_hash, source, project_id, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
                    params![name, content, content_hash, source, project_id, now, now],
                )?;
            }
            Backend::Remote { .. } => {
                self.remote_exec(
                    "INSERT OR REPLACE INTO workflows (name, content, content_hash, source, project_id, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
                    vec![serde_json::json!(name), serde_json::json!(content), serde_json::json!(content_hash), serde_json::json!(source), serde_json::json!(project_id), serde_json::json!(now), serde_json::json!(now)],
                )?;
            }
        }
        Ok(())
    }

    pub fn get_workflow(&self, name: &str) -> Result<Option<WorkflowRow>> {
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                let row = conn.query_row(
                    "SELECT name, content, content_hash, source, project_id, created_at, updated_at FROM workflows WHERE name = ?1",
                    params![name],
                    |row| {
                        Ok(WorkflowRow {
                            name: row.get(0)?,
                            content: row.get(1)?,
                            content_hash: row.get(2)?,
                            source: row.get(3)?,
                            project_id: row.get(4)?,
                            created_at: row.get(5)?,
                            updated_at: row.get(6)?,
                        })
                    },
                );
                match row {
                    Ok(r) => Ok(Some(r)),
                    Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
                    Err(e) => Err(e.into()),
                }
            }
            Backend::Remote { .. } => {
                self.remote_query_one(
                    "SELECT name, content, content_hash, source, project_id, created_at, updated_at FROM workflows WHERE name = ?1",
                    vec![serde_json::json!(name)],
                )
            }
        }
    }

    pub fn list_workflows(&self) -> Result<Vec<WorkflowRow>> {
        const SQL: &str = "SELECT name, content, content_hash, source, project_id, created_at, updated_at FROM workflows ORDER BY name";
        match &self.backend {
            Backend::Local(_) => {
                let conn = self.local_conn()?;
                let mut stmt = conn.prepare(SQL)?;
                let rows = stmt.query_map([], |row| {
                    Ok(WorkflowRow {
                        name: row.get(0)?,
                        content: row.get(1)?,
                        content_hash: row.get(2)?,
                        source: row.get(3)?,
                        project_id: row.get(4)?,
                        created_at: row.get(5)?,
                        updated_at: row.get(6)?,
                    })
                })?;
                let mut result = Vec::new();
                for r in rows {
                    result.push(r?);
                }
                Ok(result)
            }
            Backend::Remote { .. } => self.remote_query(SQL, vec![]),
        }
    }

    pub fn seed_builtin_workflows(&self, dir: &std::path::Path) -> Result<()> {
        if !dir.is_dir() {
            tracing::warn!("workflows directory not found: {}", dir.display());
            return Ok(());
        }
        for entry in std::fs::read_dir(dir)? {
            let entry = entry?;
            let path = entry.path();
            if path.extension().and_then(|e| e.to_str()) != Some("yaml") {
                continue;
            }
            let name = path
                .file_stem()
                .and_then(|s| s.to_str())
                .ok_or_else(|| anyhow::anyhow!("invalid filename: {}", path.display()))?;
            let raw = std::fs::read_to_string(&path)?;
            let hash = Self::normalize_and_hash(&raw);
            let existing = self.get_workflow(name)?;
            match existing {
                None => {
                    self.save_workflow(name, raw.trim(), &hash, "builtin", None)?;
                    tracing::info!("seeded workflow: {}", name);
                }
                Some(w) if w.content_hash.as_deref() != Some(&hash) => {
                    self.save_workflow(name, raw.trim(), &hash, "builtin", None)?;
                    tracing::info!("updated workflow: {}", name);
                }
                Some(_) => {}
            }
        }
        Ok(())
    }

    fn normalize_and_hash(content: &str) -> String {
        let trimmed = content.trim();
        let value: serde_yaml::Value = serde_yaml::from_str(trimmed).unwrap_or_else(|_| {
            serde_yaml::Value::String(trimmed.to_string())
        });
        let sorted = Self::sort_yaml_keys(value);
        let normalized = serde_yaml::to_string(&sorted).unwrap_or_else(|_| trimmed.to_string());
        let lines: Vec<&str> = normalized
            .lines()
            .filter(|l| !l.trim().is_empty())
            .collect();
        let collapsed = lines.join("\n");
        use sha2::{Sha256, Digest};
        let mut hasher = Sha256::new();
        hasher.update(collapsed.as_bytes());
        format!("{:x}", hasher.finalize())
    }

    fn sort_yaml_keys(val: serde_yaml::Value) -> serde_yaml::Value {
        match val {
            serde_yaml::Value::Mapping(map) => {
                let mut entries: Vec<(serde_yaml::Value, serde_yaml::Value)> = map.into_iter().collect();
                entries.sort_by(|a, b| {
                    match (&a.0, &b.0) {
                        (serde_yaml::Value::String(a_s), serde_yaml::Value::String(b_s)) => a_s.cmp(b_s),
                        _ => std::cmp::Ordering::Equal,
                    }
                });
                let sorted: serde_yaml::Mapping = entries
                    .into_iter()
                    .map(|(k, v)| (k, Self::sort_yaml_keys(v)))
                    .collect();
                serde_yaml::Value::Mapping(sorted)
            }
            serde_yaml::Value::Sequence(seq) => {
                serde_yaml::Value::Sequence(seq.into_iter().map(Self::sort_yaml_keys).collect())
            }
            other => other,
        }
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
    workspace_path  TEXT,
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
    content_hash    TEXT,
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

const MIGRATIONS: &[&str] = &[
    "ALTER TABLE workflows ADD COLUMN content_hash TEXT",
    "ALTER TABLE checkpoints ADD COLUMN commit_message TEXT DEFAULT ''",
    "ALTER TABLE jobs ADD COLUMN workspace_path TEXT",
    "ALTER TABLE workers ADD COLUMN workspace_path TEXT",
];
