use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use anyhow::Context;
use tokio::time::{interval, Duration};
use tracing::{error, info, warn};
use crate::config::TrailheadConfig;
use crate::db::{Database, CheckpointParams};
use crate::provider::{WorkerProvider, WorkerSpec};
use crate::worker::adapter::{OpencodeAdapter, PermissionRule};
use crate::worker::permission::PermissionPolicy;
use crate::workflow;
use crate::workflow::{CommitInfo, CommitPolicy};
use crate::workflow::resolver;

pub struct SchedulerConfig {
    pub max_global_workers: usize,
    pub max_workers_per_project: usize,
    pub job_timeout_secs: u64,
    pub max_retries: u32,
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
        let mut rx = self.db.job_notify_receiver();
        let mut timeout_interval = interval(Duration::from_secs(60));
        loop {
            tokio::select! {
                _ = rx.changed() => {
                    if let Err(e) = self.schedule_queued_jobs().await {
                        error!("scheduler schedule error: {}", e);
                    }
                }
                _ = timeout_interval.tick() => {
                    if let Err(e) = self.detect_timed_out_jobs().await {
                        error!("scheduler timeout check error: {}", e);
                    }
                }
            }
        }
    }

    pub async fn shutdown(&self) -> anyhow::Result<()> {
        info!("scheduler shutdown: destroying all workers");
        match self.provider.list_workers().await {
            Ok(workers) => {
                for w in &workers {
                    if let Err(e) = self.provider.destroy_worker(&w.id).await {
                        warn!("shutdown: failed to destroy worker {}: {}", w.id, e);
                    }
                }
                info!("shutdown: destroyed {} workers", workers.len());
            }
            Err(e) => warn!("shutdown: failed to list workers: {}", e),
        }
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

        let workspace_path = if let Some(ref ws) = job.workspace_path {
            PathBuf::from(ws)
        } else {
            let workspace_base = std::env::var("WORKSPACE_BASE")
                .unwrap_or_else(|_| "/opt/codery/workspaces".to_string());
            PathBuf::from(format!("{}/{}", workspace_base, job.project_id))
        };

        if let Err(e) = std::process::Command::new("git")
            .args(["-C", &workspace_path.to_string_lossy(), "rev-parse", "--is-inside-work-tree"])
            .output()
        {
            return Err(anyhow::anyhow!("workspace is not a git repo (or missing): {}", e));
        }

        let branch = &wf.branch;
        let checkout = std::process::Command::new("git")
            .args(["-C", &workspace_path.to_string_lossy(), "checkout", branch])
            .output()
            .context("git checkout")?;
        if !checkout.status.success() {
            let create_branch = std::process::Command::new("git")
                .args(["-C", &workspace_path.to_string_lossy(), "checkout", "-b", branch])
                .output()
                .context("git checkout -b")?;
            if !create_branch.status.success() {
                let stderr = String::from_utf8_lossy(&create_branch.stderr);
                return Err(anyhow::anyhow!("failed to checkout branch '{}': {}", branch, stderr));
            }
            info!("created new branch '{}' for job {}", branch, job.id);
        } else {
            info!("checked out branch '{}' for job {}", branch, job.id);
        }

        let start_stage = job.current_stage.clone();
        let engine = workflow::Engine::new(wf, start_stage)?;

        let stage = engine.current_stage_def()
            .ok_or_else(|| anyhow::anyhow!("no current stage"))?;
        let resolved = self.app_config.resolve_model(stage.model.as_deref())?;

        let mut env = HashMap::new();
        if stage.commits == CommitPolicy::Prohibited {
            env.insert("GIT_COMMIT_POLICY".to_string(), "prohibited".to_string());
        }

        let spec = WorkerSpec {
            job_id: job.id.clone(),
            workspace_path: workspace_path.clone(),
            worker_image: "ghcr.io/coderyoss/trailhead:worker-latest".to_string(),
            env,
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
        let provider = self.provider.clone();

        let provider_id = resolved.provider_id.clone();
        let model_id = resolved.model_id.clone();
        tokio::spawn(async move {
            if let Err(e) = run_stage(
                adapter,
                engine,
                &job_id,
                &description,
                db.clone(),
                container_id.clone(),
                provider.clone(),
                workspace_path.clone(),
                &provider_id,
                &model_id,
            ).await {
                error!("stage execution failed for job {}: {}", job_id, e);
                let _ = provider.destroy_worker(&container_id).await;
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
                        if let Some(ref worker_id) = job.worker_id {
                            let _ = self.provider.destroy_worker(worker_id).await;
                        }
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

fn git_head_sha(workspace: &std::path::Path) -> Option<String> {
    std::process::Command::new("git")
        .args(["-C", &workspace.to_string_lossy(), "rev-parse", "HEAD"])
        .output()
        .ok()
        .and_then(|o| {
            if o.status.success() {
                Some(String::from_utf8_lossy(&o.stdout).trim().to_string())
            } else {
                None
            }
        })
}

fn git_commit_count_since(workspace: &std::path::Path, pre_sha: &str) -> anyhow::Result<usize> {
    let output = std::process::Command::new("git")
        .args(["-C", &workspace.to_string_lossy(), "rev-list", "--count", &format!("{}..HEAD", pre_sha)])
        .output()
        .context("git rev-list --count")?;
    if !output.status.success() {
        let stdout = String::from_utf8_lossy(&output.stderr);
        warn!("git rev-list failed for {}..HEAD: {}", pre_sha, stdout);
        return Ok(0);
    }
    let stdout = String::from_utf8_lossy(&output.stdout);
    Ok(stdout.trim().parse::<usize>().unwrap_or(0))
}

fn git_commit_list(workspace: &std::path::Path, pre_sha: &str) -> anyhow::Result<Vec<CommitInfo>> {
    let output = std::process::Command::new("git")
        .args(["-C", &workspace.to_string_lossy(), "log", "--format=%H|||%h|||%s", &format!("{}..HEAD", pre_sha)])
        .output()
        .context("git log")?;
    if !output.status.success() {
        return Ok(vec![]);
    }
    let stdout = String::from_utf8_lossy(&output.stdout);
    let commits: Vec<CommitInfo> = stdout
        .lines()
        .filter(|line| !line.is_empty())
        .filter_map(|line| {
            let parts: Vec<&str> = line.split("|||").collect();
            if parts.len() >= 3 {
                Some(CommitInfo {
                    sha: parts[0].to_string(),
                    short_hash: parts[1].to_string(),
                    message: parts[2].chars().take(72).collect(),
                })
            } else {
                None
            }
        })
        .collect();
    Ok(commits)
}

fn git_changed_files(workspace: &std::path::Path, pre_sha: &str) -> anyhow::Result<Vec<String>> {
    let output = std::process::Command::new("git")
        .args(["-C", &workspace.to_string_lossy(), "diff", "--name-only", &format!("{}..HEAD", pre_sha)])
        .output()
        .context("git diff --name-only")?;
    if !output.status.success() {
        return Ok(vec![]);
    }
    let stdout = String::from_utf8_lossy(&output.stdout);
    Ok(stdout.lines().filter(|l| !l.is_empty()).map(|l| l.to_string()).collect())
}

fn git_deny_rules() -> Vec<PermissionRule> {
    vec![
        PermissionRule { permission: "bash".to_string(), pattern: "git\\s+(commit|add)".to_string(), action: "deny".to_string() },
    ]
}

#[allow(clippy::too_many_arguments)]
async fn run_stage(
    adapter: OpencodeAdapter,
    mut engine: workflow::Engine,
    job_id: &str,
    description: &str,
    db: Arc<Database>,
    container_id: String,
    provider: Arc<dyn WorkerProvider>,
    workspace_path: PathBuf,
    provider_id: &str,
    model_id: &str,
) -> anyhow::Result<()> {
    let pre_sha = git_head_sha(&workspace_path);
    info!("stage pre-sha for job {}: {:?}", job_id, pre_sha);

    let mut retries = 0u32;
    loop {
        let ready = adapter.create_session(
            &format!("trailhead-{}-probe", job_id),
            provider_id,
            model_id,
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

    let stage = engine.current_stage_def().ok_or_else(|| anyhow::anyhow!("no current stage"))?;
    let commit_policy = stage.commits.clone();
    let stage_name = engine.current_stage.clone();

    let project = resolver::ProjectVars {
        name: String::new(),
        repo: String::new(),
        branch: String::new(),
    };
    let mut prompt = engine.resolve_stage_prompt(description, &project, &HashMap::new())?;

    let is_phase1_prohibited = commit_policy == CommitPolicy::Prohibited || commit_policy == CommitPolicy::Required;

    let permission_rules = if is_phase1_prohibited {
        prompt.push_str("\n\nCRITICAL RULE: Do NOT create any git commits during this stage. Do not use git add or git commit.");
        git_deny_rules()
    } else {
        vec![]
    };

    let session_id = adapter.create_session(
        &format!("trailhead-{}-{}", job_id, stage_name),
        provider_id,
        model_id,
        permission_rules,
    ).await?;

    adapter.send_prompt(&session_id, &prompt).await?;

    let policy = PermissionPolicy::AutoApprove;
    adapter.wait_for_idle(&session_id, &policy).await?;

    let messages = adapter.get_messages(&session_id).await?;
    let last_assistant = messages.iter().rev().find(|m| {
        m.get("info")
            .and_then(|i| i.get("role"))
            .and_then(|r| r.as_str())
            == Some("assistant")
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

    let _phase2_commit_sha = if commit_policy == CommitPolicy::Required {
        let commit_session_id = adapter.create_session(
            &format!("trailhead-{}-{}-commit", job_id, stage_name),
            provider_id,
            model_id,
            vec![],
        ).await?;

        let commit_prompt = "Now create exactly one git commit with all the changes you made during this stage.\n\
            Use git add to stage the changes, then git commit with a descriptive message.\n\n\
            After the commit is created, call submit_result with this output:\n\
            { \"commit_sha\": \"the full commit SHA\", \"status\": \"committed\" }\n\n\
            Do NOT make any other changes. Only stage and commit existing changes.";

        adapter.send_prompt(&commit_session_id, commit_prompt).await?;

        match tokio::time::timeout(
            tokio::time::Duration::from_secs(120),
            adapter.wait_for_idle(&commit_session_id, &policy),
        ).await {
            Ok(Ok(())) => {
                let commit_messages = adapter.get_messages(&commit_session_id).await?;
                let commit_output = commit_messages.iter().rev().find(|m| {
                    m.get("info")
                        .and_then(|i| i.get("role"))
                        .and_then(|r| r.as_str())
                        == Some("assistant")
                });
                commit_output
                    .and_then(|msg| msg.get("parts").and_then(|p| p.as_array()))
                    .and_then(|parts| parts.iter().find(|p| p.get("type").and_then(|t| t.as_str()) == Some("text")))
                    .and_then(|p| p.get("text").and_then(|t| t.as_str()))
                    .and_then(|text| {
                        serde_json::from_str::<serde_json::Value>(text).ok()
                            .and_then(|v| v.get("commit_sha").and_then(|s| s.as_str().map(|s| s.to_string())))
                    })
            }
            Ok(Err(e)) => {
                warn!("commit phase failed for job {}: {}", job_id, e);
                None
            }
            Err(_) => {
                warn!("commit phase timed out for job {}", job_id);
                None
            }
        }
    } else {
        None
    };

    if commit_policy == CommitPolicy::Required {
        if let Some(ref pre) = pre_sha {
            let commit_count = git_commit_count_since(&workspace_path, pre).unwrap_or(0);
            if commit_count == 0 {
                return Err(anyhow::anyhow!("commits required but no commit was created"));
            }
        } else {
            return Err(anyhow::anyhow!("commits required but pre-stage SHA not available"));
        }
    } else if commit_policy == CommitPolicy::Prohibited {
        if let Some(ref pre) = pre_sha {
            let commit_count = git_commit_count_since(&workspace_path, pre).unwrap_or(0);
            if commit_count > 0 {
                return Err(anyhow::anyhow!("commits prohibited but {} unauthorized commit(s) detected", commit_count));
            }
        }
    }

    let commits = if let Some(ref pre) = pre_sha {
        git_commit_list(&workspace_path, pre).unwrap_or_default()
    } else {
        vec![]
    };

    let changed_files = if let Some(ref pre) = pre_sha {
        git_changed_files(&workspace_path, pre).unwrap_or_default()
    } else {
        vec![]
    };

    let shas_json = serde_json::to_string(&commits.iter().map(|c| &c.sha).collect::<Vec<_>>())?;
    let messages_json = serde_json::to_string(&commits.iter().map(|c| format!("{} {}", c.short_hash, c.message)).collect::<Vec<_>>())?;
    let files_json = serde_json::to_string(&changed_files)?;

    if commit_policy == CommitPolicy::Prohibited {
        let _ = db.save_checkpoint(&CheckpointParams {
            job_id: job_id.to_string(),
            stage: stage_name.clone(),
            response: serde_json::to_string(&output)?,
            session_path: session_id.clone(),
            git_shas: String::new(),
            commit_messages: String::new(),
            token_usage: None,
            files_changed: files_json,
        });
    } else {
        let _ = db.save_checkpoint(&CheckpointParams {
            job_id: job_id.to_string(),
            stage: stage_name.clone(),
            response: serde_json::to_string(&output)?,
            session_path: session_id.clone(),
            git_shas: shas_json,
            commit_messages: messages_json,
            token_usage: None,
            files_changed: files_json,
        });
    }

    let result = engine.process_response_with_commits(output, commits)?;

    provider.destroy_worker(&container_id).await?;
    info!("destroyed worker {} for job {}", container_id, job_id);

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
