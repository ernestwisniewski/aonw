import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';

enum ReplayBuildFailureReason { missingInitialSnapshot, offsetGap, corruptLog }

class ReplayBuildException implements Exception {
  final ReplayBuildFailureReason reason;
  final String message;
  final Object? cause;

  const ReplayBuildException(this.reason, this.message, {this.cause});

  @override
  String toString() => message;
}

class ReplayTimeline {
  final String saveId;
  final CanonicalGameSnapshot initialSnapshot;
  final GameClientState initialState;
  final List<ReplayStep> steps;

  const ReplayTimeline({
    required this.saveId,
    required this.initialSnapshot,
    required this.initialState,
    required this.steps,
  });

  GameSnapshotMetadata get metadata => initialSnapshot.metadata;
  List<Player> get participants => initialSnapshot.domain.participants;
  CameraState get initialCamera {
    final camera = metadata.camera;
    return CameraState(x: camera.x, y: camera.y, zoom: camera.zoom);
  }

  List<String> get playerIds {
    final ids = [
      for (final player in participants)
        if (player.id.isNotEmpty) player.id,
      for (final playerId in initialSnapshot.domain.turnStatesByPlayerId.keys)
        if (playerId.isNotEmpty) playerId,
    ];
    return ids.toSet().toList()..sort();
  }

  int get firstTurn => initialSnapshot.domain.turn;

  int get lastTurn {
    if (steps.isEmpty) return firstTurn;
    return steps.last.domain.turn;
  }
}

class ReplayStep {
  final int index;
  final RecordedDomainCommand loggedCommand;
  final CanonicalGameSnapshot snapshot;
  final GameClientState previousState;
  final GameClientState state;
  final List<GameEvent> events;
  final List<UiEffect> uiEffects;
  final List<CombatAnimationFact> combatAnimations;
  final List<MovementCommandExecution> movementExecutions;
  final int? originatingTurn;

  const ReplayStep({
    required this.index,
    required this.loggedCommand,
    required this.snapshot,
    required this.previousState,
    required this.state,
    required this.events,
    required this.uiEffects,
    this.combatAnimations = const [],
    this.movementExecutions = const [],
    this.originatingTurn,
  });

  GameSnapshotMetadata get metadata => snapshot.metadata;
  DomainState get domain => snapshot.domain;

  int get offset => loggedCommand.offset;

  int get turn => originatingTurn ?? loggedCommand.turn ?? domain.turn;

  DateTime get timestamp => loggedCommand.timestamp;

  String? get effectiveActorPlayerId => inferEffectiveActorPlayerId(
    loggedCommand: loggedCommand,
    state: state,
    previousState: previousState,
  );

  bool get hasActivity =>
      events.isNotEmpty || loggedCommand.activity.isNotEmpty;

  static String? inferEffectiveActorPlayerId({
    required RecordedDomainCommand loggedCommand,
    required GameClientState state,
    GameClientState? previousState,
  }) {
    final actorPlayerId = loggedCommand.actorPlayerId;
    if (actorPlayerId != null) return actorPlayerId;
    final command = loggedCommand.command;
    if (command == null) return null;
    return _inferActorPlayerId(
      command: command,
      state: state,
      previousState: previousState ?? state,
    );
  }

  static String? _inferActorPlayerId({
    required DomainCommand command,
    required GameClientState state,
    required GameClientState previousState,
  }) {
    return switch (command) {
      EndTurnCommand(:final playerId) ||
      SubmitTurnCommand(:final playerId) ||
      SelectTechnologyCommand(:final playerId) ||
      SendDiplomaticProposalCommand(:final playerId) ||
      RespondDiplomaticProposalCommand(:final playerId) ||
      DeclareWarCommand(:final playerId) ||
      SendGoldGiftCommand(:final playerId) ||
      SendDiplomaticMessageCommand(:final playerId) ||
      RespondDiplomaticMessageCommand(:final playerId) ||
      TradeArtifactCommand(:final playerId) ||
      OpenResourceTradeCommand(:final playerId) ||
      OpenResourceExchangeCommand(:final playerId) => playerId,
      MoveUnitCommand(:final unitId) ||
      CancelUnitActionCommand(:final unitId) ||
      SkipUnitTurnCommand(:final unitId) ||
      FortifyUnitCommand(:final unitId) ||
      AutoExploreUnitCommand(:final unitId) ||
      AssignMerchantTradeRouteCommand(:final unitId) ||
      MoveMerchantToCityCommand(:final unitId) ||
      DetachTroopCommand(:final unitId) ||
      FoundCityCommand(founderId: final unitId) ||
      SelectWorkerImprovementCommand(:final unitId) ||
      ConfirmWorkerImprovementCommand(:final unitId) ||
      CancelWorkerJobCommand(:final unitId) ||
      AssignWorkerToHexCommand(:final unitId) ||
      CancelWorkerAssignmentCommand(:final unitId) ||
      AttackHexCommand(attackerUnitId: final unitId) ||
      StartArtifactExcavationCommand(:final unitId) ||
      StoreArtifactInCityCommand(
        :final unitId,
      ) => _unitOwner(unitId, state: state, previousState: previousState),
      StartBuildingCommand(:final cityId) ||
      StartUnitProductionCommand(:final cityId) ||
      StartCityProjectCommand(:final cityId) ||
      StartWonderCommand(:final cityId) ||
      SetCitySpecializationCommand(:final cityId) ||
      RushProductionCommand(:final cityId) ||
      ToggleWorkedHexCommand(:final cityId) ||
      SelectCityExpansionHexCommand(
        :final cityId,
      ) => _cityOwner(cityId, state: state, previousState: previousState),
    };
  }

