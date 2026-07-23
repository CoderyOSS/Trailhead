# Config Objects Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add persistent, project-scoped configuration objects (Elixir literals) stored server-side in Mnesia, editable in a new Settings section, and opt-in per-node via `config.config_key` with deep-merge at node startup.

**Architecture:** `Carta.ConfigStore` GenServer owns a Mnesia `:carta_configs` table (disc-backed, project-local). Five new REST endpoints under `/api/v1/configs`. `Carta.Node.Server.init/3` reads `config_key` and deep-merges the stored term over the node's inline `config:` map before calling the behaviour's `init/3`. Deploy-time validation rejects flows referencing missing keys. Frontend adds a Settings section (expandable cards with `PayloadEditor`), a Riverpod provider, a `ConfigsApi` client, a `configKey` field on `WorkflowNode`, YAML round-trip, and a drawer text field.

**Tech Stack:** Elixir (Mnesia, GenServer, Plug) + Flutter (Riverpod, `flutter_code_editor`).

## Global Constraints

- Backend lives in `/home/gem/projects/Carta` (separate repo, no commits from CartaClient).
- Frontend lives in `/home/gem/projects/CartaClient/frontend`.
- Mnesia table: `:carta_configs`, type `:set`, `disc_copies: [node()]`.
- Record shape: `{:config, {project, key}, source, term, updated_at}`.
- Merge semantics: **stored wins** (deep-merge; maps recurse, other types overwrite).
- `config_key` is a string; empty/missing = no stored config lookup.
- Deploy-time validation rejects unknown `config_key` with `{:config_key_not_found, node_id, key}`.
- Source validation uses existing `Carta.ElixirTerm.parse_literal/1`.
- All tests: `mix test` (Carta), `~/projects/flutter/bin/flutter test` (frontend) — must stay green.
- Commits in Carta repo: plain `git commit`. Commits in CartaClient repo: plain `git commit`. Never push.

---

### Task 1: `Carta.ConfigStore` GenServer (Mnesia-backed)

**Files:**
- Create: `/home/gem/projects/Carta/lib/carta/config_store.ex`
- Test: `/home/gem/projects/Carta/test/carta/config_store_test.exs`
- Modify: `/home/gem/projects/Carta/mix.exs` (add `:mnesia` to `extra_applications`)
- Modify: `/home/gem/projects/Carta/lib/carta/application.ex` (supervise `ConfigStore` after `Carta.FlowsSup`)

**Interfaces:**
- Consumes: `Carta.ElixirTerm.parse_literal/1`, `Carta.Project.flows_dir/0`
- Produces:
  - `Carta.ConfigStore.start_link/1`
  - `Carta.ConfigStore.put(project :: String.t(), key :: String.t(), source :: String.t()) :: :ok | {:error, term()}`
  - `Carta.ConfigStore.get(project :: String.t(), key :: String.t()) :: {:ok, %{key: String.t(), source: String.t(), term: term(), updated_at: String.t()}} | :error`
  - `Carta.ConfigStore.list(project :: String.t()) :: [%{key: String.t(), source: String.t(), updated_at: String.t()}]`
  - `Carta.ConfigStore.delete(project :: String.t(), key :: String.t()) :: :ok | {:error, :not_found}`
  - `Carta.ConfigStore.configs_dir/0` (3-tier resolution)

- [ ] **Step 1: Write the failing test**

Create `/home/gem/projects/Carta/test/carta/config_store_test.exs`:

```elixir
defmodule Carta.ConfigStoreTest do
  use ExUnit.Case, async: false

  @project "test_project_#{System.unique_integer([:positive])}"

  setup do
    # Clean any leftovers from prior runs
    Carta.ConfigStore.list(@project)
    |> Enum.each(fn c -> Carta.ConfigStore.delete(@project, c.key) end)
    :ok
  end

  test "put → get round-trip preserves source and parses term" do
    source = "%{host: \"localhost\", port: 5432}"
    assert :ok = Carta.ConfigStore.put(@project, "db", source)

    assert {:ok, cfg} = Carta.ConfigStore.get(@project, "db")
    assert cfg.key == "db"
    assert cfg.source == source
    assert cfg.term == %{host: "localhost", port: 5432}
    assert is_binary(cfg.updated_at)
  end

  test "put rejects non-literal source without writing" do
    assert {:error, _} = Carta.ConfigStore.put(@project, "bad", "Map.new()")
    assert :error = Carta.ConfigStore.get(@project, "bad")
  end

  test "list filters by project (no cross-project leak)" do
    :ok = Carta.ConfigStore.put(@project, "a", "%{x: 1}")
    :ok = Carta.ConfigStore.put("other_#{@project}", "b", "%{y: 2}")

    mine = Carta.ConfigStore.list(@project) |> Enum.map(& &1.key) |> Enum.sort()
    assert mine == ["a"]
  end

  test "delete removes; second delete returns error" do
    :ok = Carta.ConfigStore.put(@project, "del", "%{x: 1}")
    assert :ok = Carta.ConfigStore.delete(@project, "del")
    assert :error = Carta.ConfigStore.get(@project, "del")
    assert {:error, :not_found} = Carta.ConfigStore.delete(@project, "del")
  end

  test "re-put same key overwrites" do
    :ok = Carta.ConfigStore.put(@project, "rw", "%{v: 1}")
    :ok = Carta.ConfigStore.put(@project, "rw", "%{v: 2}")
    {:ok, cfg} = Carta.ConfigStore.get(@project, "rw")
    assert cfg.term == %{v: 2}
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/gem/projects/Carta && mix test test/carta/config_store_test.exs
```

Expected: FAIL — `Carta.ConfigStore` undefined.

- [ ] **Step 3: Add `:mnesia` to extra_applications**

Modify `/home/gem/projects/Carta/mix.exs:17`:

```elixir
extra_applications: [:logger, :mnesia],
```

- [ ] **Step 4: Write minimal `Carta.ConfigStore`**

Create `/home/gem/projects/Carta/lib/carta/config_store.ex`:

