## Context

Trailhead is a Rust service (v0.3.5) running on a VPS host. Its `web.rs` `serve_spa()` returns `StatusCode::NOT_FOUND`. The original Phase 1 design sketched a `crates/trailhead-service/ui/` React/Vite SPA that was never built. This change adds a minimal Flutter skeleton — a blank gradient page — that replaces the 404 and establishes the build/deploy pipeline for future UI work.

The Flutter app targets web (embedded in Rust binary) and iOS (native app). All components, state management, API connections, and graph rendering will come in follow-up changes.

## Goals / Non-Goals

**Goals:**
- Flutter project at `frontend/` with web + iOS targets
- Blank page with a light gradient background
- Web build output embedded in Rust binary via `rust-embed`
- Axum serves Flutter HTML + static assets at `:4050/`
- Local dev: `flutter run -d chrome` and `cargo run` work independently
- CI: Flutter web build in `build.yml`, iOS build on macOS runner
- AGENTS.md files at `frontend/` and `crates/trailhead-service/`
- Remove old empty `ui/` stub

**Non-Goals:**
- Any UI components, pages, navigation, or layout
- Riverpod, API client, SSE, or any state management
- vyuh_node_flow or any graph rendering
- Design system or component library
- Authentication
- iOS deployment/distribution (CI builds only)

## Decisions

### Flutter over React / Svelte
**Chosen: Flutter.** Single Dart codebase targets web (WASM, embedded in Rust) and native iOS. For this scaffold, any framework would work — Flutter was chosen because future phases need both web and native iOS from one codebase.

### Blank Gradient Page
**Chosen: `Container` with `Decoration.linearGradient`.** A simple `Container` filling the viewport with a soft light gradient proves the Flutter rendering pipeline works end-to-end without introducing any framework-specific state or component abstractions.

### Embedded SPA via rust-embed
**Chosen: `rust-embed` with `build.rs` copying `frontend/build/web/` into `ui/dist/`.** The `build.rs` runs `rerun-if-changed` on the frontend build output so Rust rebuilds when the Flutter web bundle changes. If the directory is absent (no Flutter SDK in local dev), `build.rs` prints a warning and `serve_spa()` returns a plain text message.

### Axum Static Asset Serving
**Chosen: Serve Flutter assets via `rust-embed` in axum handlers.** A catch-all route after API routes returns the SPA `index.html` for HTML5 history mode. Specific static asset paths (`.js`, `.wasm`, `.json`, `.png`, `.ttf`, `.otf`) are served with correct `Content-Type` headers. This avoids needing a separate tower-http `ServeDir`.

### Manual Router for Flutter
**Chosen: No router package in this scaffold.** The app has a single page (gradient background). Routing will be added in a follow-up change when multiple pages exist.

### CI Strategy
**Chosen: Single `build.yml` workflow. Flutter web builds in the same job chain as Rust.** The `build-frontend` job runs `flutter build web --release` and uploads the output as a pipeline artifact. The `release` job builds the Rust binary with the web output embedded. Separate `build-frontend-ios.yml` on macOS runner triggered by `frontend-v*` tags.

### AGENTS.md Strategy
**Three files:** Root `AGENTS.md` maps sub-projects. `frontend/AGENTS.md` says this is a Flutter skeleton, no state management or components yet, just `flutter create` + gradient page. `crates/trailhead-service/AGENTS.md` documents Rust conventions, cargo workspace, and the embed pipeline.

## Risks / Trade-offs

- **Flutter SDK unavailable on dev machine** → Mitigation: `build.rs` gracefully skips embedding, prints warning. `serve_spa()` returns a text message. Dev can still `cargo run` the backend without the frontend.
- **`build.rs` triggers Rust rebuild on frontend changes** → Acceptable. Frontend and backend are committed together in one repo.
- **iOS build requires macOS** → Mitigation: iOS CI job on `macos-latest` runner. Local iOS dev requires a Mac. Web dev works on Linux.
- **`rust-embed` includes all Flutter web assets (~2MB)** → Mitigation: use `#[folder]` path, Flutter's `--release` flag, and gzip on the axum layer if needed later.
