#!/bin/sh

set -eu

log_path=${1:?Godot log path is required}
success_marker=${2:-}
error_report=$(mktemp /tmp/aonw-godot-log-errors.XXXXXX)
trap 'rm -f "$error_report"' EXIT HUP INT TERM

if [ ! -f "$log_path" ]; then
  echo "Godot log was not created: $log_path" >&2
  exit 1
fi

if awk '
  /SCRIPT ERROR|(^|[[:space:]])ERROR:|AoNW Map Workbench:/ {
    if ($0 !~ /ERROR: Condition "ret != noErr" is true\. Returning: ""/) {
      print
      found = 1
    }
  }
  END { exit found ? 0 : 1 }
' "$log_path" >"$error_report"; then
  echo "Godot reported an error in $log_path:" >&2
  cat "$error_report" >&2
  exit 1
fi

if [ -n "$success_marker" ] && ! grep -F "$success_marker" "$log_path" >/dev/null; then
  echo "Godot success marker not found in $log_path: $success_marker" >&2
  exit 1
fi
