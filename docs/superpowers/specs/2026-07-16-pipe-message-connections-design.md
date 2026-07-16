# Pipe & Message Connection Types

## Goal

Design the two connection types for the Trailhead/THRT visual workflow engine
so the node graph generates **literal standard Elixir** — `|>` (pipe) and
`send/2` (message) — with minimal magic. The graph is a notation for real
Elixir code, not an abstraction over it.

## Why

The current engine routes everything through dynamic per-node GenServers and
runtime `send/2`, with a single `edges:` list that conflates two fundamentally
different Elixir semantics. This makes the generated "code" non-idiomatic and
hides what actually executes. Two distinct connection types — one per Elixir
construct — make the graph's meaning literal and auditable.

## Constraints & Preferences

- **Follow standard Elixir language rules.** No abstractions or syntax sugar
  beyond the one unavoidable desugar: `function → actor` is sugar for
  `|> send/2(actor)` (you cannot pipe directly into a process).
- **Graph generates literal Elixir code.** What you draw is what runs.
- **Trusted authors.** No sandbox or guardrails — focus on making it work.
- **Throw out the current `task.ex` implementation entirely.** It deviated
  from the original intent; rebuild fresh.
- **Keep multi-port handle frontend code.** Needed for future `case`
  expressions (deferred — see §10).
- **Don't over-engineer node internals.** Function nodes are just Elixir
  functions.

## Core Model

### Two connection types

| Type   | Derived when            | Visual        | Elixir semantics |
|--------|-------------------------|---------------|------------------|
| Pipe   | `to` node is a function | Solid bezier  | `\|>` operator   |
| Message| `to` node is an actor   | Dashed bezier | `send/2` to named GenServer |

**The type is DERIVED from the target node, never stored in YAML.**

### Actor vs function classification

- **Actor** = any module that wraps or abstracts the Erlang Process primitive
  (has a mailbox, can send/receive messages). Detected by exporting
  `handle_message/3`. GenServer, Task, and Agent are all actors.
- **Function** = everything else. Uses the `transform/3` callback. 1 pipe in,
  1 pipe out.

Detection is via module introspection
(`function_exported?(module, :handle_message, 3)`), **not** a hardcoded type
registry.

### The one allowed desugar

A `function → actor` connection is sugar for `|> send/2(actor)`. This is the
only non-literal transform — required because you cannot pipe a value directly
into a process mailbox. Every other connection maps 1:1 to literal Elixir.

## YAML Schema

Single flat `connections:` list with `{from, to}` only. No type field, no
separate `pipes`/`messages` lists.

```yaml
name: my-flow
nodes:
  - { id: ingress,  type: http,     config: {} }
  - { id: downcase, type: function, config: { expr: "String.downcase(payload)" } }
  - { id: encode,   type: function, config: { expr: "Jason.encode!(payload)" } }
  - { id: logger,   type: genserver, config: {} }
connections:
  - { from: ingress,  to: downcase }
  - { from: downcase, to: encode }
  - { from: ingress,  to: logger }
  - { from: downcase, to: logger }
```

**Legacy migration:** the parser accepts the old `edges:` key and treats it as
`connections:` (auto-migrate). Existing flows' edges pointing at GenServer
nodes become messages; the rest become pipes.

## Validation Rules

Shared identically by frontend and backend:

