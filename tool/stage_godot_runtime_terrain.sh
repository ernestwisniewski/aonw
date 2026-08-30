#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_root="${repo_root}/clients/aonw_godot"
source_root="${godot_root}/.godot/terrain_compiled"
map_root="${godot_root}/assets/maps"
output_root="${godot_root}/assets/terrain_compiled"
output_parent="$(dirname "${output_root}")"

if [[ ! -d "${source_root}" ]]; then
  echo "Compiled Godot terrain is missing: ${source_root}" >&2
  exit 1
fi

mkdir -p "${output_parent}"
staging_root="$(mktemp -d "${output_parent}/terrain_compiled.staging.XXXXXX")"
previous_root="${output_parent}/terrain_compiled.previous.$$"
cleanup() {
  if [[ -n "${staging_root}" && -d "${staging_root}" ]]; then
    rm -rf -- "${staging_root}"
  fi
  if [[ -n "${previous_root}" && -d "${previous_root}" ]]; then
    rm -rf -- "${previous_root}"
  fi
}
trap cleanup EXIT

map_count=0
for map_path in "${map_root}"/*/map.json; do
  [[ -f "${map_path}" ]] || continue
  map_id="$(basename "$(dirname "${map_path}")")"
  source_directory="${source_root}/${map_id}"
  destination_directory="${staging_root}/${map_id}"
  if [[ ! -f "${source_directory}/terrain_compile.json" ]]; then
    echo "Compiled terrain manifest is missing for packaged map ${map_id}." >&2
    exit 1
  fi
  mkdir -p "${destination_directory}"
  cp "${source_directory}/terrain_compile.json" "${destination_directory}/"
  for layer in base min max; do
    if [[ ! -f "${source_directory}/${layer}.exr" ]]; then
      echo "Compiled terrain ${layer}.exr is missing for packaged map ${map_id}." >&2
      exit 1
    fi
    cp "${source_directory}/${layer}.exr" "${destination_directory}/"
  done
  map_count=$((map_count + 1))
done

if [[ ${map_count} -eq 0 ]]; then
  echo "No packaged Godot maps found under ${map_root}." >&2
  exit 1
fi

if [[ -d "${output_root}" ]]; then
  mv "${output_root}" "${previous_root}"
fi
if ! mv "${staging_root}" "${output_root}"; then
  if [[ -d "${previous_root}" ]]; then
    mv "${previous_root}" "${output_root}"
  fi
  exit 1
fi
staging_root=""
rm -rf -- "${previous_root}"
previous_root=""
trap - EXIT

echo "Staged runtime terrain for ${map_count} packaged map(s)."
