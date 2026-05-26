## Context

Trailhead v0.3.6 runs on a VPS host with direct Docker socket access via
`bollard`. The existing `WorkerProvider` trait in `provider/mod.rs` already
abstracts worker lifecycle — `scheduler.rs` receives `Arc<dyn WorkerProvider>`
and never touches the concrete type. This design leverages that existing
abstraction to add three new provider backends without touching scheduler,
database, or job-state code.

## Goals / Non-Goals

**Goals:**
- Provider-kind enum + factory function to select backend at daemon startup
- Three new providers: Daytona VMs, k3s pods, localhost processes
- All providers implement the same `WorkerProvider` trait (full coverage:
  create_worker, destroy_worker, get_status, get_logs, list_workers)
- `trailhead.toml` config sections per provider type with deserialization into
  typed config structs
- `GET /api/v1/providers` endpoint + MCP tool for IDE queries
- CLI `--worker-provider` flag on `daemon` command
- Existing tests pass without modification

**Non-Goals:**
- Dynamic provider switching per-job (provider is a daemon-level choice, not
  per-job)
- Autoscaling or provider pool management
- Provider monitoring or health checks beyond status queries
- Migration of existing Docker workers to another provider
- GUI provider configuration

## Decisions

### Provider Kind as String, Not Enum in Config
**Chosen: String in config, enum in Rust.** The `trailhead.toml` value
`worker_provider = "daytona"` is parsed into `ProviderKind` via
`FromStr`. This keeps config human-friendly and opens the door for
plugin-based providers later without config format changes.

### Single Daemon-Wide Provider
**Chosen: One provider per daemon instance.** All workers for this daemon
instance use the same provider backend. Per-job provider selection would
require routing worker lifecycle calls to different provider instances and
addressing provider-specific fields in the job creation API — complexity
not yet justified. Can revisit when multi-cluster scheduling is needed.

### Localhost Without OS Sandboxing (Phase 1)
**Chosen: No seccomp/namespaces/local-user isolation in the first
implementation.** The localhost provider spawns the worker binary directly.
Admins who enable it are expected to run Trailhead in a dedicated
environment or container. OS-level isolation can be added as a follow-up
(separate system user per worker, PR_SET_NO_NEW_PRIVS, cgroup limits).

### WorkerSpec ResourceLimits as Optional Struct
**Chosen: `Option<ResourceLimits>` in WorkerSpec.** Each provider maps
limits to its own primitives:
- Docker: `HostConfig.memory`, `HostConfig.nano_cpus`
- Daytona: VM size tier
- k3s: Pod resource requests/limits
- Localhost: cgroup v2 limits (future)

Null/None means provider defaults.

## Provider Integration Details

### Daytona (`provider/daytona.rs`)

Daytona provides a REST API for workspace lifecycle.
Documentation: https://daytona.io/docs

```
create_worker(spec):
  1. POST /workspace
     { name: "trailhead-{job_id}",
       image: spec.worker_image,
       env: spec.env,
       git_context: { url: null }  // no clone; push-based
     }
  2. Poll GET /workspace/{id} until status == "running"
  3. Return WorkerHandle { id: container_name, provider_id: workspace_id,
                           status: Running, ip_address }

destroy_worker(id):
  1. DELETE /workspace/{provider_id}

get_status(id):
  1. GET /workspace/{provider_id}
  2. Map: running→Running, creating→Creating, stopped→Stopped, error→Failed

get_logs(id, tail):
  1. GET /workspace/{provider_id}/logs?tail=N

list_workers():
  1. GET /workspaces?prefix=trailhead-
  2. Map each to WorkerHandle
```

