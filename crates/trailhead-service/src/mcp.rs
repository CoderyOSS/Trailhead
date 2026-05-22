use std::os::unix::fs::PermissionsExt;
use std::sync::Arc;

use rmcp::{
    handler::server::router::tool::ToolRouter,
    handler::server::wrapper::Parameters,
    tool, tool_router,
};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

use crate::db::Database;

#[derive(Debug, Clone)]
pub struct TrailheadMcpServer {
    db: Arc<Database>,
    #[allow(dead_code)]
    tool_router: ToolRouter<Self>,
}

#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
pub struct CreateJobParams {
    pub project_id: String,
    pub description: String,
    pub workflow: Option<String>,
    pub project_path: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
pub struct JobIdParams {
    pub job_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
pub struct AttachJobParams {
    pub job_id: String,
    pub ide: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
pub struct WorkerIdParams {
    pub worker_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
pub struct AddProjectParams {
    pub name: String,
    pub repo: String,
    pub branch: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
pub struct WorkflowNameParams {
    pub name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
pub struct SecretParams {
    pub name: String,
    pub value: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
pub struct SubmitResultParams {
    pub job_id: String,
    pub stage: String,
    pub output: String,
}

impl TrailheadMcpServer {
    pub fn new(db: Arc<Database>) -> Self {
        Self {
            db,
            tool_router: Self::tool_router(),
        }
    }
}

#[tool_router(server_handler)]
impl TrailheadMcpServer {
    #[tool(description = "Get the running Trailhead service version")]
    pub async fn version(&self) -> String {
        serde_json::json!({"version": env!("CARGO_PKG_VERSION")}).to_string()
    }

    #[tool(description = "List all jobs")]
    pub async fn jobs_list(&self) -> String {
        match self.db.list_jobs() {
            Ok(jobs) => serde_json::to_string_pretty(&jobs).unwrap_or_else(|e| format!("serialize error: {e}")),
            Err(e) => format!("error: {e}"),
        }
    }

    #[tool(description = "Create a new job")]
    pub async fn jobs_create(&self, Parameters(params): Parameters<CreateJobParams>) -> String {
        let id = uuid::Uuid::new_v4().to_string();
        match self.db.create_job(&id, &params.project_id, &params.description, params.workflow.as_deref(), None, params.project_path.as_deref()) {
            Ok(()) => serde_json::json!({"job_id": id}).to_string(),
            Err(e) => format!("error: {e}"),
        }
    }

    #[tool(description = "Cancel a job")]
    pub async fn jobs_cancel(&self, Parameters(params): Parameters<JobIdParams>) -> String {
        match self.db.get_job(&params.job_id) {
            Ok(Some(job)) => {
                if crate::jobs::is_terminal(&job.status) {
                    format!("job already terminal: {}", job.status)
                } else {
                    match self.db.update_job_status(&params.job_id, "cancelled") {
                        Ok(()) => "cancelled".into(),
                        Err(e) => format!("error: {e}"),
                    }
                }
            }
            Ok(None) => "job not found".into(),
            Err(e) => format!("error: {e}"),
        }
    }

    #[tool(description = "Pause a running job")]
    pub async fn jobs_pause(&self, Parameters(params): Parameters<JobIdParams>) -> String {
        match self.db.get_job(&params.job_id) {
            Ok(Some(job)) => {
                match crate::jobs::transition(&job.status, "paused") {
                    Ok(()) => match self.db.update_job_status(&params.job_id, "paused") {
                        Ok(()) => "paused".into(),
                        Err(e) => format!("error: {e}"),
                    },
                    Err(e) => format!("invalid transition: {e}"),
                }
            }
            Ok(None) => "job not found".into(),
            Err(e) => format!("error: {e}"),
        }
    }

