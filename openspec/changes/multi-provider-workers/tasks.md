## 1. Provider Infrastructure (`provider/mod.rs`)

- [ ] 1.1 Add `ProviderKind` enum with `Docker`, `Daytona`, `K3s`, `Localhost` variants
- [ ] 1.2 Implement `FromStr` and `Display` for `ProviderKind`
- [ ] 1.3 Add `ResourceLimits` struct with `cpus`, `memory_mb`, `disk_mb` fields
- [ ] 1.4 Add `resource_limits` and `provider_options` fields to `WorkerSpec`
- [ ] 1.5 Implement `create_provider(kind, config, db) -> Result<Arc<dyn WorkerProvider>>` factory
- [ ] 1.6 Verify `cargo check -p trailhead-service` passes after refactor

## 2. Config Extension (`config.rs`)

- [ ] 2.1 Add `worker_provider: Option<String>` field to `TrailheadConfig`
- [ ] 2.2 Add `WorkerProvidersSection` struct with per-provider config blocks
- [ ] 2.3 Add `DaytonaProviderConfig`, `K3sProviderConfig`, `LocalhostProviderConfig` structs
- [ ] 2.4 Add accessor methods: `daytona_provider()`, `k3s_provider()`, `localhost_provider()`
- [ ] 2.5 Implement `${ENV_VAR}` expansion for secret fields (API key, etc.)
- [ ] 2.6 Add serde tests for new config sections
- [ ] 2.7 Verify backward compatibility: old config without `[worker_providers]` parses fine

## 3. CLI Flag (`main.rs`)

- [ ] 3.1 Add `--worker-provider` flag to `daemon` command args parsing
- [ ] 3.2 Precedence: CLI flag > config file > default ("docker")
- [ ] 3.3 Replace `Arc::new(provider::docker::DockerProvider::new()?)` with
       `create_provider(&kind, &app_config, db.clone())?`
- [ ] 3.4 Verify `cargo check -p trailhead-service` passes

## 4. Localhost Provider (`provider/local.rs`)

- [ ] 4.1 Create struct with `DashMap<String, ChildHandle>` for process tracking
- [ ] 4.2 Implement `create_worker`: spawn worker binary with env, capture stdout/stderr
- [ ] 4.3 Implement `destroy_worker`: SIGTERM → 5s wait → SIGKILL, reap child
- [ ] 4.4 Implement `get_status`: check pid existence via `kill(pid, 0)`
- [ ] 4.5 Implement `get_logs`: read from in-memory ring buffer
- [ ] 4.6 Implement `list_workers`: iterate process map, filter dead entries
- [ ] 4.7 `cargo test -p trailhead-service` passes

## 5. Daytona Provider (`provider/daytona.rs`)

- [ ] 5.1 Create struct with `DaytonaClient` wrapping `reqwest::Client`
- [ ] 5.2 Implement workspace creation via `POST /workspace`
- [ ] 5.3 Implement status polling: `GET /workspace/{id}` until running or timeout
- [ ] 5.4 Implement worker destruction: `DELETE /workspace/{id}`
- [ ] 5.5 Implement log retrieval: `GET /workspace/{id}/logs?tail=N`
- [ ] 5.6 Implement `list_workers`: `GET /workspaces` with name prefix filter
- [ ] 5.7 Project content delivery: git clone inside VM
- [ ] 5.8 `cargo test -p trailhead-service` passes

## 6. k3s Provider (`provider/k3s.rs`)

- [ ] 6.1 Add `kube` crate dependency to `Cargo.toml` (optional, feature-gated)
- [ ] 6.2 Create struct with `kube::Client` and namespace
- [ ] 6.3 Implement pod creation from `WorkerSpec` with `api.create_pod()`
- [ ] 6.4 Implement status watching: watch `pod.status.phase` until Running
- [ ] 6.5 Support two project-path modes: `hostPath` and `git` (init-container)
- [ ] 6.6 Implement worker destruction: `api.delete_pod()`
- [ ] 6.7 Implement log retrieval: `api.get_pod_logs()`
- [ ] 6.8 Implement `list_workers`: `api.list_pods()` with label selector
- [ ] 6.9 `cargo test -p trailhead-service` passes

## 7. API Endpoint (`api.rs`)

- [ ] 7.1 Add `GET /api/v1/providers` route
- [ ] 7.2 Handler returns list of `{kind, configured, status}` for each provider
- [ ] 7.3 Provider status: "available" (configured + reachable), "unconfigured", "error"
- [ ] 7.4 `cargo test -p trailhead-service` passes

## 8. MCP Tool (`mcp.rs`)

- [ ] 8.1 Add `WorkersProvidersListParams` struct with `JsonSchema` derive
- [ ] 8.2 Add `workers_providers_list` tool to `TrailheadMcpServer`
- [ ] 8.3 Tool returns same data as `GET /api/v1/providers`
- [ ] 8.4 `cargo test -p trailhead-service` passes

## 9. Verification

- [ ] 9.1 `cargo test --workspace` passes
- [ ] 9.2 `cargo clippy --workspace -- -D warnings` passes
- [ ] 9.3 `cargo check -p trailhead-service` with `--no-default-features` succeeds (k3s feature-gated)
- [ ] 9.4 Config parse test: valid `trailhead.toml` with all provider sections
- [ ] 9.5 Config parse test: old `trailhead.toml` without `[worker_providers]` defaults to Docker
- [ ] 9.6 daemon_test: `trailhead-service daemon --worker-provider localhost` starts clean
