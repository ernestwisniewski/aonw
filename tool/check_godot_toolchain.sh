#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pin_file="${repo_root}/.godot-version"

if [[ ! -f "${pin_file}" ]]; then
  echo "Missing Godot pin: ${pin_file}" >&2
  exit 1
fi

pinned_version="$(<"${pin_file}")"
if [[ ! "${pinned_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.stable\.official\.[[:xdigit:]]+$ ]]; then
  echo ".godot-version must contain one exact official stable build." >&2
  exit 1
fi

godot_bin="${GODOT_BIN:-}"
if [[ -z "${godot_bin}" ]]; then
  bootstrapped_bin="${repo_root}/.toolchains/godot/${pinned_version}/godot"
  if [[ -x "${bootstrapped_bin}" ]]; then
    godot_bin="${bootstrapped_bin}"
  elif [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
    godot_bin=/Applications/Godot.app/Contents/MacOS/Godot
  elif command -v godot >/dev/null 2>&1; then
    godot_bin="$(command -v godot)"
  else
    echo "Godot is required. Install ${pinned_version} or set GODOT_BIN." >&2
    exit 1
  fi
fi

if [[ "${godot_bin}" == */* ]]; then
  if [[ ! -x "${godot_bin}" ]]; then
    echo "GODOT_BIN is not executable: ${godot_bin}" >&2
    exit 1
  fi
elif ! command -v "${godot_bin}" >/dev/null 2>&1; then
  echo "Godot command not found: ${godot_bin}" >&2
  exit 1
fi

actual_version="$("${godot_bin}" --version)"
if [[ "${actual_version}" != "${pinned_version}" ]]; then
  echo "Godot version mismatch: expected ${pinned_version}, found ${actual_version:-unknown}. Run make bootstrap." >&2
  exit 1
fi

echo "Godot toolchain OK: ${actual_version}."
