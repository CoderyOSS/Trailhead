## ADDED Requirements

### Requirement: Flutter SPA is served from Trailhead binary
The system SHALL serve a Flutter single-page application at the root path (`GET /`) of the Trailhead service. The SPA SHALL be embedded in the Rust binary at compile time via `rust-embed`.

#### Scenario: Root path returns Flutter SPA
- **WHEN** a browser requests `GET /` on the Trailhead service port
- **THEN** the response SHALL be `text/html` containing the Flutter web app's `index.html`

#### Scenario: SPA routes are handled client-side
- **WHEN** a browser requests any path without a matching API or static asset route
- **THEN** the server SHALL return the SPA `index.html` to allow client-side routing

#### Scenario: API routes are not shadowed
- **WHEN** a browser requests `GET /api/v1/jobs`
- **THEN** the server SHALL return the JSON job list, NOT the SPA index.html

### Requirement: Flutter app displays a blank gradient page
The Flutter app SHALL render a full-screen page with a light gradient background using only the default Flutter SDK (no third-party packages).

#### Scenario: App shows gradient background
- **WHEN** the Flutter web app loads in a browser
- **THEN** the viewport SHALL be filled with a light vertical gradient (e.g., white to light blue/gray)

### Requirement: AGENTS.md guides AI agents
The `frontend/AGENTS.md` file SHALL document that this is a Flutter skeleton with no state management, no components, and no routing beyond a single gradient page. The `crates/trailhead-service/AGENTS.md` file SHALL document the Rust conventions and the embed pipeline.

#### Scenario: AI agent reads frontend AGENTS.md
- **WHEN** an AI agent is tasked to work on the frontend
- **THEN** the agent SHALL find instructions for `flutter run -d chrome`, `flutter build web`, `flutter test`, and the note that this is a scaffold with no state management yet
