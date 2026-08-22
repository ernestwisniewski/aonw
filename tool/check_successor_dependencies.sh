#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --repo-root)
      repo_root="${2:?--repo-root requires a path}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 64
      ;;
  esac
done

successor_flutter="${repo_root}/clients/aonw_flutter"
if [[ ! -d "${successor_flutter}" ]]; then
  echo "Successor Flutter directory not found: ${successor_flutter}" >&2
  exit 1
fi

violations="$(mktemp "${TMPDIR:-/tmp}/aonw-successor-dependencies.XXXXXX")"
trap 'rm -f "${violations}"' EXIT

while IFS= read -r -d '' source_file; do
  grep -nHE 'package:(aonw_core|aonw)/' "${source_file}" >>"${violations}" || true
done < <(
  find "${successor_flutter}" \
    \( -path '*/.dart_tool' -o -path '*/build' \) -prune -o \
    -type f -name '*.dart' -print0
)

while IFS= read -r -d '' pubspec_file; do
  grep -nHE '^[[:space:]]+(aonw_core|aonw):([[:space:]]|$)' "${pubspec_file}" >>"${violations}" || true
done < <(
  find "${successor_flutter}" \
    \( -path '*/.dart_tool' -o -path '*/build' \) -prune -o \
    -type f -name 'pubspec.yaml' -print0
)

if [[ -s "${violations}" ]]; then
  echo "Successor Flutter must not depend on or import legacy Dart packages:" >&2
  sed "s#${repo_root}/##" "${violations}" >&2
  exit 1
fi

echo "Successor dependency boundaries are intact."