1. Classify each node: actor (`handle_message`) vs function (`transform`).
2. Infer each connection's type from the `to` node's classification.
3. **Max 1 pipe per `from` node** — at most one connection whose `to` is a
   function. (You can't pipe one value into two functions.)
4. Messages: unlimited.
5. All `from`/`to` must reference declared nodes.

**Frontend enforcement:** drag end → if invalid, red flash + connection
cancelled. Loaded invalid connections render red.

**Backend enforcement:** validation fails the deploy / compile.

## Engine: Option B (AST Generation)

Chosen approach. At deploy time, the engine walks the graph and generates
Elixir AST via `quote`/`unquote`, then evaluates with `Code.eval_quoted/3`.

**Rules the generator follows:**

1. Messages fire **first** (before pipe) — mirrors Elixir syntax order.
2. Pipe chains become nested `|>` (or sequential bindings).
3. When a node has BOTH message and pipe outputs, bind the intermediate to a
   variable, send the messages, then continue the pipe.
4. Actor names: `:"{flow_name}.{node_id}"` — registered atoms for `send/2`.

**Generated code for the example graph above:**

```elixir
def handle_message(payload) do
  send(:"my_flow.logger", payload)          # message: ingress→logger (fires first)
  result = String.downcase(payload)         # pipe step 1
  send(:"my_flow.logger", result)           # message: downcase→logger
  result |> Jason.encode!()                 # pipe step 2
end
```

**Runtime structure:**

- Actors spawn as named GenServers at deploy, registered as `:"{flow}.{id}"`.
  They own their mailbox + state.
- Functions have **no process** — they inline into the actor handler that
  pipe-chains from it at eval time.

### Execution order

1. **Message phase** — all `send/2` calls fire first.
2. **Pipe phase** — the `|>` chain executes after.

## Node Behaviour Refactor

### Callbacks

Remove `output_ports/0` and `handle_tick/2`. Two callback tracks:

- **Actor:** `handle_message/3(env, state) -> {:noreply, state}`
- **Function:** `transform/3(payload, state) -> {:ok, data, state}`

Add classification helper: `THRT.Node.actor?(module)` →
`function_exported?(module, :handle_message, 3)`.

### Built-in node table

| Node          | Type      | Callback          | Notes                                              |
|---------------|-----------|-------------------|----------------------------------------------------|
| `task.ex`     | **Actor** | `handle_message/3`| **Rebuilt.** Elixir Task process. Throw out current sync impl. |
| `function.ex` | **Function** | `transform/3`  | **NEW.** User writes Elixir in config `expr`. 1 pipe in, 1 pipe out. |
| `genserver.ex`| Actor     | `handle_message/3`| Conceptually unchanged.                            |
| `http.ex`     | Actor     | `handle_message/3`| HTTP Plug context.                                 |
| `delay.ex`    | Function  | `transform/3`     |                                                    |
| `sink/log.ex` | Function  | `transform/3`     | `Logger.debug/2`. Terminal (no pipe out).          |

### Things removed

- `output_ports/0` callback
- `handle_tick/2` callback
- Edge **labels** entirely (user never wanted them)
- `emit` callback anywhere — the **engine owns all routing** based on graph
  structure. Nodes never decide where their output goes.
- Per-node GenServer (`Node.Server`) for function nodes — they're inlined

## Implementation Plan

### Phase 1 — THRT Backend (Elixir)

All paths under `/home/gem/projects/THRT/`.

**1.1 Node behaviour** (`lib/thrt/node.ex`)
- Remove `output_ports/0`, `handle_tick/2`
- Add `transform/3(payload, state) -> {:ok, data, state}` for functions
- Keep `handle_message/3(env, state) -> {:noreply, state}` for actors
- Add `THRT.Node.actor?(module)` helper via export introspection

**1.2 YAML schema + flow model** (`lib/thrt/yaml.ex`, `lib/thrt/flow.ex`)
- `Flow.Edge` → `Flow.Connection { from, to }` (drop `port`, `label`)
- YAML key: `connections:` (accept legacy `edges:` for migration)
- Parser classifies each node actor/function
- Validator: ≤1 pipe per `from`; type inferred from `to`; all refs resolve

**1.3 AST code generator** (new: `lib/thrt/codegen.ex`)
Core of Option B. Walks graph, builds Elixir AST:
- For each actor root: generate `handle_message/3` body
- Message connections → `send(:"{flow}.{target}", payload)` AST (fire first)
- Pipe chain → nested `|>` or sequential binds
- Node with both message + pipe outputs → bind intermediate variable, send, continue pipe
- Function node config `expr` → parsed via `Code.string_to_quoted!/1`, spliced into chain
- Returns `%{actor_id => quoted_ast}`

**1.4 Deploy pipeline** (`lib/thrt/engine.ex`)
- At deploy:
  1. Validate graph (rules in §5)
  2. Run codegen → AST map
  3. Spawn actor GenServers, register `:"{flow}.{id}"`
  4. `Code.eval_quoted/3` actor handlers with bindings `[payload: env.payload, ...]`
- Functions inline — no processes for function nodes
- Remove old `Node.Server` GenServer-per-node for functions
- Actors keep `Node.Server` (mailbox + state)

**1.5 Tests** (`test/`)
- `codegen_test.exs` — verify AST structure for pipe-only, message-only, mixed
- `yaml_test.exs` — `connections` parsing + validation (reject >1 pipe/source)
- `engine_test.exs` — deploy + trigger → message fires before pipe
- Migration test — legacy `edges:` loads as `connections`

### Phase 2 — Frontend (Flutter)

All paths under `/home/gem/projects/CoderyTrailhead/frontend/`.

**2.1 Data model** (`lib/models/workflow_edge.dart`)
- `WorkflowEdge` → `WorkflowConnection { from, to }`
- **Keep `sourcePort`** field (reused for future ports — see §10)
- Node type metadata: `isActor` boolean (derived from type ∈ actor set `{genserver, http, task, ...}`)

**2.2 YAML round-trip** (`lib/utils/workflow_to_yaml.dart`, `lib/utils/yaml_to_workflow.dart`)
- Write/read `connections:` with `{from, to}`
- Legacy `edges:` read for migration

**2.3 Connection painter** (`lib/widgets/canvas/connection_painter.dart`)
- Infer type per connection: `to.isActor` → message → **dashed** bezier; else → pipe → **solid**
- Dashed: traverse path metrics, draw alternating dash/gap segments
- Solid: current style

**2.4 Drag UX** (`lib/widgets/canvas/graph_canvas.dart`)
- Single output handle per node (one snap point)
- On drag end: classify target; if `to` is function AND `from` already has a pipe out → invalid → red flash + cancel
- Loaded invalid connections: render red (visual error state)

**2.5 Remove**
- Edge **labels** — all label UI + data
- Do **NOT** remove multi-port handle code (kept for §10)

### Phase 3 — Future alternatives doc
Write design notes for Option A and Option C (see §11).

## Deferred: Ports as Literal `case` Expressions

**Status: deferred. Not this pass. Frontend multi-port handle code preserved
as the foundation.**

Nodes declare multiple output ports. Each port = a **pattern clause in a
literal Elixir `case` expression**. User supplies the patterns. Generated code
is a real `case do ... end`, not an abstraction.

**Graph:**
```yaml
nodes:
  - id: classify
    type: function
    ports: [ok, error]
connections:
  - { from: classify, port: ok,    to: handle_ok }
  - { from: classify, port: error, to: handle_err }
```

**Generated Elixir (literal, no sugar):**
```elixir
case classify(payload) do
  {:ok, result}     -> handle_ok(result)
  {:error, reason}  -> handle_err(reason)
end
```

Each port maps to one `case` arm. Patterns authored by the user in node
config. The frontend multi-port handles already render this visually — one
handle per port.

## Future Alternatives

Documented for later; not implemented now.

- **Option A — Generate `.ex` files, `mix compile`.** Real BEAM modules, real
  stack traces, but slower deploy and files on disk.
- **Option C — Keep the dynamic per-node GenServer engine, simulate `|>` and
  `send/2` semantics at runtime.** No codegen, but non-literal (back to
  abstraction).
- **Config flag concept:** `engine_mode: :ast_eval | :compile | :dynamic` to
  flip between modes.

## Q&A / Decision Rationale

The full set of decisions made during the design session, with the user's
verbatim intent preserved.

1. **Connection types = pipe + message.** User confirmed two types, mapped to
   `|>` and `send/2`. Visuals: solid vs dashed.

2. **Type is derived, never stored.** *User correction:* "I don't think I
   like the pipes/messages section of the YAML... have the connections all be
   listed as simply connections or 'channels', and have the frontend and
   backend both follow the validation rules... Whether a channel is a pipe or
   message is determined at runtime of the frontend, and at validation before
   compilation in the backend." → Single flat `connections:` list, no type
   field.

3. **Actor definition.** *User:* "An Actor is any module in Elixir which
   wraps or abstracts the Erlang Process primitive, meaning it has a mailbox
   so it can send and receive messages, meaning it implements the
   handle_message callback. GenServer, Task, and Agent are all examples."
   → Detection is module-introspection based, not a hardcoded registry.

4. **HTTP node.** *User:* "this node will implement code within the context
   of an HTTP Plug server." → Actor.

5. **`sink.log`.** *User:* "sink.log is Logger.debug/2." → Function, terminal.

6. **Security.** *User:* "trusted authors, focus on making it work, not
   guardrails." → No sandbox on `Code.eval_quoted/3`.

7. **Engine = Option B (AST generation).** Chosen over Option A (compile
   `.ex` files) and Option C (dynamic simulation). AST via `quote`/`unquote`
   → `Code.eval_quoted/3` at deploy.

8. **Messages fire before pipe.** Mirrors Elixir syntax order; simplifies
   codegen.

9. **Actors = named GenServers** registered as `:"{flow}.{id}"`. Functions
   inline into caller scope (no process).

10. **`task.ex` rebuild.** *User:* "current THRT task.ex node does synchronous
    transforms → Throw out the current task.ex implementation, build it
    correctly. I don't care about the current implementation, it apparently
    deviated from the original intent." → `task` rebuilt as an actor (Elixir
    Task is a process). New separate `function` node for synchronous
    transforms.

