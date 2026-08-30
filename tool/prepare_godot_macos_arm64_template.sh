#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

if [[ "$#" -ne 2 ]]; then
  echo "Usage: $0 <official-macos.zip> <arm64-macos.zip>" >&2
  exit 64
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_template="$1"
output_template="$2"
expected_checksum="$(awk '$1 == "macos-export-template" { print $2 }' \
  "${repo_root}/tool/godot_checksums.txt")"

if [[ ! -f "${source_template}" ]]; then
  echo "Official Godot macOS export template not found: ${source_template}" >&2
  echo "Install the pinned export templates or set GODOT_MACOS_TEMPLATE_SOURCE." >&2
  exit 1
fi
if [[ ! "${expected_checksum}" =~ ^[[:xdigit:]]{64}$ ]]; then
  echo "Pinned macOS export template checksum is missing." >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  actual_checksum="$(sha256sum "${source_template}" | awk '{ print $1 }')"
elif command -v shasum >/dev/null 2>&1; then
  actual_checksum="$(shasum -a 256 "${source_template}" | awk '{ print $1 }')"
else
  echo "sha256sum or shasum is required to verify the export template." >&2
  exit 1
fi
if [[ "${actual_checksum}" != "${expected_checksum}" ]]; then
  echo "Godot macOS export template checksum mismatch." >&2
  exit 1
fi

for command_name in lipo unzip zip; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "${command_name} is required to prepare the arm64 export template." >&2
    exit 1
  fi
done

temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/aonw-godot-macos-template.XXXXXX")"
trap 'rm -rf -- "${temporary_directory}"' EXIT
extracted_directory="${temporary_directory}/extracted"
mkdir -p "${extracted_directory}"
unzip -q "${source_template}" -d "${extracted_directory}"

template_binary_directory="${extracted_directory}/macos_template.app/Contents/MacOS"
for build_profile in debug release; do
  universal_binary="${template_binary_directory}/godot_macos_${build_profile}.universal"
  arm64_binary="${template_binary_directory}/godot_macos_${build_profile}.arm64"
  if [[ ! -f "${universal_binary}" ]]; then
    echo "Official template is missing ${universal_binary}." >&2
    exit 1
  fi
  lipo "${universal_binary}" -thin arm64 -output "${arm64_binary}"
  chmod 755 "${arm64_binary}"
  rm "${universal_binary}"
done

mkdir -p "$(dirname "${output_template}")"
staged_directory="$(mktemp -d "$(dirname "${output_template}")/.macos-template.XXXXXX")"
staged_template="${staged_directory}/macos-arm64.zip"
trap 'rm -rf -- "${temporary_directory}" "${staged_directory}"' EXIT
(
  cd "${extracted_directory}"
  zip -q -r -y "${staged_template}" macos_template.app
)
unzip -q -t "${staged_template}"
mv "${staged_template}" "${output_template}"

echo "Godot macOS arm64 export template ready: ${output_template}"
