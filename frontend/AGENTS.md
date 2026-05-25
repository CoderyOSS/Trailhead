# Trailhead Frontend - Agent Guide

## Purpose

Flutter SPA for Trailhead workflow visualization and management. Follows the Codery design system (dark slate theme variant).

## Current State

- Flutter project targeting **web** (embedded in Rust binary) and **iOS** (native app)
- Dark slate background (`#0c0d10` page, `#14161b` main content)
- **Riverpod** for state management (`flutter_riverpod`)
- **Mode rail** + **top bar** implemented, driven by `modeProvider`
- Mock data drives UI — no backend connection yet
- No routing, no API client, no sidebars, no canvas, no filmstrip yet

### Implemented

| Component | File | Notes |
|-----------|------|-------|
| Design tokens | `lib/theme/tokens.dart` | Colors, spacing, radii from slate dark theme |
| SVG icons | `lib/widgets/icons.dart` | 12 Lucide stroke icons via `flutter_svg` |
| Mode rail | `lib/widgets/mode_rail.dart` | 52px ConsumerWidget rail, reads/writes `modeProvider` |
| Top bar | `lib/widgets/top_bar.dart` | ConsumerWidget — BuildBar, JobBar, HistoryListBar per mode |
| App button | `lib/widgets/app_button.dart` | ghost/secondary/trail/primary/danger variants |
| Status tag | `lib/widgets/status_tag.dart` | StatusDot (with pulse) + StatusTag (colored pill) |
| State providers | `lib/providers/mode_provider.dart` | `modeProvider`, `selectedJobProvider`, `workflowProvider` |
| Mock data | `lib/providers/mock_data.dart` | `JobSummary`, `WorkflowSummary`, `JobState` + mock instances |
| App shell | `lib/main.dart` | ProviderScope + ConsumerWidget shell: rail + top bar + content |
| Static server | `serve.js` | Bun server for dev preview at trailhead-dev subdomain |

### Not Yet Implemented

- Sidebars (Workflows sidebar, Jobs sidebar)
- Canvas (workflow graph visualization)
- Stage drawer (right slide-over)
- Snapshot filmstrip (bottom strip)
- Runs table (History mode)
- API client (backend connectivity)
- Routing (multiple pages)
- Graph rendering (`vyuh_node_flow`)

## Build Commands

| Action | Command |
|--------|---------|
| Run web dev | `~/flutter/bin/flutter run -d chrome` |
| Build web release | `~/flutter/bin/flutter build web --release` |
| Run tests | `~/flutter/bin/flutter test` |
| Analyze | `~/flutter/bin/flutter analyze` |
| Run iOS build | `~/flutter/bin/flutter build ios --release --no-codesign` (macOS only) |

## Dev Preview

The Flutter web build is served live at **trailhead-dev.rancidgrandmas.online** via a Bun static server in the apps container.

**Iterate cycle:**
```bash
~/flutter/bin/flutter build web --release
# Refresh browser — changes are live
```

The dev preview uses **mock backend data** baked into the Flutter build (no API calls). To update mock data, edit `lib/providers/mock_data.dart` and rebuild.

**App config:** `trailhead-ui` app, internal port 8040, directory `/home/gem/projects/CoderyTrailhead/frontend`, command `bun run serve.js`.

**Production** (`trailhead.rancidgrandmas.online`): served by the Rust binary via `rust-embed`. Requires `flutter build web --release` + copy to `crates/trailhead-service/ui/static/` + `cargo build` + service restart.

## Code Style

- Standard `flutter_lints` package (no third-party lints)
- When adding new packages, add to `pubspec.yaml` first, then run `~/flutter/bin/flutter pub get`
- Riverpod for state management (`flutter_riverpod`, manual providers — no codegen)
- Use `vyuh_node_flow` for graph rendering (when added)

## Project Structure

```
frontend/
├── lib/
│   ├── main.dart              # TrailheadApp (ProviderScope) + TrailheadShell (ConsumerWidget)
│   ├── providers/
│   │   ├── mode_provider.dart # modeProvider, selectedJobProvider, workflowProvider
│   │   └── mock_data.dart     # JobSummary, WorkflowSummary, JobState + mock data
│   ├── theme/
│   │   └── tokens.dart        # AppColors, AppSpacing, AppRadius
│   └── widgets/
│       ├── app_button.dart    # AppButton (ghost/secondary/trail/primary/danger)
│       ├── icons.dart         # TrailheadIcon (12 Lucide SVG stroke icons)
│       ├── mode_rail.dart     # ModeRail (ConsumerWidget) + AppMode enum
│       ├── status_tag.dart    # StatusDot + StatusTag
│       └── top_bar.dart       # TopBar (ConsumerWidget) + BuildBar/JobBar/HistoryListBar
├── serve.js                   # Bun static server for dev preview
├── assets/
│   └── images/
│       └── trailhead-logo.png
├── test/
│   └── widget_test.dart
├── ios/
├── pubspec.yaml
└── AGENTS.md
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management (manual StateProviders) |
| `flutter_svg` | SVG icon rendering (Lucide stroke paths) |
| `cupertino_icons` | iOS-style icons |

## Design System

The frontend follows the Codery design system at `design.rancidgrandmas.online`.

Theme: **dark** with **slate** variant. Key tokens:

| Token | CSS Variable | Flutter Constant | Hex |
|-------|-------------|-----------------|-----|
| Page background | `--co-bg-0` | `AppColors.bg0` | `#0c0d10` |
| App shell | `--co-bg-1` | `AppColors.bg1` | `#14161b` |
| Surface | `--co-bg-2` | `AppColors.bg2` | `#1a1d23` |
| Hover | `--co-bg-3` | `AppColors.bg3` | `#22262d` |
| Active | `--co-bg-4` | `AppColors.bg4` | `#2b303a` |
| Accent (orange) | `--co-accent` | `AppColors.accent` | `#e8923a` |
| Accent ink | `--co-accent-ink` | `AppColors.accentInk` | `#2d1810` |
| Text strong | `--co-fg-0` | `AppColors.fg0` | `#f3f4f6` |
| Text muted | `--co-fg-2` | `AppColors.fg2` | `#a5a9b1` |
| Border | `--co-border-1` | `AppColors.border1` | `#21242a` |

## Backend

The backend Rust service lives at `crates/trailhead-service/`. The web build output is embedded at compile time via `build.rs`.
