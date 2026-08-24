#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
checker="${repo_root}/tool/check_rust_determinism_inventory.sh"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/aonw-rust-determinism-test.XXXXXX")"
inventory="${fixture_root}/engine/migration/determinism_inventory"
case_log="${fixture_root}/case.log"

cleanup() {
  rm -rf "${fixture_root}"
}
trap cleanup EXIT

sources=(
  packages/aonw_core/lib/game/domain/combat/combat_rng.dart
  packages/aonw_core/lib/ai/ai_rng.dart
  packages/aonw_core/lib/game/domain/resource/initial_resource_distribution_generator.dart
  packages/aonw_core/lib/game/domain/unit/starting_units.dart
  packages/aonw_core/lib/game/domain/unit/starting_position_seed.dart
  packages/aonw_core/lib/game/domain/artifact/world_artifact_generator.dart
  packages/aonw_core/lib/map/domain/map_player_capacity.dart
  packages/aonw_core/lib/ai/mcts/mcts_budget.dart
  packages/aonw_core/lib/ai/mcts/mcts_strategy.dart
)

write_baseline() {
  rm -rf "${fixture_root}/packages" "${fixture_root}/engine"
  mkdir -p "$(dirname "${inventory}")"
  cp "${repo_root}/engine/migration/determinism_inventory" "${inventory}"
  local source
  for source in "${sources[@]}"; do
    mkdir -p "${fixture_root}/$(dirname "${source}")"
    cp "${repo_root}/${source}" "${fixture_root}/${source}"
  done
  mkdir -p \
    "${fixture_root}/engine/crates/aonw_domain/src" \
    "${fixture_root}/engine/crates/aonw_engine/src" \
    "${fixture_root}/engine/crates/aonw_contract_mapping/src" \
    "${fixture_root}/engine/crates/aonw_contracts/src" \
    "${fixture_root}/engine/crates/aonw_local_runtime/src"
  printf '%s\n' 'pub struct ReplayLogDto;' >"${fixture_root}/engine/crates/aonw_contracts/src/persistence.rs"
}

expect_rejection() {
  local label="$1"
  if "${checker}" --repo-root "${fixture_root}" --inventory "${inventory}" >"${case_log}" 2>&1; then
    echo "Determinism checker accepted ${label}." >&2
    exit 1
  fi
  echo "Determinism checker rejected ${label}."
  write_baseline
}

write_baseline
"${checker}" --repo-root "${fixture_root}" --inventory "${inventory}" >/dev/null

sed -i.bak 's/expected-randomness-count 7/expected-randomness-count 6/' "${inventory}"
rm -f "${inventory}.bak"
expect_rejection "a stale randomness count"

printf '%s\n' 'unknown-directive value' >>"${inventory}"
expect_rejection "an unknown directive"

sed -i.bak 's/CombatRng/MissingCombatRng/' "${inventory}"
rm -f "${inventory}.bak"
expect_rejection "a missing oracle symbol"

sed -i.bak 's/seed+ordered-rolls/final-result/' "${inventory}"
rm -f "${inventory}.bak"
expect_rejection "RNG evidence without ordered draws"

printf '%s\n' 'final class UnregisteredRng {}' >"${fixture_root}/packages/aonw_core/lib/unregistered_rng.dart"
expect_rejection "an unregistered Dart RNG class"

printf '%s\n' 'void readClock() => DateTime.now();' >"${fixture_root}/packages/aonw_core/lib/unregistered_clock.dart"
expect_rejection "an unregistered Dart wall-clock read"

printf '%s\n' 'fn now() { let _ = std::time::SystemTime::now(); }' >"${fixture_root}/engine/crates/aonw_engine/src/clock.rs"
expect_rejection "a system-clock read in the pure Rust engine"

printf '%s\n' 'pub struct RngState { pub seed: u64 }' >"${fixture_root}/engine/crates/aonw_local_runtime/src/fake_rng.rs"
expect_rejection "generic persisted RNG state"

echo "Rust determinism inventory negative tests passed."
