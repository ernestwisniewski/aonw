#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
checker="${repo_root}/tool/check_rust_engine_inventory.sh"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/aonw-rust-inventory-test.XXXXXX")"
case_log="${fixture_root}/case.log"

cleanup() {
  rm -rf "${fixture_root}"
}
trap cleanup EXIT

command_root="${fixture_root}/packages/aonw_core/lib/game/domain/command"
system_root="${fixture_root}/packages/aonw_core/lib/game/application/engine"
event_root="${fixture_root}/packages/aonw_core/lib/game/domain/event"
movement_root="${fixture_root}/packages/aonw_core/lib/game/domain/movement"
rust_root="${fixture_root}/engine/crates/aonw_engine/src/application"
contracts_root="${fixture_root}/engine/crates/aonw_contracts/src"
runtime_root="${fixture_root}/engine/crates/aonw_local_runtime/src"
manifest="${fixture_root}/engine/migration/authoritative_inventory"

mkdir -p "${command_root}" "${system_root}" "${event_root}" "${movement_root}" "${rust_root}" "${contracts_root}/client" "${runtime_root}" "$(dirname "${manifest}")"

write_baseline() {
  printf '%s\n' \
    "part 'commands.dart';" \
    'sealed class DomainCommand {}' \
    >"${command_root}/game_command.dart"
  printf '%s\n' \
    "part of 'game_command.dart';" \
    'final class ExampleCommand extends DomainCommand {}' \
    >"${command_root}/commands.dart"
  printf '%s\n' \
    'sealed class SystemCommand {}' \
    'final class ExampleSystemCommand extends SystemCommand {}' \
    >"${system_root}/system_command.dart"
  printf '%s\n' \
    "part 'events.dart';" \
    'sealed class GameEvent {}' \
    'sealed class DomainEvent extends GameEvent {}' \
    >"${event_root}/game_event.dart"
  printf '%s\n' \
    "part of 'game_event.dart';" \
    'final class ExampleEvent extends DomainEvent {}' \
    >"${event_root}/events.dart"
  printf '%s\n' \
    'final class ExampleExecution {}' \
    >"${movement_root}/movement_command_execution.dart"
  printf '%s\n' \
    "pub enum PlayerCommand<'command> {" \
    "    Example(ExampleCommand<'command>)," \
    '}' \
    >"${rust_root}/command.rs"
  printf '%s\n' \
    "pub enum GameQuery<'query> {" \
    '    Example(ExampleQuery),' \
    '}' \
    'pub enum QueryResult {' \
    '    Example(ExampleResult),' \
    '}' \
    >"${rust_root}/query.rs"
  printf '%s\n' \
    'pub enum DomainEvent {' \
    '    Example(ExampleEvent),' \
    '}' \
    'pub enum ExecutionEvidence {' \
    '    Example(ExampleExecution),' \
    '}' \
    >"${rust_root}/transition.rs"
  printf '%s\n' \
    'pub enum ReplayEventDto {' \
    '    Example { value: u32 },' \
    '}' \
    'pub enum ReplayEvidenceDto {' \
    '    Example { value: u32 },' \
    '}' \
    >"${contracts_root}/persistence.rs"
  printf '%s\n' \
    'pub enum ClientCommandDto {' \
    '    Example { value: u32 },' \
    '}' \
    >"${contracts_root}/client/request.rs"
  printf '%s\n' \
    'pub enum ClientQueryResultDto {' \
    '    Example { value: u32 },' \
    '}' \
    'pub enum ClientEventDto {' \
    '    Example { value: u32 },' \
    '}' \
    'pub enum ClientEvidenceDto {' \
    '    Example { value: u32 },' \
    '}' \
    'pub enum PendingActionViewDto {' \
    '    Example,' \
    '}' \
    'pub struct ExampleSnapshotDto {' \
    '    pub value: u32,' \
    '}' \
    >"${contracts_root}/client/response.rs"
  printf '%s\n' \
    'pub enum PendingActionView {' \
    '    Example,' \
    '}' \
    'pub struct ExampleSnapshot {' \
    '    value: u32,' \
    '}' \
    >"${runtime_root}/player_view.rs"
  printf '%s\n' \
    'oracle-tree 0000000000000000000000000000000000000000' \
    'expected-domain-count 1' \
    'expected-system-count 1' \
    'expected-query-count 1' \
    'expected-event-count 1' \
    'expected-native-event-count 0' \
    'expected-evidence-count 1' \
    'expected-native-evidence-count 0' \
    'expected-projection-type-count 1' \
    'expected-projection-variant-count 1' \
    'dart-domain-root packages/aonw_core/lib/game/domain/command/game_command.dart' \
    'dart-system-source packages/aonw_core/lib/game/application/engine/system_command.dart' \
    'dart-event-root packages/aonw_core/lib/game/domain/event/game_event.dart' \
    'dart-evidence-source packages/aonw_core/lib/game/domain/movement/movement_command_execution.dart' \
    'rust-domain-source engine/crates/aonw_engine/src/application/command.rs' \
    'rust-system-source -' \
    'rust-query-source engine/crates/aonw_engine/src/application/query.rs' \
    'rust-event-source engine/crates/aonw_engine/src/application/transition.rs' \
    'rust-evidence-source engine/crates/aonw_engine/src/application/transition.rs' \
    'rust-persistence-source engine/crates/aonw_contracts/src/persistence.rs' \
    'rust-client-command-source engine/crates/aonw_contracts/src/client/request.rs' \
    'rust-client-event-source engine/crates/aonw_contracts/src/client/response.rs' \
    'rust-client-response-source engine/crates/aonw_contracts/src/client/response.rs' \
    'rust-projection-source engine/crates/aonw_local_runtime/src/player_view.rs' \
    'partial-parity-mode opaque-splice' \
    'domain ExampleCommand movement characterized Example packages/aonw_core/lib/game/domain/command/commands.dart' \
    'system ExampleSystemCommand system-lifecycle reference-only - packages/aonw_core/lib/game/application/engine/system_command.dart' \
    'query Example Example Example movement characterized' \
    'event ExampleEvent movement characterized Example packages/aonw_core/lib/game/domain/event/events.dart' \
    'evidence ExampleExecution movement characterized Example packages/aonw_core/lib/game/domain/movement/movement_command_execution.dart' \
    'projection-type ExampleSnapshot recipient-snapshot characterized ExampleSnapshotDto engine/crates/aonw_local_runtime/src/player_view.rs' \
    'projection-variant Example pending-action characterized Example' \
    >"${manifest}"
}

