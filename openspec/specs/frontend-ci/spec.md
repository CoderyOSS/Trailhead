## ADDED Requirements

### Requirement: Flutter web build runs in CI on ubuntu-latest
The CI pipeline SHALL build the Flutter web frontend on every push to main using `flutter build web --release`.

#### Scenario: Flutter web build succeeds
- **WHEN** code is pushed to main or a PR targets main
- **THEN** `flutter build web --release` SHALL run from `frontend/` and produce `build/web/` output without errors

#### Scenario: Web output is available to Rust build
- **WHEN** the Flutter web build completes successfully
- **THEN** the `build/web/` directory SHALL be available as a pipeline artifact for the Rust `release` job to embed

### Requirement: Flutter iOS build runs in CI on macos-latest
A CI pipeline SHALL build the Flutter iOS app on macOS runners when a `frontend-v*` tag is pushed.

#### Scenario: iOS build runs on tag push
- **WHEN** a tag matching `frontend-v*` is pushed
- **THEN** `flutter build ios --release --no-codesign` SHALL run on `macos-latest` and produce an `.app` bundle

#### Scenario: iOS build is published as a release artifact
- **WHEN** the iOS build completes
- **THEN** the `.ipa` or `.app` SHALL be uploaded as a GitHub Release artifact on the tag

### Requirement: Flutter tests run in CI
The CI pipeline SHALL run `flutter test` to verify the Dart test suite passes.

#### Scenario: Flutter tests pass
- **WHEN** the CI pipeline runs `flutter test`
- **THEN** all tests SHALL pass. Any failure SHALL block the build.
