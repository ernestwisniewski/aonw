import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state_reducer.dart';
import 'package:aonw_core/game/domain/command.dart';

class BootstrapGameStateResult {
  final GameState state;
  final int offset;

  const BootstrapGameStateResult({required this.state, required this.offset});
}

class BootstrapGameStateUseCase {
  final GameRepository repository;
  final DispatchCommandUseCase dispatchCommand;
  final EventLog? eventLog;
  final GameStateReducer? replayReducer;

  const BootstrapGameStateUseCase({
    required this.repository,
    required this.dispatchCommand,
    this.eventLog,
    this.replayReducer,
  });

  Future<GameState> execute({
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
      return const BootstrapGameStateResult(state: GameState(), offset: 0);
    }

    final snapshot = await repository.load(saveId);
    final control = PlayerControlCoordinator.initialForPlayer(
      save: snapshot.save,
      preferredPlayerId: preferredPlayerId,
    );
    var offset = snapshot.eventLogOffset;
    var initialState = snapshot.toGameState(
      activePlayerId: control.activePlayerId,
      activePlayerCanAct: control.canAct,
    );
    if (snapshot.save.gameMode == GameMode.multiplayer) {
      final replayed = await _replayEventsSinceSnapshot(
        saveId: saveId,
        state: initialState,
        offset: offset,
      );
      initialState = replayed.state;
      offset = replayed.offset;
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

    final result = await dispatchCommand.execute(
      saveId: saveId,
      currentState: initialState,
      command: SetActivePlayerCommand(control.activePlayerId, canAct: canAct),
    );
    offset = _maxOffset(offset, result.offset);
    if (snapshot.save.gameMode != GameMode.multiplayer || !canAct) {
      return BootstrapGameStateResult(state: result.state, offset: offset);
    }

    final focused = await dispatchCommand.execute(
      saveId: saveId,
      currentState: result.state,
      command: FocusTurnStartActionCommand(control.activePlayerId),
    );
    offset = _maxOffset(offset, focused.offset);
    return BootstrapGameStateResult(state: focused.state, offset: offset);
  }

  Future<BootstrapGameStateResult> _replayEventsSinceSnapshot({
    required String saveId,
    required GameState state,
    required int offset,
  }) async {
    final log = eventLog;
    final reducer = replayReducer;
    if (log == null || reducer == null) {
      return BootstrapGameStateResult(state: state, offset: offset);
    }

    var currentState = state;
    var currentOffset = offset;
    await for (final logged in log.readSince(saveId, offset: offset + 1)) {
      if (logged.offset <= currentOffset) continue;
      if (logged.offset != currentOffset + 1) {
        throw StateError(
          'Missing multiplayer event between offsets $currentOffset and '
          '${logged.offset}.',
        );
      }
      final transition = reducer.reduce(
        currentState,
        logged.command,
        context: GameCommandContext(actorPlayerId: logged.actorPlayerId),
      );
      currentState = transition.state;
      currentOffset = logged.offset;
    }
    return BootstrapGameStateResult(state: currentState, offset: currentOffset);
  }

  int _maxOffset(int first, int second) => first > second ? first : second;
}
