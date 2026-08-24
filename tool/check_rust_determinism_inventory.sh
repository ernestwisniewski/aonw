#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
inventory="${repo_root}/engine/migration/determinism_inventory"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --repo-root)
      repo_root="${2:?--repo-root requires a path}"
      shift 2
      ;;
    --inventory)
      inventory="${2:?--inventory requires a path}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 64
      ;;
  esac
done

if [[ "${inventory}" != /* ]]; then
  inventory="${repo_root}/${inventory}"
fi

fail() {
  echo "Rust determinism inventory check failed: $*" >&2
  exit 1
}

require_repo_file() {
  local relative_path="$1"
  [[ "${relative_path}" != /* ]] || fail "absolute source path is forbidden: ${relative_path}"
  [[ "${relative_path}" != *".."* ]] || fail "parent traversal is forbidden: ${relative_path}"
  [[ -f "${repo_root}/${relative_path}" ]] || fail "source file not found: ${relative_path}"
}

valid_status() {
  case "$1" in
    reference-only|characterized|engine-parity|runtime-ready|client-ready|shadow-ready|cutover) return 0 ;;
    *) return 1 ;;
  esac
}

[[ -f "${inventory}" ]] || fail "inventory not found: ${inventory}"
command -v rg >/dev/null || fail "rg is required"

scratch="$(mktemp -d "${TMPDIR:-/tmp}/aonw-rust-determinism.XXXXXX")"
cleanup() {
  rm -rf "${scratch}"
}
trap cleanup EXIT

randomness_ids="${scratch}/randomness.ids"
clock_ids="${scratch}/clock.ids"
rng_expected="${scratch}/rng.expected"
rng_actual="${scratch}/rng.actual"
clock_expected="${scratch}/clock.expected"
clock_actual="${scratch}/clock.actual"
: >"${randomness_ids}"
: >"${clock_ids}"
: >"${rng_expected}"
: >"${clock_expected}"

expected_randomness_count=""
expected_clock_count=""
randomness_count=0
clock_count=0
line_number=0

while IFS= read -r raw_line || [[ -n "${raw_line}" ]]; do
  line_number=$((line_number + 1))
  line="${raw_line%%#*}"
  read -r -a fields <<<"${line}"
  [[ "${#fields[@]}" -gt 0 ]] || continue
  key="${fields[0]}"
  case "${key}" in
    expected-randomness-count|expected-wall-clock-count)
      [[ "${#fields[@]}" -eq 2 ]] || fail "${inventory}:${line_number}: ${key} requires one value"
      [[ "${fields[1]}" =~ ^[0-9]+$ ]] || fail "${inventory}:${line_number}: ${key} must be an integer"
      if [[ "${key}" == "expected-randomness-count" ]]; then
        [[ -z "${expected_randomness_count}" ]] || fail "duplicate expected-randomness-count"
        expected_randomness_count="${fields[1]}"
      else
        [[ -z "${expected_clock_count}" ]] || fail "duplicate expected-wall-clock-count"
        expected_clock_count="${fields[1]}"
      fi
      ;;
    randomness)
      [[ "${#fields[@]}" -eq 10 ]] || fail "${inventory}:${line_number}: randomness requires nine values"
      id="${fields[1]}"
      kind="${fields[2]}"
      algorithm="${fields[3]}"
      inputs="${fields[4]}"
      evidence="${fields[5]}"
      status="${fields[6]}"
      rust_symbol="${fields[7]}"
      source_path="${fields[8]}"
      source_symbol="${fields[9]}"
      [[ "${id}" =~ ^[a-z][a-z0-9-]*$ ]] || fail "invalid randomness id: ${id}"
      case "${kind}" in rng-class|seed-derivation|selector) ;; *) fail "invalid randomness kind for ${id}: ${kind}" ;; esac
      [[ "${algorithm}" =~ ^[a-z0-9][a-z0-9+-]*$ ]] || fail "invalid algorithm for ${id}: ${algorithm}"
      [[ "${inputs}" =~ ^[a-z0-9][a-z0-9+-]*$ ]] || fail "invalid inputs for ${id}: ${inputs}"
      [[ "${evidence}" =~ ^[a-z0-9][a-z0-9+-]*$ ]] || fail "invalid evidence for ${id}: ${evidence}"
      if [[ "${kind}" == "rng-class" ]]; then
        [[ "${evidence}" == *"ordered-"* ]] || fail "RNG evidence for ${id} must expose ordered draws, rolls, or jitters"
      fi
      valid_status "${status}" || fail "invalid status for ${id}: ${status}"
      [[ "${source_symbol}" =~ ^[A-Za-z_][A-Za-z0-9_.]*$ ]] || fail "invalid source symbol for ${id}: ${source_symbol}"
      require_repo_file "${source_path}"
      grep -Fq -- "${source_symbol}" "${repo_root}/${source_path}" || fail "source symbol not found for ${id}: ${source_symbol}"
      if [[ "${status}" == "reference-only" ]]; then
        [[ "${rust_symbol}" == "-" ]] || fail "reference-only ${id} cannot claim a Rust symbol"
      else
        [[ "${rust_symbol}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "Rust-backed ${id} requires a Rust symbol"
        rg -q "(struct|enum|fn)[[:space:]]+${rust_symbol}([[:space:]<{(;]|$)" \
          "${repo_root}/engine/crates" --glob '*.rs' || \
          fail "Rust symbol not found for ${id}: ${rust_symbol}"
      fi
      printf '%s\n' "${id}" >>"${randomness_ids}"
      if [[ "${kind}" == "rng-class" ]]; then
        printf '%s %s\n' "${source_symbol}" "${source_path}" >>"${rng_expected}"
      fi
      randomness_count=$((randomness_count + 1))
      ;;
    wall-clock)
      [[ "${#fields[@]}" -eq 7 ]] || fail "${inventory}:${line_number}: wall-clock requires six values"
      id="${fields[1]}"
      usage="${fields[2]}"
      status="${fields[3]}"
      rust_symbol="${fields[4]}"
      source_path="${fields[5]}"
      source_symbol="${fields[6]}"
      [[ "${id}" =~ ^[a-z][a-z0-9-]*$ ]] || fail "invalid wall-clock id: ${id}"
      [[ "${usage}" =~ ^[a-z][a-z0-9-]*$ ]] || fail "invalid usage for ${id}: ${usage}"
      valid_status "${status}" || fail "invalid status for ${id}: ${status}"
      require_repo_file "${source_path}"
      grep -Fq -- "${source_symbol}" "${repo_root}/${source_path}" || fail "source symbol not found for ${id}: ${source_symbol}"
      if [[ "${status}" == "reference-only" ]]; then
        [[ "${rust_symbol}" == "-" ]] || fail "reference-only ${id} cannot claim a Rust symbol"
      else
        [[ "${rust_symbol}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "Rust-backed ${id} requires a Rust symbol"
      fi
      printf '%s\n' "${id}" >>"${clock_ids}"
      printf '%s %s\n' "${source_symbol}" "${source_path}" >>"${clock_expected}"
      clock_count=$((clock_count + 1))
      ;;
    *)
      fail "${inventory}:${line_number}: unknown directive ${key}"
      ;;
  esac
done <"${inventory}"

[[ -n "${expected_randomness_count}" ]] || fail "missing expected-randomness-count"
[[ -n "${expected_clock_count}" ]] || fail "missing expected-wall-clock-count"
[[ "${randomness_count}" -eq "${expected_randomness_count}" ]] || fail "randomness count ${randomness_count}, expected ${expected_randomness_count}"
[[ "${clock_count}" -eq "${expected_clock_count}" ]] || fail "wall-clock count ${clock_count}, expected ${expected_clock_count}"
[[ -z "$(sort "${randomness_ids}" | uniq -d)" ]] || fail "duplicate randomness id"
[[ -z "$(sort "${clock_ids}" | uniq -d)" ]] || fail "duplicate wall-clock id"

dart_root="${repo_root}/packages/aonw_core/lib"
[[ -d "${dart_root}" ]] || fail "Dart oracle root not found: packages/aonw_core/lib"
rg -n --no-heading '^(abstract final class|final class|class) [A-Za-z_][A-Za-z0-9_]*Rng[[:space:]]*\{' "${dart_root}" --glob '*.dart' \
  | sed -E 's#^([^:]+):[0-9]+:(abstract final class|final class|class) ([A-Za-z_][A-Za-z0-9_]*Rng).*#\3 \1#' \
  | sed "s# ${repo_root}/# #" \
  | sort >"${rng_actual}"
sort "${rng_expected}" -o "${rng_expected}"
cmp -s "${rng_expected}" "${rng_actual}" || {
  diff -u "${rng_expected}" "${rng_actual}" >&2 || true
  fail "Dart RNG class census drifted"
}

rg -n --no-heading 'DateTime\.now' "${dart_root}" --glob '*.dart' \
  | sed -E 's#^([^:]+):[0-9]+:.*#DateTime.now \1#' \
  | sed "s# ${repo_root}/# #" \
  | sort >"${clock_actual}"
sort "${clock_expected}" -o "${clock_expected}"
cmp -s "${clock_expected}" "${clock_actual}" || {
  diff -u "${clock_expected}" "${clock_actual}" >&2 || true
  fail "Dart wall-clock census drifted"
}

for pure_root in \
  "${repo_root}/engine/crates/aonw_domain/src" \
  "${repo_root}/engine/crates/aonw_engine/src" \
  "${repo_root}/engine/crates/aonw_contract_mapping/src"; do
  [[ -d "${pure_root}" ]] || fail "pure Rust source root not found: ${pure_root#${repo_root}/}"
  if rg -n 'SystemTime|Instant::now|Utc::now|Local::now|thread_rng|rand::|getrandom' "${pure_root}"; then
    fail "production Rust engine code reads nondeterministic time or randomness"
  fi
done

for persistence_root in \
  "${repo_root}/engine/crates/aonw_contracts/src/persistence.rs" \
  "${repo_root}/engine/crates/aonw_local_runtime/src"; do
  [[ -e "${persistence_root}" ]] || fail "persistence source not found: ${persistence_root#${repo_root}/}"
  if rg -n 'RngStateDto|initial_rng_state|rng_state|pub struct RngState' "${persistence_root}"; then
    fail "generic RNG state is forbidden; record named capability evidence instead"
  fi
done

echo "Rust determinism inventory check passed (${randomness_count} randomness sources, ${clock_count} wall-clock reads)."
