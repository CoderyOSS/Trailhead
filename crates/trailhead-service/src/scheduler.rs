use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use anyhow::Context;
use tokio::time::{interval, Duration};
use tracing::{error, info, warn};
use crate::config::TrailheadConfig;
use crate::db::Database;
use crate::provider::{WorkerProvider, WorkerSpec};
use crate::worker::adapter::OpencodeAdapter;
use crate::worker::permission::PermissionPolicy;
use crate::workflow;
use crate::workflow::resolver;

pub struct SchedulerConfig {
    pub max_global_workers: usize,
    pub max_workers_per_project: usize,
    pub job_timeout_secs: u64,
    pub max_retries: u32,
    pub interval_secs: u64,
}

impl Default for SchedulerConfig {
    fn default() -> Self {
        Self {
            max_global_workers: std::env::var("MAX_GLOBAL_WORKERS")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(3),
            max_workers_per_project: std::env::var("MAX_WORKERS_PER_PROJECT")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(1),
            job_timeout_secs: std::env::var("JOB_TIMEOUT_SECS")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(3600),
            max_retries: std::env::var("MAX_RETRIES")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(3),
            interval_secs: std::env::var("SCHEDULER_INTERVAL_SECS")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(30),
        }
    }
}

pub struct Scheduler {
    db: Arc<Database>,
    provider: Arc<dyn WorkerProvider>,
    config: SchedulerConfig,
    app_config: Arc<TrailheadConfig>,
}

impl Scheduler {
    pub fn new(
        db: Arc<Database>,
        provider: Arc<dyn WorkerProvider>,
        config: SchedulerConfig,
        app_config: Arc<TrailheadConfig>,
    ) -> Self {
        Self {
            db,
            provider,
            config,
            app_config,
        }
    }

    pub async fn run(&self) {
        let mut tick = interval(Duration::from_secs(self.config.interval_secs));
        loop {
            tick.tick().await;
            if let Err(e) = self.tick().await {
                error!("scheduler tick error: {}", e);
            }
        }
    }

    async fn tick(&self) -> anyhow::Result<()> {
        self.detect_timed_out_jobs().await?;
        self.schedule_queued_jobs().await?;
        Ok(())
    }

    async fn schedule_queued_jobs(&self) -> anyhow::Result<()> {
        let active = self.db.get_active_jobs()?;
        if active.len() >= self.config.max_global_workers {
            return Ok(());
        }
        let queued = self.db.get_queued_jobs()?;
        let capacity = self.config.max_global_workers - active.len();

        let mut scheduled = 0;
        for job in queued {
            if scheduled >= capacity {
                break;
            }
            let project_active = active
                .iter()
                .filter(|j| j.project_id == job.project_id)
                .count();
            if project_active >= self.config.max_workers_per_project {
                continue;
            }

            self.db.update_job_status(&job.id, "scheduled")?;
            info!("scheduled job {}", job.id);

            if let Err(e) = self.launch_worker_for_job(&job).await {
                error!("failed to launch worker for job {}: {}", job.id, e);
                let _ = self.db.fail_job(&job.id, &format!("launch failed: {}", e), "failed_retryable");
            }

            scheduled += 1;
        }
        Ok(())
    }

    async fn launch_worker_for_job(&self, job: &crate::db::JobRow) -> anyhow::Result<()> {
        let workflow_name = job.workflow_name.as_deref().unwrap_or("feature");
        let workflow_row = self.db.get_workflow(workflow_name)
            .context("load workflow")?
            .ok_or_else(|| anyhow::anyhow!("workflow not found: {}", workflow_name))?;
        let wf = workflow::parser::parse_workflow(&workflow_row.content)?;

        let start_stage = job.current_stage.clone();
        let engine = workflow::Engine::new(wf, start_stage)?;

        let stage = engine.current_stage_def()
            .ok_or_else(|| anyhow::anyhow!("no current stage"))?;
        let resolved = self.app_config.resolve_model(stage.model.as_deref())?;

        let spec = WorkerSpec {
            job_id: job.id.clone(),
            workspace_path: PathBuf::from(format!("/opt/codery/workspaces/{}", job.project_id)),
            worker_image: "opencode-worker:latest".to_string(),
            env: HashMap::new(),
            llm_provider: resolved.provider_id.clone(),
            llm_model: format!("{}/{}", resolved.provider_id, resolved.model_id),
            llm_base_url: resolved.base_url.clone(),
            trailhead_url: "http://host.docker.internal:4050".to_string(),
        };

        let handle = self.provider.create_worker(&spec).await?;
        info!("created worker {} for job {}", handle.id, job.id);

        self.db.update_job_status(&job.id, "running")?;

        let worker_addr = handle.ip_address
            .map(|ip| format!("{}:8080", ip))
            .unwrap_or_else(|| format!("{}:8080", handle.id));
        let adapter = OpencodeAdapter::new(format!("http://{}", worker_addr));
        let job_id = job.id.clone();
        let description = job.description.clone();
        let db = self.db.clone();
        let container_id = handle.id.clone();

        tokio::spawn(async move {
            if let Err(e) = run_stage(adapter, engine, &job_id, &description, db.clone(), container_id.clone()).await {
                error!("stage execution failed for job {}: {}", job_id, e);
                let _ = db.fail_job(&job_id, &format!("stage failed: {}", e), "failed_retryable");
            }
        });

        Ok(())
    }

