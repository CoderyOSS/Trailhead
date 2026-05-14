use std::sync::Arc;
use tokio::time::{interval, Duration};
use tracing::{error, info, warn};
use crate::config::TrailheadConfig;
use crate::db::Database;
use crate::provider::WorkerProvider;

pub struct SchedulerConfig {
    pub max_global_workers: usize,
    pub max_workers_per_project: usize,
    pub heartbeat_timeout_secs: u64,
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
            heartbeat_timeout_secs: std::env::var("HEARTBEAT_TIMEOUT_SECS")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(180),
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
        self.detect_stuck_workers().await?;
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
            scheduled += 1;
        }
        Ok(())
    }

    async fn detect_stuck_workers(&self) -> anyhow::Result<()> {
        let workers = self.db.list_workers()?;
        let now = chrono::Utc::now();
        for worker in workers {
            if worker.status != "running" {
                continue;
            }
            if let Some(ref hb) = worker.heartbeat_at {
                if let Ok(hb_time) = chrono::DateTime::parse_from_rfc3339(hb) {
                    let elapsed = (now - hb_time.to_utc()).num_seconds() as u64;
                    if elapsed > self.config.heartbeat_timeout_secs {
                        warn!("worker {} heartbeat timeout ({}s)", worker.id, elapsed);
                        if let Some(ref job_id) = worker.job_id {
                            if let Ok(Some(job)) = self.db.get_job(job_id) {
                                if job.attempt < job.max_attempts {
                                    self.db
                                        .fail_job(job_id, "heartbeat timeout", "failed_retryable")?;
                                } else {
                                    self.db.fail_job(
                                        job_id,
                                        "heartbeat timeout (max retries)",
                                        "failed_final",
                                    )?;
                                }
                            }
                        }
                        self.db.update_worker_status(&worker.id, "stopped")?;
                    }
                }
            }
        }
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
