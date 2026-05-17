use anyhow::Result;
use async_trait::async_trait;
use std::collections::HashMap;
use std::path::PathBuf;

pub mod docker;

#[derive(Debug, Clone)]
pub enum WorkerStatus {
    Creating,
    Running,
    Stopped,
    Failed(String),
}

#[derive(Debug, Clone)]
pub struct WorkerSpec {
    pub job_id: String,
    pub workspace_path: PathBuf,
    pub worker_image: String,
    pub env: HashMap<String, String>,
    pub llm_provider: String,
    pub llm_model: String,
    pub llm_base_url: String,
    pub trailhead_url: String,
}

#[derive(Debug, Clone)]
pub struct WorkerHandle {
    pub id: String,
    pub provider_id: String,
    pub status: WorkerStatus,
    pub ip_address: Option<String>,
}

#[async_trait]
pub trait WorkerProvider: Send + Sync {
    async fn create_worker(&self, spec: &WorkerSpec) -> Result<WorkerHandle>;
    async fn destroy_worker(&self, id: &str) -> Result<()>;
    async fn get_status(&self, id: &str) -> Result<WorkerStatus>;
    async fn get_logs(&self, id: &str, tail: usize) -> Result<String>;
    async fn list_workers(&self) -> Result<Vec<WorkerHandle>>;
}
