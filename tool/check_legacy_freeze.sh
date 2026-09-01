#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="${repo_root}/tool/legacy_freeze_manifest.v1"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --repo-root)
      repo_root="${2:?--repo-root requires a path}"
      shift 2
      ;;
    --manifest)
      manifest="${2:?--manifest requires a path}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 64
      ;;
  esac
done

if ! git -C "${repo_root}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Legacy freeze check requires a Git worktree: ${repo_root}" >&2
  exit 1
fi
if [[ ! -f "${manifest}" ]]; then
  echo "Legacy freeze manifest not found: ${manifest}" >&2
  exit 1
fi

manifest_version=""
found_lib=0
found_core=0

check_tree() {
  local path="$1"
  local expected_oid="$2"
  local actual_oid
  local untracked

  if [[ ! "${expected_oid}" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Invalid tree OID for ${path}: ${expected_oid}" >&2
    exit 1
  fi

  if ! actual_oid="$(git -C "${repo_root}" rev-parse "HEAD:${path}" 2>/dev/null)"; then
    echo "Frozen tree is missing from HEAD: ${path}" >&2
    exit 1
  fi
  if [[ "${actual_oid}" != "${expected_oid}" ]]; then
    echo "Frozen tree ${path} differs from the manifest." >&2
    echo "Expected: ${expected_oid}" >&2
    echo "Actual:   ${actual_oid}" >&2
    exit 1
  fi

  if ! git -C "${repo_root}" diff --quiet -- "${path}"; then
    echo "Frozen tree has unstaged changes: ${path}" >&2
    git -C "${repo_root}" status --short -- "${path}" >&2
    exit 1
  fi
  if ! git -C "${repo_root}" diff --cached --quiet -- "${path}"; then
    echo "Frozen tree has staged changes: ${path}" >&2
    git -C "${repo_root}" status --short -- "${path}" >&2
    exit 1
  fi

  untracked="$(git -C "${repo_root}" ls-files --others --exclude-standard -- "${path}")"
  if [[ -n "${untracked}" ]]; then
    echo "Frozen tree has untracked files: ${path}" >&2
    printf '%s\n' "${untracked}" >&2
    exit 1
  fi

  printf '%s %s\n' "${path}" "${actual_oid}"
}

while read -r record field value extra; do
  [[ -z "${record}" || "${record}" == \#* ]] && continue
  if [[ -n "${extra:-}" ]]; then
    echo "Malformed legacy freeze manifest row: ${record} ${field} ${value} ${extra}" >&2
    exit 1
  fi

  case "${record}" in
    version)
      if [[ -n "${manifest_version}" || "${field}" != "1" || -n "${value:-}" ]]; then
        echo "Legacy freeze manifest must declare exactly: version 1" >&2
        exit 1
      fi
      manifest_version="${field}"
      ;;
    tree)
      if [[ "${manifest_version}" != "1" ]]; then
        echo "Legacy freeze manifest must declare version before tree entries." >&2
        exit 1
      fi
      case "${field}" in
        lib)
          [[ "${found_lib}" -eq 0 ]] || { echo "Duplicate manifest tree: lib" >&2; exit 1; }
          found_lib=1
          ;;
        packages/aonw_core)
          [[ "${found_core}" -eq 0 ]] || { echo "Duplicate manifest tree: packages/aonw_core" >&2; exit 1; }
          found_core=1
          ;;
        *)
          echo "Unexpected frozen tree in v1 manifest: ${field}" >&2
          exit 1
          ;;
      esac
      check_tree "${field}" "${value}"
      ;;
    *)
      echo "Unknown legacy freeze manifest record: ${record}" >&2
      exit 1
      ;;
  esac
done <"${manifest}"

if [[ "${manifest_version}" != "1" || "${found_lib}" -ne 1 || "${found_core}" -ne 1 ]]; then
  echo "Legacy freeze manifest must contain version 1 and both required trees." >&2
  exit 1
fi

echo "Legacy Dart trees match the freeze manifest."
