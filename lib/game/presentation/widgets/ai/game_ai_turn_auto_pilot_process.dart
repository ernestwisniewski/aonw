import 'package:aonw/game/presentation/engine/renderer_view_model.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_runner.dart';
import 'package:aonw/game/presentation/services/ai_turn_presentation_driver.dart';
import 'package:aonw/game/presentation/services/ai_turn_process_preparer.dart';
import 'package:aonw/game/presentation/services/isolated_ai_plan_executor.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_context.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_rules.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_runtime.dart';
import 'package:aonw_core/game/domain/ruleset.dart';

extension GameAiTurnAutoPilotProcess on GameAiTurnAutoPilotContext {
  AiTurnPrecomputeRunner aiTurnPrecomputeRunner() {
    return AiTurnPrecomputeRunner(
      logger: ref.read(gameLoggerProvider),
      coordinator: precomputeCoordinator,
      throttler: runtimeThrottler,
      planExecutor: isolatedAiPlanPrecomputeExecutor,
      startPrecompute:
          ({required saveId, required playerId, required planExecutor}) async {
            final process = await prepareAiTurnProcess(
              saveId: saveId,
              playerId: playerId,
            );
            return process?.precompute(planExecutor: planExecutor);
          },
      cacheSizeReader: () => precomputeCache.length,
      precomputeStats: runtimeCoordinator.precomputeStats,
      throttleStats: runtimeCoordinator.throttleStats,
      logThrottleChange: runtimeCoordinator.logThrottleChange,
    );
  }

  Future<PreparedAiTurnProcess?> prepareAiTurnProcess({
    required String saveId,
    required String playerId,
    int? scheduledTurn,
  }) async {
    final executionToken = scheduledTurn == null
        ? null
        : followUpIdentityGuard.beginExecution(
            saveId: saveId,
            turn: scheduledTurn,
            playerId: playerId,
          );
    if (scheduledTurn != null && executionToken == null) return null;

    final presentationDriver = aiTurnPresentationDriver();
    final preparer = AiTurnProcessPreparer(
      repository: ref.read(gameRepositoryProvider),
      logger: ref.read(gameLoggerProvider),
      dispatch: presentationDriver.dispatchCommand,
      planExecutor: isolatedAiPlanExecutor,
      sessionReader: () => ref.read(activeGameSessionProvider),
      networkSessionReader: () => ref.read(networkSessionProvider),
      canContinue: canContinue,
      shouldRunLocalAiForMode: GameAiTurnAutoPilotRules.shouldRunLocalAiForMode,
      canRunScheduledAiTurn: GameAiTurnAutoPilotRules.canRunScheduledAiTurn,
      strategyRegistryFor: strategyRegistryFor,
      rulesetReader: () {
        return GameRuleset.standard().copyWith(
          city: ref.read(cityRulesetProvider),
          technology: ref.read(technologyRulesetProvider),
          stability: ref.read(stabilityRulesetProvider),
        );
      },
      eventLogReader: () => ref.read(eventLogProvider),
      precomputeCache: precomputeCache,
      strategicPlanProvider: strategicPlanProvider,
    );
    return preparer.prepare(
      saveId: saveId,
      playerId: playerId,
      scheduledTurn: scheduledTurn,
    );
  }

  AiTurnPresentationDriver aiTurnPresentationDriver() {
    return AiTurnPresentationDriver(
      sessionReader: () => ref.read(activeGameSessionProvider),
      stateReader: (saveId) => ref.read(gameStateProvider(saveId)).value,
      localizationReader: () => ref.read(activeRendererViewModelProvider)?.l10n,
      applyTransition: (state, effects) async {
        final renderer = ref.read(activeRendererViewModelProvider);
        if (renderer == null) return;
        await renderer.applyTransition(state, effects);
      },
      applyProjectedTransition: (state, batch) async {
        final renderer = ref.read(activeRendererViewModelProvider);
        if (renderer == null) return;
        await renderer.applyProjectedTransition(state, batch);
      },
      hiddenDispatch: ({required saveId, required command, required context}) {
        return ref
            .read(gameStateProvider(saveId).notifier)
            .dispatchTransition(
              command,
              context: context,
              canPublish: canContinue,
            );
      },
      canContinue: canContinue,
    );
  }
}
