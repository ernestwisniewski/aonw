import 'dart:async';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart' as api;
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/ports/wire_command_dispatcher.dart';
import 'package:aonw/game/application/services/game_handoff.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/multiplayer_snapshot_cache_key.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/audio/game_audio_controller.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_game_renderer.dart';

part 'support/game_provider_movement_fixtures.dart';
part 'support/game_provider_renderer_fixtures.dart';
part 'support/game_provider_turn_lifecycle_cases.dart';
part 'support/game_provider_shared_fixtures.dart';
part 'support/game_provider_multiplayer_fixtures.dart';
part 'support/game_provider_session_scenarios.dart';
part 'support/game_provider_state_scenarios.dart';
part 'support/game_provider_state_bootstrap_scenarios.dart';
part 'support/game_provider_state_live_sync_scenarios.dart';
part 'support/game_provider_state_dispatch_scenarios.dart';
part 'support/game_provider_command_scenarios.dart';
part 'support/game_provider_player_control_scenarios.dart';
part 'support/game_provider_save_index_scenarios.dart';
part 'support/game_provider_camera_scenarios.dart';
part 'support/game_provider_save_scenarios.dart';

void main() {
  _registerGameSessionNotifierScenarios();
  _registerGameStateNotifierScenarios();
  _registerGameCommandControllerScenarios();
  _registerGamePlayerControlScenarios();
  _registerGameSaveIndexProviderScenarios();
  _registerSavedCameraProviderScenarios();
  _registerGameSaveProviderScenarios();
}
