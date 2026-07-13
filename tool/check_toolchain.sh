#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pin_file="${repo_root}/.fvmrc"

if [[ ! -f "${pin_file}" ]]; then
  echo "Missing Flutter SDK pin: ${pin_file}" >&2
  exit 1
fi

pin_contents="$(<"${pin_file}")"
pin_pattern='^[[:space:]]*\{[[:space:]]*"flutter"[[:space:]]*:[[:space:]]*"([0-9]+\.[0-9]+\.[0-9]+)"[[:space:]]*\}[[:space:]]*$'
if [[ ! "${pin_contents}" =~ ${pin_pattern} ]]; then
  echo ".fvmrc must contain only one exact Flutter version." >&2
  exit 1
fi
pinned_version="${BASH_REMATCH[1]}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is required. Install ${pinned_version} from .fvmrc and expose it on PATH." >&2
  exit 1
fi
if ! command -v dart >/dev/null 2>&1; then
  echo "Dart is required and must come from the pinned Flutter SDK." >&2
  exit 1
fi

flutter_machine="$(flutter --version --machine)"
actual_flutter_version="$(
  printf '%s\n' "${flutter_machine}" |
    sed -n 's/^[[:space:]]*"frameworkVersion":[[:space:]]*"\([^"]*\)".*/\1/p'
)"
flutter_channel="$(
  printf '%s\n' "${flutter_machine}" |
    sed -n 's/^[[:space:]]*"channel":[[:space:]]*"\([^"]*\)".*/\1/p'
)"
flutter_dart_version="$(
  printf '%s\n' "${flutter_machine}" |
    sed -n 's/^[[:space:]]*"dartSdkVersion":[[:space:]]*"\([^"]*\)".*/\1/p'
)"
flutter_root="$(
  printf '%s\n' "${flutter_machine}" |
    sed -n 's/^[[:space:]]*"flutterRoot":[[:space:]]*"\([^"]*\)".*/\1/p'
)"
active_dart_version="$(
  dart --version 2>&1 |
    sed -n 's/^Dart SDK version:[[:space:]]*\([^[:space:]]*\).*/\1/p'
)"

if [[ "${actual_flutter_version}" != "${pinned_version}" ]]; then
  echo "Flutter version mismatch: .fvmrc requires ${pinned_version}, found ${actual_flutter_version:-unknown}." >&2
  exit 1
fi
if [[ "${flutter_channel}" != "stable" ]]; then
  echo "Flutter channel mismatch: expected stable, found ${flutter_channel:-unknown}." >&2
  exit 1
fi
if [[ -z "${flutter_dart_version}" || "${active_dart_version}" != "${flutter_dart_version}" ]]; then
  echo "Dart must match Flutter ${pinned_version}: expected ${flutter_dart_version:-unknown}, found ${active_dart_version:-unknown}." >&2
  exit 1
fi
if [[ -z "${flutter_root}" ]]; then
  echo "Could not determine the pinned Flutter SDK root." >&2
  exit 1
fi

if [[ "${flutter_root}" == [A-Za-z]:* ]]; then
  if ! command -v cygpath >/dev/null 2>&1; then
    echo "cygpath is required to validate the Flutter SDK from a Windows POSIX shell." >&2
    exit 1
  fi
  flutter_root="$(
    printf '%s\n' "${flutter_root}" |
      sed 's/\\\\/\\/g' |
      cygpath -u -f -
  )"
fi

canonical_directory() {
  cd -P "$1" && pwd
}

sdk_bin_directory="$(canonical_directory "${flutter_root}/bin")"
dart_sdk_bin_directory="$(canonical_directory "${flutter_root}/bin/cache/dart-sdk/bin")"
active_flutter_directory="$(canonical_directory "$(dirname "$(command -v flutter)")")"
active_dart_directory="$(canonical_directory "$(dirname "$(command -v dart)")")"
if [[ "${active_flutter_directory}" != "${sdk_bin_directory}" || ( "${active_dart_directory}" != "${sdk_bin_directory}" && "${active_dart_directory}" != "${dart_sdk_bin_directory}" ) ]]; then
  echo "Pinned Flutter/Dart commands must come from ${sdk_bin_directory} or its bundled ${dart_sdk_bin_directory}: found ${active_flutter_directory} and ${active_dart_directory}." >&2
  exit 1
fi

echo "Toolchain OK: Flutter ${pinned_version} stable with bundled Dart ${flutter_dart_version}."