    #[tool(description = "Retry a failed_retryable job")]
    pub async fn jobs_retry(&self, Parameters(params): Parameters<JobIdParams>) -> String {
        match self.db.get_job(&params.job_id) {
            Ok(Some(job)) if job.status == "failed_retryable" => {
                match self.db.requeue_job(&params.job_id) {
                    Ok(()) => serde_json::json!({
                        "status": "re-queued",
                        "job_id": params.job_id,
                    })
                    .to_string(),
                    Err(e) => format!("error: {e}"),
                }
            }
            Ok(Some(job)) => format!("{{\"error\": \"job is {}, not failed_retryable\"}}", job.status),
            Ok(None) => "job not found".into(),
            Err(e) => format!("error: {e}"),
        }
    }

    #[tool(description = "Resume a paused job")]
    pub async fn jobs_resume(&self, Parameters(params): Parameters<JobIdParams>) -> String {
        match self.db.get_job(&params.job_id) {
            Ok(Some(job)) => {
                match crate::jobs::transition(&job.status, "resuming") {
                    Ok(()) => match self.db.update_job_status(&params.job_id, "resuming") {
                        Ok(()) => "resuming".into(),
                        Err(e) => format!("error: {e}"),
                    },
                    Err(e) => format!("invalid transition: {e}"),
                }
            }
            Ok(None) => "job not found".into(),
            Err(e) => format!("error: {e}"),
        }
    }

    #[tool(description = "Attach IDE to a job")]
    pub async fn jobs_attach(&self, Parameters(params): Parameters<AttachJobParams>) -> String {
        let ide_name = params.ide.as_deref().unwrap_or("ssh");
        let adapter = crate::ide::get_adapter(ide_name);
        match adapter {
            Some(adapter) => {
                match self.db.get_job(&params.job_id) {
                    Ok(Some(job)) => {
                        let ctx = crate::ide::JobContext {
                            job_id: job.id.clone(),
                            current_step: job.current_stage.clone().unwrap_or_default(),
                            last_agent_output: String::new(),
                            changed_files: Vec::new(),
                            project_path: std::path::PathBuf::from("/tmp"),
                        };
                        match adapter.open_workspace(std::path::Path::new("/tmp"), &ctx) {
                            Ok(()) => format!("attached with {}", ide_name),
                            Err(e) => format!("open error: {e}"),
                        }
                    }
                    Ok(None) => "job not found".into(),
                    Err(e) => format!("error: {e}"),
                }
            }
            None => format!("unknown ide: {ide_name}"),
        }
    }

    #[tool(description = "Detach from a job")]
    pub async fn jobs_detach(&self, Parameters(params): Parameters<JobIdParams>) -> String {
        format!("detached from {}", params.job_id)
    }

    #[tool(description = "List all workers")]
    pub async fn workers_list(&self) -> String {
        match self.db.list_workers() {
            Ok(workers) => serde_json::to_string_pretty(&workers).unwrap_or_else(|e| format!("serialize error: {e}")),
            Err(e) => format!("error: {e}"),
        }
    }

    #[tool(description = "Destroy a worker")]
    pub async fn workers_destroy(&self, Parameters(params): Parameters<WorkerIdParams>) -> String {
        match self.db.destroy_worker(&params.worker_id) {
            Ok(()) => format!("destroyed {}", params.worker_id),
            Err(e) => format!("error: {e}"),
        }
    }

    #[tool(description = "List all projects")]
    pub async fn projects_list(&self) -> String {
        match self.db.list_projects() {
            Ok(projects) => serde_json::to_string_pretty(&projects).unwrap_or_else(|e| format!("serialize error: {e}")),
            Err(e) => format!("error: {e}"),
        }
    }

    #[tool(description = "Add a project")]
    pub async fn projects_add(&self, Parameters(params): Parameters<AddProjectParams>) -> String {
        let id = uuid::Uuid::new_v4().to_string();
        let branch = params.branch.as_deref().unwrap_or("main");
        match self.db.create_project(&id, &params.name, &params.repo, branch) {
            Ok(()) => serde_json::json!({"project_id": id, "name": params.name}).to_string(),
            Err(e) => format!("error: {e}"),
        }
    }

