import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/services/authoritative_command_policy.dart';
import 'package:aonw/game/application/services/game_activity_event_projector.dart';
import 'package:aonw/game/application/services/game_intent_resolver.dart';
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
    required GameState currentState,
    required GameCommand command,
    GameCommandContext context = const GameCommandContext(),
  }) async {
    final clientOnlyResult = _dispatchClientOnly(
      currentState: currentState,
      command: command,
      context: context,
    );
    if (clientOnlyResult != null) return clientOnlyResult;

    return _dispatchPersistent(
      saveId: saveId,
      currentState: currentState,
      command: command,
      context: context,
    );
  }

  Future<CommandTransportResult> _dispatchPersistent({
    required String saveId,
    required GameState currentState,
    required GameCommand command,
    required GameCommandContext context,
  }) async {
    final baseSnapshot = await gameRepository.load(saveId);
    final latestOffset = await eventLog.latestOffset(saveId);
    final timestamp = clock.nowUtc();
    final resolver = LocalCommandResolver(reducer: reducer);
    final authoritativeCommand =
        AuthoritativeCommandPolicy.authoritativeCommandForClientIntent(
          currentState,
          command,
          context,
        );
    final commandToApply = authoritativeCommand ?? command;
    final movementPresentationOrigin =
        command is TileTappedCommand && authoritativeCommand is MoveUnitCommand
        ? LocalMovementPresentationOrigin.previewConfirmation
        : LocalMovementPresentationOrigin.direct;
    final resolved = resolver.resolve(
      baseSnapshot: baseSnapshot,
      currentState: currentState,
      command: commandToApply,
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
      authoritativeCommand: authoritativeCommand,
    );
  }

  Future<CommandTransportResult> _persistResolution({
    required String saveId,
    required SaveSnapshot baseSnapshot,
    required int latestOffset,
    required DateTime timestamp,
    required LocalCommandResolution resolved,
    required GameState currentState,
    required GameCommand command,
    required GameCommand? authoritativeCommand,
  }) async {
    final shouldLogCommand =
        authoritativeCommand != null ||
        AuthoritativeCommandPolicy.shouldLogForReplay(currentState, command);
    final offset = shouldLogCommand ? latestOffset + 1 : latestOffset;
    final commandToLog = authoritativeCommand ?? command;

    await _appendCommandIfNeeded(
      saveId: saveId,
      turn: baseSnapshot.domain.turn,
      currentState: currentState,
      commandToLog: commandToLog,
      resolved: resolved,
      timestamp: timestamp,
      offset: offset,
      shouldLog: shouldLogCommand,
    );

    final snapshot = resolved.snapshot.withEventLogOffset(offset);
    await gameRepository.save(snapshot);

    final storedSnapshot = await _storeSnapshotIfNeeded(
      saveId: saveId,
      command: commandToLog,
      snapshot: snapshot,
      timestamp: timestamp,
      offset: offset,
      shouldLog: shouldLogCommand,
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
    required GameCommand command,
    required SaveSnapshot snapshot,
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
      Snapshot(offset: offset, state: snapshot, createdAt: timestamp),
    );
    return true;
  }

  Future<void> _appendCommandIfNeeded({
    required String saveId,
    required int turn,
    required GameState currentState,
    required GameCommand commandToLog,
    required LocalCommandResolution resolved,
    required DateTime timestamp,
    required int offset,
    required bool shouldLog,
  }) async {
    if (!shouldLog) return;

    await eventLog.append(
      saveId,
      LoggedCommand(
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

  CommandTransportResult? _dispatchClientOnly({
    required GameState currentState,
    required GameCommand command,
    required GameCommandContext context,
  }) {
    final authoritativeCommand =
        AuthoritativeCommandPolicy.authoritativeCommandForClientIntent(
          currentState,
          command,
          context,
        );
    if (authoritativeCommand == null &&
        AuthoritativeCommandPolicy.isClientOnlyForState(
          currentState,
          command,
        )) {
      final resolution = resolveClientIntent(
        reducer,
        currentState,
        command,
        context,
      );
      return CommandTransportResult(
        state: resolution.state,
        uiEffects: resolution.uiEffects,
        events: const [],
        snapshot: null,
        offset: -1,
      );
    }
    return null;
  }
}
