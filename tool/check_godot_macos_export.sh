#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

if [[ "$#" -ne 2 ]]; then
  echo "Usage: $0 <application.app> <smoke-log>" >&2
  exit 64
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
application_path="$1"
smoke_log="$2"

case "${application_path}" in
  /*.app) ;;
  *)
    echo "Godot macOS export path must be an absolute .app path." >&2
    exit 1
    ;;
esac

info_plist="${application_path}/Contents/Info.plist"
native_library="${application_path}/Contents/Frameworks/libaonw_godot.dylib"
if [[ ! -f "${info_plist}" || ! -f "${native_library}" ]]; then
  echo "Godot macOS export is incomplete: ${application_path}" >&2
  exit 1
fi
if rg -n 'engine/target|\.\./\.\./engine' \
  "${repo_root}/clients/aonw_godot/aonw_engine.gdextension"; then
  echo "Godot GDExtension must not reference the Rust target directory." >&2
  exit 1
fi

bundle_executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "${info_plist}")"
if [[ -z "${bundle_executable}" || "${bundle_executable}" == */* ]]; then
  echo "Godot macOS export has an invalid bundle executable." >&2
  exit 1
fi
executable_path="${application_path}/Contents/MacOS/${bundle_executable}"
if [[ ! -x "${executable_path}" ]]; then
  echo "Godot macOS export executable is missing: ${executable_path}" >&2
  exit 1
fi

if [[ "$(lipo -archs "${executable_path}")" != "arm64" ]]; then
  echo "Godot macOS export executable is not arm64-only." >&2
  exit 1
fi
if [[ "$(lipo -archs "${native_library}")" != "arm64" ]]; then
  echo "Godot native library is not arm64-only." >&2
  exit 1
fi

codesign --verify --deep --strict "${application_path}"
"${executable_path}" --headless --log-file "${smoke_log}" --quit-after 5
"${repo_root}/tool/check_godot_log.sh" "${smoke_log}"

echo "Godot macOS arm64 export smoke: OK"
