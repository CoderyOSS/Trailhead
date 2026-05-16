use axum::{
    extract::{Path, State},
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use crate::config::TrailheadConfig;
use crate::db::Database;

#[derive(Deserialize)]
struct CreateWorkerRequest {
    job_id: String,
    provider: Option<String>,
}

#[derive(Serialize)]
struct JobConfigResponse {
    job_id: String,
    stage: String,
    prompt: String,
    tools: Vec<String>,
    max_tokens: u32,
    timeout_secs: u64,
    skill_content: String,
    model: String,
    provider: String,
    base_url: String,
    api_key: String,
}

type AppState = (Arc<Database>, Arc<TrailheadConfig>);

pub fn api_routes(db: Arc<Database>, config: Arc<TrailheadConfig>) -> Router {
    Router::new()
        .route("/api/v1/workers", post(create_worker))
        .route("/api/v1/jobs/{id}/config", get(job_config))
        .route("/api/v1/jobs/{id}/skill/{name}", get(skill_content))
        .with_state((db, config))
}

async fn create_worker(
    State((db, _config)): State<AppState>,
    Json(body): Json<CreateWorkerRequest>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let id = uuid::Uuid::new_v4().to_string();
    let provider = body.provider.as_deref().unwrap_or("test");
    db.create_worker(&id, &body.job_id, provider)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    Ok(Json(serde_json::json!({"worker_id": id})))
}

async fn job_config(
    Path(job_id): Path<String>,
    State((db, config)): State<AppState>,
) -> Result<Json<JobConfigResponse>, (StatusCode, String)> {
    let job = db
        .get_job(&job_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let job = job.ok_or((StatusCode::NOT_FOUND, "job not found".into()))?;

    let stage = job.current_stage.clone().unwrap_or_default();

    let workflow_content = if let Some(ref wf_name) = job.workflow_name {
        let wf = db
            .get_workflow(wf_name)
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
        wf.map(|w| w.content).unwrap_or_default()
    } else {
        String::new()
    };

    let parsed_workflow = crate::workflow::parser::parse_workflow(&workflow_content).ok();
    let stage_def = parsed_workflow
        .as_ref()
        .and_then(|wf| wf.stages.get(&stage));

    let prompt = if let Some(s) = stage_def {
        if s.prompt.is_empty() {
            job.description.clone()
        } else {
            let vars = crate::workflow::resolver::TemplateVars {
                input: job.description.clone(),
                project: crate::workflow::resolver::ProjectVars {
                    name: String::new(),
                    repo: String::new(),
                    branch: String::new(),
                },
                stages: std::collections::HashMap::new(),
                env: std::collections::HashMap::new(),
            };
            crate::workflow::resolver::resolve_prompt(&s.prompt, &vars)
                .unwrap_or_else(|_| s.prompt.clone())
        }
    } else {
        job.description.clone()
    };

    let skill_content = if let Some(ref skill_name) = stage_def.and_then(|s| s.skill.as_ref()) {
        let skill_path = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("skills")
            .join(format!("{}.md", skill_name));
        if skill_path.exists() {
            std::fs::read_to_string(&skill_path).unwrap_or_default()
        } else {
            String::new()
        }
    } else {
        String::new()
    };

    let stage_model = stage_def.and_then(|s| s.model.as_deref());
    let resolved = config.resolve_model(stage_model)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let default_tools = vec![
        "bash".into(),
        "read".into(),
        "write".into(),
        "edit".into(),
        "glob".into(),
        "grep".into(),
    ];
    let tools = stage_def
        .and_then(|s| if s.tools.is_empty() { None } else { Some(s.tools.clone()) })
        .unwrap_or(default_tools);

    let max_tokens = stage_def.and_then(|s| s.max_tokens).unwrap_or(8096);
    let timeout_secs = stage_def.and_then(|s| s.timeout_secs).unwrap_or(600);

    Ok(Json(JobConfigResponse {
        job_id: job.id,
        stage,
        prompt,
        tools,
        max_tokens,
        timeout_secs,
        skill_content,
        model: resolved.model_id,
        provider: resolved.api,
        base_url: resolved.base_url,
        api_key: resolved.api_key,
    }))
}

async fn skill_content(
    Path((_job_id, skill_name)): Path<(String, String)>,
    State((_db, _config)): State<AppState>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let skill_path = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("skills")
        .join(format!("{}.md", skill_name));

    let content = if skill_path.exists() {
        std::fs::read_to_string(&skill_path)
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
    } else {
        String::new()
    };

    Ok(Json(serde_json::json!({
        "content": content,
    })))
}
