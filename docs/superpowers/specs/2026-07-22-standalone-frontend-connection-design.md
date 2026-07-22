# Design: Standalone Frontend — THRT Connection Layer

Date: 2026-07-22
Status: approved (brainstorm session)

## Context

The Trailhead frontend currently assumes same-origin: it is served by a Bun
proxy that forwards `/api/*` to THRT, so no connection configuration, CORS, or
auth exists. The new architecture makes the frontend a **pure client** — a
static web build (hosted on any web server, independent of the THRT instance),
an iOS app, or an Android app — that connects to any Elixir project which has
THRT installed as a Mix dependency and the conventional project structure
(`trailhead.yaml`, `flows/`, `subflows/`).

Connection model (decided in brainstorm):

- **THRT is the server.** No companion daemon, no host manager. The app talks
  directly to the project's THRT HTTP/WS API, MongoDB-Compass-style.
- **URL entry on all platforms.** iOS is URL-only. The folder browser (local
  project discovery) is **deferred** to a later change.
- **Optional bearer token auth**, network trust otherwise.
- The existing Bun-proxy same-origin deployment keeps working unchanged as the
  zero-config default for web.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Server piece | THRT itself (Bandit) | Already serves HTTP+WS; no new moving parts |
| Connection UX | URL + optional token, saved connection list, one active | Compass-style; works identically on web/iOS/Android |
| Auth | Optional bearer token via `THRT_AUTH_TOKEN`; unset = open | Local dev stays frictionless; remote mode opt-in secure |
| CORS | Env-configured origins (`THRT_CORS_ORIGINS`), default off | Same-origin proxy unaffected; cross-origin opt-in |
| Bind guard | Default `127.0.0.1`; `0.0.0.0` requires token or explicit `THRT_ALLOW_INSECURE=1` | Fail-fast against accidentally exposed open API |
| Folder browser | Deferred | Needs THRT fs/browse API or desktop shell — separate design |
| Bun proxy | Kept, unchanged | Zero-config web default stays |

## THRT backend changes

### `THRT.Cors` (new plug)

- Reads `THRT_CORS_ORIGINS` (comma-separated origins, `*` allowed). Default
  empty → no CORS headers emitted (current behavior preserved).
- Answers `OPTIONS` preflights for allowed origins; allows headers
  `Authorization, Content-Type` and methods `GET, POST, PUT, PATCH, DELETE,
  OPTIONS`.
- Inserted first in the `THRT.Api` plug pipeline so preflights never hit
  routing or auth.

### `THRT.Auth` (new plug)

- If `THRT_AUTH_TOKEN` unset → pass-through (open mode).
- If set → all `/api/*` requests require `Authorization: Bearer <token>`;
  mismatch → 401 `%{error: "unauthorized"}`.
- The log-stream WebSocket (`GET /api/v1/workflows/:name/logs/stream`) accepts
  the token via `?token=` query param instead (browsers cannot set headers on
  WS handshakes). Auth plug accepts either header or query param on that path.
- Health endpoint `GET /` stays open.

### Bind address guard

- New env `THRT_BIND` (default `127.0.0.1`) controls Bandit's bind IP.
- Boot refuses `0.0.0.0` (or any non-loopback bind) without `THRT_AUTH_TOKEN`
  unless `THRT_ALLOW_INSECURE=1` is set — crash with a clear message.

### Out of scope (backend)

- No routing changes; API surface identical.
- No `fs/browse` or `project/open` endpoints (folder browser deferred).
- No TLS termination inside THRT (Caddy or LAN trust handles that).

## Frontend changes

### Connection model

- **`ConnectionSettings`** (new model): `{name, baseUrl, token?}`.
- **`connectionsProvider`** (new): persisted list via `shared_preferences`
  (web → localStorage), plus `activeConnectionProvider` holding the selected
  one. First launch with zero saved connections → connect screen.
- **Default connection**: when the web build is served same-origin (Bun
  proxy), the default is a relative-URL connection — current behavior, zero
  config. Detection: if no saved connections exist and `Uri.base` has an
  http(s) origin, seed a "This server" relative connection.

### API client refactor

All clients take `(baseUrl, token)` from the active connection instead of
hardcoded relative URLs:

- `WorkflowsApi`, `ThrtApi`, `ProjectApi`, `JobsApi` — add `Authorization`
  header when token present; base URL no longer assumed relative.
- `LogSocket` — builds `ws(s)://<base>/api/v1/workflows/:name/logs/stream`,
  appends `?token=` when present.
- `api_provider.dart` / `project_provider.dart` and friends re-created from
  `activeConnectionProvider` (Riverpod `watch` → rebuild clients on switch).

### Connect UI

- **Connect screen** (new, blocking on first run / when active connection
  removed): URL field, optional token field, "Test connection" button (GET
  `/api/v1/project` — 200 = success), Save.
- **Settings → Instance section**: shows active connection (name, URL), edit
  token, disconnect/switch. Existing instance info display unchanged in shape.
- **Connection switcher**: saved list in the connect screen (and settings) —
  tap to activate.
- **401 handling**: any client getting 401 surfaces "authentication failed"
  on the active connection; UI prompts to edit the token (banner + settings
  deep-link), does not silently retry.

## Platforms / deployment

- **Web prod**: `flutter build web` output is pure static — host on any web
  server independent of THRT. Connects cross-origin via CORS + token.
- **iOS / Android**: same connect screen; URL entry only.
- **Existing deployment** (`trailhead.rancidgrandmas.online` Bun proxy → THRT
  on localhost): unchanged; seeds the relative default connection.

## Testing

- THRT `mix test`:
  - CORS: preflight allowed/denied origin shapes; no headers when unconfigured.
  - Auth: 401 without token when set; 200 with header; WS query-param token
    accepted; open mode passes through.
  - Bind guard: refuses non-loopback without token/`THRT_ALLOW_INSECURE`.
  - Full existing suite (279 tests) stays green in open mode.
- Frontend (manual E2E):
  - Static web build served from a **different origin** → connect to remote
    THRT with token; workflows CRUD, deploy, inject, log stream all work.
  - Same-origin Bun proxy path: zero-config default still works.
  - 401 path: wrong token → banner + settings prompt.
  - iOS connect flow verified on macOS simulator (out of sandbox).

## Out of scope

- Folder browser / local project discovery (deferred; needs THRT fs/browse or
  desktop shell — separate change).
- Multi-connection simultaneous use (one active connection at a time).
- Token storage hardening (keychain/keystore) — `shared_preferences` for now.
- TLS inside THRT.
