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

printf 'void main() {}\n' >"${dependency_fixture}/clients/aonw_flutter/lib/main.dart"
mkdir -p "${dependency_fixture}/clients/aonw_flutter/lib/features/map/presentation"
printf "import 'package:aonw_rust_client/aonw_rust_client.dart';\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/presentation/map.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted Rust transport in presentation." >&2
  exit 1
fi
echo "Dependency checker rejected Rust transport in presentation."

mkdir -p "${dependency_fixture}/clients/aonw_flutter/lib/features/map/application"
printf "import 'package:flutter/foundation.dart';\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/application/controller.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted Flutter in successor application code." >&2
  exit 1
fi
echo "Dependency checker rejected Flutter in successor application code."
rm "${dependency_fixture}/clients/aonw_flutter/lib/features/map/application/controller.dart"

printf 'final class ProtocolFallbackReader {}\n' \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/application/protocol.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted a successor protocol fallback." >&2
  exit 1
fi
echo "Dependency checker rejected successor protocol fallback code."
rm "${dependency_fixture}/clients/aonw_flutter/lib/features/map/application/protocol.dart"

printf "final polish = Localizations.localeOf(context).languageCode == 'pl';\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/presentation/map.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted a manual locale branch." >&2
  exit 1
fi
echo "Dependency checker rejected a manual locale branch."

printf "const _polishText = <String, String>{'title': 'Mapa'};\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/presentation/map.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted an in-code language dictionary." >&2
  exit 1
fi
echo "Dependency checker rejected an in-code language dictionary."

printf "Widget build() => Text('Map');\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/presentation/map.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted hardcoded user-facing copy." >&2
  exit 1
fi
echo "Dependency checker rejected hardcoded user-facing copy."
printf 'void main() {}\n' \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/presentation/map.dart"

mkdir -p "${dependency_fixture}/clients/aonw_flutter/lib/game/rendering"
printf "import '../../features/map/infrastructure/rust_map_repository.dart';\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/game/rendering/map_layer.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted infrastructure in a Flame game layer." >&2
  exit 1
fi
echo "Dependency checker rejected infrastructure in a Flame game layer."
rm "${dependency_fixture}/clients/aonw_flutter/lib/game/rendering/map_layer.dart"

printf "import '../../features/map/application/map_repository.dart';\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/game/rendering/map_repository_leak.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted a repository in a Flame game layer." >&2
  exit 1
fi
echo "Dependency checker rejected a repository in a Flame game layer."
rm "${dependency_fixture}/clients/aonw_flutter/lib/game/rendering/map_repository_leak.dart"

printf 'void main() {}\n' \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/presentation/map.dart"
mkdir -p "${dependency_fixture}/clients/aonw_godot/game/presentation/map"
printf 'var terrain_mesh_resource\n' \
  >"${dependency_fixture}/clients/aonw_godot/game/presentation/map/legacy_terrain.gd"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted a Godot mesh terrain fallback." >&2
  exit 1
fi
echo "Dependency checker rejected a Godot mesh terrain fallback."
rm "${dependency_fixture}/clients/aonw_godot/game/presentation/map/legacy_terrain.gd"

printf '%s\n' \
  '[configuration]' \
  'entry_symbol = "gdext_rust_init"' \
  '[libraries]' \
  'windows.release.x86_64 = "res://../../engine/target/release/aonw_godot.dll"' \
  >"${dependency_fixture}/clients/aonw_godot/aonw_engine.gdextension"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted an unstaged or unsupported GDExtension library." >&2
  exit 1
fi
echo "Dependency checker rejected an unstaged and unsupported GDExtension library."
rm "${dependency_fixture}/clients/aonw_godot/aonw_engine.gdextension"

authoring_fixture="${dependency_fixture}/clients/aonw_godot/editor/map_authoring"
mkdir -p \
  "${authoring_fixture}/application" \
  "${authoring_fixture}/infrastructure" \
  "${authoring_fixture}/presentation"
printf 'const Store := preload("res://editor/map_authoring/infrastructure/store.gd")\n' \
  >"${authoring_fixture}/application/session.gd"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted Godot application-to-infrastructure coupling." >&2
  exit 1
fi
echo "Dependency checker rejected Godot application-to-infrastructure coupling."
rm "${authoring_fixture}/application/session.gd"

printf 'const Surface := preload("res://editor/map_authoring/presentation/surface.gd")\n' \
  >"${authoring_fixture}/infrastructure/scenes.gd"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted Godot infrastructure-to-presentation coupling." >&2
  exit 1
fi
echo "Dependency checker rejected Godot infrastructure-to-presentation coupling."
rm "${authoring_fixture}/infrastructure/scenes.gd"

printf 'const Store := preload("res://editor/map_authoring/infrastructure/store.gd")\n' \
  >"${authoring_fixture}/presentation/surface.gd"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted Godot presentation-to-infrastructure coupling." >&2
  exit 1
fi
echo "Dependency checker rejected Godot presentation-to-infrastructure coupling."
rm "${authoring_fixture}/presentation/surface.gd"

printf 'var canonical_map := {"terrainTags": []}\n' \
  >"${authoring_fixture}/presentation/canonical_map_writer.gd"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted a Godot canonical map writer." >&2
  exit 1
fi
echo "Dependency checker rejected a Godot canonical map writer."

echo "Successor boundary negative tests passed."
