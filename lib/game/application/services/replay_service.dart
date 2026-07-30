import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/game_intent_resolver.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
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
  final SaveSnapshot initialSnapshot;
  final GameState initialState;
  final List<ReplayStep> steps;

  const ReplayTimeline({
    required this.saveId,
    required this.initialSnapshot,
    required this.initialState,
    required this.steps,
  });

  GameSnapshotMetadata get metadata => initialSnapshot.metadata;
  List<Player> get participants => initialSnapshot.domain.participants;
  MatchSessionState get session => initialSnapshot.session;
  CameraState get initialCamera {
    final camera = metadata.camera;
    return CameraState(x: camera.x, y: camera.y, zoom: camera.zoom);
  }

  List<String> get playerIds {
    final ids = [
      for (final player in participants)
        if (player.id.isNotEmpty) player.id,
      for (final playerId in session.turnStatesByPlayerId.keys)
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
  final LoggedCommand loggedCommand;
  final SaveSnapshot snapshot;
  final GameState previousState;
  final GameState state;
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
  MatchSessionState get session => snapshot.session;

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
    required LoggedCommand loggedCommand,
    required GameState state,
    GameState? previousState,
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
    required GameCommand command,
    required GameState state,
    required GameState previousState,
  }) {
    return switch (command) {
      EndTurnCommand(:final playerId) ||
      SubmitTurnCommand(:final playerId) ||
      SelectTechnologyCommand(:final playerId) ||
      CancelResearchSelectionCommand(:final playerId) ||
      FocusNextPendingActionCommand(:final playerId) ||
      FocusTurnStartActionCommand(:final playerId) ||
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
      StartMerchantTradeRouteSelectionCommand(:final unitId) ||
      CancelMerchantTradeRouteSelectionCommand(:final unitId) ||
      AssignMerchantTradeRouteCommand(:final unitId) ||
      StartMerchantMoveToCitySelectionCommand(:final unitId) ||
      CancelMerchantMoveToCitySelectionCommand(:final unitId) ||
      MoveMerchantToCityCommand(:final unitId) ||
      DetachTroopCommand(:final unitId) ||
      FoundCityCommand(founderId: final unitId) ||
      StartWorkerActionSelectionCommand(:final unitId) ||
      SelectWorkerImprovementCommand(:final unitId) ||
      ConfirmWorkerImprovementCommand(:final unitId) ||
      CancelWorkerActionSelectionCommand(:final unitId) ||
      CancelWorkerJobCommand(:final unitId) ||
      AssignWorkerToHexCommand(:final unitId) ||
      CancelWorkerAssignmentCommand(:final unitId) ||
      StartCommanderMergeSelectionCommand(commanderUnitId: final unitId) ||
      CancelCommanderMergeSelectionCommand(commanderUnitId: final unitId) ||
      StartAttackTargetingCommand(attackerUnitId: final unitId) ||
      CancelAttackTargetingCommand(attackerUnitId: final unitId) ||
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
      StartCityWorkedHexSelectionCommand(:final cityId) ||
      CancelCityWorkedHexSelectionCommand(:final cityId) ||
      ToggleWorkedHexCommand(:final cityId) ||
      StartCityExpansionSelectionCommand(:final cityId) ||
      CancelCityExpansionSelectionCommand(:final cityId) ||
      SelectCityExpansionHexCommand(:final cityId) ||
      CityTappedCommand(:final cityId) ||
      SelectCityCommand(
        :final cityId,
      ) => _cityOwner(cityId, state: state, previousState: previousState),
      SelectUnitCommand(:final unitId) => _unitOwner(
        unitId,
        state: state,
        previousState: previousState,
      ),
      TileTappedCommand() ||
      SelectTileCommand() ||
      ToggleMoveTargetingCommand() ||
      StartCityFoundingCommand() ||
      CancelCityFoundingCommand() => null,
    };
  }

  static String? _unitOwner(
    String unitId, {
    required GameState state,
    required GameState previousState,
  }) {
    return state.unitById(unitId)?.ownerPlayerId ??
        previousState.unitById(unitId)?.ownerPlayerId;
  }

  static String? _cityOwner(
    String cityId, {
    required GameState state,
    required GameState previousState,
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
    var currentState = initialSnapshot.toGameState();
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
        final command = logged.command;
        if (command == null) {
          throw ReplayBuildException(
            ReplayBuildFailureReason.corruptLog,
            'Replay log entry ${logged.offset} has a redacted command; '
            'deterministic replay is unavailable.',
          );
        }
        final originatingTurn = logged.turn ?? currentSnapshot.domain.turn;
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
      initialState: initialSnapshot.toGameState(),
      steps: List.unmodifiable(steps),
    );
  }
}

LocalCommandResolution _resolveReplayCommand({
  required LocalCommandResolver commandResolver,
  required LoggedCommand loggedCommand,
  required SaveSnapshot baseSnapshot,
  required GameState currentState,
  required GameCommand command,
  required DateTime savedAt,
  required GameCommandContext context,
}) {
  final effectiveContext = context.copyWith(
    actorPlayerId: ReplayStep.inferEffectiveActorPlayerId(
      loggedCommand: loggedCommand,
      state: currentState,
    ),
  );
  if (command is! GameIntent) {
    return commandResolver.resolve(
      baseSnapshot: baseSnapshot,
      currentState: currentState,
      command: command,
      savedAt: savedAt,
      context: effectiveContext,
    );
  }
  final intent = GameIntentResolver(
    reducer: commandResolver.reducer,
    context: effectiveContext,
  ).resolve(currentState.interaction, command, currentState);
  final interactionState = intent.interaction == currentState.interaction
      ? currentState
      : currentState.copyWith(interaction: intent.interaction);
  final domainCommand = intent.domainCommand;
  if (domainCommand == null) {
    return LocalCommandResolution(
      snapshot: baseSnapshot
          .withSavedAt(savedAt)
          .withGameState(interactionState),
      state: interactionState,
      events: const [],
      uiEffects: intent.presentationFocus,
      context: effectiveContext,
    );
  }
  final domain = commandResolver.resolve(
    baseSnapshot: baseSnapshot,
    currentState: interactionState,
    command: domainCommand,
    savedAt: savedAt,
    context: effectiveContext,
  );
  return LocalCommandResolution(
    snapshot: domain.snapshot,
    state: domain.state,
    events: domain.events,
    uiEffects: [...intent.presentationFocus, ...domain.uiEffects],
    context: domain.context,
    combatAnimations: domain.combatAnimations,
    movementExecutions: domain.movementExecutions,
  );
}

void _appendReplayStep(
  List<ReplayStep> steps, {
  required LoggedCommand logged,
  required LocalCommandResolution resolved,
  required SaveSnapshot snapshot,
  required GameState previousState,
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
