#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_kind="${1:-}"
build_profile="${2:-debug}"

case "${build_kind}" in
  runtime|editor) ;;
  *)
    echo "Usage: $0 <runtime|editor> [debug|release]" >&2
    exit 64
    ;;
esac
case "${build_profile}" in
  debug|release) ;;
  *)
    echo "Unsupported Godot native build profile: ${build_profile}" >&2
    exit 64
    ;;
esac

workspace_version="$({
  awk '
    /^\[workspace\.package\]$/ { in_package = 1; next }
    /^\[/ { in_package = 0 }
    in_package && /^version = "/ {
      value = $0
      sub(/^version = "/, "", value)
      sub(/"$/, "", value)
      print value
      exit
    }
  ' "${repo_root}/engine/Cargo.toml"
})"
client_api_version="$({
  sed -n 's/^pub const CLIENT_API_VERSION: u16 = \([0-9][0-9]*\);$/\1/p' \
    "${repo_root}/engine/crates/aonw_contracts/src/client/mod.rs"
})"
source_revision="$(git -C "${repo_root}" rev-parse --verify HEAD)"
source_tree="$({
  git -C "${repo_root}" ls-files --cached --others --exclude-standard -z -- \
    engine clients/aonw_godot |
    while IFS= read -r -d '' source_path; do
      printf '%s\0' "${source_path}"
      git -C "${repo_root}" hash-object -- "${source_path}"
    done
} | git -C "${repo_root}" hash-object --stdin)"
rustc_bin="${RUSTC:-rustc}"
target_triple="$({
  "${rustc_bin}" -vV | sed -n 's/^host: //p'
})"

case "${target_triple}" in
  aarch64-apple-darwin)
    staged_platform="macos"
    staged_architecture="arm64"
    library_name="libaonw_godot.dylib"
    ;;
  x86_64-unknown-linux-gnu)
    staged_platform="linux"
    staged_architecture="x86_64"
    library_name="libaonw_godot.so"
    ;;
  *)
    echo "Unsupported staged Godot native target: ${target_triple}" >&2
    exit 1
    ;;
esac

for required_value in \
  "${workspace_version}" \
  "${client_api_version}" \
  "${source_revision}" \
  "${source_tree}" \
  "${target_triple}"; do
  if [[ -z "${required_value}" || ! "${required_value}" =~ ^[A-Za-z0-9._+-]+$ ]]; then
    echo "Cannot derive a safe Godot native build identity component." >&2
    exit 1
  fi
done

identity="aonw_godot/${workspace_version};client_api=${client_api_version};source=${source_revision};source_tree=${source_tree};target=${target_triple};profile=${build_profile};kind=${build_kind}"
rust_cargo="${RUST_CARGO:-cargo}"
cargo_args=(
  build
  --locked
  -p aonw_godot
  --no-default-features
)
if [[ "${build_kind}" == "editor" ]]; then
  cargo_args+=(--features editor-tools)
fi
if [[ "${build_profile}" == "release" ]]; then
  cargo_args+=(--release)
fi

(
  cd "${repo_root}/engine"
  AONW_GODOT_BUILD_IDENTITY="${identity}" "${rust_cargo}" "${cargo_args[@]}"
)

artifact_path="${repo_root}/engine/target/${build_profile}/${library_name}"
if [[ ! -f "${artifact_path}" ]]; then
  echo "Godot native build did not produce ${artifact_path}." >&2
  exit 1
fi

stage_directory="${repo_root}/clients/aonw_godot/native/${staged_platform}/${staged_architecture}/${build_profile}"
library_path="${stage_directory}/${library_name}"
identity_path="${stage_directory}/aonw_native_build_identity.txt"
mkdir -p "${stage_directory}"
staged_library="$(mktemp "${library_path}.staging.XXXXXX")"
staged_identity="$(mktemp "${identity_path}.staging.XXXXXX")"
trap 'rm -f "${staged_library}" "${staged_identity}"' EXIT
cp "${artifact_path}" "${staged_library}"
chmod 755 "${staged_library}"
printf '%s\n' "${identity}" >"${staged_identity}"
mv "${staged_library}" "${library_path}"
mv "${staged_identity}" "${identity_path}"
trap - EXIT

echo "Godot native ${build_kind} staged at ${library_path}"
echo "Godot native ${build_kind} identity: ${identity}"