    #[tool(description = "List available workflows")]
    pub async fn workflows_list(&self) -> String {
        match self.db.list_workflows() {
            Ok(wfs) => {
                let names: Vec<&str> = wfs.iter().map(|w| w.name.as_str()).collect();
                serde_json::to_string_pretty(&names).unwrap_or_else(|e| format!("serialize error: {e}"))
            }
            Err(e) => format!("error: {e}"),
        }
    }

    #[tool(description = "Submit structured output for a completed workflow stage")]
    pub async fn submit_result(&self, Parameters(params): Parameters<SubmitResultParams>) -> String {
        match self.db.get_job(&params.job_id) {
            Ok(Some(_job)) => {
                let result_json = params.output;
                match self.db.complete_job(&params.job_id, &result_json) {
                    Ok(()) => serde_json::json!({
                        "status": "submitted",
                        "job_id": params.job_id,
                        "stage": params.stage,
                    })
                    .to_string(),
                    Err(e) => format!("error: {e}"),
                }
            }
            Ok(None) => "job not found".into(),
            Err(e) => format!("error: {e}"),
        }
    }

    #[tool(description = "Show workflow content")]
    pub async fn workflows_show(&self, Parameters(params): Parameters<WorkflowNameParams>) -> String {
        match self.db.get_workflow(&params.name) {
            Ok(Some(wf)) => wf.content,
            Ok(None) => format!("workflow '{}' not found", params.name),
            Err(e) => format!("error: {e}"),
        }
    }

    #[tool(description = "List all secrets")]
    pub async fn secrets_list(&self) -> String {
        let dir = std::path::Path::new("/opt/codery/secrets");
        if !dir.is_dir() {
            return serde_json::json!([]).to_string();
        }
        let mut names = Vec::new();
        match std::fs::read_dir(dir) {
            Ok(entries) => {
                for e in entries.flatten() {
                    if let Some(name) = e.file_name().to_str() {
                        names.push(name.to_string());
                    }
                }
                serde_json::to_string_pretty(&names).unwrap_or_else(|e| format!("serialize error: {e}"))
            }
            Err(e) => format!("error: {e}"),
        }
    }

    #[tool(description = "Set a secret value")]
    pub async fn secrets_set(&self, Parameters(params): Parameters<SecretParams>) -> String {
        let dir = std::path::Path::new("/opt/codery/secrets");
        if let Err(e) = std::fs::create_dir_all(dir) {
            return format!("error creating secrets dir: {e}");
        }
        let path = dir.join(&params.name);
        match std::fs::write(&path, &params.value) {
            Ok(()) => {
                let _ = std::fs::set_permissions(&path, std::fs::Permissions::from_mode(0o600));
                format!("secret '{}' set", params.name)
            }
            Err(e) => format!("error: {e}"),
        }
    }

    #[tool(description = "Delete a secret")]
    pub async fn secrets_delete(&self, Parameters(params): Parameters<WorkflowNameParams>) -> String {
        let path = std::path::Path::new("/opt/codery/secrets").join(&params.name);
        match std::fs::remove_file(&path) {
            Ok(()) => format!("secret '{}' deleted", params.name),
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => format!("secret '{}' not found", params.name),
            Err(e) => format!("error: {e}"),
        }
    }
}

use rmcp::transport::streamable_http_server::session::never::NeverSessionManager;
use rmcp::transport::{StreamableHttpServerConfig, StreamableHttpService};

pub fn create_mcp_service(
    db: Arc<Database>,
) -> StreamableHttpService<TrailheadMcpServer, NeverSessionManager> {
    StreamableHttpService::new(
        {
            let db = db.clone();
            move || Ok(TrailheadMcpServer::new(db.clone()))
        },
        NeverSessionManager::default().into(),
        StreamableHttpServerConfig::default()
            .with_stateful_mode(false)
            .disable_allowed_hosts(),
    )
}
