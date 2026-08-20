import 'dart:async';

import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/services/end_turn_strategy.dart';
import 'package:aonw/game/application/services/game_handoff.dart';
import 'package:aonw/game/application/services/local_single_player_turn_phase.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/application/services/turn_opening_lease.dart';
import 'package:aonw/game/application/use_cases/confirm_handoff_use_case.dart';
import 'package:aonw/game/application/use_cases/end_turn_use_case.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/providers/game/game_actions_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider.dart';
import 'package:aonw/game/presentation/providers/player/handoff_provider.dart';
import 'package:aonw/game/presentation/providers/renderer/renderer_provider.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/game/presentation/providers/session/session_providers.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_control_provider.g.dart';
part 'player_control_provider_handoff.dart';
part 'player_control_provider_sync.dart';
part 'player_control_provider_turns.dart';

/// Scoped HUD-level provider holding the current [GameSave] for player control.
@Riverpod(dependencies: [])
GameSave? gamePlayerControlSave(Ref ref) => null;

@Riverpod(
  dependencies: [
    gamePlayerControlSave,
    activeGameSession,
    networkSession,
    activeRendererViewModel,
    GameCommandController,
    GameStateNotifier,
  ],
)
class GamePlayerControlController extends _$GamePlayerControlController {
  PlayerControlState? _pendingHumanTurnRelease;
  TurnOpeningLease? _turnOpeningLease;

  Ref get _providerRef => ref;
  bool get _isMounted => ref.mounted;
  PlayerControlState get _currentControl => state;
  set _currentControl(PlayerControlState value) => state = value;

  @override
  PlayerControlState build() {
    final save = ref.watch(gamePlayerControlSaveProvider);
    final networkSession = ref.watch(networkSessionProvider);
    final previous = stateOrNull ?? const PlayerControlState();
    final normalized = PlayerControlCoordinator.normalize(
      current: previous,
      save: save,
    );
    if (normalized.activePlayerId != previous.activePlayerId) {
      _clearTurnOpening();
    }
    return _withSavePhase(
      normalized,
      save: save,
      previous: previous,
      networkSession: networkSession,
    );
  }
}