expect_rejection() {
  local label="$1"
  if "${checker}" --repo-root "${fixture_root}" --manifest "${manifest}" >"${case_log}" 2>&1; then
    echo "Inventory checker accepted ${label}." >&2
    exit 1
  fi
  echo "Inventory checker rejected ${label}."
  write_baseline
}

write_baseline
"${checker}" --repo-root "${fixture_root}" --manifest "${manifest}" >/dev/null

printf '%s\n' 'final class UnclassifiedCommand extends DomainCommand {}' >>"${command_root}/commands.dart"
expect_rejection "an unclassified Dart command"

sed -i.bak '/Example(ExampleCommand/a\
    Unclassified(UnclassifiedCommand),' "${rust_root}/command.rs"
rm -f "${rust_root}/command.rs.bak"
expect_rejection "an unclassified Rust command variant"

sed -i.bak '/    Example {/a\
    TrustedSystem { value: u32 },' "${contracts_root}/client/request.rs"
rm -f "${contracts_root}/client/request.rs.bak"
expect_rejection "a trusted system command exposed to clients"

sed -i.bak 's/characterized Example/engine-parity Example/' "${manifest}"
rm -f "${manifest}.bak"
expect_rejection "engine-parity in a synthetic opaque-splice manifest"

sed -i.bak 's#command/commands.dart#command/wrong_source.dart#' "${manifest}"
rm -f "${manifest}.bak"
expect_rejection "a stale declaration source path"

sed -i.bak '/Example(ExampleQuery)/a\
    Unclassified(UnclassifiedQuery),' "${rust_root}/query.rs"
rm -f "${rust_root}/query.rs.bak"
expect_rejection "an unclassified Rust query variant"

printf '%s\n' 'final class UnclassifiedEvent extends DomainEvent {}' >>"${event_root}/events.dart"
expect_rejection "an unclassified Dart domain event"

sed -i.bak '/    Example,/a\
    Unclassified,' "${runtime_root}/player_view.rs"
rm -f "${runtime_root}/player_view.rs.bak"
expect_rejection "an unclassified recipient projection variant"

echo "Rust engine inventory negative tests passed."
