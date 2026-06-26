import 'dart:async';

import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/ai_turn_command_pacer.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/command.dart';

typedef AiCommandDispatcher =
    Future<DispatchCommandResult> Function({
      required String saveId,
      required GameState currentState,
      required GameCommand command,
      required GameCommandContext context,
    });

final class AiTurnCommandExecutionReport {
  final GameState finalState;
  final List<GameCommand> dispatchedCommands;
  final List<GameCommand> rejectedCommands;
  final List<GameCommand> skippedTerminalCommands;
  final List<GameCommand> skippedStaleCommands;
  final Duration dispatchDuration;
  final Duration interCommandDelayDuration;
  final int delayedCommandCount;

  AiTurnCommandExecutionReport({
    required this.finalState,
    required Iterable<GameCommand> dispatchedCommands,
    required Iterable<GameCommand> rejectedCommands,
    required Iterable<GameCommand> skippedTerminalCommands,
    required Iterable<GameCommand> skippedStaleCommands,
    required this.dispatchDuration,
    required this.interCommandDelayDuration,
    required this.delayedCommandCount,
  }) : dispatchedCommands = List.unmodifiable(dispatchedCommands),
       rejectedCommands = List.unmodifiable(rejectedCommands),
       skippedTerminalCommands = List.unmodifiable(skippedTerminalCommands),
       skippedStaleCommands = List.unmodifiable(skippedStaleCommands);
}

final class AiTurnCommandExecutor {
  final GameLogger? logger;
  final AiTurnCommandPacer commandPacer;
  final AiCommandDispatcher _dispatch;

  AiTurnCommandExecutor({
    required AiCommandDispatcher dispatch,
    this.logger,
    Future<void> Function(Duration duration)? delay,
    AiTurnCommandPacer? commandPacer,
  }) : _dispatch = dispatch,
       commandPacer =
           commandPacer ??
           AiTurnCommandPacer(delay: delay ?? Future<void>.delayed);

  Future<AiTurnCommandExecutionReport> executePlan({
    required String saveId,
    required String playerId,
    required AiContext aiContext,
    required GameState initialState,
    required Iterable<GameCommand> commands,
    required Duration interCommandDelay,
  }) async {
    var state = initialState;
    final dispatched = <GameCommand>[];
    final rejected = <GameCommand>[];
    final skippedTerminals = <GameCommand>[];
    final skippedStale = <GameCommand>[];
    var dispatchDuration = Duration.zero;
    var interCommandDelayDuration = Duration.zero;
    var delayedCommandCount = 0;

    final commandList = commands.toList(growable: false);
    final executableCommandCount = commandList
        .where((command) => !_isTerminal(command))
        .length;
    var commandIndex = 0;

    for (final command in commandList) {
      if (_isTerminal(command)) {
        skippedTerminals.add(command);
        logger?.warn(
          'AI',
          'AI strategy returned terminal command; runner owns turn submit: '
              '${describeCommand(command)}.',
        );
        continue;
      }
      if (command case final MoveUnitCommand moveCommand
          when _isMoveAlreadyAtTarget(moveCommand, state)) {
        skippedStale.add(command);
        logger?.info(
          'AI',
          'Skipping stale move for $playerId: ${describeCommand(command)}',
        );
        continue;
      }

      commandIndex += 1;
      logger?.info(
        'AI',
        'Executing command $commandIndex/$executableCommandCount for '
            '$playerId: ${describeCommand(command)}',
      );
      final dispatchStopwatch = Stopwatch()..start();
      final result = await _dispatch(
        saveId: saveId,
        currentState: state,
        command: command,
        context: commandContext(playerId: playerId, aiContext: aiContext),
      );
      dispatchStopwatch.stop();
      dispatchDuration += dispatchStopwatch.elapsed;

      if (result.state == state) {
        rejected.add(command);
        logger?.info(
          'AI',
          'Command rejected for $playerId: ${describeCommand(command)}',
        );
        continue;
      }

      state = result.state;
      dispatched.add(command);

      final pause = await commandPacer.pauseAfterDispatch(
        result: result,
        interCommandDelay: interCommandDelay,
      );
      if (pause.paused) {
        delayedCommandCount += 1;
        interCommandDelayDuration += pause.duration;
      }
    }

    return AiTurnCommandExecutionReport(
      finalState: state,
      dispatchedCommands: dispatched,
      rejectedCommands: rejected,
      skippedTerminalCommands: skippedTerminals,
      skippedStaleCommands: skippedStale,
      dispatchDuration: dispatchDuration,
      interCommandDelayDuration: interCommandDelayDuration,
      delayedCommandCount: delayedCommandCount,
    );
  }

