#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pin_file="${repo_root}/.terrain3d-version"
checksum_file="${repo_root}/tool/terrain3d_checksums.txt"
addon_directory="${repo_root}/clients/aonw_godot/addons/terrain_3d"
project_file="${repo_root}/clients/aonw_godot/project.godot"
compatibility_patch="${repo_root}/tool/patches/terrain3d-1.0.2-headless-display-scale.patch"
compatibility_patch_id="terrain3d-1.0.2-headless-display-scale-v1"

if [[ ! -f "${pin_file}" || ! -f "${checksum_file}" || ! -f "${compatibility_patch}" ]]; then
  echo "Terrain3D pin, checksum manifest, or compatibility patch is missing." >&2
  exit 1
fi

pinned_version="$(<"${pin_file}")"
if [[ ! "${pinned_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo ".terrain3d-version must contain one exact stable version." >&2
  exit 1
fi
release_tag="v${pinned_version}-stable"
archive_name="Terrain3D_${release_tag}.zip"
expected_checksum="$(awk -v archive="${archive_name}" '$2 == archive { print $1 }' "${checksum_file}")"
if [[ ! "${expected_checksum}" =~ ^[[:xdigit:]]{64}$ ]]; then
  echo "Missing SHA-256 for ${archive_name} in ${checksum_file}." >&2
  exit 1
fi
download_url="https://github.com/TokisanGames/Terrain3D/releases/download/${release_tag}/${archive_name}"
expected_marker="version=${pinned_version}
archive=${archive_name}
sha256=${expected_checksum}
source=${download_url}
license=MIT
patch=${compatibility_patch_id}"

for required_file in plugin.cfg terrain.gdextension LICENSE.txt .aonw-install; do
  if [[ ! -f "${addon_directory}/${required_file}" ]]; then
    echo "Terrain3D ${pinned_version} is not bootstrapped. Run make bootstrap." >&2
    exit 1
  fi
done

plugin_version="$(sed -n 's/^version="\([^"]*\)"/\1/p' "${addon_directory}/plugin.cfg")"
if [[ "${plugin_version}" != "${pinned_version}" ]]; then
  echo "Terrain3D version mismatch: expected ${pinned_version}, found ${plugin_version:-unknown}. Run make bootstrap." >&2
  exit 1
fi
if [[ "$(<"${addon_directory}/.aonw-install")" != "${expected_marker}" ]]; then
  echo "Terrain3D source or checksum does not match the pin. Run make bootstrap." >&2
  exit 1
fi
if ! grep -Fq "MIT License" "${addon_directory}/LICENSE.txt"; then
  echo "Terrain3D license does not match the reviewed MIT release. Run make bootstrap." >&2
  exit 1
fi
if ! grep -Fq 'if es.has_setting("interface/editor/display_scale"):' \
  "${addon_directory}/src/double_slider.gd"; then
  echo "Terrain3D headless display-scale compatibility patch is missing. Run make bootstrap." >&2
  exit 1
fi
if ! grep -Fq '"res://addons/terrain_3d/plugin.cfg"' "${project_file}"; then
  echo "Terrain3D must be enabled in ${project_file}." >&2
  exit 1
fi

echo "Terrain3D dependency OK: ${pinned_version}."
