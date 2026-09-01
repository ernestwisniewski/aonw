#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="${repo_root}/engine/migration/reducer_fixture_dispositions"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --repo-root)
      repo_root="${2:?--repo-root requires a path}"
      shift 2
      ;;
    --manifest)
      manifest="${2:?--manifest requires a path}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 64
      ;;
  esac
done

if [[ "${manifest}" != /* ]]; then
  manifest="${repo_root}/${manifest}"
fi

fail() {
  echo "Rust fixture disposition check failed: $*" >&2
  exit 1
}

require_relative_file() {
  local relative_path="$1"
  [[ "${relative_path}" != /* ]] || fail "absolute path is forbidden: ${relative_path}"
  [[ "${relative_path}" != *".."* ]] || fail "parent traversal is forbidden: ${relative_path}"
  [[ -f "${repo_root}/${relative_path}" ]] || fail "file not found: ${relative_path}"
}

require_relative_directory() {
  local relative_path="$1"
  [[ "${relative_path}" != /* ]] || fail "absolute path is forbidden: ${relative_path}"
  [[ "${relative_path}" != *".."* ]] || fail "parent traversal is forbidden: ${relative_path}"
  [[ -d "${repo_root}/${relative_path}" ]] || fail "directory not found: ${relative_path}"
}

[[ -f "${manifest}" ]] || fail "manifest not found: ${manifest}"
command -v git >/dev/null || fail "git is required"
command -v rg >/dev/null || fail "rg is required"

scratch="$(mktemp -d "${TMPDIR:-/tmp}/aonw-fixture-dispositions.XXXXXX")"
cleanup() {
  rm -rf "${scratch}"
}
trap cleanup EXIT

case_ids="${scratch}/case.ids"
source_ids="${scratch}/source.ids"
canonical_paths="${scratch}/canonical.paths"
engine_commands="${scratch}/engine.commands"
inventory_engine_commands="${scratch}/inventory-engine.commands"
current_contract_families="${scratch}/current-contract.families"
historical_families="${scratch}/historical.families"
: >"${case_ids}"
: >"${canonical_paths}"
: >"${engine_commands}"
: >"${current_contract_families}"
: >"${historical_families}"

source_corpus=""
source_corpus_oid=""
canonical_corpus=""
authoritative_inventory=""
expected_case_count=""
expected_round_trip_count=""
expected_engine_parity_count=""
expected_blocked_count=""
expected_historical_count=""
case_count=0
round_trip_count=0
engine_parity_count=0
blocked_count=0
historical_count=0
line_number=0

while IFS= read -r raw_line || [[ -n "${raw_line}" ]]; do
  line_number=$((line_number + 1))
  line="${raw_line%%#*}"
  read -r -a fields <<<"${line}"
  [[ "${#fields[@]}" -gt 0 ]] || continue
  key="${fields[0]}"
  case "${key}" in
    source-corpus|source-corpus-oid|canonical-corpus|authoritative-inventory|expected-case-count|expected-round-trip-count|expected-engine-parity-count|expected-blocked-count|expected-historical-count)
      [[ "${#fields[@]}" -eq 2 ]] || fail "${manifest}:${line_number}: ${key} requires one value"
      value="${fields[1]}"
      case "${key}" in
        source-corpus) [[ -z "${source_corpus}" ]] || fail "duplicate source-corpus"; source_corpus="${value}" ;;
        source-corpus-oid) [[ -z "${source_corpus_oid}" ]] || fail "duplicate source-corpus-oid"; source_corpus_oid="${value}" ;;
        canonical-corpus) [[ -z "${canonical_corpus}" ]] || fail "duplicate canonical-corpus"; canonical_corpus="${value}" ;;
        authoritative-inventory) [[ -z "${authoritative_inventory}" ]] || fail "duplicate authoritative-inventory"; authoritative_inventory="${value}" ;;
        expected-case-count) [[ -z "${expected_case_count}" ]] || fail "duplicate expected-case-count"; expected_case_count="${value}" ;;
        expected-round-trip-count) [[ -z "${expected_round_trip_count}" ]] || fail "duplicate expected-round-trip-count"; expected_round_trip_count="${value}" ;;
        expected-engine-parity-count) [[ -z "${expected_engine_parity_count}" ]] || fail "duplicate expected-engine-parity-count"; expected_engine_parity_count="${value}" ;;
        expected-blocked-count) [[ -z "${expected_blocked_count}" ]] || fail "duplicate expected-blocked-count"; expected_blocked_count="${value}" ;;
        expected-historical-count) [[ -z "${expected_historical_count}" ]] || fail "duplicate expected-historical-count"; expected_historical_count="${value}" ;;
      esac
      ;;
    current-contract-evidence)
      [[ "${#fields[@]}" -eq 4 ]] || fail "${manifest}:${line_number}: current-contract-evidence requires family, engine test, and runtime test"
      family="${fields[1]}"
      [[ "${family}" =~ ^[a-z][a-z0-9-]*$ ]] || fail "invalid current-contract evidence family: ${family}"
      require_relative_file "${fields[2]}"
      require_relative_file "${fields[3]}"
      printf '%s\n' "${family}" >>"${current_contract_families}"
      ;;
    case)
      [[ "${#fields[@]}" -eq 11 ]] || fail "${manifest}:${line_number}: case requires ten values"
      id="${fields[1]}"
      family="${fields[2]}"
      command="${fields[3]}"
      oracle_outcome="${fields[4]}"
      oracle_reason="${fields[5]}"
      structural_status="${fields[6]}"
      execution_status="${fields[7]}"
      checkpoint="${fields[8]}"
      blocker="${fields[9]}"
      canonical_artifact="${fields[10]}"

      [[ "${id}" =~ ^[a-z][a-z0-9-]*$ ]] || fail "invalid case id: ${id}"
      [[ "${family}" =~ ^[a-z][a-z0-9-]*$ ]] || fail "invalid family for ${id}: ${family}"
      [[ "${command}" =~ ^[A-Z][A-Za-z0-9]*$ ]] || fail "invalid command for ${id}: ${command}"
      case "${oracle_outcome}" in
        accepted) [[ "${oracle_reason}" == "-" ]] || fail "accepted ${id} cannot have a rejection reason" ;;
        rejected) [[ "${oracle_reason}" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]] || fail "rejected ${id} requires a stable reason" ;;
        *) fail "invalid oracle outcome for ${id}: ${oracle_outcome}" ;;
      esac

      case "${structural_status}/${execution_status}" in
        round-trip/engine-parity)
          [[ "${checkpoint}" == "current" ]] || fail "engine-parity ${id} must use checkpoint current"
          [[ "${blocker}" == "-" ]] || fail "engine-parity ${id} cannot have a blocker"
          [[ "${canonical_artifact}" != "-" ]] || fail "engine-parity ${id} requires a canonical artifact"
          [[ "${canonical_artifact}" == "${canonical_corpus}/"* ]] || fail "canonical artifact for ${id} is outside ${canonical_corpus}"
          require_relative_file "${canonical_artifact}"
          [[ "$(basename "${canonical_artifact}" .json)" == "${id}" ]] || fail "canonical artifact filename differs from ${id}"
          printf '%s\n' "${canonical_artifact}" >>"${canonical_paths}"
          printf '%s\n' "${command}" >>"${engine_commands}"
          round_trip_count=$((round_trip_count + 1))
          engine_parity_count=$((engine_parity_count + 1))
          ;;
        blocked/reference-only)
          [[ "${checkpoint}" =~ ^CP[0-9]+$ ]] || fail "blocked ${id} requires a concrete CP checkpoint"
          case "${blocker}" in
            awaits-independent-current-contract-review|awaits-full-turn-pipeline) ;;
            *) fail "blocked ${id} requires a reviewed blocker" ;;
          esac
          if [[ "${blocker}" == "awaits-full-turn-pipeline" ]]; then
            [[ "${family}" == "turn-finalization" && "${checkpoint}" == "CP9" ]] || fail "full-turn blocker is reserved for CP9 turn-finalization"
          fi
          [[ "${canonical_artifact}" == "-" ]] || fail "blocked ${id} cannot claim a canonical artifact"
          blocked_count=$((blocked_count + 1))
          ;;
        historical/reference-only)
          [[ "${checkpoint}" == "current" ]] || fail "historical ${id} must use checkpoint current"
          [[ "${blocker}" == "superseded-by-current-contract" ]] || fail "historical ${id} requires the current-contract disposition"
          [[ "${canonical_artifact}" == "-" ]] || fail "historical ${id} cannot claim a canonical artifact"
          printf '%s\n' "${family}" >>"${historical_families}"
          historical_count=$((historical_count + 1))
          ;;
        *)
          fail "unsupported structural/execution status for ${id}: ${structural_status}/${execution_status}"
          ;;
      esac

      require_relative_file "${source_corpus}/${id}.json"
      printf '%s\n' "${id}" >>"${case_ids}"
      case_count=$((case_count + 1))
      ;;
    *)
      fail "${manifest}:${line_number}: unknown directive ${key}"
      ;;
  esac
done <"${manifest}"

for count_name in expected_case_count expected_round_trip_count expected_engine_parity_count expected_blocked_count expected_historical_count; do
  count_value="${!count_name}"
  [[ "${count_value}" =~ ^[0-9]+$ ]] || fail "${count_name//_/-} must be an integer"
done
[[ "${source_corpus_oid}" =~ ^[0-9a-f]{40}$ ]] || fail "source-corpus-oid must be a full Git blob OID"
require_relative_directory "${source_corpus}"
require_relative_directory "${canonical_corpus}"
require_relative_file "${authoritative_inventory}"

[[ "${case_count}" -eq "${expected_case_count}" ]] || fail "case count ${case_count}, expected ${expected_case_count}"
[[ "${round_trip_count}" -eq "${expected_round_trip_count}" ]] || fail "round-trip count ${round_trip_count}, expected ${expected_round_trip_count}"
[[ "${engine_parity_count}" -eq "${expected_engine_parity_count}" ]] || fail "engine-parity count ${engine_parity_count}, expected ${expected_engine_parity_count}"
[[ "${blocked_count}" -eq "${expected_blocked_count}" ]] || fail "blocked count ${blocked_count}, expected ${expected_blocked_count}"
[[ "${historical_count}" -eq "${expected_historical_count}" ]] || fail "historical count ${historical_count}, expected ${expected_historical_count}"
[[ $((round_trip_count + blocked_count + historical_count)) -eq "${case_count}" ]] || fail "every case must have round-trip evidence, an explicit blocker, or a reviewed historical disposition"

duplicates="$(sort "${case_ids}" | uniq -d)"
[[ -z "${duplicates}" ]] || fail "duplicate case id: ${duplicates}"
duplicates="$(sort "${canonical_paths}" | uniq -d)"
[[ -z "${duplicates}" ]] || fail "duplicate canonical artifact: ${duplicates}"
duplicates="$(sort "${current_contract_families}" | uniq -d)"
[[ -z "${duplicates}" ]] || fail "duplicate current-contract evidence family: ${duplicates}"

sort -u "${historical_families}" -o "${historical_families}"
sort -u "${current_contract_families}" -o "${current_contract_families}"
if ! cmp -s "${historical_families}" "${current_contract_families}"; then
  diff -u "${historical_families}" "${current_contract_families}" >&2 || true
  fail "historical family set differs from current-contract evidence"
fi

find "${repo_root}/${source_corpus}" -maxdepth 1 -type f -name '*.json' -print \
  | sed "s#^${repo_root}/${source_corpus}/##" \
  | sed 's/\.json$//' \
  | sort >"${source_ids}"
sort "${case_ids}" -o "${case_ids}"
if ! cmp -s "${case_ids}" "${source_ids}"; then
  diff -u "${case_ids}" "${source_ids}" >&2 || true
  fail "source fixture filename census differs from reviewed dispositions"
fi

source_files="${scratch}/source.files"
source_entries="${scratch}/source.entries"
find "${repo_root}/${source_corpus}" -maxdepth 1 -type f -name '*.json' -print | sort >"${source_files}"
: >"${source_entries}"
while IFS= read -r source_file; do
  blob_oid="$(git hash-object "${source_file}")"
  printf '%s %s\n' "${blob_oid}" "$(basename "${source_file}")" >>"${source_entries}"
done <"${source_files}"
actual_corpus_oid="$(git hash-object "${source_entries}")"
[[ "${actual_corpus_oid}" == "${source_corpus_oid}" ]] || fail "source corpus OID ${actual_corpus_oid}, expected ${source_corpus_oid}"

awk '
  $1 == "domain" && $4 == "engine-parity" && $5 != "-" { print $5 }
' "${repo_root}/${authoritative_inventory}" | sort -u >"${inventory_engine_commands}"
sort -u "${engine_commands}" -o "${engine_commands}"
if ! cmp -s "${engine_commands}" "${inventory_engine_commands}"; then
  diff -u "${engine_commands}" "${inventory_engine_commands}" >&2 || true
  fail "engine-parity command set differs from authoritative inventory"
fi

if rg -n -F "${source_corpus}" "${repo_root}/engine/crates" --glob '*.rs'; then
  fail "Rust crates may not read the historical reducer envelope"
fi

echo "Rust fixture dispositions are closed: ${case_count} reviewed, ${round_trip_count} round-trip/engine-parity, ${blocked_count} explicitly blocked, ${historical_count} superseded by current contracts."