**Project content delivery**: Daytona VMs don't bind-mount host directories.
Trailhead pushes project content to the VM after creation via:
1. `rsync` over SSH (if VM exposes SSH), or
2. Tarball upload via Daytona file API, or
3. Git clone inside the VM (Daytona's native model)

Option 3 (git clone) is simplest: Trailhead passes the repo URL to Daytona
at create time, and Daytona clones it. This means the project branch must
already be pushed to the remote — local uncommitted changes are not
available in the VM.

### k3s (`provider/k3s.rs`)

Uses the `kube` crate to interact with the k3s API server
(https://kube.rs).

```
create_worker(spec):
  1. Build v1.Pod spec:
     - name: "trailhead-worker-{job_id}"
     - image: spec.worker_image
     - env: spec.env entries
     - volumeMounts:
       - hostPath: spec.project_path → /workspace
         (or emptyDir + git-init sidecar if hostPath not available)
     - restartPolicy: Never
  2. api.create_pod(&pod).await
  3. Watch pod.status.phase until Running
  4. Return WorkerHandle { id: pod_name, provider_id: uid,
                           status: Running, ip_address: pod_ip }

destroy_worker(id):
  1. api.delete_pod(&provider_id).await

get_status(id):
  1. api.get_pod(&provider_id).await
  2. Map phase: Running→Running, Pending→Creating,
     Succeeded→Stopped, Failed→Failed

get_logs(id, tail):
  1. api.get_pod_logs(&provider_id, tail).await
```

**Project path delivery**: Two modes:
- **hostPath**: Bind-mount `spec.project_path` into the pod. Requires
  the host directory to be accessible on the k3s node (single-node k3s
  or NFS mount on all nodes).
- **git clone**: Use an init-container that clones the repo into an
  emptyDir volume shared with the worker container. No host filesystem
  dependency, works on multi-node clusters.

Config flag: `project_path_mode = "hostPath" | "git"` in the
`[worker_providers.k3s]` section.

### Localhost (`provider/local.rs`)

Spawns the worker binary as a child process on the host machine.

```
create_worker(spec):
  1. Build args + env from spec
  2. child = Command::new(spec.worker_binary)
          .args([...])
          .envs(spec.env)
          .stdout(Stdio::piped())
          .stderr(Stdio::piped())
          .kill_on_drop(true)
          .spawn()
  3. Store child PID in process table
  4. Return WorkerHandle { id: pid_string,
                           provider_id: pid_string,
                           status: Running, ip_address: "127.0.0.1" }

destroy_worker(id):
  1. Send SIGTERM, wait 5s, then SIGKILL

get_status(id):
  1. Check if process exists via kill(pid, 0)
  2. Alive → Running, Gone → Stopped

get_logs(id, tail):
  1. Read from in-memory ring buffer (captured stdout/stderr)

list_workers():
  1. Scan /proc for known PIDs, filter trailhead workers
```

**Process tracking**: Maintain a `DashMap<String, ChildHandle>` in the
provider struct. On `create_worker`, store the child PID and stdout/stderr
capture handles. On `destroy_worker`, terminate the child. On `list_workers`,
iterate the map and `try_wait` each entry.

**Worker binary path**: Configurable via `[worker_providers.localhost]
worker_binary = "/usr/local/bin/opencode"` in trailhead.toml.

## Config Schema

```toml
# Select default worker provider: "docker", "daytona", "k3s", "localhost"
worker_provider = "docker"

[worker_providers.daytona]
api_key = "${DAYTONA_API_KEY}"
api_url = "https://api.daytona.io"
region = "us-east-1"
vm_size = "small"
project_content = "git"             # "git" | "push"

[worker_providers.k3s]
kubeconfig = "/etc/kubernetes/kubeconfig"
namespace = "trailhead"
project_path_mode = "git"           # "hostPath" | "git"
image_pull_policy = "Always"

[worker_providers.localhost]
worker_binary = "/usr/local/bin/opencode"
workspace_dir = "/opt/codery/workspaces"
```

## Rust Type Changes

### ProviderKind enum + factory (`provider/mod.rs`)

```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ProviderKind {
    Docker,
    Daytona,
    K3s,
    Localhost,
}

impl FromStr for ProviderKind { /* parse "docker", "daytona", etc. */ }

pub fn create_provider(
    kind: &ProviderKind,
    config: &TrailheadConfig,
    db: Arc<Database>,
) -> Result<Arc<dyn WorkerProvider>> {
    match kind {
        ProviderKind::Docker => Ok(Arc::new(docker::DockerProvider::new()?)),
        ProviderKind::Daytona => {
            let cfg = config.daytona_provider()?;
            Ok(Arc::new(daytona::DaytonaProvider::new(cfg)?))
        }
        ProviderKind::K3s => {
            let cfg = config.k3s_provider()?;
            Ok(Arc::new(k3s::K3sProvider::new(cfg)?))
        }
        ProviderKind::Localhost => {
            let cfg = config.localhost_provider()?;
            Ok(Arc::new(local::LocalhostProvider::new(cfg)?))
        }
    }
}
```

### WorkerSpec enrichment

```rust
pub struct ResourceLimits {
    pub cpus: Option<f32>,
    pub memory_mb: Option<u32>,
    pub disk_mb: Option<u32>,
}

pub struct WorkerSpec {
    pub job_id: String,
    pub project_path: PathBuf,
    pub worker_image: String,
    pub env: HashMap<String, String>,
    pub trailhead_url: String,
    pub resource_limits: Option<ResourceLimits>,
    pub provider_options: HashMap<String, String>,
}
```

### TrailheadConfig extension

```rust
pub struct TrailheadConfig {
    pub model: Option<String>,
    pub provider: HashMap<String, ProviderConfig>,
    pub worker_provider: Option<String>,       // NEW
    pub worker_providers: Option<WorkerProvidersSection>,  // NEW
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkerProvidersSection {
    pub daytona: Option<DaytonaProviderConfig>,
    pub k3s: Option<K3sProviderConfig>,
    pub localhost: Option<LocalhostProviderConfig>,
}

pub struct DaytonaProviderConfig {
    pub api_key: String,
    pub api_url: String,
    pub region: String,
    pub vm_size: String,
    pub project_content: Option<String>,
}
// + K3sProviderConfig, LocalhostProviderConfig
```

## File Layout

```
crates/trailhead-service/src/
├── provider/
│   ├── mod.rs         ← ProviderKind enum, create_producer factory, ResourceLimits
│   ├── docker.rs      ← unchanged (existing)
│   ├── daytona.rs     ← NEW
│   ├── k3s.rs         ← NEW
│   └── local.rs       ← NEW
├── config.rs          ← +worker_provider, worker_providers fields
├── main.rs            ← factory call replaces DockerProvider::new()
├── api.rs             ← +GET /api/v1/providers
└── mcp.rs             ← +workers_providers_list tool
```

## Security

1. **Daytona API key**: Read from `trailhead.toml` with `${ENV_VAR}` expansion,
   stored in process memory only. Never logged or exposed in API responses.
2. **k3s kubeconfig**: Path to kubeconfig file. File permissions validated
   (must be 0600 or owner-only). No inline credentials in config.
3. **Localhost**: Worker process inherits Trailhead's user. No sandboxing in
   Phase 1. Config must be read-only by trailhead user. Warning logged when
   localhost provider is selected.
4. **All providers**: `submit_result` MCP tool validates job ownership and
   stage matching (existing mechanism unchanged).