```elixir
defmodule Carta.ConfigStore do
  @moduledoc """
  Mnesia-backed, project-scoped storage for configuration objects.

  A configuration object is a named Elixir literal (map, keyword list, etc.)
  stored as both raw source and parsed term. Nodes opt into a stored object
  via `config.config_key`; the engine deep-merges the stored term over the
  node's inline config at node startup.
  """

  use GenServer
  require Logger

  @table :carta_configs
  # {key, source, term, updated_at_iso8601} — keyed by {project, key}

  defstruct [:project, :key, :source, :term, :updated_at]

  # ── Client API ─────────────────────────────────────────────────────────

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @spec put(String.t(), String.t(), String.t()) :: :ok | {:error, term()}
  def put(project, key, source) when is_binary(project) and is_binary(key) and is_binary(source) do
    GenServer.call(__MODULE__, {:put, project, key, source})
  end

  @spec get(String.t(), String.t()) :: {:ok, %__MODULE__{}} | :error
  def get(project, key) do
    case :mnesia.dirty_read(@table, {project, key}) do
      [{@table, {_p, k}, source, term, updated_at}] ->
        {:ok, %__MODULE__{project: project, key: k, source: source, term: term, updated_at: updated_at}}

      [] ->
        :error
    end
  end

  @spec list(String.t()) :: [%__MODULE__{}]
  def list(project) do
    :mnesia.dirty_match_object(@table, {@table, {project, :_}, :_, :_, :_})
    |> Enum.map(fn {@table, {p, k}, source, _term, updated_at} ->
      %__MODULE__{project: p, key: k, source: source, term: nil, updated_at: updated_at}
    end)
    |> Enum.sort_by(& &1.key)
  end

  @spec delete(String.t(), String.t()) :: :ok | {:error, :not_found}
  def delete(project, key) do
    GenServer.call(__MODULE__, {:delete, project, key})
  end

  @doc "Schema/table directory — mirrors Carta.Store.configured_dir/0 3-tier pattern."
  @spec configs_dir() :: String.t()
  def configs_dir do
    Application.get_env(:carta_fbp, :configs_dir) ||
      System.get_env("CONFIGS_DIR") ||
      Path.join(Carta.Project.flows_dir(), "configs")
  end

  # ── Server ─────────────────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    dir = configs_dir()
    File.mkdir_p!(dir)
    :ok = :mnesia.create_schema([node()])

    case :mnesia.create_table(@table,
           attributes: [:key, :source, :term, :updated_at],
           disc_copies: [node()],
           type: :set
         ) do
      {:atomic, :ok} -> :ok
      {:aborted, {:already_exists, @table}} -> :ok
      {:aborted, reason} -> raise "failed to create #{@table}: #{inspect(reason)}"
    end

    :ok = :mnesia.wait_for_tables([@table], 5_000)
    Logger.info("ConfigStore ready (dir=#{dir})")
    {:ok, %{}}
  end

  @impl true
  def handle_call({:put, project, key, source}, _from, s) do
    case Carta.ElixirTerm.parse_literal(source) do
      {:ok, term} ->
        updated_at = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

        {:atomic, :ok} =
          :mnesia.transaction(fn ->
            :mnesia.write({@table, {project, key}, source, term, updated_at})
          end)

        {:reply, :ok, s}

      {:error, msg, line} ->
        {:reply, {:error, {:bad_literal, msg, line}}, s}
    end
  end

  def handle_call({:delete, project, key}, _from, s) do
    result =
      :mnesia.transaction(fn ->
        case :mnesia.read(@table, {project, key}) do
          [] -> {:error, :not_found}
          [_] -> :mnesia.delete({@table, {project, key}})
        end
      end)

    case result do
      {:atomic, :ok} -> {:reply, :ok, s}
      {:atomic, {:error, :not_found}} -> {:reply, {:error, :not_found}, s}
      {:aborted, reason} -> {:reply, {:error, reason}, s}
    end
  end
end
```

- [ ] **Step 5: Supervise in application.ex**

Modify `/home/gem/projects/Carta/lib/carta/application.ex:27-28` — insert `Carta.ConfigStore` after `Carta.FlowsSup` and before `{Carta.Store, []}`:

```elixir
      Carta.FlowsSup,
      Carta.ConfigStore,
      {Carta.Store, []},
```

- [ ] **Step 6: Run test to verify it passes**

```bash
cd /home/gem/projects/Carta && mix test test/carta/config_store_test.exs
```

Expected: PASS (5 tests).

- [ ] **Step 7: Run full Carta test suite**

```bash
cd /home/gem/projects/Carta && mix test
```

Expected: all 346+ tests pass.

- [ ] **Step 8: Commit**

```bash
cd /home/gem/projects/Carta && git add lib/carta/config_store.ex test/carta/config_store_test.exs lib/carta/application.ex mix.exs
git commit -m "feat(configs): Mnesia-backed ConfigStore GenServer"
```

---

### Task 2: REST API endpoints (`/api/v1/configs/*`)

**Files:**
- Modify: `/home/gem/projects/Carta/lib/carta/api.ex` (add 5 routes)
- Test: `/home/gem/projects/Carta/test/carta/api_configs_test.exs` (new)

**Interfaces:**
- Consumes: `Carta.ConfigStore.{put,get,list,delete}/2..3`
- Produces: endpoints used by frontend `ConfigsApi` Dart client (Task 5).

- [ ] **Step 1: Write the failing test**

Create `/home/gem/projects/Carta/test/carta/api_configs_test.exs`:

```elixir
defmodule Carta.ApiConfigsTest do
  use ExUnit.Case, async: false
  import Plug.Test

  @opts Carta.Api.init([])
  @project "api_test_#{System.unique_integer([:positive])}"

  setup do
    Carta.ConfigStore.list(@project)
    |> Enum.each(fn c -> Carta.ConfigStore.delete(@project, c.key) end)
    :ok
  end

  defp json_req(method, path, body \\ nil) do
    conn = conn(method, path, body && Jason.encode!(body))
    conn = if body, do: put_req_header(conn, "content-type", "application/json"), else: conn
    Carta.Api.call(conn, @opts)
  end

  test "GET /api/v1/configs?project=X returns empty list when none" do
    conn = json_req(:get, "/api/v1/configs?project=#{@project}")
    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) == []
  end

  test "POST creates; GET fetches; PUT overwrites; DELETE removes" do
    # POST
    conn = json_req(:post, "/api/v1/configs", %{
      "project" => @project, "key" => "db", "source" => "%{host: \"h\"}"
    })
    assert conn.status == 201

    # GET
    conn = json_req(:get, "/api/v1/configs/db?project=#{@project}")
    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert body["key"] == "db"
    assert body["source"] == "%{host: \"h\"}"
    assert body["term"] == %{"host" => "h"}

    # PUT
    conn = json_req(:put, "/api/v1/configs/db?project=#{@project}", %{
      "source" => "%{host: \"h2\"}"
    })
    assert conn.status == 200
    {:ok, cfg} = Carta.ConfigStore.get(@project, "db")
    assert cfg.term == %{host: "h2"}

    # DELETE
    conn = json_req(:delete, "/api/v1/configs/db?project=#{@project}")
    assert conn.status == 204
    assert :error = Carta.ConfigStore.get(@project, "db")
  end

  test "POST rejects invalid literal" do
    conn = json_req(:post, "/api/v1/configs", %{
      "project" => @project, "key" => "bad", "source" => "Map.new()"
    })
    assert conn.status == 400
  end

  test "GET returns 404 for missing key" do
    conn = json_req(:get, "/api/v1/configs/missing?project=#{@project}")
    assert conn.status == 404
  end

  test "DELETE returns 404 for missing key" do
    conn = json_req(:delete, "/api/v1/configs/missing?project=#{@project}")
    assert conn.status == 404
  end

  test "missing project param returns 400" do
    conn = json_req(:get, "/api/v1/configs")
    assert conn.status == 400
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/gem/projects/Carta && mix test test/carta/api_configs_test.exs
```

Expected: FAIL — 404s everywhere.

- [ ] **Step 3: Add routes to `Carta.Api`**

In `/home/gem/projects/Carta/lib/carta/api.ex`, insert after the workflow CRUD routes (around line 100, before runtime endpoints). Add a new section:

