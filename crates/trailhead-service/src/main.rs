pub mod config;
pub mod db;
pub mod workflow;
pub mod provider;
pub mod jobs;
pub mod scheduler;
pub mod api;
pub mod ide;
pub mod mcp;
pub mod web;
pub mod worker;

use std::sync::Arc;

use crate::provider::WorkerProvider;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        print_usage();
        std::process::exit(1);
    }

    match args[1].as_str() {
        "daemon" => daemon_cmd(&args[2..]).await,
        "jobs" => jobs_cmd(&args[2..]).await,
        "workers" => workers_cmd(&args[2..]).await,
        "projects" => projects_cmd(&args[2..]).await,
        "--help" | "-h" => {
            print_usage();
            Ok(())
        }
        _ => {
            eprintln!("unknown command: {}", args[1]);
            std::process::exit(1);
        }
    }
}

fn print_usage() {
    eprintln!("trailhead-service <command> [options]");
    eprintln!();
    eprintln!("Commands:");
    eprintln!("  daemon [--port PORT] [--db PATH]    Start the service daemon");
    eprintln!("  jobs list [--status STATUS]         List jobs");
    eprintln!("  jobs create --project ID --desc TEXT --workflow NAME");
    eprintln!("  jobs pause <id>                     Pause a job");
    eprintln!("  jobs resume <id>                    Resume a job");
    eprintln!("  jobs cancel <id>                    Cancel a job");
    eprintln!("  jobs attach <id> [--ide IDE]        Attach IDE to job");
    eprintln!("  jobs detach <id>                    Detach from job");
    eprintln!("  workers list                        List workers");
    eprintln!("  workers destroy <id>                Destroy a worker");
    eprintln!("  projects list                       List projects");
    eprintln!("  projects add --name ID --repo URL --branch BRANCH");
}

fn open_port_for_docker_bridges(port: u16) {
    let port_str = port.to_string();
    let already_open = std::process::Command::new("iptables")
        .args(["-C", "INPUT", "-p", "tcp", "--dport", &port_str,
               "-s", "172.16.0.0/12", "-j", "ACCEPT"])
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false);

    if !already_open {
        let result = std::process::Command::new("iptables")
            .args(["-I", "INPUT", "1", "-p", "tcp", "--dport", &port_str,
                   "-s", "172.16.0.0/12", "-j", "ACCEPT"])
            .output();
        match result {
            Ok(o) if o.status.success() =>
                tracing::info!("added iptables ACCEPT rule: Docker bridges -> port {}", port),
            Ok(o) =>
                tracing::warn!("iptables rule failed: {}", String::from_utf8_lossy(&o.stderr)),
            Err(e) =>
                tracing::warn!("iptables not available: {}", e),
        }
    } else {
        tracing::info!("iptables ACCEPT rule already present for port {}", port);
    }
}

