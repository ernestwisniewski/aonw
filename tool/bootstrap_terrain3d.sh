#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pin_file="${repo_root}/.terrain3d-version"
checksum_file="${repo_root}/tool/terrain3d_checksums.txt"
addon_directory="${repo_root}/clients/aonw_godot/addons/terrain_3d"
compatibility_patch="${repo_root}/tool/patches/terrain3d-1.0.2-headless-display-scale.patch"
compatibility_patch_id="terrain3d-1.0.2-headless-display-scale"

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
install_marker="${addon_directory}/.aonw-install"
expected_marker="version=${pinned_version}
archive=${archive_name}
sha256=${expected_checksum}
source=${download_url}
license=MIT
patch=${compatibility_patch_id}"
installed_plugin_version=""
if [[ -f "${addon_directory}/plugin.cfg" ]]; then
  installed_plugin_version="$(sed -n 's/^version="\([^"]*\)"/\1/p' "${addon_directory}/plugin.cfg")"
fi

if [[ -f "${install_marker}" ]] \
  && [[ "$(<"${install_marker}")" == "${expected_marker}" ]] \
  && [[ "${installed_plugin_version}" == "${pinned_version}" ]] \
  && [[ -f "${addon_directory}/plugin.cfg" ]] \
  && [[ -f "${addon_directory}/terrain.gdextension" ]] \
  && [[ -f "${addon_directory}/LICENSE.txt" ]]; then
  echo "Terrain3D bootstrap ready: ${addon_directory}"
  exit 0
fi

for command_name in curl patch unzip; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "${command_name} is required to bootstrap Terrain3D." >&2
    exit 1
  fi
done

work_parent="${repo_root}/.toolchains/terrain3d"
mkdir -p "${work_parent}"
temporary_directory="$(mktemp -d "${work_parent}/install.XXXXXX")"
trap 'rm -rf -- "${temporary_directory}"' EXIT
archive_path="${temporary_directory}/${archive_name}"
extract_directory="${temporary_directory}/extracted"

echo "Downloading Terrain3D ${pinned_version}..."
curl --fail --location --retry 3 --silent --show-error \
  --output "${archive_path}" \
  "${download_url}"

if command -v sha256sum >/dev/null 2>&1; then
  actual_checksum="$(sha256sum "${archive_path}" | awk '{ print $1 }')"
elif command -v shasum >/dev/null 2>&1; then
  actual_checksum="$(shasum -a 256 "${archive_path}" | awk '{ print $1 }')"
else
  echo "sha256sum or shasum is required to verify Terrain3D." >&2
  exit 1
fi
if [[ "${actual_checksum}" != "${expected_checksum}" ]]; then
  echo "Terrain3D archive checksum mismatch for ${archive_name}." >&2
  exit 1
fi

mkdir -p "${extract_directory}"
unzip -q "${archive_path}" -d "${extract_directory}"
extracted_addon="${extract_directory}/addons/terrain_3d"
if [[ ! -f "${extracted_addon}/plugin.cfg" ]] \
  || [[ ! -f "${extracted_addon}/terrain.gdextension" ]] \
  || [[ ! -f "${extracted_addon}/LICENSE.txt" ]]; then
  echo "Terrain3D archive does not contain the expected addon." >&2
  exit 1
fi

plugin_version="$(sed -n 's/^version="\([^"]*\)"/\1/p' "${extracted_addon}/plugin.cfg")"
if [[ "${plugin_version}" != "${pinned_version}" ]]; then
  echo "Terrain3D plugin version mismatch: expected ${pinned_version}, found ${plugin_version:-unknown}." >&2
  exit 1
fi

patch --batch --forward --directory="${extracted_addon}" --strip=1 \
  --input="${compatibility_patch}"

printf '%s\n' "${expected_marker}" > "${extracted_addon}/.aonw-install"

if [[ -e "${addon_directory}" ]]; then
  backup_parent="${repo_root}/.toolchains/terrain3d-backups"
  backup_directory="${backup_parent}/$(date -u +%Y%m%dT%H%M%SZ)-terrain_3d"
  if [[ -e "${backup_directory}" ]]; then
    backup_directory="${backup_directory}-$$"
  fi
  mkdir -p "${backup_parent}"
  mv "${addon_directory}" "${backup_directory}"
  echo "Moved unverified Terrain3D addon to ${backup_directory}."
fi

mkdir -p "$(dirname "${addon_directory}")"
mv "${extracted_addon}" "${addon_directory}"
echo "Terrain3D bootstrap ready: ${addon_directory}"