```elixir
  # ──────────────────────────────────────────────────────────────────────
  # Configuration Objects — `/api/v1/configs/*`
  # ──────────────────────────────────────────────────────────────────────

  get "/api/v1/configs" do
    case conn.params["project"] do
      nil ->
        send_resp(conn, 400, Jason.encode!(%{error: "project required"}))

      project ->
        rows =
          Carta.ConfigStore.list(project)
          |> Enum.map(fn c -> %{key: c.key, source: c.source, updated_at: c.updated_at} end)

        send_resp(conn, 200, Jason.encode!(rows))
    end
  end

  post "/api/v1/configs" do
    case conn.body_params do
      %{"project" => p, "key" => k, "source" => s}
      when is_binary(p) and is_binary(k) and is_binary(s) ->
        case Carta.ConfigStore.get(p, k) do
          {:ok, _} ->
            send_resp(conn, 409, Jason.encode!(%{error: "key_exists"}))

          :error ->
            case Carta.ConfigStore.put(p, k, s) do
              :ok -> send_resp(conn, 201, "")
              {:error, {:bad_literal, msg, line}} ->
                send_resp(conn, 400, Jason.encode!(%{error: "invalid literal (line #{line}): #{msg}"}))
              {:error, e} ->
                send_resp(conn, 500, Jason.encode!(%{error: inspect(e)}))
            end
        end

      _ ->
        send_resp(conn, 400, Jason.encode!(%{error: "project, key, source required"}))
    end
  end

  get "/api/v1/configs/:key" do
    case conn.params["project"] do
      nil -> send_resp(conn, 400, Jason.encode!(%{error: "project required"}))
      project ->
        case Carta.ConfigStore.get(project, key) do
          {:ok, cfg} ->
            # JSON-encode the stored term by converting to plain data
            # (atoms → strings via Jason's term encoder)
            send_resp(conn, 200, Jason.encode!(%{
              key: cfg.key,
              source: cfg.source,
              term: cfg.term,
              updated_at: cfg.updated_at
            }))

          :error ->
            send_resp(conn, 404, Jason.encode!(%{error: "not_found"}))
        end
    end
  end

  put "/api/v1/configs/:key" do
    case {conn.params["project"], conn.body_params} do
      {nil, _} ->
        send_resp(conn, 400, Jason.encode!(%{error: "project required"}))

      {project, %{"source" => s}} when is_binary(s) ->
        case Carta.ConfigStore.get(project, key) do
          :error ->
            send_resp(conn, 404, Jason.encode!(%{error: "not_found"}))

          {:ok, _} ->
            case Carta.ConfigStore.put(project, key, s) do
              :ok -> send_resp(conn, 200, "")
              {:error, {:bad_literal, msg, line}} ->
                send_resp(conn, 400, Jason.encode!(%{error: "invalid literal (line #{line}): #{msg}"}))
              {:error, e} ->
                send_resp(conn, 500, Jason.encode!(%{error: inspect(e)}))
            end
        end

      {_, _} ->
        send_resp(conn, 400, Jason.encode!(%{error: "source required"}))
    end
  end

  delete "/api/v1/configs/:key" do
    case conn.params["project"] do
      nil -> send_resp(conn, 400, Jason.encode!(%{error: "project required"}))
      project ->
        case Carta.ConfigStore.delete(project, key) do
          :ok -> send_resp(conn, 204, "")
          {:error, :not_found} -> send_resp(conn, 404, Jason.encode!(%{error: "not_found"}))
        end
    end
  end
```

**Note on Jason term encoding:** `Jason.encode!(%{host: "h"})` works for maps with atom keys (Jason converts to strings). For keyword lists, tuples, structs in stored terms, the test above only exercises maps — that's the expected 99% case for config objects. Structs/tuples would need custom handling; deferred as YAGNI.

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /home/gem/projects/Carta && mix test test/carta/api_configs_test.exs
```

Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
cd /home/gem/projects/Carta && git add lib/carta/api.ex test/carta/api_configs_test.exs
git commit -m "feat(configs): REST endpoints for config objects"
```

---

### Task 3: Node startup hook — deep-merge `config_key`

**Files:**
- Modify: `/home/gem/projects/Carta/lib/carta/node/server.ex` (`init/1` merge before `module.init/3`)
- Test: `/home/gem/projects/Carta/test/carta/node/config_key_test.exs` (new)

**Interfaces:**
- Consumes: `Carta.ConfigStore.get/2`, project from `Carta.Project`
- Produces: merged config passed to `module.init(flow_id, node_id, merged_config)`

**How the project is resolved:** `Carta.Project.dir()` returns the current project directory. The config store is keyed by project name (string). For Carta's own runtime, the project name is the basename of the current project dir. Add helper `Carta.Project.name/0` (returns `Path.basename(dir())`).

- [ ] **Step 1: Write the failing test**

Create `/home/gem/projects/Carta/test/carta/node/config_key_test.exs`:

```elixir
defmodule Carta.Node.ConfigKeyTest do
  use ExUnit.Case, async: false

  @project "cfgkey_test_#{System.unique_integer([:positive])}"

  setup do
    Carta.ConfigStore.list(@project)
    |> Enum.each(fn c -> Carta.ConfigStore.delete(@project, c.key) end)
    :ok
  end

  test "deep_merge maps recursively, stored wins" do
    inline = %{"a" => %{"x" => 1, "y" => 2}, "b" => "inline"}
    stored = %{a: %{y: 99, z: 3}, b: "stored"}

    merged = Carta.Node.Server.deep_merge(inline, stored)
    assert merged == %{"a" => %{"x" => 1, "y" => 99, "z" => 3}, "b" => "stored"}
  end

  test "deep_merge with non-map stored overwrites" do
    assert Carta.Node.Server.deep_merge(%{"a" => 1}, "scalar") == "scalar"
    assert Carta.Node.Server.deep_merge(%{"a" => 1}, [1, 2, 3]) == [1, 2, 3]
  end

  test "resolve_config returns inline config when no config_key" do
    assert {:ok, %{"x" => 1}} =
             Carta.Node.Server.resolve_config(@project, %{"x" => 1})
  end

  test "resolve_config fetches and merges stored config" do
    :ok = Carta.ConfigStore.put(@project, "db", "%{host: \"h\", port: 5432}")
    inline = %{"config_key" => "db", "other" => "inline_val"}

    {:ok, merged} = Carta.Node.Server.resolve_config(@project, inline)
    assert merged["host"] == "h"
    assert merged["port"] == 5432
    assert merged["other"] == "inline_val"
    # config_key itself is consumed, not passed to the behaviour
    refute Map.has_key?(merged, "config_key")
  end

  test "resolve_config returns error for missing key" do
    assert {:error, {:config_key_not_found, "missing"}} =
             Carta.Node.Server.resolve_config(@project, %{"config_key" => "missing"})
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/gem/projects/Carta && mix test test/carta/node/config_key_test.exs
```

Expected: FAIL — `Carta.Node.Server.deep_merge/2` and `resolve_config/2` undefined.

- [ ] **Step 3: Implement `deep_merge/2` and `resolve_config/2` in `Carta.Node.Server`**

Add to `/home/gem/projects/Carta/lib/carta/node/server.ex` (public functions, called from `init/1`):

```elixir
  @doc """
  Deep-merge `stored` over `inline`. Maps recurse; all other values
  (scalars, lists, tuples) from `stored` overwrite `inline`.

  Accepts maps with either string or atom keys on either side; result
  preserves the *inline* map's key style (string keys win if both exist —
  Carta's YAML loader produces string-keyed maps).
  """
  @spec deep_merge(term(), term()) :: term()
  def deep_merge(inline, stored) when is_map(inline) and is_map(stored) do
    # Normalize stored keys to strings so they merge against YAML-sourced inline maps.
    stored_str = stringify_keys(stored)
    Map.merge(inline, stored_str, fn _k, v_inline, v_stored ->
      deep_merge(v_inline, v_stored)
    end)
  end

  def deep_merge(_inline, stored), do: stored

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), stringify_keys(v)}
      {k, v} -> {k, stringify_keys(v)}
    end)
  end

  defp stringify_keys(other), do: other

  @doc """
  Resolve a node's effective config: fetch the stored object named by
  `config["config_key"]` (if present) and deep-merge it over the inline
  config. Returns the merged map with `config_key` removed.

  Returns `{:error, {:config_key_not_found, key}}` when the key is missing
  from the store. Deploy-time validation should catch this earlier; this
  is the runtime safety net.
  """
  @spec resolve_config(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def resolve_config(project, config) when is_map(config) do
    case Map.pop(config, "config_key") do
      {nil, _} -> {:ok, config}
      {"", _} -> {:ok, Map.delete(config, "config_key")}
      {key, inline} when is_binary(key) ->
        case Carta.ConfigStore.get(project, key) do
          {:ok, %{term: term}} -> {:ok, deep_merge(inline, term)}
          :error -> {:error, {:config_key_not_found, key}}
        end
    end
  end
```

- [ ] **Step 4: Wire into `init/1`**

In `/home/gem/projects/Carta/lib/carta/node/server.ex:35-52`, modify `init/1` to call `resolve_config/2` before `module.init/3`:

```elixir
  @impl true
  def init({flow_id, node_id, module, config}) do
    # insert_new — a restart must NOT wipe counters (see Stats.init_node).
    Carta.Stats.init_node(flow_id, node_id)

    project = Carta.Project.name()

    with {:ok, resolved} <- resolve_config(project, config),
         {:ok, state} <- module.init(flow_id, node_id, resolved) do
      {:ok,
       %__MODULE__{
         flow_id: flow_id,
         node_id: node_id,
         module: module,
         state: state
       }}
    else
      {:stop, reason} -> {:stop, reason}
      {:error, reason} -> {:stop, reason}
    end
  end
```

- [ ] **Step 5: Add `Carta.Project.name/0`**

In `/home/gem/projects/Carta/lib/carta/project.ex`, add:

```elixir
  @doc "Current project name — basename of the project directory."
  @spec name() :: String.t()
  def name, do: dir() |> Path.basename()
```

(Grep `Carta.Project` first if `name/0` already exists — if so, skip this step.)

- [ ] **Step 6: Run test to verify it passes**

```bash
cd /home/gem/projects/Carta && mix test test/carta/node/config_key_test.exs
```

Expected: PASS (5 tests).

- [ ] **Step 7: Run full Carta suite**

```bash
cd /home/gem/projects/Carta && mix test
```

Expected: all green.

- [ ] **Step 8: Commit**

```bash
cd /home/gem/projects/Carta && git add lib/carta/node/server.ex lib/carta/project.ex test/carta/node/config_key_test.exs
git commit -m "feat(configs): deep-merge config_key into node config at init"
```

---

### Task 4: Deploy-time validation

**Files:**
- Modify: `/home/gem/projects/Carta/lib/carta/engine.ex` (extend `validate_node_config/2`)
- Modify: `/home/gem/projects/Carta/lib/carta/api.ex` (add humanizer clause)
- Test: `/home/gem/projects/Carta/test/carta/engine_test.exs` (append)

**Interfaces:**
- Consumes: `Carta.ConfigStore.get/2`, `Carta.Project.name/0`
- Produces: validation error `{:config_key_not_found, node_id, key}` (flow fails validate/deploy)

- [ ] **Step 1: Write the failing test**

Append to `/home/gem/projects/Carta/test/carta/engine_test.exs`:

```elixir
  describe "config_key validation" do
    test "missing config_key fails validation" do
      flow = %Carta.Flow{
        name: "cfgkey_test",
        nodes: [
          %Carta.Flow.NodeDef{
            id: :a,
            type: "function",
            config: %{"config_key" => "nonexistent_#{System.unique_integer([:positive])}", "expr" => "payload"}
          }
        ],
        connections: []
      }

      assert {:error, errors} = Carta.Engine.validate(flow)
      assert Enum.any?(errors, fn
               {:a, {:config_key_not_found, _}} -> true
               _ -> false
             end)
    end

    test "existing config_key passes validation" do
      key = "existing_#{System.unique_integer([:positive])}"
      :ok = Carta.ConfigStore.put(Carta.Project.name(), key, "%{x: 1}")

      flow = %Carta.Flow{
        name: "cfgkey_test_ok",
        nodes: [
          %Carta.Flow.NodeDef{
            id: :a,
            type: "function",
            config: %{"config_key" => key, "expr" => "payload"}
          }
        ],
        connections: []
      }

      assert :ok = Carta.Engine.validate(flow)

      # cleanup
      Carta.ConfigStore.delete(Carta.Project.name(), key)
    end
  end
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/gem/projects/Carta && mix test test/carta/engine_test.exs -k config_key
```

Expected: FAIL — validation passes (or crashes on unknown key shape) because no check exists.

- [ ] **Step 3: Extend `validate_node_config/2`**

In `/home/gem/projects/Carta/lib/carta/engine.ex`, modify the fallback `validate_node_config/2` clause (after the kind-specific ones) to also check `config_key` presence. Find the fallback clause (likely `defp validate_node_config(_node, _mod), do: :ok`) and replace:

```elixir
  # Fallback: only check config_key presence for kinds without dedicated
  # validators. Kind-specific validators must also call this.
  defp validate_node_config(node, _mod) do
    case Map.get(node.config || %{}, "config_key") do
      nil ->
        :ok

      "" ->
        :ok

      key when is_binary(key) ->
        case Carta.ConfigStore.get(Carta.Project.name(), key) do
          {:ok, _} -> :ok
          :error -> {:error, {:config_key_not_found, key}}
        end
    end
  end
```

Then ensure each kind-specific clause also runs the config_key check. Easiest: wrap each existing clause's result. Add helper:

```elixir
  defp with_config_key_check(node, result) do
    case result do
      :ok -> validate_node_config(%{node | config: Map.drop(node.config || %{}, ["expr", "payload_code", "payload_expr"])}, nil)
      other -> other
    end
  end
```

And update each kind-specific clause to return `with_config_key_check(node, <existing_result>)`. Alternative (simpler): change the dispatcher:

```elixir
  defp validate_node_configs(%Flow{nodes: nodes}, type_map) do
    errors =
      Enum.reduce(nodes, [], fn node, acc ->
        acc =
          case validate_node_config(node, Map.get(type_map, node.id)) do
            :ok -> acc
            {:error, reason} -> [{node.id, reason} | acc]
          end

        # config_key check applies to ALL node kinds, regardless of type.
        case Map.get(node.config || %{}, "config_key") do
          k when is_binary(k) and k != "" ->
            case Carta.ConfigStore.get(Carta.Project.name(), k) do
              {:ok, _} -> acc
              :error -> [{node.id, {:config_key_not_found, k}} | acc]
            end

          _ ->
            acc
        end
      end)

    if errors == [], do: :ok, else: {:error, Enum.reverse(errors)}
  end
```

Use the second approach — config_key check runs independent of kind validators.

- [ ] **Step 4: Add humanizer clause in `api.ex`**

In `/home/gem/projects/Carta/lib/carta/api.ex` near line 716, add:

```elixir
  defp humanize_reason({:config_key_not_found, key}),
    do: "config_key '#{key}' not found in project configs (Settings → Configuration Objects)"
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd /home/gem/projects/Carta && mix test test/carta/engine_test.exs -k config_key
```

Expected: PASS (2 tests).

- [ ] **Step 6: Run full Carta suite**

```bash
cd /home/gem/projects/Carta && mix test
```

- [ ] **Step 7: Commit**

```bash
cd /home/gem/projects/Carta && git add lib/carta/engine.ex lib/carta/api.ex test/carta/engine_test.exs
git commit -m "feat(configs): deploy-time validation for config_key"
```

---

### Task 5: Frontend `ConfigsApi` client + providers

**Files:**
- Create: `/home/gem/projects/CartaClient/frontend/lib/services/configs_api.dart`
- Create: `/home/gem/projects/CartaClient/frontend/lib/providers/configs_provider.dart`
- Test: `/home/gem/projects/CartaClient/frontend/test/services/configs_api_test.dart`

**Interfaces:**
- Consumes: `/api/v1/configs/*` endpoints (Task 2)
- Produces:
  - `class ConfigObject { String key; String source; String? updatedAt; }`
  - `class ConfigsApi { Future<List<ConfigObject>> list(String project); Future<void> create(String project, String key, String source); Future<ConfigObject> get(String project, String key); Future<void> update(String project, String key, String source); Future<void> delete(String project, String key); }`
  - `configsApiProvider` (singleton)
  - `projectConfigsProvider` — `FutureProvider.family<List<ConfigObject>, String>`

- [ ] **Step 1: Write the failing test**

Create `/home/gem/projects/CartaClient/frontend/test/services/configs_api_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:carta/services/configs_api.dart';

void main() {
  test('list parses configs', () async {
    final api = ConfigsApi(
      base: '',
      client: MockClient((req) async {
        expect(req.url.path, '/api/v1/configs');
        expect(req.url.queryParameters['project'], 'p1');
        return http.Response(
          jsonEncode([
            {'key': 'db', 'source': '%{x: 1}', 'updated_at': '2026-07-23T00:00:00Z'}
          ]),
          200,
        );
      }),
    );

    final cfgs = await api.list('p1');
    expect(cfgs.length, 1);
    expect(cfgs[0].key, 'db');
    expect(cfgs[0].source, '%{x: 1}');
  });

  test('create posts project+key+source', () async {
    final api = ConfigsApi(
      base: '',
      client: MockClient((req) async {
        expect(req.method, 'POST');
        final body = jsonDecode(req.body);
        expect(body['project'], 'p1');
        expect(body['key'], 'db');
        expect(body['source'], '%{x: 1}');
        return http.Response('', 201);
      }),
    );
    await api.create('p1', 'db', '%{x: 1}');
  });

  test('update puts source', () async {
    final api = ConfigsApi(
      base: '',
      client: MockClient((req) async {
        expect(req.method, 'PUT');
        expect(req.url.path, '/api/v1/configs/db');
        expect(req.url.queryParameters['project'], 'p1');
        final body = jsonDecode(req.body);
        expect(body['source'], '%{x: 2}');
        return http.Response('', 200);
      }),
    );
    await api.update('p1', 'db', '%{x: 2}');
  });

  test('delete hits right path', () async {
    final api = ConfigsApi(
      base: '',
      client: MockClient((req) async {
        expect(req.method, 'DELETE');
        expect(req.url.path, '/api/v1/configs/db');
        return http.Response('', 204);
      }),
    );
    await api.delete('p1', 'db');
  });

  test('throws on 404', () async {
    final api = ConfigsApi(
      base: '',
      client: MockClient((_) async => http.Response('{"error":"not_found"}', 404)),
    );
    expect(() => api.get('p1', 'missing'), throwsA(isA<ConfigsApiException>()));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/gem/projects/CartaClient/frontend && ~/projects/flutter/bin/flutter test test/services/configs_api_test.dart
```

Expected: FAIL — `ConfigsApi` undefined.

- [ ] **Step 3: Implement `ConfigsApi`**

Create `/home/gem/projects/CartaClient/frontend/lib/services/configs_api.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ConfigObject {
  final String key;
  final String source;
  final String? updatedAt;

  const ConfigObject({required this.key, required this.source, this.updatedAt});

  factory ConfigObject.fromJson(Map<String, dynamic> j) => ConfigObject(
        key: j['key'] as String,
        source: j['source'] as String,
        updatedAt: j['updated_at'] as String?,
      );
}

class ConfigsApiException implements Exception {
  final int status;
  final String message;
  ConfigsApiException(this.status, this.message);
  @override
  String toString() => 'ConfigsApiException($status): $message';
}

class ConfigsApi {
  final String base;
  final http.Client client;

  ConfigsApi({required this.base, http.Client? client})
      : client = client ?? http.Client();

  Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('$base$path').replace(queryParameters: q);

  Future<List<ConfigObject>> list(String project) async {
    final r = await client.get(_u('/api/v1/configs', {'project': project}));
    _ok(r, [200]);
    final arr = jsonDecode(r.body) as List;
    return arr.map((e) => ConfigObject.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ConfigObject> get(String project, String key) async {
    final r = await client.get(_u('/api/v1/configs/$key', {'project': project}));
    _ok(r, [200]);
    return ConfigObject.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<void> create(String project, String key, String source) async {
    final r = await client.post(
      _u('/api/v1/configs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'project': project, 'key': key, 'source': source}),
    );
    _ok(r, [201]);
  }

  Future<void> update(String project, String key, String source) async {
    final r = await client.put(
      _u('/api/v1/configs/$key', {'project': project}),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'source': source}),
    );
    _ok(r, [200]);
  }

  Future<void> delete(String project, String key) async {
    final r = await client.delete(_u('/api/v1/configs/$key', {'project': project}));
    _ok(r, [204, 200]);
  }

  void _ok(http.Response r, List<int> expected) {
    if (!expected.contains(r.statusCode)) {
      String msg = r.body;
      try {
        final j = jsonDecode(r.body);
        if (j is Map && j['error'] != null) msg = j['error'].toString();
      } catch (_) {}
      throw ConfigsApiException(r.statusCode, msg);
    }
  }
}
```

- [ ] **Step 4: Create providers**

Create `/home/gem/projects/CartaClient/frontend/lib/providers/configs_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/configs_api.dart';

final configsApiProvider = Provider<ConfigsApi>((ref) => ConfigsApi(base: ''));

final projectConfigsProvider =
    FutureProvider.family<List<ConfigObject>, String>((ref, project) async {
  if (project.isEmpty) return [];
  return ref.watch(configsApiProvider).list(project);
});
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd /home/gem/projects/CartaClient/frontend && ~/projects/flutter/bin/flutter test test/services/configs_api_test.dart
```

Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
cd /home/gem/projects/CartaClient && git add frontend/lib/services/configs_api.dart frontend/lib/providers/configs_provider.dart frontend/test/services/configs_api_test.dart
git commit -m "feat(configs): ConfigsApi client + Riverpod providers"
```

---

### Task 6: Frontend Settings section UI

**Files:**
- Create: `/home/gem/projects/CartaClient/frontend/lib/widgets/settings/configs_section.dart`
- Modify: `/home/gem/projects/CartaClient/frontend/lib/widgets/settings/settings_modal.dart` (register section)
- Test: `/home/gem/projects/CartaClient/frontend/test/widgets/settings/configs_section_test.dart`

**Interfaces:**
- Consumes: `projectConfigsProvider`, `configsApiProvider`, `projectProvider` (from `providers/project_provider.dart`)
- Produces: `class ConfigsSection extends ConsumerWidget` rendered inside `SettingsModal`

**Note on `projectProvider`:** check its actual name — likely a `StateProvider<String>` or similar holding the current project name. Read `lib/providers/project_provider.dart` first; adjust the watch call accordingly.

- [ ] **Step 1: Write the failing widget test**

Create `/home/gem/projects/CartaClient/frontend/test/widgets/settings/configs_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carta/widgets/settings/configs_section.dart';
import 'package:carta/services/configs_api.dart';
import 'package:carta/providers/configs_provider.dart';

class _FakeConfigsApi extends ConfigsApi {
  _FakeConfigsApi() : super(base: '');
  List<ConfigObject> items = [
    const ConfigObject(key: 'db', source: '%{host: "h"}', updatedAt: '2026-07-23T00:00:00Z'),
  ];
  String? lastDeleted;

  @override
  Future<List<ConfigObject>> list(String project) async => items;

  @override
  Future<void> delete(String project, String key) async {
    lastDeleted = key;
    items = items.where((c) => c.key != key).toList();
  }
}

void main() {
  testWidgets('renders list of configs', (tester) async {
    final fake = _FakeConfigsApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          configsApiProvider.overrideWithValue(fake),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ConfigsSection(project: 'p1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('db'), findsOneWidget);
  });

  testWidgets('delete button calls api.delete', (tester) async {
    final fake = _FakeConfigsApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [configsApiProvider.overrideWithValue(fake)],
        child: const MaterialApp(
          home: Scaffold(body: ConfigsSection(project: 'p1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(fake.lastDeleted, 'db');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/gem/projects/CartaClient/frontend && ~/projects/flutter/bin/flutter test test/widgets/settings/configs_section_test.dart
```

Expected: FAIL — `ConfigsSection` undefined.

- [ ] **Step 3: Implement `ConfigsSection`**

Create `/home/gem/projects/CartaClient/frontend/lib/widgets/settings/configs_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/configs_provider.dart';
import '../../services/configs_api.dart';
import '../../theme/tokens.dart';
import '../node_drawer/payload_editor.dart';

/// Settings section listing project-scoped configuration objects.
/// Each card expands to reveal a PayloadEditor for the source literal.
class ConfigsSection extends ConsumerWidget {
  final String project;
  const ConfigsSection({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configs = ref.watch(projectConfigsProvider(project));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Configuration Objects — $project',
                style: TextStyle(color: AppColors.fg0, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              color: AppColors.accent,
              tooltip: 'New configuration object',
              onPressed: () => _promptNewKey(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 8),
        configs.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load: $e', style: TextStyle(color: AppColors.danger)),
          ),
          data: (items) => items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No configuration objects yet — click + New.',
                    style: TextStyle(color: AppColors.fg2, fontSize: 12),
                  ),
                )
              : Column(
                  children: [
                    for (final cfg in items) _ConfigCard(project: project, config: cfg),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _promptNewKey(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final key = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('New configuration object', style: TextStyle(color: AppColors.fg0)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: AppColors.fg0, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: 'key name (e.g. db_settings)',
            hintStyle: TextStyle(color: AppColors.fg2),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (key == null || key.isEmpty) return;
    try {
      await ref.read(configsApiProvider).create(project, key, '%{}');
      ref.invalidate(projectConfigsProvider(project));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Create failed: $e')));
      }
    }
  }
}

class _ConfigCard extends ConsumerStatefulWidget {
  final String project;
  final ConfigObject config;
  const _ConfigCard({required this.project, required this.config});

  @override
  ConsumerState<_ConfigCard> createState() => _ConfigCardState();
}

class _ConfigCardState extends ConsumerState<_ConfigCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border.all(color: AppColors.border1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(_expanded ? Icons.expand_more : Icons.chevron_right,
                      size: 16, color: AppColors.fg2),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(cfg.key,
                        style: TextStyle(
                            color: AppColors.fg0, fontFamily: 'monospace', fontSize: 13)),
                  ),
                  if (cfg.updatedAt != null)
                    Text(cfg.updatedAt!,
                        style: TextStyle(color: AppColors.fg2, fontSize: 11)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: AppColors.danger,
                    tooltip: 'Delete',
                    onPressed: () => _delete(context),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: PayloadEditor(
                key: ValueKey('cfg-${widget.project}-${cfg.key}'),
                initialCode: cfg.source,
                isExpr: false,
                onChanged: _save,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save(String source) async {
    try {
      await ref.read(configsApiProvider).update(widget.project, widget.config.key, source);
      ref.invalidate(projectConfigsProvider(widget.project));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  Future<void> _delete(BuildContext context) async {
    try {
      await ref.read(configsApiProvider).delete(widget.project, widget.config.key);
      ref.invalidate(projectConfigsProvider(widget.project));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }
}
```

**Note on `PayloadEditor`:** check its actual constructor signature at `lib/widgets/node_drawer/payload_editor.dart` — the named params above (`initialCode`, `isExpr`, `onChanged`) are inferred from its usage in the codebase. Adjust to match the real signature.

- [ ] **Step 4: Register in `settings_modal.dart`**

Modify `/home/gem/projects/CartaClient/frontend/lib/widgets/settings/settings_modal.dart`:

1. Add import: `import 'configs_section.dart';` and `import '../../providers/project_provider.dart';`
2. Add to `_sections` (around line 39-47):

```dart
  _SectionMeta(value: 'configs', label: 'Configuration Objects', icon: CartaIconData.settings),
```

(Use whatever icon constant exists in `CartaIconData` — pick `settings` or similar; check `lib/widgets/icons.dart`.)

3. Add case in `_buildSection` (around line 381-400):

```dart
      case 'configs':
        final project = ref.watch(projectProvider);
        return ConfigsSection(project: project);
```

(Adjust `projectProvider` access pattern to match how it's actually declared — may need `.current`, `.name`, etc.)

- [ ] **Step 5: Run test to verify it passes**

```bash
cd /home/gem/projects/CartaClient/frontend && ~/projects/flutter/bin/flutter test test/widgets/settings/configs_section_test.dart
```

Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
cd /home/gem/projects/CartaClient && git add frontend/lib/widgets/settings/configs_section.dart frontend/lib/widgets/settings/settings_modal.dart frontend/test/widgets/settings/configs_section_test.dart
git commit -m "feat(configs): settings section UI for config objects"
```

---

### Task 7: `WorkflowNode.configKey` + YAML round-trip

**Files:**
- Modify: `/home/gem/projects/CartaClient/frontend/lib/models/workflow_node.dart` (add `configKey` field + `copyWith`)
- Modify: `/home/gem/projects/CartaClient/frontend/lib/utils/workflow_to_yaml.dart` (emit `config.config_key`)
- Modify: `/home/gem/projects/CartaClient/frontend/lib/utils/yaml_to_workflow.dart` (parse `config.config_key`)
- Test: `/home/gem/projects/CartaClient/frontend/test/utils/yaml_config_key_test.dart` (new)

**Interfaces:**
- Consumes: existing `WorkflowNode` shape, YAML parse/emit pipeline
- Produces: `WorkflowNode.configKey` (nullable String), YAML round-trip via `config.config_key`

- [ ] **Step 1: Write the failing test**

Create `/home/gem/projects/CartaClient/frontend/test/utils/yaml_config_key_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carta/utils/workflow_to_yaml.dart';
import 'package:carta/utils/yaml_to_workflow.dart';
import 'package:carta/providers/mock_data.dart';
import 'package:carta/models/workflow_node.dart';

void main() {
  test('workflowToYaml emits config.config_key when set', () {
    final node = WorkflowNode(
      id: 'a', kind: 'function', label: 'a',
      x: 0, y: 0,
      expr: 'payload',
      configKey: 'db',
      logIn: false, logOut: false,
      outputs: const [], matchAll: false,
      skills: const [], configs: const [], cases: const [], branches: const [],
      waitsFor: const [],
    );
    final wf = WorkflowSummary(
      id: 'w1', name: 'w', version: 1, draft: null,
      nodes: [node], edges: const [], servers: const [],
      subflowParams: const [], subflowInputs: const {}, subflowOutputs: const {},
    );

    final yaml = workflowToYaml(wf);
    expect(yaml, contains('config_key: "db"'));
  });

  test('yamlToWorkflow parses config.config_key', () {
    const yaml = '''
name: w
version: 1
nodes:
  - id: "a"
    type: function
    label: "a"
    config:
      expr: |
        payload
      config_key: "db"
connections: []
''';
    final wf = yamlToWorkflow('w', yaml);
    expect(wf.nodes.single.configKey, 'db');
  });

  test('configKey round-trips', () {
    final node = WorkflowNode(
      id: 'a', kind: 'function', label: 'a',
      x: 0, y: 0,
      expr: 'payload',
      configKey: 'db',
      logIn: false, logOut: false,
      outputs: const [], matchAll: false,
      skills: const [], configs: const [], cases: const [], branches: const [],
      waitsFor: const [],
    );
    final wf = WorkflowSummary(
      id: 'w1', name: 'w', version: 1, draft: null,
      nodes: [node], edges: const [], servers: const [],
      subflowParams: const [], subflowInputs: const {}, subflowOutputs: const {},
    );
    final yaml = workflowToYaml(wf);
    final parsed = yamlToWorkflow('w', yaml);
    expect(parsed.nodes.single.configKey, 'db');
  });
}
```

**Note on `WorkflowNode` constructor:** the test above guesses required named params. Read `/home/gem/projects/CartaClient/frontend/lib/models/workflow_node.dart` fully first, then match the test to the actual signature.

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/gem/projects/CartaClient/frontend && ~/projects/flutter/bin/flutter test test/utils/yaml_config_key_test.dart
```

Expected: FAIL — `configKey` param doesn't exist.

- [ ] **Step 3: Add `configKey` field to `WorkflowNode`**

In `/home/gem/projects/CartaClient/frontend/lib/models/workflow_node.dart`:

1. Add field to the class (near other `String?` fields like `expr`):

```dart
  /// Name of a stored configuration object (Settings → Configuration Objects).
  /// Merged over this node's inline config at deploy. Empty/null = no lookup.
  final String? configKey;
```

2. Add to constructor: `this.configKey,`
3. Add to `copyWith`: `String? configKey,` parameter and `configKey: configKey ?? this.configKey,` in body.

- [ ] **Step 4: Emit in `workflow_to_yaml.dart`**

In `/home/gem/projects/CartaClient/frontend/lib/utils/workflow_to_yaml.dart`, inside the `wantsConfig` block (around line 188-189 where `log_in`/`log_out` are added), insert before those lines:

```dart
        if (node.configKey != null && node.configKey!.isNotEmpty) {
          configLines.add('      config_key: "${node.configKey}"');
        }
```

Also update `wantsConfig` predicate (around line 130-140) to include `node.configKey != null && node.configKey!.isNotEmpty` so the `config:` block is emitted even when no other config fields are set.

- [ ] **Step 5: Parse in `yaml_to_workflow.dart`**

In `/home/gem/projects/CartaClient/frontend/lib/utils/yaml_to_workflow.dart`, near where `logIn`/`logOut` are parsed (around line 226):

```dart
    configKey = _toStr(config['config_key']);
```

Add `String? configKey;` to local declarations (around line 187), then pass to the `WorkflowNode` constructor (around line 334-348).

- [ ] **Step 6: Run test to verify it passes**

```bash
cd /home/gem/projects/CartaClient/frontend && ~/projects/flutter/bin/flutter test test/utils/yaml_config_key_test.dart
```

Expected: PASS (3 tests).

- [ ] **Step 7: Run full frontend suite**

```bash
cd /home/gem/projects/CartaClient/frontend && ~/projects/flutter/bin/flutter test
```

Expected: all 77+ tests green.

- [ ] **Step 8: Commit**

```bash
cd /home/gem/projects/CartaClient && git add frontend/lib/models/workflow_node.dart frontend/lib/utils/workflow_to_yaml.dart frontend/lib/utils/yaml_to_workflow.dart frontend/test/utils/yaml_config_key_test.dart
git commit -m "feat(configs): WorkflowNode.configKey + YAML round-trip"
```

---

### Task 8: Node drawer `config_key` field

**Files:**
- Modify: `/home/gem/projects/CartaClient/frontend/lib/widgets/node_drawer/editor_settings_tab.dart`
- Test: covered by existing widget tests (no new test file; visual verification via `flutter build web`)

**Interfaces:**
- Consumes: `WorkflowNode.configKey`, `updateCanvasNode` (from `mode_provider.dart`)
- Produces: text field bound to `configKey` on every node's settings tab

- [ ] **Step 1: Add controller + field**

In `/home/gem/projects/CartaClient/frontend/lib/widgets/node_drawer/editor_settings_tab.dart`:

1. Add controller declaration (line 38 area):

```dart
  late TextEditingController _configKeyCtrl;
```

2. Initialize in `initState` (line 56 area):

```dart
    _configKeyCtrl = TextEditingController(text: widget.node.configKey ?? '');
```

3. Dispose in `dispose` (line 74 area):

```dart
    _configKeyCtrl.dispose();
```

4. Add UI field — find the section that renders universal node fields (label, etc.). Insert a new block near the top of the settings form:

```dart
        // Config key — applies to all node kinds
        _buildTextField(
          controller: _configKeyCtrl,
          label: 'config_key',
          hint: 'e.g. db_settings',
          monospace: true,
          onChanged: (v) => _updateNode(widget.node.copyWith(
            configKey: v.trim().isEmpty ? null : v.trim(),
          )),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            'Name of a stored configuration object (Settings → Configuration Objects). '
            'Merged over this node's inline config at deploy.',
            style: TextStyle(color: AppColors.fg2, fontSize: 11),
          ),
        ),
```

Use the existing `_buildTextField` helper if present; otherwise use the same `TextFormField` pattern used for `_labelCtrl`.

- [ ] **Step 2: Run flutter analyze + tests**

```bash
cd /home/gem/projects/CartaClient/frontend && ~/projects/flutter/bin/flutter analyze && ~/projects/flutter/bin/flutter test
```

Expected: no errors, all tests green.

- [ ] **Step 3: Build web and verify**

```bash
cd /home/gem/projects/CartaClient/frontend && ~/projects/flutter/bin/flutter build web --release
```

Then restart the `cartaclient` Launchy app and spot-check in browser:
- Open a flow → click a node → settings tab → `config_key` field visible.
- Save a value → autosave PUTs YAML → confirm `config_key` appears in emitted YAML via YAML drawer.

- [ ] **Step 4: Commit**

```bash
cd /home/gem/projects/CartaClient && git add frontend/lib/widgets/node_drawer/editor_settings_tab.dart
git commit -m "feat(configs): config_key field in node drawer settings tab"
```

---

### Task 9: End-to-end verification + docs

**Files:**
- Modify: `/home/gem/projects/CartaClient/AGENTS.md` (Recently Landed entry)
- Modify: `/home/gem/projects/CartaClient/frontend/AGENTS.md` (Conventions section)

- [ ] **Step 1: Run both test suites one final time**

```bash
cd /home/gem/projects/Carta && mix test
cd /home/gem/projects/CartaClient/frontend && ~/projects/flutter/bin/flutter test
```

Expected: all green.

- [ ] **Step 2: Build web release + restart apps**

```bash
cd /home/gem/projects/CartaClient/frontend && ~/projects/flutter/bin/flutter build web --release
```

Then via MCP: `codery_restart_app` for `cbe1` and `cartaclient`.

- [ ] **Step 3: Manual E2E via curl**

```bash
# Create a config object
curl -s -X POST https://carta.rancidgrandmas.online/api/v1/configs \
  -H "Content-Type: application/json" \
  -d '{"project":"cbe1","key":"test_db","source":"%{host: \"localhost\", port: 5432}"}'

# List
curl -s 'https://carta.rancidgrandmas.online/api/v1/configs?project=cbe1'

# Create flow referencing the key
curl -s -X POST https://carta.rancidgrandmas.online/api/v1/workflows \
  -H "Content-Type: application/json" \
  -d '{"name":"cfgkey_e2e","content":"name: cfgkey_e2e\nnodes:\n  - id: a\n    type: function\n    config:\n      expr: |\n        payload\n      config_key: test_db\nedges: []\n"}'

# Validate (should pass)
curl -s -X POST https://carta.rancidgrandmas.online/api/v1/workflows/validate \
  -H "Content-Type: application/json" \
  -d '{"name":"cfgkey_e2e"}'

# Deploy (should succeed)
curl -s -X POST https://carta.rancidgrandmas.online/api/v1/workflows/cfgkey_e2e/deploy

# Cleanup
curl -s -X DELETE https://carta.rancidgrandmas.online/api/v1/workflows/cfgkey_e2e/deploy
curl -s -X DELETE https://carta.rancidgrandmas.online/api/v1/workflows/cfgkey_e2e
curl -s -X DELETE 'https://carta.rancidgrandmas.online/api/v1/configs/test_db?project=cbe1'
```

**Note on project name:** the Carta runtime's project name is `Path.basename(Carta.Project.dir())`. Check what that resolves to in the apps container — likely the dir of the Carta checkout (e.g. `Carta` or `cbe1`). Adjust the curl `project` param to match.

- [ ] **Step 4: Update AGENTS.md**

Add to `/home/gem/projects/CartaClient/AGENTS.md` under "Recently Landed" (top of list):

```markdown
- **Configuration objects (2026-07-23)**: Project-scoped named Elixir
  literals stored in Mnesia (`Carta.ConfigStore`), editable in Settings →
  Configuration Objects, opt-in per node via `config.config_key`. Node
  startup deep-merges the stored term over inline `config:` (stored wins).
  Deploy-time validation rejects unknown keys. 5 new endpoints under
  `/api/v1/configs`. Deferred: encrypted secrets file unlocked at job
  launch.
```

Add to `/home/gem/projects/CartaClient/frontend/AGENTS.md` under "Conventions":

```markdown
- **`config_key` on any node** references a stored configuration object
  (Settings → Configuration Objects). Round-trips via `config.config_key`
  in YAML. `WorkflowNode.configKey` holds the value; drawer field in
  `editor_settings_tab.dart`.
```

- [ ] **Step 5: Commit docs**

```bash
cd /home/gem/projects/CartaClient && git add AGENTS.md frontend/AGENTS.md
git commit -m "docs: configuration objects"
```

---

## Self-Review

**Spec coverage:**
- ✅ Mnesia store (Task 1)
- ✅ REST API (Task 2)
- ✅ Node hook + deep-merge (Task 3)
- ✅ Deploy validation (Task 4)
- ✅ Frontend API client + providers (Task 5)
- ✅ Settings UI (Task 6)
- ✅ YAML round-trip (Task 7)
- ✅ Drawer field (Task 8)
- ✅ E2E + docs (Task 9)

**Out of scope (deferred, not in plan):**
- Encrypted secrets file (explicit defer)
- Global (cross-project) namespace
- `config_key` autocomplete
- Per-environment overlays

**Placeholder scan:** No TBD/TODO. Code is complete in each step. The two flagged notes (PayloadEditor signature, projectProvider shape, WorkflowNode constructor signature) instruct the implementer to verify against actual code — these are not placeholders but integration checkpoints.

**Type consistency:** `ConfigObject` fields consistent between Task 5 (Dart) and Task 6 (widget). `Carta.ConfigStore` API consistent between Task 1 (impl), Task 2 (HTTP wrapper), Task 3 (runtime consumer), Task 4 (validation consumer).
