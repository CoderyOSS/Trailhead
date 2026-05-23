## ADDED Requirements

### Requirement: SPA placeholder replaced with embedded Flutter app
The `serve_spa()` handler in `web.rs` SHALL serve the embedded Flutter web app instead of returning `404 Not Found`.

#### Scenario: Root path returns SPA
- **WHEN** the Trailhead daemon starts with an embedded frontend
- **THEN** `GET /` SHALL return the Flutter `index.html` with HTTP 200

#### Scenario: No frontend embedded returns a graceful message
- **WHEN** the Rust binary was compiled without embedded frontend assets
- **THEN** `GET /` SHALL return plain text: "Frontend not embedded. Build with Flutter SDK to include the UI."

### Requirement: Static assets for Flutter web are served correctly
The axum server SHALL serve Flutter web build static assets (`.js`, `.wasm`, `.png`, `.json`, `.ttf`, `.otf`) from the embedded files with correct `Content-Type` headers.

#### Scenario: main.dart.js is served
- **WHEN** browser requests `GET /main.dart.js`
- **THEN** the response SHALL have `content-type: application/javascript`

#### Scenario: Unknown static path returns 404
- **WHEN** browser requests `GET /nonexistent.xyz`
- **THEN** the response SHALL be HTTP 404

### Requirement: Old React UI stub is removed
The empty `crates/trailhead-service/ui/` directory SHALL be deleted. The `build.yml` `build-frontend` job SHALL run Flutter instead of npm.
