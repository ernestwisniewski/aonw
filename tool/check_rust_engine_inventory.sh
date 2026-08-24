#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="${repo_root}/engine/migration/authoritative_inventory"

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
  echo "Rust engine inventory check failed: $*" >&2
  exit 1
}

require_repo_file() {
  local relative_path="$1"
  [[ "${relative_path}" != /* ]] || fail "absolute source path is forbidden: ${relative_path}"
  [[ "${relative_path}" != *".."* ]] || fail "parent traversal is forbidden: ${relative_path}"
  [[ -f "${repo_root}/${relative_path}" ]] || fail "source file not found: ${relative_path}"
}

[[ -f "${manifest}" ]] || fail "manifest not found: ${manifest}"

scratch="$(mktemp -d "${TMPDIR:-/tmp}/aonw-rust-inventory.XXXXXX")"
cleanup() {
  rm -rf "${scratch}"
}
trap cleanup EXIT

domain_expected="${scratch}/domain.expected"
system_expected="${scratch}/system.expected"
rust_domain_expected="${scratch}/rust-domain.expected"
rust_system_expected="${scratch}/rust-system.expected"
query_expected="${scratch}/query.expected"
query_result_expected="${scratch}/query-result.expected"
client_query_result_expected="${scratch}/client-query-result.expected"
event_expected="${scratch}/event.expected"
rust_event_expected="${scratch}/rust-event.expected"
evidence_expected="${scratch}/evidence.expected"
rust_evidence_expected="${scratch}/rust-evidence.expected"
native_evidence_expected="${scratch}/native-evidence.expected"
native_event_expected="${scratch}/native-event.expected"
projection_type_expected="${scratch}/projection-type.expected"
projection_variant_expected="${scratch}/projection-variant.expected"
projection_dto_variant_expected="${scratch}/projection-dto-variant.expected"
: >"${domain_expected}"
: >"${system_expected}"
: >"${rust_domain_expected}"
: >"${rust_system_expected}"
: >"${query_expected}"
: >"${query_result_expected}"
: >"${client_query_result_expected}"
: >"${event_expected}"
: >"${rust_event_expected}"
: >"${evidence_expected}"
: >"${rust_evidence_expected}"
: >"${native_evidence_expected}"
: >"${native_event_expected}"
: >"${projection_type_expected}"
: >"${projection_variant_expected}"
: >"${projection_dto_variant_expected}"

oracle_tree=""
expected_domain_count=""
expected_system_count=""
expected_query_count=""
expected_event_count=""
expected_native_event_count=""
expected_evidence_count=""
expected_native_evidence_count=""
expected_projection_type_count=""
expected_projection_variant_count=""
dart_domain_root=""
dart_system_source=""
dart_event_root=""
dart_evidence_source=""
rust_domain_source=""
rust_system_source=""
rust_query_source=""
rust_event_source=""
rust_evidence_source=""
rust_persistence_source=""
rust_client_command_source=""
rust_client_event_source=""
rust_client_response_source=""
rust_projection_source=""
partial_parity_mode=""
line_number=0

valid_status() {
  case "$1" in
    reference-only|characterized|state-contract-ready|turn-kernel-ready|engine-parity|runtime-ready|client-ready|shadow-ready|cutover) return 0 ;;
    *) return 1 ;;
  esac
}

requires_full_state_parity() {
  case "$1" in
    engine-parity|runtime-ready|client-ready|shadow-ready|cutover) return 0 ;;
    *) return 1 ;;
  esac
}

while IFS= read -r raw_line || [[ -n "${raw_line}" ]]; do
  line_number=$((line_number + 1))
  line="${raw_line%%#*}"
  read -r -a fields <<<"${line}"
  [[ "${#fields[@]}" -gt 0 ]] || continue
  key="${fields[0]}"
  case "${key}" in
    oracle-tree|expected-domain-count|expected-system-count|expected-query-count|expected-event-count|expected-native-event-count|expected-evidence-count|expected-native-evidence-count|expected-projection-type-count|expected-projection-variant-count|dart-domain-root|dart-system-source|dart-event-root|dart-evidence-source|rust-domain-source|rust-system-source|rust-query-source|rust-event-source|rust-evidence-source|rust-persistence-source|rust-client-command-source|rust-client-event-source|rust-client-response-source|rust-projection-source|partial-parity-mode)
      [[ "${#fields[@]}" -eq 2 ]] || fail "${manifest}:${line_number}: ${key} requires exactly one value"
      value="${fields[1]}"
      case "${key}" in
        oracle-tree) [[ -z "${oracle_tree}" ]] || fail "duplicate oracle-tree"; oracle_tree="${value}" ;;
        expected-domain-count) [[ -z "${expected_domain_count}" ]] || fail "duplicate expected-domain-count"; expected_domain_count="${value}" ;;
        expected-system-count) [[ -z "${expected_system_count}" ]] || fail "duplicate expected-system-count"; expected_system_count="${value}" ;;
        expected-query-count) [[ -z "${expected_query_count}" ]] || fail "duplicate expected-query-count"; expected_query_count="${value}" ;;
        expected-event-count) [[ -z "${expected_event_count}" ]] || fail "duplicate expected-event-count"; expected_event_count="${value}" ;;
        expected-native-event-count) [[ -z "${expected_native_event_count}" ]] || fail "duplicate expected-native-event-count"; expected_native_event_count="${value}" ;;
        expected-evidence-count) [[ -z "${expected_evidence_count}" ]] || fail "duplicate expected-evidence-count"; expected_evidence_count="${value}" ;;
        expected-native-evidence-count) [[ -z "${expected_native_evidence_count}" ]] || fail "duplicate expected-native-evidence-count"; expected_native_evidence_count="${value}" ;;
        expected-projection-type-count) [[ -z "${expected_projection_type_count}" ]] || fail "duplicate expected-projection-type-count"; expected_projection_type_count="${value}" ;;
        expected-projection-variant-count) [[ -z "${expected_projection_variant_count}" ]] || fail "duplicate expected-projection-variant-count"; expected_projection_variant_count="${value}" ;;
        dart-domain-root) [[ -z "${dart_domain_root}" ]] || fail "duplicate dart-domain-root"; dart_domain_root="${value}" ;;
        dart-system-source) [[ -z "${dart_system_source}" ]] || fail "duplicate dart-system-source"; dart_system_source="${value}" ;;
        dart-event-root) [[ -z "${dart_event_root}" ]] || fail "duplicate dart-event-root"; dart_event_root="${value}" ;;
        dart-evidence-source) [[ -z "${dart_evidence_source}" ]] || fail "duplicate dart-evidence-source"; dart_evidence_source="${value}" ;;
        rust-domain-source) [[ -z "${rust_domain_source}" ]] || fail "duplicate rust-domain-source"; rust_domain_source="${value}" ;;
        rust-system-source) [[ -z "${rust_system_source}" ]] || fail "duplicate rust-system-source"; rust_system_source="${value}" ;;
        rust-query-source) [[ -z "${rust_query_source}" ]] || fail "duplicate rust-query-source"; rust_query_source="${value}" ;;
        rust-event-source) [[ -z "${rust_event_source}" ]] || fail "duplicate rust-event-source"; rust_event_source="${value}" ;;
        rust-evidence-source) [[ -z "${rust_evidence_source}" ]] || fail "duplicate rust-evidence-source"; rust_evidence_source="${value}" ;;
        rust-persistence-source) [[ -z "${rust_persistence_source}" ]] || fail "duplicate rust-persistence-source"; rust_persistence_source="${value}" ;;
        rust-client-command-source) [[ -z "${rust_client_command_source}" ]] || fail "duplicate rust-client-command-source"; rust_client_command_source="${value}" ;;
        rust-client-event-source) [[ -z "${rust_client_event_source}" ]] || fail "duplicate rust-client-event-source"; rust_client_event_source="${value}" ;;
        rust-client-response-source) [[ -z "${rust_client_response_source}" ]] || fail "duplicate rust-client-response-source"; rust_client_response_source="${value}" ;;
        rust-projection-source) [[ -z "${rust_projection_source}" ]] || fail "duplicate rust-projection-source"; rust_projection_source="${value}" ;;
        partial-parity-mode) [[ -z "${partial_parity_mode}" ]] || fail "duplicate partial-parity-mode"; partial_parity_mode="${value}" ;;
      esac
      ;;
    domain|system)
      [[ "${#fields[@]}" -eq 6 ]] || fail "${manifest}:${line_number}: ${key} entry requires five values"
      type_name="${fields[1]}"
      family="${fields[2]}"
      status="${fields[3]}"
      rust_variant="${fields[4]}"
      source_path="${fields[5]}"
      [[ "${type_name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "invalid Dart type: ${type_name}"
      [[ "${family}" =~ ^[a-z][a-z0-9-]*$ ]] || fail "invalid family: ${family}"
      valid_status "${status}" || fail "invalid status for ${type_name}: ${status}"
      require_repo_file "${source_path}"
      if [[ "${rust_variant}" != "-" ]]; then
        [[ "${rust_variant}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "invalid Rust variant: ${rust_variant}"
        [[ "${status}" != "reference-only" ]] || fail "Rust-backed ${type_name} cannot remain reference-only"
      elif requires_full_state_parity "${status}"; then
        fail "${type_name} cannot be ${status} without a Rust variant"
      fi
      if [[ "${partial_parity_mode}" == "opaque-splice" ]] && requires_full_state_parity "${status}"; then
        fail "${type_name} cannot be ${status} while parity preserves opaque state"
      fi
      if [[ "${key}" == "domain" ]]; then
        printf '%s %s\n' "${type_name}" "${source_path}" >>"${domain_expected}"
        [[ "${rust_variant}" == "-" ]] || printf '%s\n' "${rust_variant}" >>"${rust_domain_expected}"
      else
        printf '%s %s\n' "${type_name}" "${source_path}" >>"${system_expected}"
        [[ "${rust_variant}" == "-" ]] || printf '%s\n' "${rust_variant}" >>"${rust_system_expected}"
      fi
      ;;
    native-event|native-evidence)
      [[ "${#fields[@]}" -eq 6 ]] || fail "${manifest}:${line_number}: ${key} entry requires five values"
      rust_type="${fields[1]}"
      family="${fields[2]}"
      status="${fields[3]}"
      rust_variant="${fields[4]}"
      source_path="${fields[5]}"
      [[ "${rust_type}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "invalid ${key} type: ${rust_type}"
      [[ "${family}" =~ ^[a-z][a-z0-9-]*$ ]] || fail "invalid ${key} family: ${family}"
      valid_status "${status}" || fail "invalid status for ${key} ${rust_type}: ${status}"
      [[ "${status}" != "reference-only" ]] || fail "${key} ${rust_type} cannot be reference-only"
      [[ "${rust_variant}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "invalid ${key} variant: ${rust_variant}"
      require_repo_file "${source_path}"
      if [[ "${key}" == "native-event" ]]; then
        printf '%s %s\n' "${rust_type}" "${source_path}" >>"${native_event_expected}"
        printf '%s\n' "${rust_variant}" >>"${rust_event_expected}"
      else
        printf '%s %s\n' "${rust_type}" "${source_path}" >>"${native_evidence_expected}"
        printf '%s\n' "${rust_variant}" >>"${rust_evidence_expected}"
      fi
      ;;
    query)
      [[ "${#fields[@]}" -eq 6 ]] || fail "${manifest}:${line_number}: query entry requires five values"
      query_variant="${fields[1]}"
      result_variant="${fields[2]}"
      client_result_variant="${fields[3]}"
      family="${fields[4]}"
      status="${fields[5]}"
      for variant in "${query_variant}" "${result_variant}" "${client_result_variant}"; do
        [[ "${variant}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "invalid query variant: ${variant}"
      done
      [[ "${family}" =~ ^[a-z][a-z0-9-]*$ ]] || fail "invalid query family: ${family}"
      valid_status "${status}" || fail "invalid status for query ${query_variant}: ${status}"
      printf '%s\n' "${query_variant}" >>"${query_expected}"
      printf '%s\n' "${result_variant}" >>"${query_result_expected}"
      printf '%s\n' "${client_result_variant}" >>"${client_query_result_expected}"
      ;;
    event|evidence)
      [[ "${#fields[@]}" -eq 6 ]] || fail "${manifest}:${line_number}: ${key} entry requires five values"
      dart_type="${fields[1]}"
      family="${fields[2]}"
      status="${fields[3]}"
      rust_variant="${fields[4]}"
      source_path="${fields[5]}"
      [[ "${dart_type}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "invalid Dart ${key} type: ${dart_type}"
      [[ "${family}" =~ ^[a-z][a-z0-9-]*$ ]] || fail "invalid ${key} family: ${family}"
      valid_status "${status}" || fail "invalid status for ${dart_type}: ${status}"
      require_repo_file "${source_path}"
      if [[ "${rust_variant}" != "-" ]]; then
        [[ "${rust_variant}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "invalid Rust ${key} variant: ${rust_variant}"
        [[ "${status}" != "reference-only" ]] || fail "Rust-backed ${dart_type} cannot remain reference-only"
      elif [[ "${key}" == "evidence" ]]; then
        fail "${dart_type} evidence requires a Rust variant"
      fi
      if [[ "${key}" == "event" ]]; then
        printf '%s %s\n' "${dart_type}" "${source_path}" >>"${event_expected}"
        [[ "${rust_variant}" == "-" ]] || printf '%s\n' "${rust_variant}" >>"${rust_event_expected}"
      else
        printf '%s %s\n' "${dart_type}" "${source_path}" >>"${evidence_expected}"
        printf '%s\n' "${rust_variant}" >>"${rust_evidence_expected}"
      fi
      ;;
    projection-type)
      [[ "${#fields[@]}" -eq 6 ]] || fail "${manifest}:${line_number}: projection-type entry requires five values"
      rust_type="${fields[1]}"
      kind="${fields[2]}"
      status="${fields[3]}"
      dto_type="${fields[4]}"
      source_path="${fields[5]}"
      [[ "${rust_type}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "invalid projection type: ${rust_type}"
      [[ "${dto_type}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "invalid projection DTO type: ${dto_type}"
      [[ "${kind}" =~ ^[a-z][a-z0-9-]*$ ]] || fail "invalid projection kind: ${kind}"
      valid_status "${status}" || fail "invalid status for projection ${rust_type}: ${status}"
      require_repo_file "${source_path}"
      printf '%s %s %s\n' "${rust_type}" "${dto_type}" "${source_path}" >>"${projection_type_expected}"
      ;;
    projection-variant)
      [[ "${#fields[@]}" -eq 5 ]] || fail "${manifest}:${line_number}: projection-variant entry requires four values"
      rust_variant="${fields[1]}"
      kind="${fields[2]}"
      status="${fields[3]}"
      dto_variant="${fields[4]}"
      [[ "${rust_variant}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "invalid projection variant: ${rust_variant}"
      [[ "${dto_variant}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "invalid projection DTO variant: ${dto_variant}"
      [[ "${kind}" == "pending-action" ]] || fail "unsupported projection variant kind: ${kind}"
      valid_status "${status}" || fail "invalid status for projection ${rust_variant}: ${status}"
      printf '%s\n' "${rust_variant}" >>"${projection_variant_expected}"
      printf '%s\n' "${dto_variant}" >>"${projection_dto_variant_expected}"
      ;;
    *) fail "${manifest}:${line_number}: unknown record: ${key}" ;;
  esac
done <"${manifest}"

[[ "${oracle_tree}" =~ ^[0-9a-f]{40}$ ]] || fail "oracle-tree must be a full Git tree OID"
[[ "${expected_domain_count}" =~ ^[0-9]+$ ]] || fail "expected-domain-count must be an integer"
[[ "${expected_system_count}" =~ ^[0-9]+$ ]] || fail "expected-system-count must be an integer"
[[ "${expected_query_count}" =~ ^[0-9]+$ ]] || fail "expected-query-count must be an integer"
[[ "${expected_event_count}" =~ ^[0-9]+$ ]] || fail "expected-event-count must be an integer"
[[ "${expected_native_event_count}" =~ ^[0-9]+$ ]] || fail "expected-native-event-count must be an integer"
[[ "${expected_evidence_count}" =~ ^[0-9]+$ ]] || fail "expected-evidence-count must be an integer"
[[ "${expected_native_evidence_count}" =~ ^[0-9]+$ ]] || fail "expected-native-evidence-count must be an integer"
[[ "${expected_projection_type_count}" =~ ^[0-9]+$ ]] || fail "expected-projection-type-count must be an integer"
[[ "${expected_projection_variant_count}" =~ ^[0-9]+$ ]] || fail "expected-projection-variant-count must be an integer"
[[ "${partial_parity_mode}" == "opaque-splice" || "${partial_parity_mode}" == "full-state" ]] || fail "invalid partial-parity-mode"
require_repo_file "${dart_domain_root}"
require_repo_file "${dart_system_source}"
require_repo_file "${dart_event_root}"
require_repo_file "${dart_evidence_source}"
require_repo_file "${rust_domain_source}"
if [[ "${rust_system_source}" != "-" ]]; then
  require_repo_file "${rust_system_source}"
fi
require_repo_file "${rust_query_source}"
require_repo_file "${rust_event_source}"
require_repo_file "${rust_evidence_source}"
require_repo_file "${rust_persistence_source}"
require_repo_file "${rust_client_command_source}"
require_repo_file "${rust_client_event_source}"
require_repo_file "${rust_client_response_source}"
require_repo_file "${rust_projection_source}"

assert_no_duplicates() {
  local source_file="$1"
  local label="$2"
  local duplicates_file="${scratch}/${label}.duplicates"
  cut -d' ' -f1 "${source_file}" | sort | uniq -d >"${duplicates_file}"
  [[ ! -s "${duplicates_file}" ]] || {
    sed 's/^/  /' "${duplicates_file}" >&2
    fail "duplicate ${label} entries"
  }
}

assert_no_duplicates "${domain_expected}" "domain"
assert_no_duplicates "${system_expected}" "system"
assert_no_duplicates "${rust_domain_expected}" "rust-domain"
assert_no_duplicates "${rust_system_expected}" "rust-system"
assert_no_duplicates "${query_expected}" "query"
assert_no_duplicates "${query_result_expected}" "query-result"
assert_no_duplicates "${client_query_result_expected}" "client-query-result"
assert_no_duplicates "${event_expected}" "event"
assert_no_duplicates "${native_event_expected}" "native-event"
assert_no_duplicates "${rust_event_expected}" "rust-event"
assert_no_duplicates "${evidence_expected}" "evidence"
assert_no_duplicates "${rust_evidence_expected}" "rust-evidence"
assert_no_duplicates "${native_evidence_expected}" "native-evidence"
assert_no_duplicates "${projection_type_expected}" "projection-type"
assert_no_duplicates "${projection_variant_expected}" "projection-variant"
assert_no_duplicates "${projection_dto_variant_expected}" "projection-dto-variant"

actual_domain_count="$(wc -l <"${domain_expected}" | tr -d ' ')"
actual_system_count="$(wc -l <"${system_expected}" | tr -d ' ')"
actual_query_count="$(wc -l <"${query_expected}" | tr -d ' ')"
actual_event_count="$(wc -l <"${event_expected}" | tr -d ' ')"
actual_native_event_count="$(wc -l <"${native_event_expected}" | tr -d ' ')"
actual_evidence_count="$(wc -l <"${evidence_expected}" | tr -d ' ')"
actual_native_evidence_count="$(wc -l <"${native_evidence_expected}" | tr -d ' ')"
actual_projection_type_count="$(wc -l <"${projection_type_expected}" | tr -d ' ')"
actual_projection_variant_count="$(wc -l <"${projection_variant_expected}" | tr -d ' ')"
[[ "${actual_domain_count}" == "${expected_domain_count}" ]] || fail "manifest has ${actual_domain_count} domain commands, expected ${expected_domain_count}"
[[ "${actual_system_count}" == "${expected_system_count}" ]] || fail "manifest has ${actual_system_count} system commands, expected ${expected_system_count}"
[[ "${actual_query_count}" == "${expected_query_count}" ]] || fail "manifest has ${actual_query_count} queries, expected ${expected_query_count}"
[[ "${actual_event_count}" == "${expected_event_count}" ]] || fail "manifest has ${actual_event_count} events, expected ${expected_event_count}"
[[ "${actual_native_event_count}" == "${expected_native_event_count}" ]] || fail "manifest has ${actual_native_event_count} native events, expected ${expected_native_event_count}"
[[ "${actual_evidence_count}" == "${expected_evidence_count}" ]] || fail "manifest has ${actual_evidence_count} evidence types, expected ${expected_evidence_count}"
[[ "${actual_native_evidence_count}" == "${expected_native_evidence_count}" ]] || fail "manifest has ${actual_native_evidence_count} native evidence types, expected ${expected_native_evidence_count}"
[[ "${actual_projection_type_count}" == "${expected_projection_type_count}" ]] || fail "manifest has ${actual_projection_type_count} projection types, expected ${expected_projection_type_count}"
[[ "${actual_projection_variant_count}" == "${expected_projection_variant_count}" ]] || fail "manifest has ${actual_projection_variant_count} projection variants, expected ${expected_projection_variant_count}"

census_dart_subclasses() {
  local root_path="$1"
  local base_type="$2"
  local output_file="$3"
  local source_list="${scratch}/${base_type}.sources"
  local declarations="${scratch}/${base_type}.declarations"
  local root_dir
  root_dir="$(dirname "${root_path}")"
  printf '%s\n' "${root_path}" >"${source_list}"
  sed -nE "s/^[[:space:]]*part[[:space:]]+'([^']+)';[[:space:]]*$/\1/p" "${repo_root}/${root_path}" |
    while IFS= read -r part_path; do
      printf '%s/%s\n' "${root_dir}" "${part_path}"
    done >>"${source_list}"

  : >"${declarations}"
  while IFS= read -r source_path; do
    require_repo_file "${source_path}"
    while IFS= read -r source_line || [[ -n "${source_line}" ]]; do
      if [[ "${source_line}" =~ ^[[:space:]]*((final|sealed|abstract|base)[[:space:]]+)*class[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)([[:space:]]+extends[[:space:]]+([A-Za-z_][A-Za-z0-9_]*))? ]]; then
        class_name="${BASH_REMATCH[3]}"
        parent_name="${BASH_REMATCH[5]:--}"
        class_kind="nonfinal"
        if [[ "${source_line}" =~ ^[[:space:]]*final[[:space:]]+class[[:space:]] ]]; then
          class_kind="final"
        fi
        printf '%s %s %s %s\n' "${class_name}" "${parent_name}" "${class_kind}" "${source_path}" >>"${declarations}"
      fi
    done <"${repo_root}/${source_path}"
  done <"${source_list}"

  awk -v base="${base_type}" '
    {
      parent[$1] = $2
      kind[$1] = $3
      source[$1] = $4
      names[++count] = $1
    }
    END {
      for (row_index = 1; row_index <= count; row_index++) {
        name = names[row_index]
        if (kind[name] != "final") continue
        current = name
        for (depth = 0; depth <= count; depth++) {
          if (!(current in parent) || parent[current] == "-") break
          if (parent[current] == base) {
            print name, source[name]
            break
          }
          current = parent[current]
        }
      }
    }
  ' "${declarations}" | sort >"${output_file}"
}

census_rust_enum() {
  local source_path="$1"
  local enum_name="$2"
  local output_file="$3"
  awk -v enum_name="${enum_name}" '
    $0 ~ "^[[:space:]]*pub enum " enum_name "([[:space:]]|<)" {
      inside = 1
      next
    }
    inside && $0 ~ /^}/ { exit }
    inside {
      line = $0
      sub(/^[[:space:]]*/, "", line)
      if (match(line, /^[A-Z][A-Za-z0-9_]*/)) {
        name = substr(line, RSTART, RLENGTH)
        rest = substr(line, RLENGTH + 1)
        sub(/^[[:space:]]*/, "", rest)
        if (rest ~ /^[({,]/) print name
      }
    }
  ' "${repo_root}/${source_path}" | sort >"${output_file}"
}

require_dart_class() {
  local source_path="$1"
  local type_name="$2"
  awk -v type_name="${type_name}" '
    $0 ~ "^[[:space:]]*((final|sealed|abstract|base)[[:space:]]+)*class[[:space:]]+" type_name "([[:space:]]|$)" { found = 1 }
    END { exit found ? 0 : 1 }
  ' "${repo_root}/${source_path}" || fail "Dart class ${type_name} missing from ${source_path}"
}

require_rust_type() {
  local source_path="$1"
  local type_name="$2"
  awk -v type_name="${type_name}" '
    $0 ~ "^[[:space:]]*pub (struct|enum)[[:space:]]+" type_name "([[:space:]<{]|$)" { found = 1 }
    END { exit found ? 0 : 1 }
  ' "${repo_root}/${source_path}" || fail "Rust type ${type_name} missing from ${source_path}"
}

domain_actual="${scratch}/domain.actual"
system_actual="${scratch}/system.actual"
rust_domain_actual="${scratch}/rust-domain.actual"
rust_system_actual="${scratch}/rust-system.actual"
client_command_actual="${scratch}/client-command.actual"
query_actual="${scratch}/query.actual"
query_result_actual="${scratch}/query-result.actual"
client_query_result_actual="${scratch}/client-query-result.actual"
event_actual="${scratch}/event.actual"
rust_event_actual="${scratch}/rust-event.actual"
replay_event_actual="${scratch}/replay-event.actual"
client_event_actual="${scratch}/client-event.actual"
rust_evidence_actual="${scratch}/rust-evidence.actual"
replay_evidence_actual="${scratch}/replay-evidence.actual"
client_evidence_actual="${scratch}/client-evidence.actual"
projection_variant_actual="${scratch}/projection-variant.actual"
projection_dto_variant_actual="${scratch}/projection-dto-variant.actual"

census_dart_subclasses "${dart_domain_root}" "DomainCommand" "${domain_actual}"
census_dart_subclasses "${dart_system_source}" "SystemCommand" "${system_actual}"
census_dart_subclasses "${dart_event_root}" "DomainEvent" "${event_actual}"
census_rust_enum "${rust_domain_source}" "PlayerCommand" "${rust_domain_actual}"
census_rust_enum "${rust_client_command_source}" "ClientCommandDto" "${client_command_actual}"
if [[ "${rust_system_source}" == "-" ]]; then
  : >"${rust_system_actual}"
else
  census_rust_enum "${rust_system_source}" "SystemCommand" "${rust_system_actual}"
fi
census_rust_enum "${rust_query_source}" "GameQuery" "${query_actual}"
census_rust_enum "${rust_query_source}" "QueryResult" "${query_result_actual}"
census_rust_enum "${rust_client_response_source}" "ClientQueryResultDto" "${client_query_result_actual}"
census_rust_enum "${rust_event_source}" "DomainEvent" "${rust_event_actual}"
census_rust_enum "${rust_persistence_source}" "ReplayEventDto" "${replay_event_actual}"
census_rust_enum "${rust_client_event_source}" "ClientEventDto" "${client_event_actual}"
census_rust_enum "${rust_evidence_source}" "ExecutionEvidence" "${rust_evidence_actual}"
census_rust_enum "${rust_persistence_source}" "ReplayEvidenceDto" "${replay_evidence_actual}"
census_rust_enum "${rust_client_response_source}" "ClientEvidenceDto" "${client_evidence_actual}"
census_rust_enum "${rust_projection_source}" "PendingActionView" "${projection_variant_actual}"
census_rust_enum "${rust_client_response_source}" "PendingActionViewDto" "${projection_dto_variant_actual}"

while read -r type_name source_path; do
  require_dart_class "${source_path}" "${type_name}"
done <"${evidence_expected}"

while read -r rust_type source_path; do
  require_rust_type "${source_path}" "${rust_type}"
done <"${native_event_expected}"

while read -r rust_type source_path; do
  require_rust_type "${source_path}" "${rust_type}"
done <"${native_evidence_expected}"

while read -r rust_type dto_type source_path; do
  require_rust_type "${source_path}" "${rust_type}"
  require_rust_type "${rust_client_response_source}" "${dto_type}"
done <"${projection_type_expected}"

compare_inventory() {
  local expected_file="$1"
  local actual_file="$2"
  local label="$3"
  sort "${expected_file}" >"${expected_file}.sorted"
  if ! diff -u "${expected_file}.sorted" "${actual_file}"; then
    fail "${label} census does not match the manifest"
  fi
}

compare_inventory "${domain_expected}" "${domain_actual}" "Dart DomainCommand"
compare_inventory "${system_expected}" "${system_actual}" "Dart SystemCommand"
compare_inventory "${rust_domain_expected}" "${rust_domain_actual}" "Rust PlayerCommand"
compare_inventory "${rust_domain_expected}" "${client_command_actual}" "client player command"
compare_inventory "${rust_system_expected}" "${rust_system_actual}" "Rust SystemCommand"
compare_inventory "${query_expected}" "${query_actual}" "Rust GameQuery"
compare_inventory "${query_result_expected}" "${query_result_actual}" "Rust QueryResult"
compare_inventory "${client_query_result_expected}" "${client_query_result_actual}" "client query result"
compare_inventory "${event_expected}" "${event_actual}" "Dart DomainEvent"
compare_inventory "${rust_event_expected}" "${rust_event_actual}" "Rust DomainEvent"
compare_inventory "${rust_event_expected}" "${replay_event_actual}" "replay event"
compare_inventory "${rust_event_expected}" "${client_event_actual}" "client event"
compare_inventory "${rust_evidence_expected}" "${rust_evidence_actual}" "Rust execution evidence"
compare_inventory "${rust_evidence_expected}" "${replay_evidence_actual}" "replay evidence"
compare_inventory "${rust_evidence_expected}" "${client_evidence_actual}" "client evidence"
compare_inventory "${projection_variant_expected}" "${projection_variant_actual}" "runtime pending-action projection"
compare_inventory "${projection_dto_variant_expected}" "${projection_dto_variant_actual}" "client pending-action projection"

echo "Rust engine inventory is closed: ${actual_domain_count} domain commands, ${actual_system_count} system commands, ${actual_query_count} queries, ${actual_event_count} mapped and ${actual_native_event_count} native events, ${actual_evidence_count} mapped and ${actual_native_evidence_count} native evidence types, ${actual_projection_type_count} projection types and ${actual_projection_variant_count} projection variants."
