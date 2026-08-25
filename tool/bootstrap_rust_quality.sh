#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rust_toolchain="1.97.1"

rustup toolchain install "${rust_toolchain}" \
  --profile minimal \
  --component clippy \
  --component llvm-tools-preview \
  --component rustfmt

ensure_cargo_tool() {
  local binary="$1"
  local crate="$2"
  local expected="$3"
  local cargo_subcommand="${4:-}"
  local installed_version=""
  if command -v "${binary}" >/dev/null 2>&1; then
    if [[ -n "${cargo_subcommand}" ]]; then
      installed_version="$("${binary}" "${cargo_subcommand}" --version)"
    else
      installed_version="$("${binary}" --version)"
    fi
  fi
  if [[ "${installed_version}" == "${binary} ${expected}" ]]; then
    return
  fi
  (
    cd "${repo_root}/engine"
    cargo install --locked --force --version "${expected}" "${crate}"
  )
  if [[ -n "${cargo_subcommand}" ]]; then
    installed_version="$("${binary}" "${cargo_subcommand}" --version)"
  else
    installed_version="$("${binary}" --version)"
  fi
  [[ "${installed_version}" == "${binary} ${expected}" ]] || {
    echo "${binary} ${expected} was not installed exactly." >&2
    exit 1
  }
}

ensure_cargo_tool cargo-deny cargo-deny 0.20.2
ensure_cargo_tool cargo-llvm-cov cargo-llvm-cov 0.9.0 llvm-cov

echo "Pinned Rust quality tools are installed."
