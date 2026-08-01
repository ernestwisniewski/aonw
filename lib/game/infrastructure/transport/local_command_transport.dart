import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/services/game_activity_event_projector.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/application/services/local_movement_presentation_origin.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/infrastructure/system/system_clock.dart';
import 'package:aonw_core/game/domain/command.dart';

class LocalCommandTransport implements CommandTransport {
  final GameStateReducer reducer;
  final GameRepository gameRepository;
  final EventLog eventLog;
  final SnapshotStore snapshotStore;
  final int snapshotEvery;
  final Clock clock;

  const LocalCommandTransport({
    required this.reducer,
    required this.gameRepository,
    required this.eventLog,
    required this.snapshotStore,
    this.snapshotEvery = 50,
    this.clock = const SystemClock(),
  });

  @override
  Future<CommandTransportResult> dispatch({
    required String saveId,
    required GameClientState currentState,
    required DomainCommand command,
    GameCommandContext context = const GameCommandContext(),
    bool fromMovePreviewConfirmation = false,
  }) => _dispatchPersistent(
    saveId: saveId,
    currentState: currentState,
    command: command,
    context: context,
    fromMovePreviewConfirmation: fromMovePreviewConfirmation,
  );

  Future<CommandTransportResult> _dispatchPersistent({
    required String saveId,
    required GameClientState currentState,
    required DomainCommand command,
    required GameCommandContext context,
    required bool fromMovePreviewConfirmation,
  }) async {
    final baseSnapshot = await gameRepository.load(saveId);
    final latestOffset = await eventLog.latestOffset(saveId);
    final timestamp = clock.nowUtc();
    final resolver = LocalCommandResolver(reducer: reducer);
    final movementPresentationOrigin =
        fromMovePreviewConfirmation && command is MoveUnitCommand
        ? LocalMovementPresentationOrigin.previewConfirmation
        : LocalMovementPresentationOrigin.direct;
    final resolved = resolver.resolve(
      baseSnapshot: baseSnapshot,
      currentState: currentState,
      command: command,
      savedAt: timestamp,
      context: context,
      movementPresentationOrigin: movementPresentationOrigin,
    );

    return _persistResolution(
      saveId: saveId,
      baseSnapshot: baseSnapshot,
      latestOffset: latestOffset,
      timestamp: timestamp,
      resolved: resolved,
      currentState: currentState,
      command: command,
    );
  }

  Future<CommandTransportResult> _persistResolution({
    required String saveId,
    required CanonicalGameSnapshot baseSnapshot,
    required int latestOffset,
    required DateTime timestamp,
    required LocalCommandResolution resolved,
    required GameClientState currentState,
    required DomainCommand command,
  }) async {
    final offset = latestOffset + 1;

    await _appendCommandIfNeeded(
      saveId: saveId,
      turn: baseSnapshot.domain.turn,
      currentState: currentState,
      commandToLog: command,
      resolved: resolved,
      timestamp: timestamp,
      offset: offset,
      shouldLog: true,
    );

    final snapshot = resolved.snapshot.withEventLogOffset(offset);
    await gameRepository.save(snapshot);

    final storedSnapshot = await _storeSnapshotIfNeeded(
      saveId: saveId,
      command: command,
      snapshot: snapshot,
      timestamp: timestamp,
      offset: offset,
      shouldLog: true,
    );

    return CommandTransportResult(
      state: resolved.state,
      uiEffects: resolved.uiEffects,
      events: resolved.events,
      combatAnimations: resolved.combatAnimations,
      movementExecutions: resolved.movementExecutions,
      snapshot: snapshot,
      offset: offset,
      storedSnapshot: storedSnapshot,
    );
  }

  Future<bool> _storeSnapshotIfNeeded({
    required String saveId,
    required DomainCommand command,
    required CanonicalGameSnapshot snapshot,
    required DateTime timestamp,
    required int offset,
    required bool shouldLog,
  }) async {
    final shouldStore =
        shouldLog &&
        (command is EndTurnCommand ||
            command is SubmitTurnCommand ||
            (snapshotEvery > 0 && offset % snapshotEvery == 0));
    if (!shouldStore) return false;

    await snapshotStore.save(
      saveId,
      Snapshot(state: snapshot, createdAt: timestamp),
    );
    return true;
  }

  Future<void> _appendCommandIfNeeded({
    required String saveId,
    required int turn,
    required GameClientState currentState,
    required DomainCommand commandToLog,
    required LocalCommandResolution resolved,
    required DateTime timestamp,
    required int offset,
    required bool shouldLog,
  }) async {
    if (!shouldLog) return;

    await eventLog.append(
      saveId,
      RecordedDomainCommand(
        offset: offset,
        timestamp: timestamp,
        turn: turn,
        actorPlayerId: resolved.context.actorPlayerId,
        canAct: resolved.context.canAct,
        commandTick: resolved.context.commandTick,
        ignoreFogOfWar: resolved.context.ignoreFogOfWar,
        command: commandToLog,
        events: resolved.events,
        activity: GameActivityEventProjector.project(
          events: resolved.events,
          state: resolved.state,
          previousState: currentState,
        ),
      ),
    );
  }
}
