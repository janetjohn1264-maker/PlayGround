#!/usr/bin/env bash
# Capture desktop and mobile screenshots of the running preview.
# Requires CAPTURE_URL (the preview URL to open) and CAPTURE_DIR (output directory).
# Exits 75 for temporary navigation/browser infrastructure failures and 1 for
# script or rendering defects. Screenshots go to CAPTURE_DIR; the app is untouched.
set -euo pipefail

run() { /usr/bin/time -p "$@"; }

cd "$(dirname "$0")"

: "${CAPTURE_DIR:?Set CAPTURE_DIR for screenshot output.}"
: "${CAPTURE_URL:?Set CAPTURE_URL to the preview URL.}"
mkdir -p "$CAPTURE_DIR"

run node "${RUNTIME_DIR:?}/scripts/default-capture.mjs"
