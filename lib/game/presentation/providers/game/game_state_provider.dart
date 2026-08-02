import 'dart:async';

import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/live_multiplayer_events.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw/game/application/services/game_intent_resolver.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/live_snapshot_presentation_policy.dart';
import 'package:aonw/game/application/services/live_wire_command_dispatcher.dart';
import 'package:aonw/game/application/services/multiplayer_interaction_reconciler.dart';
import 'package:aonw/game/application/services/multiplayer_snapshot_cache_key.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/application/use_cases/bootstrap_game_state_use_case.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_save.dart' show GameMode;
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/presentation/audio/game_audio_controller.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue_mapper.dart';
import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw/game/presentation/engine/renderer_view_model.dart';
import 'package:aonw/game/presentation/providers/audio/game_audio_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_activity_history_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/game/live_snapshot_presentation_resolver.dart'
    as live;
import 'package:aonw/game/presentation/providers/multiplayer/multiplayer_connection_status_provider.dart';
import 'package:aonw/game/presentation/providers/renderer/renderer_provider.dart';
import 'package:aonw/game/presentation/providers/ruleset/ruleset_providers.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/game/presentation/providers/session/session_providers.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'game_state_provider.g.dart';
part 'game_state_provider_application_bootstrap.dart';
part 'game_state_provider_commands.dart';
part 'game_state_provider_effects.dart';
part 'game_state_provider_multiplayer_sync.dart';

@Riverpod(
  retry: _doNotRetry,
  dependencies: [activeGameSession, networkSession, activeRendererViewModel],
)
class GameStateNotifier extends _$GameStateNotifier {
  DispatchCommandUseCase? _dispatchCommand;
  GameStateReducer? _reducer;
  LiveMultiplayerEventHandle? _liveEvents;
  Future<LiveMultiplayerEventHandle?>? _liveEventsStarting;
  String _saveId = '';
  Future<void> _dispatchQueue = Future<void>.value();
  Future<void> _networkSnapshotQueue = Future<void>.value();
  int _eventLogOffset = 0;
  Ref get _providerRef => ref;
  bool get _isMounted => ref.mounted;
  GameClientState? get _stateValue => state.value;
  Future<GameClientState> get _stateFuture => future;
  set _stateValue(GameClientState value) => state = AsyncData(value);

  @override
  Future<GameClientState> build(String saveId) => _buildState(saveId);
}
