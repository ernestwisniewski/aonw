#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C
export TZ=UTC

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
serverpod_cli="${SERVERPOD_CLI:-${HOME}/.pub-cache/bin/serverpod}"

required_flutter_versions="$(
  awk '$1 == "flutter-version:" { gsub(/"/, "", $2); print $2 }' \
    "${repo_root}/.github/workflows/ci.yml" | sort -u
)"
if [[ -z "${required_flutter_versions}" || "${required_flutter_versions}" == *$'\n'* ]]; then
  echo "CI must declare exactly one Flutter version for generated code." >&2
  exit 1
fi

flutter_machine="$(flutter --version --machine)"
actual_flutter_version="$(
  printf '%s\n' "${flutter_machine}" |
    sed -n 's/^[[:space:]]*"frameworkVersion":[[:space:]]*"\([^"]*\)".*/\1/p'
)"
flutter_dart_version="$(
  printf '%s\n' "${flutter_machine}" |
    sed -n 's/^[[:space:]]*"dartSdkVersion":[[:space:]]*"\([^"]*\)".*/\1/p'
)"
active_dart_version="$(
  dart --version 2>&1 |
    sed -n 's/^Dart SDK version:[[:space:]]*\([^[:space:]]*\).*/\1/p'
)"
if [[ "${actual_flutter_version}" != "${required_flutter_versions}" ]]; then
  echo "Flutter version mismatch: CI requires ${required_flutter_versions}, found ${actual_flutter_version:-unknown}." >&2
  exit 1
fi
if [[ -z "${flutter_dart_version}" || "${active_dart_version}" != "${flutter_dart_version}" ]]; then
  echo "Dart must match Flutter ${required_flutter_versions}: expected ${flutter_dart_version:-unknown}, found ${active_dart_version:-unknown}." >&2
  exit 1
fi

if [[ "${serverpod_cli}" != /* ]]; then
  serverpod_cli="$(command -v "${serverpod_cli}" || true)"
fi
if [[ -z "${serverpod_cli}" || ! -x "${serverpod_cli}" ]]; then
  echo "Serverpod CLI not found. Install the matching version with: make serverpod-cli-install" >&2
  exit 1
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/aonw-generated-code.XXXXXX")"
snapshot_root="${tmp_dir}/repository"

cleanup() {
  if [[ "${AONW_KEEP_GENERATED_CODE_SNAPSHOT:-0}" == "1" ]]; then
    echo "Generated-code snapshot kept at ${snapshot_root}." >&2
    return
  fi
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

mkdir -p "${snapshot_root}"
git -C "${repo_root}" archive HEAD | tar -xf - -C "${snapshot_root}"

snapshot_git() {
  GIT_CONFIG_NOSYSTEM=1 \
    GIT_CONFIG_GLOBAL=/dev/null \
    git -C "${snapshot_root}" "$@"
}

snapshot_git init -q
snapshot_git config user.email generated-code-check@aonw.invalid
snapshot_git config user.name "AONW generated-code check"
snapshot_git config commit.gpgSign false
snapshot_git config core.hooksPath /dev/null
snapshot_git add -A
snapshot_git commit -qm "HEAD snapshot"

workspace_patch="${tmp_dir}/workspace.patch"
git -C "${repo_root}" diff --binary --full-index HEAD -- . >"${workspace_patch}"
if [[ -s "${workspace_patch}" ]]; then
  snapshot_git apply --binary --whitespace=nowarn "${workspace_patch}"
fi

while IFS= read -r -d '' path; do
  mkdir -p "${snapshot_root}/$(dirname "${path}")"
  cp -pP "${repo_root}/${path}" "${snapshot_root}/${path}"
done < <(git -C "${repo_root}" ls-files --others --exclude-standard -z)

snapshot_git add -A
if ! snapshot_git diff --cached --quiet; then
  snapshot_git commit -qm "Current workspace snapshot"
fi

echo "Checking aonw_core generated code..."
(
  cd "${snapshot_root}/packages/aonw_core"
  dart pub get --enforce-lockfile
  dart run build_runner build
)

echo "Checking Flutter generated code and localizations..."
(
  cd "${snapshot_root}"
  flutter pub get --enforce-lockfile
  flutter pub run build_runner build
  flutter gen-l10n
)

echo "Checking Serverpod protocol, client, test tools, and migrations..."
(
  cd "${snapshot_root}/server"
  dart pub get --enforce-lockfile
  "${serverpod_cli}" generate
  "${serverpod_cli}" create-migration
)

status="$(
  snapshot_git status \
    --porcelain=v1 \
    --untracked-files=all
)"
if [[ -n "${status}" ]]; then
  echo "Generated code is out of sync with its sources:" >&2
  printf '%s\n' "${status}" >&2
  snapshot_git diff --no-ext-diff --stat >&2
  echo "Run the relevant generator in the workspace, review the diff, and commit it." >&2
  echo "Set AONW_KEEP_GENERATED_CODE_SNAPSHOT=1 to inspect the isolated snapshot." >&2
  exit 1
fi

echo "Generated code, localizations, protocol, and migrations are in sync."
