import 'dart:async';

import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/ai_turn_command_pacer.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/command.dart';

typedef AiCommandDispatcher =
    Future<DispatchCommandResult> Function({
      required String saveId,
      required GameState currentState,
      required DomainCommand command,
      required GameCommandContext context,
    });

final class AiTurnCommandExecutionReport {
  final GameState finalState;
  final List<DomainCommand> dispatchedCommands;
  final List<DomainCommand> rejectedCommands;
  final List<DomainCommand> skippedTerminalCommands;
  final List<DomainCommand> skippedStaleCommands;
  final Duration dispatchDuration;
  final Duration interCommandDelayDuration;
  final int delayedCommandCount;

  AiTurnCommandExecutionReport({
    required this.finalState,
    required Iterable<DomainCommand> dispatchedCommands,
    required Iterable<DomainCommand> rejectedCommands,
    required Iterable<DomainCommand> skippedTerminalCommands,
    required Iterable<DomainCommand> skippedStaleCommands,
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
    required Iterable<DomainCommand> commands,
    required Duration interCommandDelay,
  }) async {
    var state = initialState;
    final dispatched = <DomainCommand>[];
    final rejected = <DomainCommand>[];
    final skippedTerminals = <DomainCommand>[];
    final skippedStale = <DomainCommand>[];
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

  static bool _isTerminal(DomainCommand command) {
    return command is EndTurnCommand || command is SubmitTurnCommand;
  }

  static bool _isMoveAlreadyAtTarget(MoveUnitCommand command, GameState state) {
    for (final unit in state.units) {
      if (unit.id == command.unitId) {
        return unit.occupies(command.targetCol, command.targetRow);
      }
    }
    return false;
  }

  static String describeCommand(DomainCommand command) {
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
      StartWonderCommand() =>
        'start ${command.wonderType.name} wonder in city ${command.cityId}',
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
      AssignMerchantTradeRouteCommand() =>
        'assign merchant ${command.unitId} trade route to city '
            '${command.destinationCityId}',
      MoveMerchantToCityCommand() =>
        'move merchant ${command.unitId} to city '
            '${command.destinationCityId}',
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
      SendGoldGiftCommand() =>
        'send ${command.amount} gold gift from ${command.playerId} to '
            '${command.targetPlayerId}',
      RushProductionCommand() => 'rush production in city ${command.cityId}',
      DetachTroopCommand() =>
        'detach ${command.troopType.name} from unit ${command.unitId}',
      ToggleWorkedHexCommand() =>
        'toggle worked hex (${command.col}, ${command.row}) for city '
            '${command.cityId}',
      SelectCityExpansionHexCommand() =>
        'select expansion hex (${command.col}, ${command.row}) for city '
            '${command.cityId}',
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
      CancelUnitActionCommand() => 'cancel unit action for ${command.unitId}',
    };
  }
}
