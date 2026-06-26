import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/application/services/authoritative_command_policy.dart';
import 'package:aonw/game/application/services/game_activity_event_projector.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
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
    final baseSnapshot = await gameRepository.load(saveId);
    final latestOffset = await eventLog.latestOffset(saveId);
    final timestamp = clock.nowUtc();
    final resolver = LocalCommandResolver(reducer: reducer);
    final resolved = resolver.resolve(
      baseSnapshot: baseSnapshot,
      currentState: currentState,
      command: command,
      savedAt: timestamp,
      context: context,
    );
    final authoritativeCommand =
        AuthoritativeCommandPolicy.authoritativeCommandForClientIntent(
          currentState,
          command,
          resolved.context,
        );
    final shouldLogCommand =
        authoritativeCommand != null ||
        AuthoritativeCommandPolicy.shouldLogForReplay(command);
    final offset = shouldLogCommand ? latestOffset + 1 : latestOffset;
    final commandToLog = authoritativeCommand ?? command;

    if (shouldLogCommand) {
      final logResolution = authoritativeCommand == null
          ? resolved
          : resolver.resolve(
              baseSnapshot: baseSnapshot,
              currentState: currentState,
              command: authoritativeCommand,
              savedAt: timestamp,
              context: context,
            );
      await eventLog.append(
        saveId,
        LoggedCommand(
          offset: offset,
          timestamp: timestamp,
          turn: baseSnapshot.save.turn,
          actorPlayerId: logResolution.context.actorPlayerId,
          canAct: logResolution.context.canAct,
          commandTick: logResolution.context.commandTick,
          ignoreFogOfWar: logResolution.context.ignoreFogOfWar,
          command: commandToLog,
          events: logResolution.events,
          activity: GameActivityEventProjector.project(
            events: logResolution.events,
            state: logResolution.state,
            previousState: currentState,
          ),
        ),
      );
    }

    final snapshot = SaveSnapshot.fromGameState(
      save: resolved.save,
      state: resolved.state,
      eventLogOffset: offset,
    );
    await gameRepository.save(snapshot);

    final shouldStoreSnapshot =
        shouldLogCommand &&
        (commandToLog is EndTurnCommand ||
            commandToLog is SubmitTurnCommand ||
            (snapshotEvery > 0 && offset % snapshotEvery == 0));
    if (shouldStoreSnapshot) {
      await snapshotStore.save(
        saveId,
        Snapshot(offset: offset, state: snapshot, createdAt: timestamp),
      );
    }

    return CommandTransportResult(
      state: resolved.state,
      uiEffects: resolved.uiEffects,
      events: resolved.events,
      snapshot: snapshot,
      offset: offset,
      storedSnapshot: shouldStoreSnapshot,
    );
  }
}