    async fn detect_timed_out_jobs(&self) -> anyhow::Result<()> {
        let active = self.db.get_active_jobs()?;
        let now = chrono::Utc::now();
        for job in active {
            if let Some(ref started) = job.started_at {
                if let Ok(start_time) = chrono::DateTime::parse_from_rfc3339(started) {
                    let elapsed = (now - start_time.to_utc()).num_seconds() as u64;
                    if elapsed > self.config.job_timeout_secs {
                        warn!("job {} timed out ({}s)", job.id, elapsed);
                        if job.attempt < job.max_attempts {
                            self.db.fail_job(&job.id, "job timeout", "failed_retryable")?;
                        } else {
                            self.db
                                .fail_job(&job.id, "job timeout (max retries)", "failed_final")?;
                        }
                    }
                }
            }
        }
        Ok(())
    }
}

async fn run_stage(
    adapter: OpencodeAdapter,
    mut engine: workflow::Engine,
    job_id: &str,
    description: &str,
    db: Arc<Database>,
    container_id: String,
) -> anyhow::Result<()> {
    let mut retries = 0u32;
    loop {
        let ready = adapter.create_session(
            &format!("trailhead-{}-probe", job_id),
            "anthropic",
            "claude-sonnet-4-20250514",
            vec![],
        ).await.is_ok();
        if ready {
            break;
        }
        if retries >= 30 {
            return Err(anyhow::anyhow!("opencode not ready after 30s"));
        }
        tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
        retries += 1;
    }

    let _ = &container_id;

    let stage = engine.current_stage_def()
        .ok_or_else(|| anyhow::anyhow!("no current stage"))?;

    let project = resolver::ProjectVars {
        name: String::new(),
        repo: String::new(),
        branch: String::new(),
    };
    let prompt = engine.resolve_stage_prompt(description, &project, &HashMap::new())?;

    let model_provider = stage.model.as_deref()
        .and_then(|m| m.split_once('/').map(|(p, _)| p))
        .unwrap_or("anthropic");
    let model_id = stage.model.as_deref()
        .and_then(|m| m.split_once('/').map(|(_, id)| id))
        .unwrap_or("claude-sonnet-4-20250514");

    let session_id = adapter.create_session(
        &format!("trailhead-{}-{}", job_id, engine.current_stage),
        model_provider,
        model_id,
        vec![],
    ).await?;

    adapter.send_prompt(&session_id, &prompt).await?;

    let policy = PermissionPolicy::AutoApprove;
    adapter.wait_for_idle(&session_id, &policy).await?;

    let messages = adapter.get_messages(&session_id).await?;
    let last_assistant = messages.iter().rev().find(|m| {
        m.get("role").and_then(|r| r.as_str()) == Some("assistant")
    });

    let output: serde_json::Value = match last_assistant {
        Some(msg) => {
            let text = msg.get("parts")
                .and_then(|p| p.as_array())
                .and_then(|parts| parts.iter().find(|p| p.get("type").and_then(|t| t.as_str()) == Some("text")))
                .and_then(|p| p.get("text").and_then(|t| t.as_str()))
                .unwrap_or("");
            serde_json::from_str(text).unwrap_or_else(|_| {
                serde_json::json!({"text": text})
            })
        }
        None => serde_json::json!({"error": "no assistant response"}),
    };

    let result = engine.process_response(output)?;

    match result {
        workflow::AdvanceResult::Finished => {
            db.complete_job(job_id, &serde_json::to_string(&engine.stage_outputs)?)?;
        }
        workflow::AdvanceResult::PauseForHuman => {
            db.update_job_status(job_id, "paused_for_human")?;
        }
        workflow::AdvanceResult::Advance => {
            let history = serde_json::to_string(&engine.stage_history)?;
            db.update_job_stage(job_id, &engine.current_stage, &history)?;
            db.update_job_status(job_id, "scheduled")?;
        }
    }

    Ok(())
}
