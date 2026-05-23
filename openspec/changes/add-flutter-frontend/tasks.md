## 1. Scaffold Flutter Project

- [ ] 1.1 Run `flutter create frontend/` with `--platforms web,ios` at repo root
- [ ] 1.2 Clear `lib/main.dart` — replace default counter app with a full-screen `Container` using `BoxDecoration.linearGradient` (light white → light gray/blue, vertical)
- [ ] 1.3 Verify `flutter test` passes (include a basic widget test that the gradient page renders without error)
- [ ] 1.4 Verify `flutter run -d chrome` shows the gradient page in browser
- [ ] 1.5 Verify `flutter build web --release` produces `frontend/build/web/` output

## 2. Embed Flutter Web in Rust Binary

- [ ] 2.1 Add `rust-embed = "8"` dependency to `crates/trailhead-service/Cargo.toml`
- [ ] 2.2 Create `crates/trailhead-service/build.rs`:
  - If `frontend/build/web/` exists, copy it to `crates/trailhead-service/ui/dist/`
  - Print `cargo:rerun-if-changed=ui/dist/`
  - If source absent, print `cargo:warning=frontend build not found, skip embedding` (not a hard error)
- [ ] 2.3 Add `#[derive(rust_embed::Embed)] #[folder = "ui/dist/"] struct WebAssets;` in `web.rs`
- [ ] 2.4 Replace `serve_spa()` to return `Html(WebAssets::get("index.html").unwrap_or_default().data)` or a text fallback
- [ ] 2.5 Add axum route for `GET /*path` fallback that:
  - Checks `WebAssets::get(path)` — if found, serves with correct content-type via a `mime_guess` or manual map (`.js` → `application/javascript`, `.wasm` → `application/wasm`, `.json` → `application/json`, `.png` → `image/png`, `.ttf`/`.otf` → `font/*`)
  - If not found, returns the SPA `index.html` for HTML5 history mode
- [ ] 2.6 Verify `cargo check -p trailhead-service` passes
- [ ] 2.7 Build frontend + backend and verify `GET /` returns the Flutter gradient page

## 3. Remove Old UI Stub

- [ ] 3.1 Delete `crates/trailhead-service/ui/` directory (if it exists)
- [ ] 3.2 Verify `cargo check -p trailhead-service` still passes

## 4. AGENTS.md Files

- [ ] 4.1 Create `frontend/AGENTS.md`:
  - Flutter skeleton — no state management, no components, no routing yet
  - Build: `flutter run -d chrome`, `flutter build web --release`, `flutter test`
  - When adding new UI, add Flutter dependencies to `pubspec.yaml` first
  - Code style: standard `flutter_lints`, no third-party lints yet
- [ ] 4.2 Verify `crates/trailhead-service/AGENTS.md` exists and documents Rust conventions (cargo workspace, `db.rs` patterns, migration pattern, test commands)
- [ ] 4.3 Verify root `AGENTS.md` has entries pointing to sub-project AGENTS.md files

## 5. CI Workflows

- [ ] 5.1 Update `.github/workflows/build.yml` `build-frontend` job:
  - Replace npm/node setup with `subosito/flutter-action@v2` (stable channel)
  - Run `cd frontend && flutter build web --release`
  - Upload `frontend/build/web/` as pipeline artifact for the `release` job
- [ ] 5.2 In `build.yml` `release` job: download `frontend-web` artifact, place it at `crates/trailhead-service/ui/dist/` before `cargo build`
- [ ] 5.3 Create `.github/workflows/build-frontend-ios.yml`:
  - Trigger: push of tag matching `frontend-v*`
  - Runner: `macos-latest`
  - Steps: `subosito/flutter-action@v2`, `cd frontend && flutter build ios --release --no-codesign`
  - Upload `frontend/build/ios/iphoneos/*.app` as release artifact
- [ ] 5.4 Add `cd frontend && flutter test` step to `build-frontend` job
- [ ] 5.5 Verify CI passes end-to-end: check job → test job → frontend job → release job

## 6. Verification

- [ ] 6.1 `cargo test --workspace` passes
- [ ] 6.2 `cargo clippy --workspace -- -D warnings` passes
- [ ] 6.3 `flutter test` passes from `frontend/`
- [ ] 6.4 `flutter build web --release` succeeds from `frontend/`
- [ ] 6.5 Running the daemon serves the gradient page at `:4050/`
