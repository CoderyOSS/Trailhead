#!/usr/bin/env bash
set -euo pipefail

# Build the Trailhead Flutter frontend and Rust service binary.
# The Flutter web output is embedded into the Rust binary by build.rs.
#
# This script detects whether it is running on the apps container (where
# Flutter and Rust are installed). If run from the sandbox or another context,
# it re-invokes itself over ssh on the apps container.
#
# After a successful build, it prints the commands to run on the host to
# install the new binary and restart the service.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(grep '^version = ' "$REPO_ROOT/crates/trailhead-service/Cargo.toml" | head -1 | sed 's/version = "//;s/"//')"

# The host may mount the repo at a different path than inside the containers.
# Override with: HOST_REPO_ROOT=/home/ubuntu/projects/CoderyTrailhead ./scripts/build-trailhead.sh
HOST_REPO_ROOT="${HOST_REPO_ROOT:-$REPO_ROOT}"

FLUTTER_BIN="/home/gem/flutter/bin/flutter"
CARGO_BIN="$HOME/.cargo/bin/cargo"

run_build() {
  echo "==> Building Flutter web release..."
  cd "$REPO_ROOT/frontend"
  "$FLUTTER_BIN" build web --release

  echo "==> Building trailhead-service release binary..."
  cd "$REPO_ROOT"
  "$CARGO_BIN" build --release -p trailhead-service

  # Copy release artifacts to a host-visible directory. The container's
  # target/ directory may not be exposed on the host bind mount.
  DEPLOY_DIR="$REPO_ROOT/deploy"
  rm -rf "$DEPLOY_DIR"
  mkdir -p "$DEPLOY_DIR/skills"
  cp "$REPO_ROOT/target/release/trailhead-service" "$DEPLOY_DIR/trailhead-service"
  cp "$REPO_ROOT/crates/trailhead-service/skills/"*.md "$DEPLOY_DIR/skills/"

  echo ""
  echo "Build complete: $DEPLOY_DIR/trailhead-service"
  echo ""
  echo "Run these commands on the host to deploy and restart Trailhead:"
  echo ""
  echo "VERSION=$VERSION"
  echo "sudo cp \"$HOST_REPO_ROOT/deploy/trailhead-service\" \"/opt/codery/trailhead/bin/trailhead-service-\${VERSION}\""
  echo "sudo chmod +x \"/opt/codery/trailhead/bin/trailhead-service-\${VERSION}\""
  echo "sudo ln -sf \"/opt/codery/trailhead/bin/trailhead-service-\${VERSION}\" /opt/codery/trailhead/bin/current"
  echo "sudo cp \"$HOST_REPO_ROOT/deploy/skills/\"*.md /opt/codery/trailhead/skills/"
  echo "sudo supervisorctl -c /etc/supervisor/supervisord.conf restart trailhead"
  echo ""
}

if [[ -f "$FLUTTER_BIN" && -f "$CARGO_BIN" ]]; then
  run_build
else
  echo "Toolchains not found locally; running build on apps container via ssh..."
  ssh gem@apps "cd '$REPO_ROOT' && bash scripts/build-trailhead.sh"
fi
