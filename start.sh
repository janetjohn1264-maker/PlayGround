#!/usr/bin/env bash
# Serve this project's static site in the foreground on $PORT (default 3000).
# Source and built output stay inside PROJECT_DIR; OPENCODE_WEB_DIR/RUNNER_TEMP
# are used only for worker metadata such as deployment-output.json.
set -euo pipefail

run() { /usr/bin/time -p "$@"; }

cd "$(dirname "$0")"
PROJECT_DIR="$(pwd)"
PORT="${PORT:-3000}"
export PORT

# Worker metadata location (never inside the served source tree).
METADATA_DIR="${OPENCODE_WEB_DIR:-${RUNNER_TEMP:-/tmp}/omgithub-web}"

STATIC_DIR="$PROJECT_DIR/dist"
if [[ -f "$PROJECT_DIR/package.json" ]]; then
  if [[ -f "$PROJECT_DIR/package-lock.json" ]]; then
    run npm ci --no-audit --no-fund
  else
    run npm install --no-audit --no-fund
  fi
  if run npm run build; then
    :
  else
    # Keep the app servable even when the package has no build step.
    STATIC_DIR="$PROJECT_DIR"
  fi
else
  # Plain static project: serve the project root itself.
  STATIC_DIR="$PROJECT_DIR"
fi

if [[ ! -f "$STATIC_DIR/index.html" ]]; then
  echo "start.sh: no servable index.html under $STATIC_DIR (build one or add a static index.html)." >&2
  exit 1
fi

# Publish the deployment metadata for the controller.
run node -e '
const fs = require("node:fs");
fs.writeFileSync(process.argv[1], JSON.stringify({
  project: process.argv[2],
  directory: process.argv[3],
}));
' "$METADATA_DIR/deployment-output.json" "$PROJECT_DIR" "$STATIC_DIR"

# Run the server in the foreground of this session.
if [[ -n "${RUNTIME_DIR:-}" && -f "$RUNTIME_DIR/scripts/default-start.mjs" ]]; then
  exec /usr/bin/time -p node "$RUNTIME_DIR/scripts/default-start.mjs"
else
  exec /usr/bin/time -p python3 -m http.server "$PORT" --bind 0.0.0.0 --directory "$STATIC_DIR"
fi