  static String? _unitOwner(
    String unitId, {
    required GameClientState state,
    required GameClientState previousState,
  }) {
    return state.unitById(unitId)?.ownerPlayerId ??
        previousState.unitById(unitId)?.ownerPlayerId;
  }

  static String? _cityOwner(
    String cityId, {
    required GameClientState state,
    required GameClientState previousState,
  }) {
    return state.cityById(cityId)?.ownerPlayerId ??
        previousState.cityById(cityId)?.ownerPlayerId;
  }
}

class ReplayService {
  final ReplayStore replayStore;
  final EventLog eventLog;
  final LocalCommandResolver commandResolver;

  const ReplayService({
    required this.replayStore,
    required this.eventLog,
    required this.commandResolver,
  });

  Future<ReplayTimeline> buildTimeline(String saveId) async {
    final initialSnapshot = await replayStore.initialSnapshot(saveId);
    if (initialSnapshot == null) {
      throw ReplayBuildException(
        ReplayBuildFailureReason.missingInitialSnapshot,
        'Replay seed snapshot not found for save: $saveId',
      );
    }

    var currentSnapshot = initialSnapshot;
    var currentState = initialSnapshot.toClientState();
    final steps = <ReplayStep>[];
    try {
      await for (final logged in eventLog.readSince(
        saveId,
        offset: currentSnapshot.eventLogOffset + 1,
      )) {
        if (logged.offset <= currentSnapshot.eventLogOffset) continue;
        if (logged.offset != currentSnapshot.eventLogOffset + 1) {
          throw ReplayBuildException(
            ReplayBuildFailureReason.offsetGap,
            'Replay log has a gap between offsets '
            '${currentSnapshot.eventLogOffset} and '
            '${logged.offset}.',
          );
        }

        final previousState = currentState;
        final command = _authoritativeReplayCommand(logged);
        final originatingTurn = _originatingReplayTurn(logged);
        final commandContext = logged.toCommandContext(
          victoryRules: currentSnapshot.domain.matchRules.victory,
          paceBalance: currentSnapshot.domain.matchRules.paceBalance,
          fallbackTurn: originatingTurn,
        );
        final resolved = _resolveReplayCommand(
          commandResolver: commandResolver,
          loggedCommand: logged,
          baseSnapshot: currentSnapshot,
          currentState: currentState,
          command: command,
          savedAt: logged.timestamp,
          context: commandContext,
        );
        final resolvedSnapshotWithOffset = resolved.snapshot.withEventLogOffset(
          logged.offset,
        );
        currentSnapshot = resolvedSnapshotWithOffset;
        currentState = resolved.state;
        _appendReplayStep(
          steps,
          logged: logged,
          resolved: resolved,
          snapshot: currentSnapshot,
          previousState: previousState,
          originatingTurn: originatingTurn,
        );
      }
    } on ReplayBuildException {
      rethrow;
    } catch (error) {
      throw ReplayBuildException(
        ReplayBuildFailureReason.corruptLog,
        'Replay log cannot be read for save: $saveId',
        cause: error,
      );
    }

    return ReplayTimeline(
      saveId: saveId,
      initialSnapshot: initialSnapshot,
      initialState: initialSnapshot.toClientState(),
      steps: List.unmodifiable(steps),
    );
  }
}

DomainCommand _authoritativeReplayCommand(RecordedDomainCommand logged) {
  return logged.command ??
      (throw ReplayBuildException(
        ReplayBuildFailureReason.corruptLog,
        'Replay log entry ${logged.offset} has a redacted command; '
        'deterministic replay is unavailable.',
      ));
}

int _originatingReplayTurn(RecordedDomainCommand logged) {
  return logged.turn ??
      (throw ReplayBuildException(
        ReplayBuildFailureReason.corruptLog,
        'Replay log entry ${logged.offset} has no originating turn.',
      ));
}

LocalCommandResolution _resolveReplayCommand({
  required LocalCommandResolver commandResolver,
  required RecordedDomainCommand loggedCommand,
  required CanonicalGameSnapshot baseSnapshot,
  required GameClientState currentState,
  required DomainCommand command,
  required DateTime savedAt,
  required GameCommandContext context,
}) {
  final effectiveContext = context.copyWith(
    actorPlayerId: ReplayStep.inferEffectiveActorPlayerId(
      loggedCommand: loggedCommand,
      state: currentState,
    ),
  );
  return commandResolver.resolve(
    baseSnapshot: baseSnapshot,
    currentState: currentState,
    command: command,
    savedAt: savedAt,
    context: effectiveContext,
  );
}

void _appendReplayStep(
  List<ReplayStep> steps, {
  required RecordedDomainCommand logged,
  required LocalCommandResolution resolved,
  required CanonicalGameSnapshot snapshot,
  required GameClientState previousState,
  required int originatingTurn,
}) {
  steps.add(
    ReplayStep(
      index: steps.length + 1,
      loggedCommand: logged,
      snapshot: snapshot,
      previousState: previousState,
      state: resolved.state,
      events: logged.events,
      uiEffects: resolved.uiEffects,
      combatAnimations: resolved.combatAnimations,
      movementExecutions: resolved.movementExecutions,
      originatingTurn: originatingTurn,
    ),
  );
}
