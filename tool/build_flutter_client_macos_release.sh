#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
client_root="${repo_root}/clients/aonw_flutter"
api_origin="${1:-}"
build_number="${2:-}"
archive_path="${3:-${repo_root}/dist/flutter/aonw-macos-arm64.zip}"
app_path="${client_root}/build/macos/Build/Products/Release/aonw_flutter.app"
executable_path="${app_path}/Contents/MacOS/aonw_flutter"
native_path="${app_path}/Contents/Frameworks/aonw_flutter.framework/Versions/A/aonw_flutter"
info_path="${app_path}/Contents/Info.plist"
release_entitlements="${client_root}/macos/Runner/Release.entitlements"
maximum_app_kib=$((150 * 1024))

if [[ ! "${api_origin}" =~ ^https://[A-Za-z0-9.-]+(:[0-9]{1,5})?/?$ ]]; then
  echo "The Flutter client release API must be one HTTPS origin." >&2
  exit 64
fi
if [[ ! "${build_number}" =~ ^[1-9][0-9]*$ ]]; then
  echo "The Flutter client build number must be a positive integer." >&2
  exit 64
fi
if [[ "$(uname -m)" != 'arm64' ]]; then
  echo "The qualified Flutter client release target is macOS arm64." >&2
  exit 64
fi

cd "${client_root}"
flutter build macos \
  --release \
  --no-pub \
  --build-number="${build_number}" \
  --dart-define="AONW_API_BASE_URL=${api_origin}" \
  --dart-define="AONW_BUILD_NUMBER=${build_number}"

for required_path in "${app_path}" "${executable_path}" "${native_path}" "${info_path}"; do
  if [[ ! -e "${required_path}" ]]; then
    echo "Flutter client release artifact is incomplete: ${required_path}" >&2
    exit 1
  fi
done

if [[ "$(plutil -extract CFBundleVersion raw "${info_path}")" != "${build_number}" ]]; then
  echo "Flutter client bundle build number does not match ${build_number}." >&2
  exit 1
fi
if [[ "$(lipo -archs "${executable_path}")" != 'arm64' ]]; then
  echo "Flutter client executable is not a thin arm64 artifact." >&2
  exit 1
fi
if [[ "$(lipo -archs "${native_path}")" != 'arm64' ]]; then
  echo "Flutter client Rust framework is not a thin arm64 artifact." >&2
  exit 1
fi
if ! nm -gU "${native_path}" | grep -F '_aonw_flutter_build_identity_len' >/dev/null; then
  echo "Flutter client Rust framework does not expose build identity." >&2
  exit 1
fi
if ! nm -gU "${native_path}" | grep -F '_aonw_flutter_session_new' >/dev/null; then
  echo "Flutter client Rust framework does not expose the session ABI." >&2
  exit 1
fi

if [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.network.client' "${release_entitlements}")" != 'true' ]]; then
  echo "Flutter client release entitlements must allow network clients." >&2
  exit 1
fi
signing_identity="${FLUTTER_CLIENT_SIGNING_IDENTITY:-}"
if [[ -n "${signing_identity}" ]]; then
  codesign \
    --force \
    --deep \
    --options runtime \
    --timestamp \
    --entitlements "${release_entitlements}" \
    --sign "${signing_identity}" \
    "${app_path}"
fi
codesign --verify --deep --strict --verbose=2 "${app_path}"
actual_entitlements="$(codesign -d --entitlements :- "${app_path}" 2>&1)"
for required_entitlement in \
  'com.apple.security.network.client'; do
  if [[ "${actual_entitlements}" != *"${required_entitlement}"* ]]; then
    echo "Signed Flutter client is missing ${required_entitlement}." >&2
    exit 1
  fi
done
if [[ -n "${signing_identity}" ]] && [[ "${actual_entitlements}" == *'com.apple.security.get-task-allow'* ]]; then
  echo "Signed Flutter client must not allow debugger attachment." >&2
  exit 1
fi

app_kib="$(du -sk "${app_path}" | awk '{print $1}')"
if ((app_kib > maximum_app_kib)); then
  echo "Flutter client app is ${app_kib} KiB; budget is ${maximum_app_kib} KiB." >&2
  exit 1
fi

mkdir -p "$(dirname "${archive_path}")"
rm -f -- "${archive_path}"
ditto -c -k --sequesterRsrc --keepParent "${app_path}" "${archive_path}"
unzip -tq "${archive_path}" >/dev/null

startup_log="$(mktemp "${TMPDIR:-/tmp}/aonw-flutter-release.XXXXXX")"
app_pid=''
cleanup() {
  if [[ -n "${app_pid}" ]] && kill -0 "${app_pid}" 2>/dev/null; then
    kill -TERM "${app_pid}" 2>/dev/null || true
    wait "${app_pid}" 2>/dev/null || true
  fi
  rm -f -- "${startup_log}"
}
trap cleanup EXIT INT TERM

"${executable_path}" >"${startup_log}" 2>&1 &
app_pid=$!
sleep 5
if ! kill -0 "${app_pid}" 2>/dev/null; then
  echo "Flutter client release process exited during startup." >&2
  sed -n '1,160p' "${startup_log}" >&2
  exit 1
fi
kill -TERM "${app_pid}" 2>/dev/null || true
wait "${app_pid}" 2>/dev/null || true
app_pid=''

archive_sha256="$(shasum -a 256 "${archive_path}" | awk '{print $1}')"
echo "Flutter client macOS release passed."
echo "  app: ${app_path} (${app_kib} KiB)"
echo "  archive: ${archive_path}"
echo "  sha256: ${archive_sha256}"
echo "  signing: ${signing_identity:-ad-hoc local qualification}"
