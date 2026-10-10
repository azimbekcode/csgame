#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
engine="${GODOT_BIN:-godot}"
log_path=$(mktemp)
trap 'rm -f "$log_path"' EXIT
for target in tests/game_smoke.gd tests/bot_match.gd tests/stair_gait.gd; do
  test_status=0
  "$engine" --headless --path . --script "res://$target" > "$log_path" 2>&1 || test_status=$?
  cat "$log_path"
  if [ "$test_status" -ne 0 ]; then exit "$test_status"; fi
  if rg -n 'SCRIPT ERROR:|ERROR:|Parse Error' "$log_path"; then exit 1; fi
done
