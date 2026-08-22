#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pin_file="${repo_root}/.godot-version"
checksum_file="${repo_root}/tool/godot_checksums.txt"

if [[ ! -f "${pin_file}" || ! -f "${checksum_file}" ]]; then
  echo "Godot pin or checksum manifest is missing." >&2
  exit 1
fi

pinned_version="$(<"${pin_file}")"
if [[ ! "${pinned_version}" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\.stable\.official\.[[:xdigit:]]+$ ]]; then
  echo ".godot-version must contain one exact official stable build." >&2
  exit 1
fi
release="${BASH_REMATCH[1]}-stable"

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64|Darwin-x86_64)
    platform=macos-universal
    archive_name="Godot_v${release}_macos.universal.zip"
    ;;
  Linux-x86_64)
    platform=linux-x86_64
    archive_name="Godot_v${release}_linux.x86_64.zip"
    ;;
  *)
    echo "Unsupported Godot bootstrap platform: $(uname -s)-$(uname -m)" >&2
    exit 1
    ;;
esac

expected_checksum="$(awk -v platform="${platform}" '$1 == platform { print $2 }' "${checksum_file}")"
if [[ ! "${expected_checksum}" =~ ^[[:xdigit:]]{64}$ ]]; then
  echo "Missing SHA-256 for ${platform} in ${checksum_file}." >&2
  exit 1
fi

install_parent="${repo_root}/.toolchains/godot"
install_directory="${install_parent}/${pinned_version}"
godot_bin="${install_directory}/godot"
if [[ -x "${godot_bin}" && "$("${godot_bin}" --version)" == "${pinned_version}" ]]; then
  echo "Godot bootstrap ready: ${godot_bin}"
  exit 0
fi
if [[ -e "${install_directory}" ]]; then
  backup_directory="${install_directory}.invalid-$(date +%s)"
  mv "${install_directory}" "${backup_directory}"
  echo "Moved invalid Godot cache to ${backup_directory}."
fi

for command_name in curl unzip; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "${command_name} is required to bootstrap Godot." >&2
    exit 1
  fi
done

temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/aonw-godot.XXXXXX")"
trap 'rm -rf -- "${temporary_directory}"' EXIT
archive_path="${temporary_directory}/${archive_name}"
extract_directory="${temporary_directory}/extracted"
download_url="https://github.com/godotengine/godot/releases/download/${release}/${archive_name}"

echo "Downloading Godot ${pinned_version} for ${platform}..."
curl --fail --location --retry 3 --silent --show-error \
  --output "${archive_path}" \
  "${download_url}"

if command -v sha256sum >/dev/null 2>&1; then
  actual_checksum="$(sha256sum "${archive_path}" | awk '{ print $1 }')"
elif command -v shasum >/dev/null 2>&1; then
  actual_checksum="$(shasum -a 256 "${archive_path}" | awk '{ print $1 }')"
else
  echo "sha256sum or shasum is required to verify Godot." >&2
  exit 1
fi
if [[ "${actual_checksum}" != "${expected_checksum}" ]]; then
  echo "Godot archive checksum mismatch for ${archive_name}." >&2
  exit 1
fi

mkdir -p "${extract_directory}"
unzip -q "${archive_path}" -d "${extract_directory}"
if [[ "${platform}" == macos-universal ]]; then
  executable="${extract_directory}/Godot.app/Contents/MacOS/Godot"
  if [[ ! -x "${executable}" ]]; then
    echo "Godot archive does not contain the expected macOS executable." >&2
    exit 1
  fi
  ln -s Godot.app/Contents/MacOS/Godot "${extract_directory}/godot"
else
  executable="${extract_directory}/Godot_v${release}_linux.x86_64"
  if [[ ! -f "${executable}" ]]; then
    echo "Godot archive does not contain the expected Linux executable." >&2
    exit 1
  fi
  mv "${executable}" "${extract_directory}/godot"
  chmod +x "${extract_directory}/godot"
fi

if [[ "$("${extract_directory}/godot" --version)" != "${pinned_version}" ]]; then
  echo "Downloaded Godot does not match ${pinned_version}." >&2
  exit 1
fi

mkdir -p "${install_parent}"
mv "${extract_directory}" "${install_directory}"
echo "Godot bootstrap ready: ${godot_bin}"
