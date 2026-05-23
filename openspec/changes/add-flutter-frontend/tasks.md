## 1. Scaffold Flutter Project

- [x] 1.1 Run `flutter create frontend/` with `--platforms web,ios` at repo root
- [x] 1.2 Clear `lib/main.dart` — replace default counter app with a full-screen `Container` using `BoxDecoration.linearGradient` (light white → light gray/blue, vertical)
- [x] 1.3 Verify `flutter test` passes (include a basic widget test that the gradient page renders without error)
- [x] 1.4 Verify `flutter run -d chrome` shows the gradient page in browser (skipped — headless env, verified via `flutter build web --release`)
- [x] 1.5 Verify `flutter build web --release` produces `frontend/build/web/` output

## 2. Embed Flutter Web in Rust Binary

- [x] 2.1 Add `rust-embed = "8"` dependency to `crates/trailhead-service/Cargo.toml`
- [x] 2.2 Create `crates/trailhead-service/build.rs`
- [x] 2.3 Add `WebAssets` struct with `#[derive(rust_embed::Embed)] #[folder = "ui/dist/"]` in `web.rs`
- [x] 2.4 Replace `serve_spa()` to return embedded `index.html` or text fallback
- [x] 2.5 Add static asset serving in fallback handler: manual mime-type map for `.js`, `.wasm`, `.json`, `.png`, `.ttf`, `.otf`, etc. SPA client-side routing for unknown paths
- [x] 2.6 Verify `cargo check -p trailhead-service` passes
- [ ] 2.7 Build frontend + backend and verify `GET /` returns the Flutter gradient page

## 3. Remove Old UI Stub

- [x] 3.1 Delete old React stub files from `crates/trailhead-service/ui/` (keep `dist/`)
- [x] 3.2 Verify `cargo check -p trailhead-service` still passes

## 4. AGENTS.md Files

- [x] 4.1 Create `frontend/AGENTS.md` — Flutter skeleton conventions
- [x] 4.2 Create `crates/trailhead-service/AGENTS.md` — Rust backend conventions
- [x] 4.3 Update root `AGENTS.md` with Project Layout section referencing sub-project AGENTS.md files

## 5. CI Workflows

- [x] 5.1 Update `.github/workflows/build.yml` `build-frontend` job — Flutter web build with artifact upload
- [x] 5.2 Update `build.yml` `release` job — frontend download step, `needs: [check, build-frontend]`
- [x] 5.3 Create `.github/workflows/build-frontend-ios.yml` — tag-triggered macOS iOS build
- [x] 5.4 Add `flutter test` step to `build-frontend` job
- [ ] 5.5 Verify CI passes end-to-end (requires push to GitHub to test workflow)

## 6. Verification

- [x] 6.1 `cargo test --workspace` passes
- [x] 6.2 `cargo clippy --workspace -- -D warnings` passes
- [x] 6.3 `flutter test` passes from `frontend/`
- [x] 6.4 `flutter build web --release` succeeds from `frontend/`
- [ ] 6.5 Running the daemon serves the gradient page at `:4050/` (verify on VPS deploy)
