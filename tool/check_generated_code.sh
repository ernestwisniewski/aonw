#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C
export TZ=UTC

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
serverpod_cli="${SERVERPOD_CLI:-${HOME}/.pub-cache/bin/serverpod}"

"${repo_root}/tool/check_toolchain.sh"

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
  find lib -type f \( -name '*.g.dart' -o -name '*.freezed.dart' \) -delete
  dart run build_runner build
)

echo "Checking Flutter generated code and localizations..."
(
  cd "${snapshot_root}"
  flutter pub get --enforce-lockfile
  find lib -type f \( -name '*.g.dart' -o -name '*.freezed.dart' \) -delete
  rm -rf lib/l10n/generated
  flutter gen-l10n
  flutter pub run build_runner build
)

echo "Checking Serverpod protocol, client, test tools, and migrations..."
(
  cd "${snapshot_root}/server"
  dart pub get --enforce-lockfile
  rm -rf \
    lib/src/generated \
    ../packages/aonw_server_client/lib/src/protocol \
    test/integration/test_tools/serverpod_test_tools.dart
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
