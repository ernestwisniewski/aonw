#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
content_root="${repo_root}/content/maps"
output_parent="${repo_root}/clients/aonw_godot/.godot"
output_root="${output_parent}/terrain_compiled"

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
generated_profile_count=0
for map_path in "${content_root}"/*/map.json; do
  [[ -f "${map_path}" ]] || continue
  map_directory="$(dirname "${map_path}")"
  map_id="$(basename "${map_directory}")"
  profile_path="${map_directory}/terrain_authoring.v1.json"
  if [[ ! -f "${profile_path}" ]]; then
    profile_path="${staging_root}/${map_id}/terrain_authoring.generated.v1.json"
    cargo run \
      --locked \
      --quiet \
      --manifest-path "${repo_root}/engine/Cargo.toml" \
      -p aonw_map_compiler_cli \
      --bin aonw-map-profile \
      -- \
      "${map_path}" \
      "${profile_path}" \
      10
    generated_profile_count=$((generated_profile_count + 1))
  fi
  cargo run \
    --locked \
    --quiet \
    --manifest-path "${repo_root}/engine/Cargo.toml" \
    -p aonw_map_compiler_cli \
    --bin aonw-map-compiler \
    -- \
    "${map_path}" \
    "${profile_path}" \
    "${staging_root}/${map_id}" \
    10
  map_count=$((map_count + 1))
done

if [[ ${map_count} -eq 0 ]]; then
  echo "No map.json documents found under ${content_root}." >&2
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

echo "Compiled Terrain3D authoring data for ${map_count} map(s); generated ${generated_profile_count} standard profile(s)."