11. **Single output handle, inferred type.** *User chose A:* single handle
    per node, type inferred from snap target (drag to function = pipe, drag
    to actor = message). Cleaner than two distinct handles since type is
    always derived from target.

12. **Multi-port handles KEPT.** *User correction:* "You wrote 'multi-port
    handles', what does this mean? Keep frontend code for nodes with multiple
    output connections, these will be used later for case expressions where
    each port corresponds to a pattern given by the user. These create literal
    Elixir case expressions, not syntax sugar, not an abstraction. Write this
    to a plan since we're not doing it in this pass, it's deferred." → §10.

13. **Labels dropped entirely.** User never wanted edge labels; removed from
    data model, YAML, and UI.

14. **No `emit` callback.** The engine owns all routing based on graph
    structure; nodes never self-route.

15. **`output_ports/0` + `handle_tick/2` removed** from the Node behaviour.

## Relevant Files

### Backend — THRT (`/home/gem/projects/THRT/`)
- `lib/thrt/node.ex` — Node behaviour; remove `output_ports/0` + `handle_tick/2`, add `transform/3`, add `actor?/1`
- `lib/thrt/flow.ex` — `Flow.Edge` → `Flow.Connection { from, to }`
- `lib/thrt/yaml.ex` — YAML parser; `edges` → `connections`, legacy migration
- `lib/thrt/flow/router.ex` — current routing builder (to be replaced by codegen)
- `lib/thrt/engine.ex` — deploy pipeline; integrate codegen + `Code.eval_quoted/3`
- `lib/thrt/nodes/task.ex` — **throw out**, rebuild as actor
- `lib/thrt/nodes/genserver.ex` — actor, conceptually unchanged
- `lib/thrt/nodes/delay.ex` — refactor to function (`transform/3`)
- `lib/thrt/nodes/sink/log.ex` — refactor to function (`transform/3`, `Logger.debug/2`)
- **New:** `lib/thrt/codegen.ex` — AST code generator (core of Option B)
- **New:** `lib/thrt/nodes/function.ex` — function node (`transform/3`, user-written Elixir expr)
- **New:** `lib/thrt/nodes/http.ex` — HTTP Plug actor

### Frontend — CoderyTrailhead (`/home/gem/projects/CoderyTrailhead/frontend/`)
- `lib/models/workflow_edge.dart` — → `WorkflowConnection { from, to }`, **keep `sourcePort`**
- `lib/widgets/canvas/connection_painter.dart` — dashed bezier for messages, solid for pipes
- `lib/widgets/canvas/graph_canvas.dart` — single handle per node, drag validation, red on invalid
- `lib/utils/workflow_to_yaml.dart` — write `connections:` list
- `lib/utils/yaml_to_workflow.dart` — read `connections:` + legacy `edges:`
- `lib/providers/mock_data.dart` — mock workflow data with edges

---

*Recovered from opencode session `ses_095fedb71ffeFcuzONVsSq0jJ7`
("Trailhead: pipe vs message send connections") which was lost to a
glm-5.2 API 401 (token expired) followed by an opencode serve OOM-restart.
Plan was approved in-session; commit `2ee12ee` (Rust prototype retirement)
landed before the crash. This doc reconstructs the approved design and plan
so a fresh session can execute it.*
