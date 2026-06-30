import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';

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

  GameSave get save => initialSnapshot.save;

  List<String> get playerIds {
    final ids = [
      for (final player in save.players)
        if (player.id.isNotEmpty) player.id,
      for (final playerId in save.playerStates.keys)
        if (playerId.isNotEmpty) playerId,
    ];
    return ids.toSet().toList()..sort();
  }

  int get firstTurn => save.turn;

  int get lastTurn {
    if (steps.isEmpty) return save.turn;
    return steps.last.save.turn;
  }
}

class ReplayStep {
  final int index;
  final LoggedCommand loggedCommand;
  final GameSave save;
  final GameState previousState;
  final GameState state;
  final List<GameEvent> events;
  final List<UiEffect> uiEffects;

  const ReplayStep({
    required this.index,
    required this.loggedCommand,
    required this.save,
    required this.previousState,
    required this.state,
    required this.events,
    required this.uiEffects,
  });

  int get offset => loggedCommand.offset;

  int get turn => loggedCommand.turn;

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
    return loggedCommand.actorPlayerId ??
        _inferActorPlayerId(
          command: loggedCommand.command,
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
      ResetUnitMovementCommand(:final playerId) => playerId,
      EndTurnCommand(:final playerId) ||
      SubmitTurnCommand(:final playerId) ||
      SetActivePlayerCommand(:final playerId) ||
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

    var currentSave = initialSnapshot.save;
    var currentState = initialSnapshot.toGameState();
    var currentOffset = initialSnapshot.eventLogOffset;
    final steps = <ReplayStep>[];

    try {
      await for (final logged in eventLog.readSince(
        saveId,
        offset: currentOffset + 1,
      )) {
        if (logged.offset <= currentOffset) continue;
        if (logged.offset != currentOffset + 1) {
          throw ReplayBuildException(
            ReplayBuildFailureReason.offsetGap,
            'Replay log has a gap between offsets $currentOffset and '
            '${logged.offset}.',
          );
        }

        final previousState = currentState;
        final commandContext = logged.toCommandContext();
        final effectiveActorPlayerId = ReplayStep.inferEffectiveActorPlayerId(
          loggedCommand: logged,
          state: currentState,
        );
        final baseSnapshot = SaveSnapshot.fromGameState(
          save: currentSave,
          state: currentState,
          eventLogOffset: currentOffset,
        );
        final resolved = commandResolver.resolve(
          baseSnapshot: baseSnapshot,
          currentState: currentState,
          command: logged.command,
          savedAt: logged.timestamp,
          context: commandContext.copyWith(
            actorPlayerId: effectiveActorPlayerId,
          ),
        );
        currentSave = resolved.save;
        currentState = resolved.state;
        currentOffset = logged.offset;
        steps.add(
          ReplayStep(
            index: steps.length + 1,
            loggedCommand: logged,
            save: currentSave,
            previousState: previousState,
            state: currentState,
            events: logged.events,
            uiEffects: resolved.uiEffects,
          ),
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