  static GameCommandContext commandContext({
    required String playerId,
    required AiContext aiContext,
  }) {
    return GameCommandContext(
      actorPlayerId: playerId,
      canAct: true,
      combatSeedTurn: aiContext.turn,
      ignoreFogOfWar: true,
    );
  }

  static bool _isTerminal(GameCommand command) {
    return command is EndTurnCommand || command is SubmitTurnCommand;
  }

  static bool _isMoveAlreadyAtTarget(MoveUnitCommand command, GameState state) {
    for (final unit in state.units) {
      if (unit.id == command.unitId) {
        return unit.col == command.targetCol && unit.row == command.targetRow;
      }
    }
    return false;
  }

  static String describeCommand(GameCommand command) {
    return switch (command) {
      MoveUnitCommand() =>
        'move unit ${command.unitId} to '
            '(${command.targetCol}, ${command.targetRow})',
      AttackHexCommand() =>
        'attack hex (${command.defenderCol}, ${command.defenderRow}) with '
            'unit ${command.attackerUnitId}',
      FoundCityCommand() =>
        'found city with unit ${command.founderId} controlling '
            '${command.controlledHexes.length} hex(es)',
      SelectTechnologyCommand() =>
        'research ${command.technologyId.name} for ${command.playerId}',
      StartUnitProductionCommand() =>
        'start ${command.unitType.name} production in city ${command.cityId}',
      StartBuildingCommand() =>
        'start ${command.buildingType.name} in city ${command.cityId}',
      StartCityProjectCommand() =>
        'start ${command.projectType.name} project in city ${command.cityId}',
      SetCitySpecializationCommand() =>
        'set city ${command.cityId} specialization to '
            '${command.specialization.name}',
      SelectWorkerImprovementCommand() =>
        'select ${command.improvementType.name} improvement for worker '
            '${command.unitId}',
      ConfirmWorkerImprovementCommand() =>
        'confirm worker improvement for ${command.unitId}',
      AssignWorkerToHexCommand() => 'assign worker ${command.unitId} to hex',
      CancelWorkerAssignmentCommand() =>
        'cancel worker ${command.unitId} assignment',
      CancelWorkerJobCommand() => 'cancel worker ${command.unitId} job',
      SkipUnitTurnCommand() => 'skip unit ${command.unitId}',
      FortifyUnitCommand() => 'fortify/heal unit ${command.unitId}',
      AutoExploreUnitCommand() => 'auto-explore unit ${command.unitId}',
      StartMerchantTradeRouteSelectionCommand() =>
        'start merchant trade route selection for ${command.unitId}',
      CancelMerchantTradeRouteSelectionCommand() =>
        'cancel merchant trade route selection for ${command.unitId}',
      AssignMerchantTradeRouteCommand() =>
        'assign merchant ${command.unitId} trade route to city '
            '${command.destinationCityId}',
      StartMerchantMoveToCitySelectionCommand() =>
        'start merchant city travel selection for ${command.unitId}',
      CancelMerchantMoveToCitySelectionCommand() =>
        'cancel merchant city travel selection for ${command.unitId}',
      MoveMerchantToCityCommand() =>
        'move merchant ${command.unitId} to city '
            '${command.destinationCityId}',
      ResetUnitMovementCommand() =>
        'reset movement for ${command.playerId ?? 'all players'}',
      EndTurnCommand() => 'end turn for ${command.playerId}',
      SubmitTurnCommand() => 'submit turn for ${command.playerId}',
      SendDiplomaticProposalCommand() =>
        'send ${command.kind.name} proposal from ${command.playerId} to '
            '${command.targetPlayerId}',
      RespondDiplomaticProposalCommand() =>
        '${command.accepted ? 'accept' : 'reject'} diplomatic proposal '
            '${command.proposalId} for ${command.playerId}',
      SendDiplomaticMessageCommand() =>
        'send ${command.topic.name} diplomatic message from ${command.playerId} '
            'to ${command.targetPlayerId}',
      RespondDiplomaticMessageCommand() =>
        'respond ${command.response.name} to diplomatic message '
            '${command.messageId} for ${command.playerId}',
      DeclareWarCommand() =>
        'declare war from ${command.playerId} to ${command.targetPlayerId}',
      RushProductionCommand() => 'rush production in city ${command.cityId}',
      DetachTroopCommand() =>
        'detach ${command.troopType.name} from unit ${command.unitId}',
      TileTappedCommand() => 'tap tile (${command.col}, ${command.row})',
      CityTappedCommand() => 'tap city ${command.cityId}',
      SelectTileCommand() => 'select tile (${command.col}, ${command.row})',
      SelectUnitCommand() => 'select unit ${command.unitId}',
      SelectCityCommand() => 'select city ${command.cityId}',
      FocusNextPendingActionCommand() =>
        'focus next pending action for ${command.playerId}',
      FocusTurnStartActionCommand() =>
        'focus turn-start action for ${command.playerId}',
      StartAttackTargetingCommand() =>
        'start attack targeting for ${command.attackerUnitId}',
      CancelAttackTargetingCommand() =>
        'cancel attack targeting for ${command.attackerUnitId}',
      StartWorkerActionSelectionCommand() =>
        'start worker action selection for ${command.unitId}',
      CancelWorkerActionSelectionCommand() =>
        'cancel worker action selection for ${command.unitId}',
      CancelResearchSelectionCommand() =>
        'cancel research selection for ${command.playerId}',
      StartCityFoundingCommand() => 'start city founding',
      CancelCityFoundingCommand() => 'cancel city founding',
      StartCityWorkedHexSelectionCommand() =>
        'start worked-hex selection for city ${command.cityId}',
      CancelCityWorkedHexSelectionCommand() =>
        'cancel worked-hex selection for city ${command.cityId}',
      ToggleWorkedHexCommand() =>
        'toggle worked hex (${command.col}, ${command.row}) for city '
            '${command.cityId}',
      StartCityExpansionSelectionCommand() =>
        'start city expansion selection for city ${command.cityId}',
      CancelCityExpansionSelectionCommand() =>
        'cancel city expansion selection for city ${command.cityId}',
      SelectCityExpansionHexCommand() =>
        'select expansion hex (${command.col}, ${command.row}) for city '
            '${command.cityId}',
      ToggleMoveTargetingCommand() => 'toggle move targeting',
      StartCommanderMergeSelectionCommand() =>
        'start commander merge selection for ${command.commanderUnitId}',
      CancelCommanderMergeSelectionCommand() =>
        'cancel commander merge selection for ${command.commanderUnitId}',
      StartArtifactExcavationCommand() =>
        'start artifact excavation with unit ${command.unitId}',
      StoreArtifactInCityCommand() =>
        'store carried artifact from unit ${command.unitId}',
      TradeArtifactCommand() =>
        'trade artifact ${command.offeredArtifactId} from '
            '${command.playerId} to ${command.targetPlayerId}',
      OpenResourceTradeCommand() =>
        'open ${command.resource.name} trade from '
            '${command.targetPlayerId} to ${command.playerId}',
      OpenResourceExchangeCommand() =>
        'exchange ${command.offeredResource.name} from ${command.playerId} '
            'for ${command.requestedResource.name} from '
            '${command.targetPlayerId}',
      SetActivePlayerCommand() =>
        'set active player ${command.playerId} canAct=${command.canAct}',
      CancelUnitActionCommand() => 'cancel unit action for ${command.unitId}',
    };
  }
}
