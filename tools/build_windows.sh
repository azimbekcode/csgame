#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
engine="${GODOT_BIN:-godot}"
mkdir -p build/windows
log_path=$(mktemp)
trap 'rm -f "$log_path"' EXIT
run_engine() {
  run_status=0
  "$engine" --headless --path . "$@" > "$log_path" 2>&1 || run_status=$?
  cat "$log_path"
  if [ "$run_status" -ne 0 ]; then exit "$run_status"; fi
  if rg -n 'SCRIPT ERROR:|ERROR:|Parse Error' "$log_path"; then exit 1; fi
}
run_engine --editor --import
run_engine --export-release 'Windows Desktop' build/windows/AtriumStrike.exe
python3 tools/package_windows.py