async fn daemon_cmd(args: &[String]) -> anyhow::Result<()> {
    let port: u16 = get_flag(args, "--port")
        .unwrap_or_else(|_| "4050".into())
        .parse()
        .map_err(|e| anyhow::anyhow!("invalid port: {}", e))?;
    let db_path = get_flag(args, "--db").unwrap_or_else(|_| "/opt/codery/trailhead.db".into());
    let config_path = get_flag(args, "--config").unwrap_or_else(|_| "/opt/codery/trailhead/trailhead.toml".into());

    open_port_for_docker_bridges(port);

    let app_config = config::TrailheadConfig::load(std::path::Path::new(&config_path))?;
    tracing::info!("loaded config from {}", config_path);

    let db = Arc::new(db::Database::open(&db_path)?);
    db.seed_builtin_workflows(std::path::Path::new("/opt/codery/trailhead/workflows"))?;
    let _ = std::fs::create_dir_all("/opt/codery/secrets");
    let provider = Arc::new(provider::docker::DockerProvider::new()?);

    tracing::info!("cleaning up orphaned worker containers from previous runs");
    match provider.list_workers().await {
        Ok(workers) => {
            for w in &workers {
                if w.id.starts_with("trailhead-worker-") {
                    if let Err(e) = provider.destroy_worker(&w.id).await {
                        tracing::warn!("failed to destroy orphaned worker {}: {}", w.id, e);
                    } else {
                        tracing::info!("destroyed orphaned worker {}", w.id);
                    }
                }
            }
        }
        Err(e) => tracing::warn!("failed to list workers for orphan cleanup: {}", e),
    }

    let app_config = Arc::new(app_config);

    let sched_db = db.clone();
    let sched_provider = provider.clone();
    let sched_config = app_config.clone();
    let sched = Arc::new(scheduler::Scheduler::new(
        sched_db,
        sched_provider.clone(),
        scheduler::SchedulerConfig::default(),
        sched_config,
    ));

    let sched_clone = sched.clone();
    let sched_handle = tokio::spawn(async move {
        sched_clone.run().await;
    });

    let sched_shutdown = sched.clone();
    tokio::spawn(async move {
        tokio::signal::ctrl_c().await.ok();
        tracing::info!("received SIGINT, shutting down scheduler");
        if let Err(e) = sched_shutdown.shutdown().await {
            tracing::error!("scheduler shutdown error: {}", e);
        }
        std::process::exit(0);
    });

    let api_router = api::api_routes(db.clone(), app_config.clone());
    let web_router = web::web_routes(db.clone());
    let mcp_service = mcp::create_mcp_service(db.clone());
    let app = api_router
        .merge(web_router)
        .route_service("/mcp/sse", mcp_service);

    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{}", port)).await?;
    tracing::info!("trailhead-service listening on port {}", port);

    axum::serve(listener, app).await?;
    sched_handle.abort();

    Ok(())
}

async fn jobs_cmd(args: &[String]) -> anyhow::Result<()> {
    if args.is_empty() {
        eprintln!("usage: trailhead-service jobs <list|create|pause|resume|cancel|attach|detach>");
        std::process::exit(1);
    }
    let db_path =
        std::env::var("TRAILHEAD_DB").unwrap_or_else(|_| "/opt/codery/trailhead.db".into());
    let db = db::Database::open(&db_path)?;

    match args[0].as_str() {
        "list" => {
            let status_filter = get_flag(args, "--status").ok();
            let jobs = db.list_jobs()?;
            for job in &jobs {
                if let Some(ref filter) = status_filter {
                    if job.status != *filter {
                        continue;
                    }
                }
                let short_id = job.id.split('-').next().unwrap_or(&job.id);
                println!(
                    "{} {} {} stage={} attempt={}/{}",
                    short_id,
                    job.status,
                    job.description.chars().take(50).collect::<String>(),
                    job.current_stage.as_deref().unwrap_or("-"),
                    job.attempt,
                    job.max_attempts
                );
            }
            println!("({} jobs)", jobs.len());
        }
        "create" => {
            let project_id = get_flag(args, "--project")?;
            let description = get_flag(args, "--description").or_else(|_| get_flag(args, "--desc"))?;
            let workflow = get_flag(args, "--workflow").ok();
            let branch = get_flag(args, "--branch").ok();
            let id = uuid::Uuid::new_v4().to_string();
            db.create_job(
                &id,
                &project_id,
                &description,
                workflow.as_deref(),
                branch.as_deref(),
            )?;
            println!("{}", id);
        }
        "pause" => {
            let id = get_arg_index(args, 1)?;
            let job = db
                .get_job(&id)?
                .ok_or_else(|| anyhow::anyhow!("job not found: {}", id))?;
            jobs::transition(&job.status, "paused")?;
            db.update_job_status(&id, "paused")?;
            println!("paused {}", id);
        }
        "resume" => {
            let id = get_arg_index(args, 1)?;
            let job = db
                .get_job(&id)?
                .ok_or_else(|| anyhow::anyhow!("job not found: {}", id))?;
            jobs::transition(&job.status, "resuming")?;
            db.update_job_status(&id, "resuming")?;
            println!("resumed {}", id);
        }
        "cancel" => {
            let id = get_arg_index(args, 1)?;
            db.update_job_status(&id, "cancelled")?;
            println!("cancelled {}", id);
        }
        "attach" => {
            let id = get_arg_index(args, 1)?;
            let ide_name = get_flag(args, "--ide").unwrap_or_else(|_| "auto".into());
            let job = db
                .get_job(&id)?
                .ok_or_else(|| anyhow::anyhow!("job not found: {}", id))?;
            let adapter = if ide_name == "auto" {
                ide::auto_detect()
            } else {
                ide::get_adapter(&ide_name)
            };
            match adapter {
                Some(a) => {
                    let ctx = ide::JobContext {
                        job_id: id.clone(),
                        current_step: job.current_stage.clone().unwrap_or_default(),
                        last_agent_output: String::new(),
                        changed_files: Vec::new(),
                        workspace_path: std::path::PathBuf::from("/tmp"),
                    };
                    a.open_workspace(std::path::Path::new("/tmp"), &ctx)?;
                    println!("attached via {}", a.name());
                }
                None => return Err(anyhow::anyhow!("unknown IDE: {}", ide_name)),
            }
        }
        "detach" => {
            let id = get_arg_index(args, 1)?;
            println!("detached {}", id);
        }
        _ => {
            eprintln!("unknown jobs subcommand: {}", args[0]);
            std::process::exit(1);
        }
    }
    Ok(())
}

