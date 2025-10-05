#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

if [[ -z "${GODOT_BIN:-}" ]]; then
  for candidate in godot4 /snap/bin/godot4 godot; do
    if command -v "$candidate" >/dev/null 2>&1; then
      GODOT_BIN="$candidate"
      break
    fi
  done
fi

if [[ -z "${GODOT_BIN:-}" ]]; then
  echo "Error: could not find a Godot binary (tried godot4, /snap/bin/godot4, godot)." >&2
  echo "Set GODOT_BIN to the desired executable." >&2
  exit 127
fi

"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --check-only
