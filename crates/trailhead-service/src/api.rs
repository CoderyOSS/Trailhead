use axum::{
    extract::{Path, State},
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use uuid::Uuid;
use crate::db::Database;

#[derive(Deserialize)]
struct RegisterRequest {
    job_id: String,
    status: String,
}

#[derive(Deserialize, Serialize)]
struct TokenUsageReport {
    input_tokens: u64,
    output_tokens: u64,
}

#[derive(Deserialize)]
struct HeartbeatRequest {
    #[allow(dead_code)]
    status: String,
    #[allow(dead_code)]
    current_stage: String,
    #[allow(dead_code)]
    token_usage: TokenUsageReport,
    #[allow(dead_code)]
    files_changed: u64,
    #[allow(dead_code)]
    tool_calls_made: u64,
    #[allow(dead_code)]
    message: String,
}

#[derive(Deserialize)]
struct CheckpointRequest {
    stage: String,
    #[allow(dead_code)]
    response: serde_json::Value,
    session_path: String,
    git_sha: String,
    token_usage: TokenUsageReport,
    files_changed: Vec<String>,
    next_stage: String,
}

#[derive(Deserialize)]
struct CompleteRequest {
    result: String,
}

#[derive(Deserialize)]
struct FailRequest {
    error: String,
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
}

pub fn api_routes(db: Arc<Database>) -> Router {
    Router::new()
        .route("/api/v1/workers/{id}/register", post(register_worker))
        .route("/api/v1/workers/{id}/heartbeat", post(heartbeat))
        .route("/api/v1/workers/{id}/checkpoint", post(checkpoint))
        .route("/api/v1/workers/{id}/complete", post(complete))
        .route("/api/v1/workers/{id}/fail", post(fail))
        .route("/api/v1/jobs/{id}/config", get(job_config))
        .route("/api/v1/jobs/{id}/skill/{name}", get(skill_content))
        .with_state(db)
}

async fn register_worker(
    Path(worker_id): Path<String>,
    State(db): State<Arc<Database>>,
    Json(body): Json<RegisterRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    let worker = db
        .get_worker(&worker_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let worker = worker.ok_or((StatusCode::NOT_FOUND, "worker not found".into()))?;

    if worker.job_id.as_deref() != Some(&body.job_id) {
        return Err((StatusCode::BAD_REQUEST, "job_id mismatch".into()));
    }

    db.update_worker_status(&worker_id, "running")
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    db.update_job_status(&body.job_id, "running")
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::OK)
}

async fn heartbeat(
    Path(worker_id): Path<String>,
    State(db): State<Arc<Database>>,
    Json(_body): Json<HeartbeatRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    db.update_worker_heartbeat(&worker_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    Ok(StatusCode::OK)
}

async fn checkpoint(
    Path(worker_id): Path<String>,
    State(db): State<Arc<Database>>,
    Json(body): Json<CheckpointRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    let worker = db
        .get_worker(&worker_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let worker = worker.ok_or((StatusCode::NOT_FOUND, "worker not found".into()))?;

    let job_id = worker
        .job_id
        .ok_or((StatusCode::BAD_REQUEST, "worker has no job".into()))?;

    let checkpoint_id = Uuid::new_v4().to_string();
    let token_usage = serde_json::to_string(&body.token_usage)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let files_changed = serde_json::to_string(&body.files_changed)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    db.save_checkpoint(
        &checkpoint_id,
        &job_id,
        &body.stage,
        &serde_json::to_string(&body.response)
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?,
        &body.session_path,
        &body.git_sha,
        &token_usage,
        &files_changed,
    )
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    if !body.next_stage.is_empty() {
        let mut history: Vec<serde_json::Value> = serde_json::from_str(
            &db.get_job(&job_id)
                .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
                .ok_or((StatusCode::NOT_FOUND, "job not found".into()))?
                .stage_history,
        )
        .unwrap_or_default();
        history.push(serde_json::json!({"stage": body.stage, "status": "completed"}));
        db.update_job_stage(
            &job_id,
            &body.next_stage,
            &serde_json::to_string(&history)
                .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?,
        )
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    }

    Ok(StatusCode::OK)
}

async fn complete(
    Path(worker_id): Path<String>,
    State(db): State<Arc<Database>>,
    Json(body): Json<CompleteRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    let worker = db
        .get_worker(&worker_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let worker = worker.ok_or((StatusCode::NOT_FOUND, "worker not found".into()))?;

    if let Some(ref job_id) = worker.job_id {
        db.complete_job(job_id, &body.result)
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    }
    db.destroy_worker(&worker_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::OK)
}

async fn fail(
    Path(worker_id): Path<String>,
    State(db): State<Arc<Database>>,
    Json(body): Json<FailRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    let worker = db
        .get_worker(&worker_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let worker = worker.ok_or((StatusCode::NOT_FOUND, "worker not found".into()))?;

    if let Some(ref job_id) = worker.job_id {
        let job = db
            .get_job(job_id)
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
        if let Some(job) = job {
            let status = if job.attempt < job.max_attempts {
                "failed_retryable"
            } else {
                "failed_final"
            };
            db.fail_job(job_id, &body.error, status)
                .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
        }
    }
    db.destroy_worker(&worker_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::OK)
}

async fn job_config(
    Path(job_id): Path<String>,
    State(db): State<Arc<Database>>,
) -> Result<Json<JobConfigResponse>, (StatusCode, String)> {
    let job = db
        .get_job(&job_id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let job = job.ok_or((StatusCode::NOT_FOUND, "job not found".into()))?;

    let stage = job.current_stage.clone().unwrap_or_default();

    let skill_content = if let Some(ref wf_name) = job.workflow_name {
        let wf = db
            .get_workflow(wf_name)
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
        wf.map(|w| w.content).unwrap_or_default()
    } else {
        String::new()
    };

    Ok(Json(JobConfigResponse {
        job_id: job.id,
        stage,
        prompt: String::new(),
        tools: vec![
            "bash".into(),
            "read".into(),
            "write".into(),
            "edit".into(),
            "glob".into(),
            "grep".into(),
        ],
        max_tokens: 8096,
        timeout_secs: 600,
        skill_content,
    }))
}

async fn skill_content(
    Path((job_id, skill_name)): Path<(String, String)>,
    State(_db): State<Arc<Database>>,
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
        "job_id": job_id,
        "skill": skill_name,
        "content": content,
    })))
}
