# iOS Build & Test Guide

Recipe for building, running, and testing the Trailhead Flutter frontend on iOS
(simulator + physical device). Requires a Mac with Xcode. Not buildable from the
Linux sandbox container.

## Prerequisites (Mac)

```bash
xcode-select --install                       # Xcode 15+ via App Store
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license accept

brew install --cask flutter                  # or download from flutter.dev
flutter doctor -v
```

`flutter doctor` must show ✓ on: Flutter, **Xcode**, **CocoaPods**.
If CocoaPods missing: `sudo gem install cocoapods`.

## One-time repo setup

```bash
git clone <repo-url> ~/projects/CoderyTrailhead
cd ~/projects/CoderyTrailhead/frontend
flutter pub get
```

## Code signing

```bash
open ios/Runner.xcworkspace
```

In Xcode → **Runner** target → **Signing & Capabilities**:

| Field | Value |
|-------|-------|
| Team | Your Apple Developer team ($99 account) |
| Bundle Identifier | Change `com.example.frontend` → e.g. `com.codery.trailhead` |
| Automatically manage signing | ✓ |

> **Placeholder bundle id**: project ships as `com.example.frontend`. Change it
> in Xcode Signing & Capabilities before any device install — Xcode writes all
> 3 spots in `project.pbxproj` (Debug/Release/Profile). Don't hand-edit pbxproj
> unless you know the format.

Green checkmark = ready.

## Simulator dev loop

```bash
flutter devices                              # list iOS simulators
flutter run -d "iPhone 15 Pro"               # hot reload loop
```

Console keys: `r` hot reload · `R` hot restart · `q` quit · `p` layout grids.

Headless sim: `open -a Simulator && flutter run`.

## Physical device dev loop

1. Plug iPhone/iPad into Mac via USB
   (or set up Wi-Fi debugging in Xcode → Window → Devices & Simulators)
2. **Trust the computer** on device (prompt appears on first connect)
3. Trust the dev cert on device:
   **Settings → General → VPN & Device Management → tap Developer App → Trust**
4. Run:

```bash
flutter devices                              # confirm device listed
flutter run -d <device-id>                   # device-id from `flutter devices`
```

First cold launch: ~60-90s (codesign + install). Subsequent `r` reloads: ~1-2s.

> Paid $99 account = no 7-day signing expiry. Not an issue for distribution.

## Release builds

### Unsigned smoke (CI / build check)

```bash
flutter build ios --release --no-codesign
# Output: build/ios/iphoneos/Runner.app
```

Verifies release-mode compile without provisioning.

### Signed IPA + TestFlight

```bash
flutter build ipa                            # build/ios/ipa/Runner.ipa
```

Upload via Xcode:
1. `open ios/Runner.xcworkspace`
2. **Product → Archive** (must target a physical device scheme)
3. **Window → Organizer** → select archive → **Distribute App → App Store Connect**
4. App Store Connect → My Apps → TestFlight → add testers

CLI upload:
```bash
xcrun altool --upload-app --type ios \
  -f build/ios/ipa/Runner.ipa \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
```

## Tests

### Dart unit + widget tests

```bash
flutter test                                 # all tests
flutter test test/widget_test.dart           # single file
flutter test --coverage                      # coverage/lcov.info
```

### iOS native tests (XCUITest scaffold exists in `RunnerTests/`)

```bash
xcodebuild test \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Profiling / DevTools

```bash
flutter run --profile -d <device-id>         # near-release perf + devtools
flutter attach -d <device-id>                # attach to running app
```

Press `d` in console to open DevTools, or:
```bash
flutter pub global activate devtools
dart devtools
```

Panels: **Performance** (jank), **Memory** (leaks), **Network**, **Widget Inspector**.

## Common issues

| Symptom | Fix |
|---------|-----|
| `Cocoapods not installed` | `sudo gem install cocoapods` |
| `xcodebuild: error: SDK not found` | `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` |
| `Provisioning profile doesn't include device` | Re-plug USB, re-trust, refresh Xcode signing |
| `Unable to locate a development device` | Check `flutter doctor`; `xcrun simctl shutdown all` |
| Podfile out of date | `cd ios && pod install --repo-update` |
| Bundle ID collision | Change in Xcode Signing & Capabilities (writes 3 spots in pbxproj) |
| App crashes on launch (device) | Re-trust dev cert in Settings → VPN & Device Management |

## Syncing with the Linux sandbox

The Codery sandbox is Linux — **cannot build iOS here**. Recommended flow:

1. Iterate on Mac locally with simulator/device
2. Commit + push changes to `frontend/`
3. Sandbox picks up changes → run `~/flutter/bin/flutter build web --release`
   to refresh trailhead-dev preview
4. Backend Rust embed picks up web build on next `cargo build`

Keep iOS-specific config (`ios/`, Podfile changes) in git but don't try to build
it from the Linux container.
