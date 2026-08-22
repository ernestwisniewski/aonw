#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
freeze_checker="${repo_root}/tool/check_legacy_freeze.sh"
dependency_checker="${repo_root}/tool/check_successor_dependencies.sh"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/aonw-successor-boundaries.XXXXXX")"
freeze_fixture="${fixture_root}/freeze"
dependency_fixture="${fixture_root}/dependencies"
case_log="${fixture_root}/case.log"

cleanup() {
  rm -rf "${fixture_root}"
}
trap cleanup EXIT

fixture_git() {
  GIT_CONFIG_NOSYSTEM=1 \
    GIT_CONFIG_GLOBAL=/dev/null \
    git -C "${freeze_fixture}" "$@"
}

reset_freeze_fixture() {
  fixture_git reset --hard -q HEAD
  fixture_git clean -fdq
}

expect_freeze_rejection() {
  local label="$1"
  if "${freeze_checker}" \
    --repo-root "${freeze_fixture}" \
    --manifest "${freeze_fixture}/tool/legacy_freeze_manifest.v1" \
    >"${case_log}" 2>&1; then
    echo "Freeze checker accepted ${label}." >&2
    exit 1
  fi
  echo "Freeze checker rejected ${label}."
  reset_freeze_fixture
}

mkdir -p \
  "${freeze_fixture}/lib" \
  "${freeze_fixture}/packages/aonw_core" \
  "${freeze_fixture}/tool"
printf 'legacy app\n' >"${freeze_fixture}/lib/app.dart"
printf 'legacy engine\n' >"${freeze_fixture}/packages/aonw_core/engine.dart"

fixture_git init -q
fixture_git config user.email successor-boundary-check@aonw.invalid
fixture_git config user.name "AONW successor boundary check"
fixture_git config commit.gpgSign false
fixture_git config core.hooksPath /dev/null
fixture_git add -A
fixture_git commit -qm "Freeze fixture"

lib_oid="$(fixture_git rev-parse HEAD:lib)"
core_oid="$(fixture_git rev-parse HEAD:packages/aonw_core)"
printf '# test manifest\nversion 1\ntree lib %s\ntree packages/aonw_core %s\n' \
  "${lib_oid}" \
  "${core_oid}" \
  >"${freeze_fixture}/tool/legacy_freeze_manifest.v1"

"${freeze_checker}" \
  --repo-root "${freeze_fixture}" \
  --manifest "${freeze_fixture}/tool/legacy_freeze_manifest.v1" \
  >/dev/null

printf 'changed\n' >>"${freeze_fixture}/lib/app.dart"
expect_freeze_rejection "a modified file"

printf 'new file\n' >"${freeze_fixture}/packages/aonw_core/new_rule.dart"
expect_freeze_rejection "an added file"

rm "${freeze_fixture}/lib/app.dart"
expect_freeze_rejection "a removed file"

fixture_git mv \
  packages/aonw_core/engine.dart \
  packages/aonw_core/renamed_engine.dart
expect_freeze_rejection "a renamed file"

printf 'committed change\n' >>"${freeze_fixture}/lib/app.dart"
fixture_git add lib/app.dart
fixture_git commit -qm "Change frozen tree"
if "${freeze_checker}" \
  --repo-root "${freeze_fixture}" \
  --manifest "${freeze_fixture}/tool/legacy_freeze_manifest.v1" \
  >"${case_log}" 2>&1; then
  echo "Freeze checker accepted a committed tree mismatch." >&2
  exit 1
fi
echo "Freeze checker rejected a committed tree mismatch."

mkdir -p "${dependency_fixture}/clients/aonw_flutter/lib"
printf 'void main() {}\n' >"${dependency_fixture}/clients/aonw_flutter/lib/main.dart"
"${dependency_checker}" --repo-root "${dependency_fixture}" >/dev/null

printf "import 'package:aonw_core/aonw_core.dart';\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/main.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted a legacy Dart import." >&2
  exit 1
fi
echo "Dependency checker rejected a legacy Dart import."

echo "Successor boundary negative tests passed."
