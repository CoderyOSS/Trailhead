use anyhow::{Context, Result};
use async_trait::async_trait;
use bollard::Docker;
use bollard::container::{
    Config, CreateContainerOptions, LogOutput, LogsOptions, RemoveContainerOptions,
    StartContainerOptions,
};
use bollard::models::HostConfig;
use futures_util::StreamExt;
use super::{WorkerHandle, WorkerProvider, WorkerSpec};

pub struct DockerProvider {
    docker: Docker,
    network: String,
}

impl DockerProvider {
    pub fn new() -> Result<Self> {
        let docker = Docker::connect_with_local_defaults().context("connect to Docker")?;
        Ok(Self {
            docker,
            network: "codery-net".into(),
        })
    }

    pub fn with_network(mut self, network: String) -> Self {
        self.network = network;
        self
    }
}

#[async_trait]
impl WorkerProvider for DockerProvider {
    async fn create_worker(&self, spec: &WorkerSpec) -> Result<WorkerHandle> {
        let container_name = format!("trailhead-worker-{}", spec.job_id);

        let mut env = vec![
            format!("WORKER_ID={}", spec.job_id),
            format!("JOB_ID={}", spec.job_id),
            format!("LLM_PROVIDER={}", spec.llm_provider),
            format!("LLM_MODEL={}", spec.llm_model),
            format!("LLM_API_KEY={}", spec.llm_api_key),
            format!("LLM_BASE_URL={}", spec.llm_base_url),
        ];
        for (k, v) in &spec.env {
            env.push(format!("{}={}", k, v));
        }

        let workspace_str = spec
            .workspace_path
            .to_str()
            .unwrap_or("/tmp/workspace");

        let config = Config {
            image: Some(spec.agent_runner_image.clone()),
            env: Some(env),
            host_config: Some(HostConfig {
                binds: Some(vec![format!("{}:{}:rw", workspace_str, "/workspace")]),
                network_mode: Some(self.network.clone()),
                ..Default::default()
            }),
            working_dir: Some("/workspace".into()),
            ..Default::default()
        };

        let create_opts = CreateContainerOptions {
            name: container_name.clone(),
            platform: None,
        };

        let result = self
            .docker
            .create_container(Some(create_opts), config)
            .await
            .context("create container")?;

        self.docker
            .start_container(&result.id, None::<StartContainerOptions<String>>)
            .await
            .context("start container")?;

        Ok(WorkerHandle {
            id: container_name,
            provider_id: result.id,
            status: trailhead_core::types::WorkerStatus::Running,
            ip_address: None,
        })
    }

    async fn destroy_worker(&self, id: &str) -> Result<()> {
        let _ = self.docker.stop_container(id, None).await;
        self.docker
            .remove_container(
                id,
                Some(RemoveContainerOptions {
                    force: true,
                    ..Default::default()
                }),
            )
            .await
            .context("remove container")?;
        Ok(())
    }

    async fn get_status(&self, id: &str) -> Result<trailhead_core::types::WorkerStatus> {
        let info = self
            .docker
            .inspect_container(id, None)
            .await
            .context("inspect container")?;
        let state = info.state.context("container state")?;
        let running = state.running.unwrap_or(false);
        let exit_code = state.exit_code.unwrap_or(-1);
        let status_val = state.status;

        if running {
            Ok(trailhead_core::types::WorkerStatus::Running)
        } else if status_val == Some(bollard::models::ContainerStateStatusEnum::CREATED) {
            Ok(trailhead_core::types::WorkerStatus::Creating)
        } else if status_val == Some(bollard::models::ContainerStateStatusEnum::EXITED) && exit_code == 0 {
            Ok(trailhead_core::types::WorkerStatus::Stopped)
        } else {
            Ok(trailhead_core::types::WorkerStatus::Failed(format!(
                "exit code {}",
                exit_code
            )))
        }
    }

    async fn get_logs(&self, id: &str, tail: usize) -> Result<String> {
        let options = LogsOptions {
            stdout: true,
            stderr: true,
            tail: tail.to_string(),
            ..Default::default()
        };
        let mut stream = self.docker.logs(id, Some(options));
        let mut logs = String::new();
        while let Some(chunk) = stream.next().await {
            match chunk {
                Ok(LogOutput::StdOut { message }) => {
                    logs.push_str(&String::from_utf8_lossy(&message));
                }
                Ok(LogOutput::StdErr { message }) => {
                    logs.push_str(&String::from_utf8_lossy(&message));
                }
                _ => {}
            }
        }
        Ok(logs)
    }

    async fn list_workers(&self) -> Result<Vec<WorkerHandle>> {
        let containers = self
            .docker
            .list_containers::<String>(None)
            .await
            .context("list containers")?;
        let mut handles = Vec::new();
        for c in containers {
            let names = c.names.unwrap_or_default();
            let name = names
                .first()
                .map(|n| n.trim_start_matches('/').to_string())
                .unwrap_or_default();
            if name.starts_with("trailhead-worker-") {
                handles.push(WorkerHandle {
                    id: name,
                    provider_id: c.id.unwrap_or_default(),
                    status: trailhead_core::types::WorkerStatus::Running,
                    ip_address: None,
                });
            }
        }
        Ok(handles)
    }
}
