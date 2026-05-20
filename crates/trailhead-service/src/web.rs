use axum::{
    Router,
    extract::{Path, State},
    http::StatusCode,
    response::{
        sse::{Event, Sse},
        IntoResponse,
    },
    routing::{get, post},
    Json,
};
use serde::Deserialize;
use std::convert::Infallible;
use std::sync::Arc;

use crate::db::Database;

#[derive(Deserialize)]
struct CreateJobBody {
    project_id: String,
    description: String,
    workflow: Option<String>,
    branch: Option<String>,
    workspace_path: Option<String>,
}

#[derive(Deserialize)]
struct CreateProjectBody {
    repo_url: String,
    branch: Option<String>,
}

#[derive(Deserialize)]
struct AttachBody {
    ide: Option<String>,
}

#[derive(Deserialize)]
struct ValidateWorkflowBody {
    content: String,
}

#[derive(Deserialize)]
struct CreateWorkflowBody {
    name: String,
    content: String,
}

pub fn web_routes(db: Arc<Database>) -> Router {
    Router::new()
        .route("/api/v1/jobs", get(list_jobs).post(create_job))
        .route("/api/v1/jobs/{id}", get(get_job))
        .route("/api/v1/jobs/{id}/pause", post(pause_job))
        .route("/api/v1/jobs/{id}/resume", post(resume_job))
        .route("/api/v1/jobs/{id}/cancel", post(cancel_job))
        .route("/api/v1/jobs/{id}/attach", post(attach_job))
        .route("/api/v1/workers", get(list_workers))
        .route("/api/v1/projects", get(list_projects).post(create_project))
        .route("/api/v1/workflows", post(create_workflow))
        .route("/api/v1/workflows/validate", post(validate_workflow))
        .route("/api/v1/events", get(events_sse))
        .fallback(serve_spa)
        .with_state(db)
}

async fn list_jobs(
    State(db): State<Arc<Database>>,
) -> Result<Json<Vec<crate::db::JobRow>>, (StatusCode, String)> {
    db.list_jobs()
        .map(Json)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))
}

async fn create_job(
    State(db): State<Arc<Database>>,
    Json(body): Json<CreateJobBody>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let id = uuid::Uuid::new_v4().to_string();
    db.create_job(&id, &body.project_id, &body.description, body.workflow.as_deref(), body.branch.as_deref(), body.workspace_path.as_deref())
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    Ok(Json(serde_json::json!({"job_id": id})))
}

async fn get_job(
    Path(id): Path<String>,
    State(db): State<Arc<Database>>,
) -> Result<Json<crate::db::JobRow>, (StatusCode, String)> {
    db.get_job(&id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .map(Json)
        .ok_or((StatusCode::NOT_FOUND, "job not found".into()))
}

async fn pause_job(
    Path(id): Path<String>,
    State(db): State<Arc<Database>>,
) -> Result<StatusCode, (StatusCode, String)> {
    let job = db
        .get_job(&id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .ok_or((StatusCode::NOT_FOUND, "job not found".into()))?;
    crate::jobs::transition(&job.status, "paused")
        .map_err(|e| (StatusCode::CONFLICT, e.to_string()))?;
    db.update_job_status(&id, "paused")
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    Ok(StatusCode::OK)
}

async fn resume_job(
    Path(id): Path<String>,
    State(db): State<Arc<Database>>,
) -> Result<StatusCode, (StatusCode, String)> {
    let job = db
        .get_job(&id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .ok_or((StatusCode::NOT_FOUND, "job not found".into()))?;
    crate::jobs::transition(&job.status, "resuming")
        .map_err(|e| (StatusCode::CONFLICT, e.to_string()))?;
    db.update_job_status(&id, "resuming")
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    Ok(StatusCode::OK)
}

async fn cancel_job(
    Path(id): Path<String>,
    State(db): State<Arc<Database>>,
) -> Result<StatusCode, (StatusCode, String)> {
    let job = db
        .get_job(&id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .ok_or((StatusCode::NOT_FOUND, "job not found".into()))?;
    if crate::jobs::is_terminal(&job.status) {
        return Err((StatusCode::CONFLICT, format!("job already {}", job.status)));
    }
    db.update_job_status(&id, "cancelled")
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    Ok(StatusCode::OK)
}

async fn attach_job(
    Path(id): Path<String>,
    State(db): State<Arc<Database>>,
    Json(body): Json<AttachBody>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let ide_name = body.ide.as_deref().unwrap_or("ssh");
    let adapter = crate::ide::get_adapter(ide_name)
        .ok_or_else(|| (StatusCode::BAD_REQUEST, format!("unknown ide: {ide_name}")))?;

    let job = db
        .get_job(&id)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .ok_or((StatusCode::NOT_FOUND, "job not found".into()))?;

    let ctx = crate::ide::JobContext {
        job_id: job.id.clone(),
        current_step: job.current_stage.clone().unwrap_or_default(),
        last_agent_output: String::new(),
        changed_files: Vec::new(),
        workspace_path: std::path::PathBuf::from("/tmp"),
    };

    adapter
        .open_workspace(std::path::Path::new("/tmp"), &ctx)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(serde_json::json!({"attached": true, "ide": ide_name})))
}

async fn list_workers(
    State(db): State<Arc<Database>>,
) -> Result<Json<Vec<crate::db::WorkerRow>>, (StatusCode, String)> {
    db.list_workers()
        .map(Json)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))
}

async fn list_projects(
    State(db): State<Arc<Database>>,
) -> Result<Json<Vec<crate::db::ProjectRow>>, (StatusCode, String)> {
    db.list_projects()
        .map(Json)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))
}

async fn create_project(
    State(db): State<Arc<Database>>,
    Json(body): Json<CreateProjectBody>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let id = uuid::Uuid::new_v4().to_string();
    let branch = body.branch.as_deref().unwrap_or("main");
    db.create_project(&id, &body.repo_url, branch)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    Ok(Json(serde_json::json!({"project_id": id})))
}

async fn validate_workflow(
    Json(body): Json<ValidateWorkflowBody>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    match crate::workflow::parser::parse_workflow(&body.content) {
        Ok(wf) => Ok(Json(serde_json::json!({
            "valid": true,
            "name": wf.name,
            "stages": wf.stages.len()
        }))),
        Err(e) => Ok(Json(serde_json::json!({
            "valid": false,
            "error": e.to_string()
        }))),
    }
}

async fn create_workflow(
    State(db): State<Arc<Database>>,
    Json(body): Json<CreateWorkflowBody>,
) -> Result<StatusCode, (StatusCode, String)> {
    db.save_workflow(&body.name, &body.content, "", "api", None)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    Ok(StatusCode::CREATED)
}

async fn events_sse() -> Sse<impl futures_util::Stream<Item = Result<Event, Infallible>>> {
    Sse::new(futures_util::stream::empty())
}

async fn serve_spa() -> impl IntoResponse {
    StatusCode::NOT_FOUND
}
