import 'dart:async';

import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/ai_turn_command_executor.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/command.dart';

enum AiTerminalCommand { endTurn, submitTurn }

enum AiPlanSource { fresh, precomputed, freshAfterPrecomputeFailure }

typedef AiPlanExecutor =
    Future<AiTurnPlan> Function({
      required AiStrategy strategy,
      required GameView view,
      required AiContext context,
    });

Future<AiTurnPlan> syncAiPlanExecutor({
  required AiStrategy strategy,
  required GameView view,
  required AiContext context,
}) async {
  return strategy.plan(view, context);
}

class AiTurnReport {
  final List<GameCommand> plannedCommands;
  final List<GameCommand> dispatchedCommands;
  final List<GameCommand> rejectedCommands;
  final List<GameCommand> skippedTerminalCommands;
  final List<GameCommand> skippedStaleCommands;
  final Duration planningDuration;
  final Duration executionDuration;
  final Duration dispatchDuration;
  final Duration interCommandDelayDuration;
  final Duration terminalDispatchDuration;
  final Duration totalDuration;
  final int delayedCommandCount;
  final AiPlanSource planningSource;
  final AiDebugInfo? debug;
  final GameCommand terminalCommand;
  final List<UiEffect> terminalUiEffects;
  final GameState finalState;

  AiTurnReport({
    required Iterable<GameCommand> plannedCommands,
    required Iterable<GameCommand> dispatchedCommands,
    required Iterable<GameCommand> rejectedCommands,
    required Iterable<GameCommand> skippedTerminalCommands,
    Iterable<GameCommand> skippedStaleCommands = const [],
    required this.planningDuration,
    required this.executionDuration,
    this.dispatchDuration = Duration.zero,
    this.interCommandDelayDuration = Duration.zero,
    this.terminalDispatchDuration = Duration.zero,
    required this.totalDuration,
    required this.delayedCommandCount,
    required this.planningSource,
    this.debug,
    required this.terminalCommand,
    Iterable<UiEffect> terminalUiEffects = const [],
    required this.finalState,
  }) : plannedCommands = List.unmodifiable(plannedCommands),
       dispatchedCommands = List.unmodifiable(dispatchedCommands),
       rejectedCommands = List.unmodifiable(rejectedCommands),
       skippedTerminalCommands = List.unmodifiable(skippedTerminalCommands),
       skippedStaleCommands = List.unmodifiable(skippedStaleCommands),
       terminalUiEffects = List.unmodifiable(terminalUiEffects);
}

class AiTurnRunner {
  final GameLogger? logger;
  final Future<void> Function(Duration duration) delay;
  final AiPlanExecutor planExecutor;
  final AiTurnCommandExecutor _commandExecutor;
  final AiCommandDispatcher _dispatch;

  AiTurnRunner({
    DispatchCommandUseCase? dispatchCommand,
    AiCommandDispatcher? dispatch,
    this.logger,
    this.delay = Future<void>.delayed,
    this.planExecutor = syncAiPlanExecutor,
  }) : assert(dispatchCommand != null || dispatch != null),
       _dispatch = dispatch ?? dispatchCommand!.execute,
       _commandExecutor = AiTurnCommandExecutor(
         dispatch: dispatch ?? dispatchCommand!.execute,
         logger: logger,
         delay: delay,
       );

