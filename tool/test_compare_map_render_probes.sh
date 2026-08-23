#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_directory="$(mktemp -d)"
trap 'rm -rf "${fixture_directory}"' EXIT

scenario="${fixture_directory}/scenario.json"
left="${fixture_directory}/flutter.json"
right="${fixture_directory}/godot.json"
output="${fixture_directory}/output.log"

printf '%s\n' '{"floatTolerance":0.000001,"cases":[]}' >"${scenario}"
printf '%s\n' '{"maps":[],"point":[1.0,2]}' >"${left}"
printf '%s\n' '{"maps":[],"point":[1.0000005,2]}' >"${right}"
dart "${repo_root}/tool/compare_map_render_probes.dart" \
  "${left}" "${right}" "${scenario}" >/dev/null

printf '%s\n' '{"maps":[],"point":[1.01,3]}' >"${right}"
if dart "${repo_root}/tool/compare_map_render_probes.dart" \
  "${left}" "${right}" "${scenario}" >"${output}" 2>&1; then
  echo "expected semantic probe mismatch" >&2
  exit 1
fi

grep -Fq '$.point[0]: Flutter=1.0, Godot=1.01' "${output}"
grep -Fq '$.point[1]: Flutter=2, Godot=3' "${output}"
printf '%s\n' 'map render probe comparator: OK'
