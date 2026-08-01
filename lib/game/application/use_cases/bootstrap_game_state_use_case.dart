import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/event_log_replay_service.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';

class BootstrapGameStateResult {
  final GameClientState state;
  final int offset;
  final bool shouldFocusTurnStart;

  const BootstrapGameStateResult({
    required this.state,
    required this.offset,
    this.shouldFocusTurnStart = false,
  });
}

class BootstrapGameStateUseCase {
  static const _maxAuthoritativeSnapshotAttempts = 2;

  final GameRepository repository;
  final DispatchCommandUseCase dispatchCommand;
  final EventLogReplayService? eventReplay;

  const BootstrapGameStateUseCase({
    required this.repository,
    required this.dispatchCommand,
    this.eventReplay,
  });

  Future<GameClientState> execute({
    required String saveId,
    String? preferredPlayerId,
  }) async {
    return (await executeWithResult(
      saveId: saveId,
      preferredPlayerId: preferredPlayerId,
    )).state;
  }

  Future<BootstrapGameStateResult> executeWithResult({
    required String saveId,
    String? preferredPlayerId,
  }) async {
    if (saveId.isEmpty) {
      return BootstrapGameStateResult(state: GameClientState(), offset: 0);
    }

    late CanonicalGameSnapshot snapshot;
    late PlayerControlState control;
    late GameClientState initialState;
    late int offset;
    var requiresLiveCatchup = false;
    for (
      var attempt = 0;
      attempt < _maxAuthoritativeSnapshotAttempts;
      attempt++
    ) {
      snapshot = await repository.load(saveId);
      control = _initialControl(snapshot, preferredPlayerId);
      offset = snapshot.eventLogOffset;
      initialState = snapshot.toClientState(
        activePlayerId: control.activePlayerId,
        activePlayerCanAct: control.canAct,
      );
      final replay = eventReplay;
      if (snapshot.domain.gameMode == GameMode.multiplayer && replay != null) {
        try {
          final replayed = await replay.replaySinceSnapshot(
            saveId: saveId,
            snapshot: snapshot,
            state: initialState,
          );
          initialState = replayed.state;
          offset = replayed.offset;
        } on AuthoritativeSnapshotRequiredException {
          if (attempt + 1 < _maxAuthoritativeSnapshotAttempts) continue;
          // Never expose a state that was only partially reconstructed. The
          // authoritative snapshot is safe to render while the live stream
          // catches up with events committed after it.
          requiresLiveCatchup = true;
        }
      }
      break;
    }
    final canAct =
        control.canAct &&
        !initialState.hasSubmittedTurn(control.activePlayerId);
    initialState = initialState.copyWith(
      activePlayerId: control.activePlayerId,
      activePlayerCanAct: canAct,
    );
    if (control.activePlayerId.isEmpty) {
      return BootstrapGameStateResult(state: initialState, offset: offset);
    }
    if (requiresLiveCatchup) {
      return BootstrapGameStateResult(state: initialState, offset: offset);
    }

    if (snapshot.domain.gameMode != GameMode.multiplayer || !canAct) {
      return BootstrapGameStateResult(state: initialState, offset: offset);
    }

    return BootstrapGameStateResult(
      state: initialState,
      offset: offset,
      shouldFocusTurnStart: true,
    );
  }

  PlayerControlState _initialControl(
    CanonicalGameSnapshot snapshot,
    String? preferredPlayerId,
  ) => PlayerControlCoordinator.initialFromCollections(
    orderedPlayers: snapshot.domain.participants,
    turnStatesByPlayerId: snapshot.domain.turnStatesByPlayerId,
    preferredPlayerId: preferredPlayerId,
  );
}
