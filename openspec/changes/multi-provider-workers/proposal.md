## Why

Trailhead hardcodes Docker as the only worker platform (`provider::docker::DockerProvider`).
Users who want to run workers on k3s clusters, Daytona cloud VMs, or directly on the
host (localhost) are locked out. Adding more provider backends unlocks deployment
flexibility: cheap local dev, ephemeral cloud sandboxes, and production Kubernetes.

## What Changes

- **Provider kind enum** — `ProviderKind { Docker, Daytona, K3s, Localhost }` in
  `provider/mod.rs`
- **Provider factory** — `create_provider(kind, config) -> Arc<dyn WorkerProvider>`
  replaces the hardcoded `DockerProvider::new()` in `main.rs`
- **Config extension** — `trailhead.toml` gains `[worker_providers.*]` sections for
  per-provider settings (Daytona API key, k3s kubeconfig, localhost workspace dir)
- **3 new provider modules** — `provider/daytona.rs`, `provider/k3s.rs`,
  `provider/local.rs` implementing the existing `WorkerProvider` trait
- **WorkerSpec enrichment** — optional `ResourceLimits` and `provider_options` for
  provider-specific tuning
- **CLI flag** — `trailhead-service daemon --worker-provider <kind>` to select
  provider at startup
- **API endpoint** — `GET /api/v1/providers` lists configured providers and their
  status
- **MCP tool** — `workers_providers_list` exposes provider info to IDEs

No changes to `scheduler.rs`, `jobs.rs`, `web.rs`, or `db.rs` — the existing
`Arc<dyn WorkerProvider>` abstraction already insulates them.

## Capabilities

### New

- `daytona-worker-provider` — Create/destroy/list/get-status/get-logs for workers
  running as Daytona cloud VMs. Uses Daytona REST API.
- `k3s-worker-provider` — Create/destroy/list/get-status/get-logs for workers
  running as k3s pods. Uses kube-rs API.
- `localhost-worker-provider` — Create/destroy/list/get-status/get-logs for workers
  running as localhost child processes.
- `providers-api` — `GET /api/v1/providers` endpoint + MCP tool for querying
  available worker platforms.

### Modified

- `worker-provider` — `provider/mod.rs` gains `ProviderKind` enum, factory function,
  `ResourceLimits` struct, `provider_options` field on `WorkerSpec`.
- `daemon-cli` — `--worker-provider` flag selects backend at daemon startup.
- `service-config` — `trailhead.toml` accepts `worker_provider` + per-provider
  config blocks.
- `scheduler` — No source changes, but runtime behavior changes: workers are
  created/destroyed via the selected provider instead of always Docker.

## Impact

- **Code**: 3 new files (`provider/daytona.rs`, `provider/k3s.rs`,
  `provider/local.rs`). Changes to `provider/mod.rs`, `config.rs`, `main.rs`,
  `api.rs`, `mcp.rs`.
- **Dependencies**: `kube` crate (k3s provider). Daytona and localhost use existing
  `reqwest` and `tokio::process`.
- **Config**: `trailhead.toml` format extended with `[worker_providers.*]` sections.
  Old configs without these sections default to Docker — backward compatible.
- **No breaking API changes**: Existing API endpoints unchanged. New endpoints are
  additive.
