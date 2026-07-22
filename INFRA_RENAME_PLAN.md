# Carta Rename — Infrastructure Plan

Code rename is **complete and verified** (THRT: 343 tests green; frontend: 77 tests
green + web build OK). This doc covers the **infra-side** changes you run yourself
via MCP / shell. Run in order; verify at each checkpoint.

## Current State (what's running now)

Launchy app configs live in `/etc/launchy/apps.d/` (apps container):

| File | App name | What | Sname/Port |
|------|----------|------|------------|
| `thrt.json` | `thrt` | Runtime BEAM | sname `thrt`, port 8060 |
| `trailhead.json` | `trailhead` | Frontend Bun proxy | port 8040, subdomain `trailhead.rancidgrandmas.online` |
| `flow.json` | `flow` | `sleep infinity` placeholder in THRT dir | — |
| `design.json` | `design` | Design prototype (unchanged) | — |

Key env in `thrt.json`: `THRT_PROJECT_DIR=/home/gem/projects/TrailheadTests`.
The code now reads **`CARTA_PROJECT_DIR`** (renamed in `config/config.exs`).

User config dir: `~/.trailhead/` (contains `projects.yaml`, `packages/`).
Project config file: `trailhead.yaml` in each project dir.
Remsh helper: `/home/gem/projects/thrt-remsh.sh` (targets sname `thrt`).

## Target State

| App name | What | Sname/Port | Subdomain |
|----------|------|------------|-----------|
| `cbe1` | Runtime BEAM | sname `cbe1`, port 8060 | (internal; optional `cbe1.rancidgrandmas.online`) |
| `cartaclient` | Frontend Bun proxy | port 8040 | `carta.rancidgrandmas.online` |

User config dir: `~/.carta/`. Project config: `carta.yaml`. Remsh: `carta-remsh.sh`.

---

## Step 1 — Prep: rename user config + project files

```bash
ssh gem@apps '
  # user config dir
  mv ~/.trailhead ~/.carta
  # project config files (trailhead.yaml -> carta.yaml) in every registered project
  for d in $(grep -v "^#" ~/.carta/projects.yaml 2>/dev/null); do
    [ -f "$d/trailhead.yaml" ] && mv "$d/trailhead.yaml" "$d/carta.yaml"
  done
  # the active test project
  [ -f /home/gem/projects/TrailheadTests/trailhead.yaml ] && \
    mv /home/gem/projects/TrailheadTests/trailhead.yaml /home/gem/projects/TrailheadTests/carta.yaml
  # remsh helper
  mv ~/projects/thrt-remsh.sh ~/projects/carta-remsh.sh
'
```

Then edit `carta-remsh.sh`: change `thrt` → `cbe1` (sname + grep pattern + messages).

## Step 2 — DNS (if not using wildcard)

Add A/AAAA records (or CNAME) for:
- `carta.rancidgrandmas.online` → VPS (required — public frontend)
- `cbe1.rancidgrandmas.online` → VPS (only if you want direct runtime API access)

If `*.rancidgrandmas.online` wildcard exists, skip.

## Step 3 — Swap Launchy apps

Use the Codery MCP tools (run from OpenCode — `codery.*`):

```
# Remove old apps (stops process, deletes config + route)
remove_app name='thrt'
remove_app name='trailhead'
# Optional: remove the dead placeholder
remove_app name='flow'

# Add runtime: cbe1 (Carta Backend Engine #1)
add_app name='cbe1' internal_port=8060 \
  command='bash -c "elixir --sname cbe1 -S mix run --no-halt"' \
  directory='/home/gem/projects/THRT' \
  env='{"HOME":"/home/gem/projects","PORT":"8060","CARTA_PROJECT_DIR":"/home/gem/projects/TrailheadTests"}'

# Add frontend: cartaclient
add_app name='cartaclient' subdomain='carta' internal_port=8040 \
  command='bash -c "bun run serve.js"' \
  directory='/home/gem/projects/CoderyTrailhead/frontend'
```

Then reload routes:
```
reload_routes
```

## Step 4 — Verify

```bash
# Runtime health (cbe1 serves /api directly on 8060 inside container)
ssh gem@apps 'curl -s http://localhost:8060/'
# Expect: {"service":"carta","status":"ok"}

# Frontend + proxy (public)
curl -s https://carta.rancidgrandmas.online/api/v1/workflows
# Expect: JSON workflow list (proxied to cbe1)

# App status
get_app_status name='cbe1'
get_app_status name='cartaclient'

# remsh works
ssh gem@apps '~/projects/carta-remsh.sh'
# Inside IEx: :ets.tab2list(:carta_stats)
```

## Step 5 — Redeploy running flows

Running deployments do **not** survive the BEAM restart (sname `thrt` → `cbe1`).
Redeploy any flows you need live:

```bash
curl -s -X POST https://carta.rancidgrandmas.online/api/v1/workflows/<name>/deploy
```

## Notes

- **Dir names unchanged**: `/home/gem/projects/THRT` and
  `/home/gem/projects/CoderyTrailhead` stay as-is (OpenCode session is bound to them).
  The GitHub repo can still be renamed to `Carta` separately (git remote update only).
- `flow.json` was a `sleep infinity` placeholder — safe to remove.
- The `_build/` and `.dart_tool/` artifacts were regenerated during verification
  (mix compile + flutter build). Stale `THRT`-named `.beam` files are gone.
- Graphify auto-regenerates its graph on next commit; stale `THRT` labels self-heal.
