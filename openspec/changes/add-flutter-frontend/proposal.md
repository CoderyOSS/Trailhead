## Why

Trailhead has zero frontend — `serve_spa()` returns 404. Users can only interact via CLI or MCP tools. A Flutter web SPA scaffold, embedded in the Rust binary, establishes the delivery pipeline for the future graphical UI.

## What Changes

- Add `frontend/` directory with a Flutter project targeting web + iOS
- Flutter app displays a blank page with a light gradient background
- Embed Flutter web build into Rust binary via `rust-embed` and a `build.rs` script
- `web.rs` `serve_spa()` returns the embedded Flutter `index.html` instead of 404
- Axum serves Flutter static assets (`.js`, `.wasm`, etc.) with correct content types
- **BREAKING**: Remove old `crates/trailhead-service/ui/` React SPA stub (never built)
- Add `AGENTS.md` at `frontend/AGENTS.md` and `crates/trailhead-service/AGENTS.md`
- CI: `build.yml` updated for Flutter web build, new `build-frontend-ios.yml` for macOS iOS builds
- No components, pages, state management, API client, or graph rendering — scaffold only

## Capabilities

### New Capabilities
- `flutter-frontend`: Flutter SPA skeleton served from Trailhead binary. Blank gradient page. Web + iOS build targets. AGENTS.md for subagent guidance.
- `frontend-ci`: GitHub Actions for Flutter web build (ubuntu-latest) and Flutter iOS build (macos-latest). Web output embedded in Rust binary at build time.

### Modified Capabilities
- `trailhead-web-ui`: The existing `web.rs` `serve_spa()` placeholder (404) serves the embedded Flutter SPA instead.

## Impact

- **Code**: New `frontend/` directory. Modified `crates/trailhead-service/src/web.rs`, `build.rs`, `Cargo.toml`. Updated `.github/workflows/build.yml`. New `.github/workflows/build-frontend-ios.yml`.
- **Dependencies**: Rust: add `rust-embed`. Flutter: none beyond SDK default (cupertino, material).
- **Build pipeline**: `build.yml` `build-frontend` job switches from npm (old React stub) to Flutter SDK via `subosito/flutter-action@v2`.
- **Versioning**: Frontend gets independent version in `frontend/pubspec.yaml` tagged `frontend-v{version}`.
