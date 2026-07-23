# Config Objects — Design Spec

**Date:** 2026-07-23
**Status:** Approved
**Scope:** Backend (Carta) + Frontend (CartaClient) — end-to-end

## Problem

Nodes need persistent, reusable configuration (credentials, endpoints, tuning parameters) that:
- outlives flow redeploys,
- is shared across flows within a project,
- is editable without touching flow YAML,
- is stored server-side (not in browser local storage).

## Solution

Configuration objects: named Elixir literals (maps, keyword lists, etc.) stored server-side in Mnesia, scoped to a project. A node opts into a stored object via `config.config_key` in its flow YAML. At node startup, the engine deep-merges the stored object over the node's inline `config:` map (stored wins).

## Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Storage | Mnesia (`:set`, `disc_copies`) | Built-in, transactional, disc-backed, no extra deps |
| Namespace | Project-local only | User directive — global adds complexity, not needed now |
| Record | `{config, {project, key}, source, term, updated_at}` | Source for audit + round-trip editing; term for fast lookup |
| Merge | Stored wins (deep) | Node-specific inline `config:` is the base; stored object overrides |
| Validation | Deploy-time | Fail fast before job launch; live lint in UI is advisory |
| Secrets | Deferred | Future PR: encrypted secrets file, CartaClient unlocks at job launch |

## Backend (Carta)

### Module: `Carta.ConfigStore`

GenServer wrapping Mnesia. Supervised in `lib/carta/application.ex` **after** `Carta.FlowsSup` (flows depend on it at deploy-time).

```elixir
defmodule Carta.ConfigStore do
  use GenServer
  require Logger

  @table :carta_configs

  # Client API
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def put(project, key, source), do: GenServer.call(__MODULE__, {:put, project, key, source})
  def get(project, key), do: read({project, key})
  def list(project), do: GenServer.call(__MODULE__, {:list, project})
  def delete(project, key), do: GenServer.call(__MODULE__, {:delete, project, key})

  # Internal
  # - init: ensure schema dir, create_schema (idempotent), create_table (idempotent), wait_for_tables
  # - writes inside :mnesia.transaction
  # - reads via :mnesia.dirty_read (no transaction needed)
end
```

Schema dir resolution (mirrors `Carta.Store.configured_dir/0` 3-tier pattern):

1. `CONFIGS_DIR` env
2. `Application.get_env(:carta_fbp, :configs_dir)`
3. `Path.join(Carta.Project.flows_dir(), "configs")`

`mix.exs`: add `:mnesia` to `extra_applications`.

### API (5 endpoints)

All under `/api/v1/configs`. `project` is always required (query param for GET/DELETE, body field for POST/PUT).

| Method | Path | Body | Response |
|---|---|---|---|
| GET | `/api/v1/configs?project=NAME` | — | `[{key, source, updated_at}]` |
| POST | `/api/v1/configs` | `{project, key, source}` | 201 created \| 400 bad term \| 409 exists |
| GET | `/api/v1/configs/:key?project=NAME` | — | `{key, source, term, updated_at}` \| 404 |
| PUT | `/api/v1/configs/:key?project=NAME` | `{source}` | 200 updated \| 400 bad term \| 404 |
| DELETE | `/api/v1/configs/:key?project=NAME` | — | 204 \| 404 |

Source validation on write: reuse `Carta.ElixirTerm.parse_literal/1`. Reject on parse failure — do not write.

### Node hook

`Carta.Node.Server.init/3` — before behaviour `init/3` callback:

1. Read `config["config_key"]` (string) from node config map.
2. If present, call `ConfigStore.get(project, key)`.
3. On hit: `merged = deep_merge(inline_config, stored_term)`. Call behaviour `init/3` with merged config.
4. On miss: proceed with inline config as-is (deploy-time validation already blocked this in validate path; this is the runtime safety net).

Deep merge semantics: recursive on maps; scalar/list overwrite from stored side.

### Deploy-time validation

Extend `Engine.validate_node_configs/1`:

- For each node with `config.config_key`, call `ConfigStore.get(project, key)`.
- On miss: validation error `{:config_key_not_found, node_id, key}`.
- Humanized via existing error formatter.

## Frontend (CartaClient)

### New files

- `lib/services/configs_api.dart` — `ConfigsApi` class, mirrors `WorkflowsApi` shape.
- `lib/providers/configs_provider.dart`:
  - `configsApiProvider` — singleton, empty base (same-origin).
  - `projectConfigsProvider` — `FutureProvider.family<List<ConfigObject>, String>`.
- `lib/widgets/settings/configs_section.dart` — `_ConfigCard` expandable card (modeled on `_ModuleCard` in `modules_section.dart:343-524`).

### Modified files

- `lib/widgets/settings/settings_modal.dart`:
  - Add `_SectionMeta(value: 'configs', label: 'Configuration Objects', icon: CartaIconData.X)` to `_sections`.
  - Add case in `_buildSection`.
- Node model (`WorkflowNode`): add `configKey` field.
- `lib/models/workflow_serializer.dart` (or equivalent): `workflowToYaml` emits `config.config_key`; `yamlToWorkflow` reads it.
- Node drawer settings tab: `config_key` text field (free-form, monospace, placeholder `e.g. db_settings`).

### Section UI

Header: `Configuration Objects — {project}` + `+ New` button (dialog prompts for key name).

List of `_ConfigCard`:
- Collapsed: key name, `updated_at`, delete (trash) icon.
- Expanded: `PayloadEditor` (literal mode, keyed per config id, debounced autosave via PUT).

Empty state: "No configuration objects yet — click + New."

### Node drawer field

- `TextFormField`, monospace, helper: "Name of a stored configuration object (Settings → Configuration Objects). Merged over this node's inline config at deploy."
- Live warning pip if non-empty and key not in fetched list (advisory only; deploy validation is authoritative).

## Testing

**Carta (`mix test`):**

- `test/carta/config_store_test.exs`:
  - put → get round-trip (source + term)
  - parse failure rejects (no write)
  - list filters by project (no cross-project leak)
  - delete removes
  - PUT overwrites; POST on existing key returns 409
  - boot is idempotent (second start doesn't error)
- `test/carta/engine_test.exs`:
  - deploy flow with missing `config_key` → error mentions node id + key
  - valid key passes
  - node `init` receives merged config (stored wins on conflict)
- `test/carta/api_test.exs`:
  - 5 endpoint happy paths + 404/400/409

**Frontend (`flutter test`):**

- `configs_api_test.dart` — mock HTTP; verify paths, payloads, parsing.
- `configs_section_test.dart` — list renders, expand/collapse, delete hits API, "+ New" flow.
- All 77 existing tests stay green.

## Out of Scope

- Global (cross-project) config objects — project-local only for now.
- Encrypted secrets file — future PR: encrypted at rest, CartaClient supplies key at job launch.
- Autocomplete on `config_key` field — free-form text for now.
- Per-environment config overlays (dev/staging/prod).

## Risks

- **Mnesia schema dir permissions**: schema dir must be writable by the Carta process. Mirror `Carta.Store` dir-creation logic; log and crash on failure (fail fast at boot).
- **Term size**: stored terms are loaded into every node process at init. Large terms will duplicate memory. Acceptable for config-scale data; document a soft guideline (keep configs under ~10KB).
- **Config deletion while flows running**: nodes hold merged config in process state; deleting the object doesn't affect running nodes. Redeploy picks up the change. Document this.