  Future<AiTurnReport> run({
    required String saveId,
    required String playerId,
    required AiStrategy strategy,
    required AiContext context,
    required GameState initialState,
    required GameView view,
    Future<AiTurnPlan>? precomputedPlan,
    AiTerminalCommand terminalCommand = AiTerminalCommand.endTurn,
    Duration interCommandDelay = const Duration(milliseconds: 200),
  }) async {
    final totalStopwatch = Stopwatch()..start();
    final planningStopwatch = Stopwatch()..start();
    final resolvedPlan = await _resolvePlan(
      precomputedPlan: precomputedPlan,
      strategy: strategy,
      view: view,
      context: context,
    );
    planningStopwatch.stop();
    final plan = resolvedPlan.plan;
    logger?.info(
      'AI',
      'Planned ${plan.commands.length} command(s) for $playerId with '
          '${plan.debug?.strategyId ?? strategy.runtimeType} from '
          '${resolvedPlan.source.label} in '
          '${planningStopwatch.elapsedMilliseconds}ms',
    );
    final executionStopwatch = Stopwatch()..start();
    final commandExecution = await _commandExecutor.executePlan(
      saveId: saveId,
      playerId: playerId,
      aiContext: context,
      initialState: initialState,
      commands: plan.commands,
      interCommandDelay: interCommandDelay,
    );

    final terminal = _terminalFor(terminalCommand, playerId);
    logger?.info(
      'AI',
      'Executing terminal command for $playerId: '
          '${AiTurnCommandExecutor.describeCommand(terminal)}',
    );
    final terminalDispatchStopwatch = Stopwatch()..start();
    final terminalResult = await _dispatch(
      saveId: saveId,
      currentState: commandExecution.finalState,
      command: terminal,
      context: AiTurnCommandExecutor.commandContext(
        playerId: playerId,
        aiContext: context,
      ),
    );
    terminalDispatchStopwatch.stop();
    final terminalDispatchDuration = terminalDispatchStopwatch.elapsed;
    final dispatchDuration =
        commandExecution.dispatchDuration + terminalDispatchDuration;
    executionStopwatch.stop();
    totalStopwatch.stop();
    logger?.info(
      'AI Runtime',
      'turn player=$playerId source=${resolvedPlan.source.label} '
          'planning=${planningStopwatch.elapsedMilliseconds}ms '
          'execution=${executionStopwatch.elapsedMilliseconds}ms '
          'dispatch=${dispatchDuration.inMilliseconds}ms '
          'delay=${commandExecution.interCommandDelayDuration.inMilliseconds}ms '
          'delayedCommands=${commandExecution.delayedCommandCount} '
          'terminalDispatch=${terminalDispatchDuration.inMilliseconds}ms '
          'total=${totalStopwatch.elapsedMilliseconds}ms '
          'planned=${plan.commands.length} '
          'dispatched=${commandExecution.dispatchedCommands.length} '
          'rejected=${commandExecution.rejectedCommands.length} '
          'skippedTerminal=${commandExecution.skippedTerminalCommands.length}'
          '${_debugStats(plan.debug)}',
    );

    return AiTurnReport(
      plannedCommands: plan.commands,
      dispatchedCommands: commandExecution.dispatchedCommands,
      rejectedCommands: commandExecution.rejectedCommands,
      skippedTerminalCommands: commandExecution.skippedTerminalCommands,
      skippedStaleCommands: commandExecution.skippedStaleCommands,
      planningDuration: planningStopwatch.elapsed,
      executionDuration: executionStopwatch.elapsed,
      dispatchDuration: dispatchDuration,
      interCommandDelayDuration: commandExecution.interCommandDelayDuration,
      terminalDispatchDuration: terminalDispatchDuration,
      totalDuration: totalStopwatch.elapsed,
      delayedCommandCount: commandExecution.delayedCommandCount,
      planningSource: resolvedPlan.source,
      debug: plan.debug,
      terminalCommand: terminal,
      terminalUiEffects: terminalResult.uiEffects,
      finalState: terminalResult.state,
    );
  }

  Future<_ResolvedAiTurnPlan> _resolvePlan({
    required Future<AiTurnPlan>? precomputedPlan,
    required AiStrategy strategy,
    required GameView view,
    required AiContext context,
  }) async {
    if (precomputedPlan != null) {
      try {
        return _ResolvedAiTurnPlan(
          await precomputedPlan,
          AiPlanSource.precomputed,
        );
      } catch (error, stackTrace) {
        logger?.warn(
          'AI',
          'Precomputed AI plan failed; falling back to fresh planning.',
          error,
          stackTrace,
        );
        return _ResolvedAiTurnPlan(
          await planExecutor(strategy: strategy, view: view, context: context),
          AiPlanSource.freshAfterPrecomputeFailure,
        );
      }
    }

    return _ResolvedAiTurnPlan(
      await planExecutor(strategy: strategy, view: view, context: context),
      AiPlanSource.fresh,
    );
  }

  static String _debugStats(AiDebugInfo? debug) {
    final notes = debug?.notes;
    if (notes == null || notes.isEmpty) return '';
    return ' debug="${notes.join('; ')}"';
  }

  static GameCommand _terminalFor(
    AiTerminalCommand terminalCommand,
    String playerId,
  ) {
    return switch (terminalCommand) {
      AiTerminalCommand.endTurn => EndTurnCommand(playerId),
      AiTerminalCommand.submitTurn => SubmitTurnCommand(playerId),
    };
  }
}

class _ResolvedAiTurnPlan {
  final AiTurnPlan plan;
  final AiPlanSource source;

  const _ResolvedAiTurnPlan(this.plan, this.source);
}

extension on AiPlanSource {
  String get label {
    return switch (this) {
      AiPlanSource.fresh => 'fresh',
      AiPlanSource.precomputed => 'precomputed',
      AiPlanSource.freshAfterPrecomputeFailure =>
        'fresh-after-precompute-failure',
    };
  }
}
