# Trailhead Frontend - Agent Guide

## Purpose

Flutter SPA for Trailhead workflow visualization and management. Currently a skeleton — blank gradient page. All UI, state management, and graph rendering will be added in later changes.

## Current State

- Flutter project targeting **web** (embedded in Rust binary) and **iOS** (native app)
- Single page: full-screen gradient background (white → light gray/blue)
- No routing, no components, no state management, no API client
- No third-party packages beyond Flutter SDK defaults

## Build Commands

| Action | Command |
|--------|---------|
| Run web | `flutter run -d chrome` |
| Build web release | `flutter build web --release` |
| Run tests | `flutter test` |
| Create iOS build | `flutter build ios --release --no-codesign` (macOS only) |

## Code Style

- Standard `flutter_lints` package (no third-party lints)
- When adding new packages, add to `pubspec.yaml` first, then run `flutter pub get`
- Prefer Riverpod for state management (when added)
- Use `vyuh_node_flow` for graph rendering (when added)

## Project Structure

```
frontend/
├── lib/
│   └── main.dart          # App entry - single gradient page
├── test/
│   └── widget_test.dart   # Basic render test
├── ios/                   # iOS platform (requires macOS to build)
├── pubspec.yaml
└── AGENTS.md              # This file
```

## Backend

The backend Rust service lives at `crates/trailhead-service/`. The web build output is embedded at compile time via `build.rs`.
