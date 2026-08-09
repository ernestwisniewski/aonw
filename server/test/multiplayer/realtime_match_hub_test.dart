import 'dart:async';

import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
import 'package:aonw_server/src/multiplayer/invite_code_generator.dart';
import 'package:aonw_server/src/multiplayer/lossless_match_snapshot_codec.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_endpoint.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_map_catalog.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store_limits.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store_persistence.dart';
import 'package:aonw_server/src/multiplayer/server_command_outcome_projector.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';
import 'package:aonw_server/src/observability/server_operational_event_sink.dart';
import 'package:test/test.dart';

import 'support/realtime_match_hub_query_helpers.dart';

part 'support/realtime_match_hub_fixture.dart';
part 'support/realtime_match_hub_initial_snapshot_cases.dart';
part 'support/realtime_match_hub_lifecycle_race_cases.dart';
part 'support/realtime_match_hub_outcome_cases.dart';
part 'support/realtime_match_hub_resignation_cases.dart';
part 'support/realtime_match_hub_resignation_fixture.dart';
part 'support/realtime_match_hub_turn_movement_cases.dart';
part 'support/realtime_match_hub_turn_movement_fixture.dart';
part 'support/realtime_match_hub_turn_movement_history_cases.dart';
part 'support/realtime_match_hub_timeout_actor_cases.dart';
part 'support/realtime_match_hub_timeout_fixture.dart';
part 'support/realtime_match_hub_store_fixture.dart';
part 'support/realtime_match_hub_store_failure_fixture.dart';
part 'support/realtime_match_hub_diplomacy_fixture.dart';
part 'support/realtime_match_hub_query_scenarios.dart';
part 'support/realtime_match_hub_query_projections_scenarios.dart';
part 'support/realtime_match_hub_query_listings_scenarios.dart';
part 'support/realtime_match_hub_lifecycle_scenarios.dart';
part 'support/realtime_match_hub_timeout_scenarios.dart';
part 'support/realtime_match_hub_resignation_scenarios.dart';
part 'support/realtime_match_hub_command_scenarios.dart';
part 'support/realtime_match_hub_command_application_scenarios.dart';
part 'support/realtime_match_hub_command_idempotency_scenarios.dart';
part 'support/realtime_match_hub_lobby_error_scenarios.dart';

void main() {
  _registerRealtimeMatchHubTurnMovementTests();
  _registerRealtimeMatchHubInitialSnapshotTests();
  _registerRealtimeMatchHubQueryScenarios();
  _registerRealtimeMatchHubLifecycleScenarios();
  _registerRealtimeMatchHubTimeoutScenarios();
  _registerRealtimeMatchHubResignationScenarios();
  _registerRealtimeMatchHubCommandScenarios();
  _registerRealtimeMatchHubLobbyErrorScenarios();
}
