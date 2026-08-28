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

successor_godot="${repo_root}/clients/aonw_godot"

violations="$(mktemp "${TMPDIR:-/tmp}/aonw-successor-dependencies.XXXXXX")"
trap 'rm -f "${violations}"' EXIT

while IFS= read -r -d '' source_file; do
  grep -nHE 'package:(aonw_core|aonw)/' "${source_file}" >>"${violations}" || true
done < <(
  find "${successor_flutter}" \
    \( -path '*/.dart_tool' -o -path '*/build' \) -prune -o \
    -type f -name '*.dart' -print0
)

if [[ -d "${successor_godot}/game" ]]; then
  grep -RInE \
    'BaseTerrain|terrain_mesh_resource|map_surface_mesh_builder' \
    --include='*.gd' \
    "${successor_godot}/game" \
    >>"${violations}" || true
fi

authoring_root="${successor_godot}/editor/map_authoring"
if [[ -d "${authoring_root}" ]]; then
  if [[ -d "${authoring_root}/application" ]]; then
    grep -RInE 'res://.*/infrastructure/' \
      --include='*.gd' \
      "${authoring_root}/application" \
      >>"${violations}" || true
  fi
  if [[ -d "${authoring_root}/infrastructure" ]]; then
    grep -RInE 'res://.*/presentation/' \
      --include='*.gd' \
      "${authoring_root}/infrastructure" \
      >>"${violations}" || true
  fi
  if [[ -d "${authoring_root}/presentation" ]]; then
    grep -RInE 'res://.*/infrastructure/' \
      --include='*.gd' \
      "${authoring_root}/presentation" \
      >>"${violations}" || true
  fi
  grep -RInE \
    '"(terrainTags|displayTerrain|yieldTerrain|tiles|objectives)"[[:space:]]*:' \
    --include='*.gd' \
    "${authoring_root}" \
    >>"${violations}" || true
fi

while IFS= read -r -d '' pubspec_file; do
  grep -nHE '^[[:space:]]+(aonw_core|aonw):([[:space:]]|$)' "${pubspec_file}" >>"${violations}" || true
done < <(
  find "${successor_flutter}" \
    \( -path '*/.dart_tool' -o -path '*/build' \) -prune -o \
    -type f -name 'pubspec.yaml' -print0
)

while IFS= read -r -d '' source_file; do
  case "${source_file}" in
    */infrastructure/*) ;;
    *)
      grep -nHE "package:aonw_rust_client/" "${source_file}" \
        >>"${violations}" || true
      ;;
  esac
  case "${source_file}" in
    */lib/game/*)
      grep -nHE "^import .*infrastructure/" "${source_file}" \
        >>"${violations}" || true
      grep -nHE "^import .*application/[^']*repository" "${source_file}" \
        >>"${violations}" || true
      ;;
  esac
  case "${source_file}" in
    */presentation/*)
      grep -nHE "^import .*infrastructure/" "${source_file}" \
        >>"${violations}" || true
      ;;
    */application/*|*/read_model/*)
      grep -nHE "(package:(flutter|flame)/|dart:ui)" "${source_file}" \
        >>"${violations}" || true
      ;;
  esac
  case "${source_file}" in
    */l10n/generated/*) ;;
    *)
      grep -nHE \
        "(Localizations\\.localeOf|languageCode[[:space:]]*==|==[[:space:]]*['\"](pl|en)['\"]|_(polish|english)|bool[[:space:]]+(polish|english))" \
        "${source_file}" \
        >>"${violations}" || true
      grep -nHE \
        "((^|[^[:alnum:]_])(Text|TextSpan)\\([[:space:]]*(const[[:space:]]+)?['\"][[:alpha:]]|(tooltip|semanticLabel|labelText|hintText|helperText|errorText):[[:space:]]*(const[[:space:]]+)?['\"][[:alpha:]])" \
        "${source_file}" \
        >>"${violations}" || true
      ;;
  esac
  grep -niHE \
    '(legacy[^[:alnum:]]*(dto|adapter|reader|writer)|upcaster|protocol[^[:alnum:]]*fallback|compatibility[^[:alnum:]]*(adapter|reader|fallback)|dart[^[:alnum:]]*fallback|fallback[^[:alnum:]]*to[^[:alnum:]]*dart)' \
    "${source_file}" \
    >>"${violations}" || true
done < <(
  find "${successor_flutter}/lib" \
    \( -path '*/.dart_tool' -o -path '*/build' \) -prune -o \
    -type f -name '*.dart' -print0
)

if [[ -s "${violations}" ]]; then
  echo "Successor client dependency boundaries were violated:" >&2
  sed "s#${repo_root}/##" "${violations}" >&2
  exit 1
fi

echo "Successor client dependency boundaries are intact."
