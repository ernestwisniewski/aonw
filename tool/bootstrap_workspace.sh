#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"${repo_root}/tool/check_toolchain.sh"
"${repo_root}/tool/bootstrap_godot.sh"
"${repo_root}/tool/bootstrap_terrain3d.sh"
"${repo_root}/tool/bootstrap_rust_quality.sh"

for workspace in . clients/aonw_flutter packages/aonw_core packages/aonw_server_client server; do
  for input in pubspec.yaml pubspec.lock; do
    if [[ ! -f "${repo_root}/${workspace}/${input}" ]]; then
      echo "Missing locked workspace input: ${workspace}/${input}" >&2
      exit 1
    fi
  done
done

echo "Resolving root Flutter dependencies..."
(
  cd "${repo_root}"
  flutter pub get --enforce-lockfile
)

echo "Resolving successor Flutter dependencies..."
(
  cd "${repo_root}/clients/aonw_flutter"
  flutter pub get --enforce-lockfile
)

for package in packages/aonw_core packages/aonw_server_client server; do
  echo "Resolving ${package} Dart dependencies..."
  (
    cd "${repo_root}/${package}"
    dart pub get --enforce-lockfile
  )
done

echo "Workspace lockfiles are installed."
