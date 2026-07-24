# UI Polish — Handoff for Fresh Session

## TL;DR

5-item UI polish agenda at `docs/ui-polish-agenda.md`. Items **A** and **B**
landed. **Accent-bleed regression** introduced mid-B is fixed. Next up:
**Item C** (arrange-panels icon swap).

Repo: `/home/gem/projects/CartaClient`, branch `main`.

## Project Snapshot

- **CartaClient** = Flutter web SPA (workflow node-graph editor). Lives in
  `frontend/`.
- Runtime backend is **Carta** (separate Elixir repo at
  `/home/gem/projects/Carta`) — out of scope for this agenda.
- Read `AGENTS.md` (repo root) for full architecture. The
  "design/" dir is a frozen prototype — never edit.

## Workflow (per agenda item)

1. Read the item verbatim from `docs/ui-polish-agenda.md`.
2. Plan → execute → **verification gate** → commit to `main`.
3. Never bundle items.

### Verification gate (mandatory before each commit)

```bash
cd ~/projects/CartaClient/frontend
~/projects/flutter/bin/flutter analyze        # 0 errors (warnings/info OK)
~/projects/flutter/bin/flutter test           # all green
~/projects/flutter/bin/flutter build web --release   # ✓ Built build/web
```

Then restart the live app and visually confirm:

```
codery_restart_app name='cartaclient'
# visit https://carta.rancidgrandmas.online/
```

Then commit. Caveman-style commit messages welcome but keep them
informative (see recent `git log --oneline` for tone).

## Recent Commits (newest first)

```
5ed03a2 fix(_TabChip): replace StackFit.expand overlay with foregroundDecoration
ae42298 fix(ui): shrink flow tabs to 32px, bottom-anchor foot on bar border
1dd5156 fix(ui): align top bar height with logo + connect tab underline to border
5aa46f6 fix(ui): center build bar to match active-job bar layout
a1c6a14 feat(ui): tab-style flow tabs; theme launch button + click spinner
7307d5e feat(ui): move running chip next to job dropdown; outline clear button
4690c9b docs: add UI polish agenda
```

(`[graphify]` auto-commits interspersed — ignore them.)

## Items DONE

- **A** (commit `7307d5e`): Running chip moved next to job dropdown; logs
  clear button → `AppButtonVariant.secondary` (outline).
- **B** (commits `a1c6a14`, `5aa46f6`, `1dd5156`, `ae42298`):
  - Flow tabs restyled (32px tall, bottom-anchored foot).
  - Launch button uses `AppButton` with spinner-on-click pattern (mirrors
    injector nodes; see `lib/widgets/canvas/worker_node.dart:128-136`).
  - TopBar height fixed at 52 (matches `_BrandGlyph` logo height).

## Items REMAINING

### Item C — Replace arrange-panels icon (NEXT)

**Location:** `lib/widgets/drawer_panel.dart:177-183`. Currently uses
`Icons.swap_vert` / `Icons.swap_horiz` (2 opposing arrows).

**Want:** VS Code-style 2-rectangle icons — one for side-by-side columns,
one for stacked rows.

**Leads:** Material Icons (already available, `cupertino_icons` dep present)
ships candidates worth trying:
- `Icons.vertical_split` (rows stacked top-to-bottom)
- `Icons.view_column` (columns side-by-side)
- `Icons.horizontal_split`
- `Icons.table_chart` / `Icons.grid_view`

The icon swap is a one-liner per branch — but verify the *meaning* matches
(`layout == DrawerSplitLayout.horizontal` → which icon?). Read
`DrawerSplitLayout` enum in `lib/providers/drawer_provider.dart` first to
understand semantics.

### Item D — Theme color switching delays

Two symptoms when switching theme color:
1. **Logs text** doesn't recolor until panels toggled / node selection
   changes.
2. **Edit view**: left column of logs region + "add workflow tab" plus
   button both lag the theme switch.

