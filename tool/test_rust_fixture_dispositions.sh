#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
checker="${repo_root}/tool/check_rust_fixture_dispositions.sh"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/aonw-fixture-disposition-test.XXXXXX")"
manifest="${fixture_root}/engine/migration/reducer_fixture_dispositions"
case_log="${fixture_root}/case.log"

cleanup() {
  rm -rf "${fixture_root}"
}
trap cleanup EXIT

corpus_oid() {
  local corpus_root="$1"
  local source_files="${fixture_root}/source.files"
  local source_entries="${fixture_root}/source.entries"
  find "${corpus_root}" -maxdepth 1 -type f -name '*.json' -print | sort >"${source_files}"
  : >"${source_entries}"
  while IFS= read -r source_file; do
    printf '%s %s\n' "$(git hash-object "${source_file}")" "$(basename "${source_file}")" >>"${source_entries}"
  done <"${source_files}"
  git hash-object "${source_entries}"
}

write_baseline() {
  rm -rf "${fixture_root}/test" "${fixture_root}/engine"
  mkdir -p \
    "${fixture_root}/test/fixtures/reducer_parity" \
    "${fixture_root}/engine/fixtures/canonical_commands" \
    "${fixture_root}/engine/migration" \
    "${fixture_root}/engine/crates/aonw_engine/src"
  printf '%s\n' '{"source":"a"}' >"${fixture_root}/test/fixtures/reducer_parity/a.json"
  printf '%s\n' '{"source":"b"}' >"${fixture_root}/test/fixtures/reducer_parity/b.json"
  printf '%s\n' '{"canonical":"a"}' >"${fixture_root}/engine/fixtures/canonical_commands/a.json"
  printf '%s\n' \
    'domain ACommand example engine-parity A source.dart' \
    >"${fixture_root}/engine/migration/authoritative_inventory"
  local oid
  oid="$(corpus_oid "${fixture_root}/test/fixtures/reducer_parity")"
  printf '%s\n' \
    'source-corpus test/fixtures/reducer_parity' \
    "source-corpus-oid ${oid}" \
    'canonical-corpus engine/fixtures/canonical_commands' \
    'authoritative-inventory engine/migration/authoritative_inventory' \
    'expected-case-count 2' \
    'expected-round-trip-count 1' \
    'expected-engine-parity-count 1' \
    'expected-blocked-count 1' \
    'expected-historical-count 0' \
    'case a example A accepted - round-trip engine-parity current - engine/fixtures/canonical_commands/a.json' \
    'case b example B rejected stable_reason blocked reference-only CP9 awaits-independent-current-contract-review -' \
    >"${manifest}"
}

expect_rejection() {
  local label="$1"
  if "${checker}" --repo-root "${fixture_root}" --manifest "${manifest}" >"${case_log}" 2>&1; then
    echo "Fixture disposition checker accepted ${label}." >&2
    exit 1
  fi
  echo "Fixture disposition checker rejected ${label}."
  write_baseline
}

write_baseline
"${checker}" --repo-root "${fixture_root}" --manifest "${manifest}" >/dev/null

printf '%s\n' '{"source":"unclassified"}' >"${fixture_root}/test/fixtures/reducer_parity/unclassified.json"
expect_rejection "an unclassified source fixture"

sed -i.bak 's/source-corpus-oid [0-9a-f]*/source-corpus-oid 0000000000000000000000000000000000000000/' "${manifest}"
rm -f "${manifest}.bak"
expect_rejection "a stale source corpus OID"

printf '%s\n' 'case a example A accepted - round-trip engine-parity current - engine/fixtures/canonical_commands/a.json' >>"${manifest}"
expect_rejection "a duplicate reviewed case"

sed -i.bak 's#current - engine/fixtures/canonical_commands/a.json#current - -#' "${manifest}"
rm -f "${manifest}.bak"
expect_rejection "engine parity without a canonical artifact"

sed -i.bak 's/reference-only CP9/reference-only current/' "${manifest}"
rm -f "${manifest}.bak"
expect_rejection "a blocked case without a checkpoint"

sed -i.bak 's/example engine-parity A/example characterized A/' "${fixture_root}/engine/migration/authoritative_inventory"
rm -f "${fixture_root}/engine/migration/authoritative_inventory.bak"
expect_rejection "execution parity absent from the authoritative inventory"

printf '%s\n' 'const SOURCE: &str = "test/fixtures/reducer_parity";' >"${fixture_root}/engine/crates/aonw_engine/src/legacy_reader.rs"
expect_rejection "a Rust reader for the historical envelope"

sed -i.bak 's/case a example A accepted -/case a example A accepted unexpected_reason/' "${manifest}"
rm -f "${manifest}.bak"
expect_rejection "an accepted oracle outcome with a rejection reason"

printf '%s\n' 'unknown-directive value' >>"${manifest}"
expect_rejection "an unknown directive"

echo "Rust fixture disposition negative tests passed."