async fn workers_cmd(args: &[String]) -> anyhow::Result<()> {
    if args.is_empty() {
        eprintln!("usage: trailhead-service workers <list|destroy>");
        std::process::exit(1);
    }
    let db_path =
        std::env::var("TRAILHEAD_DB").unwrap_or_else(|_| "/opt/codery/trailhead.db".into());
    let db = db::Database::open(&db_path)?;

    match args[0].as_str() {
        "list" => {
            let workers = db.list_workers()?;
            for w in &workers {
                let short_id = w.id.split('-').next().unwrap_or(&w.id);
                println!(
                    "{} {} job={} hb={}",
                    short_id,
                    w.status,
                    w.job_id.as_deref().unwrap_or("-"),
                    w.heartbeat_at.as_deref().unwrap_or("never")
                );
            }
            println!("({} workers)", workers.len());
        }
        "destroy" => {
            let id = get_arg_index(args, 1)?;
            db.destroy_worker(&id)?;
            println!("destroyed {}", id);
        }
        _ => {
            eprintln!("unknown workers subcommand: {}", args[0]);
            std::process::exit(1);
        }
    }
    Ok(())
}

async fn projects_cmd(args: &[String]) -> anyhow::Result<()> {
    if args.is_empty() {
        eprintln!("usage: trailhead-service projects <list|add>");
        std::process::exit(1);
    }
    let db_path =
        std::env::var("TRAILHEAD_DB").unwrap_or_else(|_| "/opt/codery/trailhead.db".into());
    let db = db::Database::open(&db_path)?;

    match args[0].as_str() {
        "list" => {
            let projects = db.list_projects()?;
            for p in &projects {
                println!("{} {} branch={}", p.id, p.repo_url, p.branch);
            }
            println!("({} projects)", projects.len());
        }
        "add" => {
            let name = get_flag(args, "--name")?;
            let repo = get_flag(args, "--repo")?;
            let branch = get_flag(args, "--branch").unwrap_or_else(|_| "main".into());
            db.create_project(&name, &repo, &branch)?;
            println!("added project {}", name);
        }
        _ => {
            eprintln!("unknown projects subcommand: {}", args[0]);
            std::process::exit(1);
        }
    }
    Ok(())
}

fn get_flag(args: &[String], flag: &str) -> anyhow::Result<String> {
    let idx = args
        .iter()
        .position(|a| a == flag)
        .ok_or_else(|| anyhow::anyhow!("missing flag: {}", flag))?;
    args.get(idx + 1)
        .cloned()
        .ok_or_else(|| anyhow::anyhow!("missing value for: {}", flag))
}

fn get_arg_index(args: &[String], idx: usize) -> anyhow::Result<String> {
    args.get(idx)
        .cloned()
        .ok_or_else(|| anyhow::anyhow!("missing argument at position {}", idx))
}