Likely cause: colors cached in `State` fields or `initState` rather than
read live from `AppColors` getters inside `build`. Audit those widgets'
color sources.

### Item E — Active jobs view empty state

When switching to Active jobs view with no job selected, the canvas still
renders a workflow graph (misleading; creates interaction bugs).

**Want:** Show empty state — reuse `lib/widgets/empty_workflow_hero.dart`
(the same component the edit view shows when no workflows exist).

Bind to whichever provider gates "is there an active/selected job" —
investigate `jobDocumentsProvider` / `canvasWorkflowProvider`
(see `lib/providers/carta_provider.dart` and `mode_provider.dart`).

## Key Files

| File | What |
|---|---|
| `docs/ui-polish-agenda.md` | The verbatim agenda (source of truth). |
| `frontend/lib/widgets/drawer_panel.dart` | Item C target (`:177-183`). |
| `frontend/lib/widgets/empty_workflow_hero.dart` | Item E reuse target. |
| `frontend/lib/widgets/top_bar.dart` | `_BuildBar`/`_JobBar` (items A/B). |
| `frontend/lib/widgets/topbar/flow_tab_strip.dart` | `_TabChip` (just fixed). |
| `frontend/lib/widgets/app_button.dart` | `AppButton` variants catalog. |
| `frontend/lib/providers/drawer_provider.dart` | `DrawerSplitLayout` enum. |
| `frontend/lib/providers/carta_provider.dart` | Job/workflow providers. |
| `frontend/lib/providers/mode_provider.dart` | `canvasWorkflowProvider`. |

## Critical Gotchas (learned the hard way)

1. **`BoxDecoration` border + radius:** A non-uniform `Border` (e.g. only
   `bottom`) combined with `borderRadius` falls back to per-side painting
   that IGNORES the rounded clip path → accent bleeds at corners. Fix: put
   the per-side border on `foregroundDecoration` with NO radius (the
   rect's bottom edge is already straight, so per-side painting is clean).

2. **`Stack(fit: StackFit.expand)` in horizontal scroll lists:**
   `StackFit.expand` tightens non-positioned children at
   `constraints.biggest`. In a horizontal `ReorderableListView`,
   `biggest.width` is unbounded → infinite-width constraint → layout
   failure → children render at 0 width (invisible). This regressed
   `c8d1aae` (fixed in `5ed03a2`).

3. **`AppColors.accent` is a getter, not const** — `const` widgets
   referencing it fail to compile.

4. **`_BrandGlyph` height is 52** (`mode_rail.dart:106-124`) — the
   reference height TopBar must match.

## Environment

- Flutter SDK: `~/projects/flutter/bin/flutter` (bind-mounted; survives
  container restarts — never install to `/home/gem/flutter`).
- Live app: `cartaclient` (apps container, port 8040, served at
  `carta.rancidgrandmas.online`). Restart via
  `codery_restart_app name='cartaclient'`.
- Caveman mode: ON for chat. Plans/code/commits stay normal English.
- Push: use `github-push` from sandbox; for this agenda we've been
  committing to `main` locally without pushing (confirm with user if a
  push is wanted).

## Communication Style

CAVEMAN MODE: ON. NO OFF SWITCH.

NEVER: filler, articles, pleasantries, hedging, "Sure!", "Here's what I'll
do", action summaries, "Based on", "The answer is".
ALWAYS: fragments, short synonyms, direct answers. Pattern:
[thing] [action] [reason]. One word when one word enough. Code/commits/PRs
stay normal English.

SELF-CHECK before output: could this be 50% shorter? If yes, shorten.

## First Step for New Session

1. `git log --oneline -5` (confirm at `5ed03a2` or later).
2. Read `docs/ui-polish-agenda.md` § C.
3. Read `frontend/lib/widgets/drawer_panel.dart` around line 177 and the
   `DrawerSplitLayout` enum.
4. Confirm Material icon candidates render as expected (try
   `Icons.vertical_split`, `Icons.view_column`).
5. Execute → verification gate → commit.
