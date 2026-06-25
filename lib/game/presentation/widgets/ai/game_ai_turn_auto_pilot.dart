import 'dart:async';

import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_runtime_strategy_resolver.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_strategic_plan_provider.dart';
import 'package:aonw/game/application/services/ai_turn_run_scheduler.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/services/ai_turn_auto_scheduler.dart';
import 'package:aonw/game/presentation/services/ai_turn_execution_runner.dart';
import 'package:aonw/game/presentation/services/ai_turn_follow_up_runner.dart';
import 'package:aonw/game/presentation/services/ai_turn_lifecycle_coordinator.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_coordinator.dart';
import 'package:aonw/game/presentation/services/ai_turn_precompute_runner.dart';
import 'package:aonw/game/presentation/services/ai_turn_presentation_driver.dart';
import 'package:aonw/game/presentation/services/ai_turn_process_preparer.dart';
import 'package:aonw/game/presentation/services/ai_turn_runtime_coordinator.dart';
import 'package:aonw/game/presentation/services/isolated_ai_plan_executor.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_rules.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/providers/ai_settings_provider.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameAiTurnAutoPilot extends ConsumerStatefulWidget {
  final GameSave? gameSave;
  final Duration interCommandDelay;

  const GameAiTurnAutoPilot({
    required this.gameSave,
    this.interCommandDelay = const Duration(milliseconds: 40),
    super.key,
  });

  @override
  ConsumerState<GameAiTurnAutoPilot> createState() =>
      _GameAiTurnAutoPilotState();
}

class _GameAiTurnAutoPilotState extends ConsumerState<GameAiTurnAutoPilot>
    with WidgetsBindingObserver {
  late final AiTurnRuntimeCoordinator _runtimeCoordinator;
  late final AiTurnLifecycleCoordinator _lifecycleCoordinator;
  final AiTurnPlanPrecomputeCache _precomputeCache =
      AiTurnPlanPrecomputeCache();
  final AiStrategicPlanProvider _strategicPlanProvider =
      AiStrategicPlanProvider();
  final AiRuntimeThrottler _runtimeThrottler = AiRuntimeThrottler();
  final AiTurnPrecomputeCoordinator _precomputeCoordinator =
      AiTurnPrecomputeCoordinator();
  final AiTurnRunScheduler _runScheduler = AiTurnRunScheduler();

  AiStrategyRegistry _strategyRegistryFor({
    required String playerId,
    required GameSave save,
    required GameState gameState,
    required NetworkSession? networkSession,
  }) {
    return _aiRuntimeStrategyResolver().resolve(
      playerId: playerId,
      save: save,
      gameState: gameState,
      networkSession: networkSession,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runtimeCoordinator = _createAiTurnRuntimeCoordinator();
    _lifecycleCoordinator = _createAiTurnLifecycleCoordinator();
  }

  @override
  void didUpdateWidget(GameAiTurnAutoPilot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _lifecycleCoordinator.handleSaveChange(
      previousSave: oldWidget.gameSave,
      currentSave: widget.gameSave,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleCoordinator.handleLifecyclePaused(
      state != AppLifecycleState.resumed,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleCoordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final save = widget.gameSave;
    final control = ref.watch(gamePlayerControlControllerProvider);
    final handoff = ref.watch(gameHandoffProvider);
    final networkSession = ref.watch(networkSessionProvider);
    ref.watch(aiSettingsProvider);
    final gameState = save == null
        ? null
        : ref.watch(gameStateProvider(save.id)).value;
    _aiTurnAutoScheduler().evaluate(
      save: save,
      control: control,
      handoff: handoff,
      networkSession: networkSession,
      gameState: gameState,
    );
    return const SizedBox.shrink();
  }

  AiTurnAutoScheduler _aiTurnAutoScheduler() {
    return AiTurnAutoScheduler(
      logger: ref.read(gameLoggerProvider),
      runScheduler: _runScheduler,
      precomputeCoordinator: _precomputeCoordinator,
      precomputeCache: _precomputeCache,
      throttler: _runtimeThrottler,
      shouldRunLocalAi: GameAiTurnAutoPilotRules.shouldRunLocalAi,
      aiPlayerToRun: GameAiTurnAutoPilotRules.aiPlayerToRun,
      scheduleTurn: _runtimeCoordinator.scheduleTurn,
      schedulePendingPrecompute: _runtimeCoordinator.schedulePendingPrecompute,
      precomputeStats: _runtimeCoordinator.precomputeStats,
      throttleStats: _runtimeCoordinator.throttleStats,
      logThrottleChange: _runtimeCoordinator.logThrottleChange,
    );
  }

  AiTurnLifecycleCoordinator _createAiTurnLifecycleCoordinator() {
    return AiTurnLifecycleCoordinator(
      runScheduler: _runScheduler,
      precomputeCoordinator: _precomputeCoordinator,
      precomputeCache: _precomputeCache,
      strategicPlanProvider: _strategicPlanProvider,
      throttler: _runtimeThrottler,
      cancelQueuedPrecompute: _runtimeCoordinator.cancelQueuedPrecompute,
      schedulePendingPrecompute: _runtimeCoordinator.schedulePendingPrecompute,
      shutdownPrecomputeExecutor: () {
        unawaited(shutdownIsolatedAiPlanExecutor());
      },
    );
  }

  AiTurnRuntimeCoordinator _createAiTurnRuntimeCoordinator() {
    return AiTurnRuntimeCoordinator(
      logger: ref.read(gameLoggerProvider),
      runScheduler: _runScheduler,
      precomputeCoordinator: _precomputeCoordinator,
      throttler: _runtimeThrottler,
      executionRunner: _aiTurnExecutionRunner,
      precomputeRunner: _aiTurnPrecomputeRunner,
      schedulePostFrame: (callback) {
        WidgetsBinding.instance.addPostFrameCallback((_) => callback());
      },
      canContinue: () => mounted,
      notifyStateChanged: () {
        if (mounted) setState(() {});
      },
      interCommandDelay: () => widget.interCommandDelay,
      now: _nowUtc,
    );
  }

  AiRuntimeStrategyResolver _aiRuntimeStrategyResolver() {
    return AiRuntimeStrategyResolver(
      logger: ref.read(gameLoggerProvider),
      throttler: _runtimeThrottler,
      forceBatterySaver: () => ref.read(aiSettingsProvider).batterySaver,
    );
  }

  AiTurnExecutionRunner _aiTurnExecutionRunner() {
    final followUpRunner = _aiTurnFollowUpRunner();
    return AiTurnExecutionRunner.fromPreparedProcess(
      logger: ref.read(gameLoggerProvider),
      throttler: _runtimeThrottler,
      prepareProcess: _prepareAiTurnProcess,
      invalidateSaveSnapshot: (saveId) =>
          ref.invalidate(gameSaveSnapshotProvider(saveId)),
      advanceAfterAiTurn: followUpRunner.advanceAfterAiTurn,
      canContinue: () => mounted,
      precomputeStats: _runtimeCoordinator.precomputeStats,
      throttleStats: _runtimeCoordinator.throttleStats,
      logThrottleChange: _runtimeCoordinator.logThrottleChange,
    );
  }

  AiTurnFollowUpRunner _aiTurnFollowUpRunner() {
    final presentationDriver = _aiTurnPresentationDriver();
    return AiTurnFollowUpRunner(
      logger: ref.read(gameLoggerProvider),
      localAiRuntimeEnabled: (save) {
        return GameAiTurnAutoPilotRules.shouldRunLocalAi(
          save: save,
          networkSession: ref.read(networkSessionProvider),
        );
      },
      controlPlayerId: () {
        return ref.read(gamePlayerControlControllerProvider).activePlayerId;
      },
      playTurnAdvanceEffects: ({required saveId, required terminalUiEffects}) {
        return presentationDriver.playTurnAdvanceEffects(
          saveId: saveId,
          terminalUiEffects: terminalUiEffects,
        );
      },
      confirmHumanTurn: (playerId) {
        return ref
            .read(gamePlayerControlControllerProvider.notifier)
            .confirmHandoff(playerId, resetMovement: false);
      },
      focusTurnStartMapTarget: (playerId) {
        return ref
            .read(gameCommandControllerProvider.notifier)
            .focusTurnStartMapTarget(playerId);
      },
      canContinue: () => mounted,
      clearHandoff: ref.read(gameHandoffProvider.notifier).clear,
      setHandoff: ref.read(gameHandoffProvider.notifier).setPending,
      playerNameFormatter: (player) {
        return GameDisplayNames.player(AppLocalizations.of(context), player);
      },
    );
  }

  AiTurnPrecomputeRunner _aiTurnPrecomputeRunner() {
    return AiTurnPrecomputeRunner(
      logger: ref.read(gameLoggerProvider),
      coordinator: _precomputeCoordinator,
      throttler: _runtimeThrottler,
      planExecutor: isolatedAiPlanPrecomputeExecutor,
      startPrecompute:
          ({required saveId, required playerId, required planExecutor}) async {
            final process = await _prepareAiTurnProcess(
              saveId: saveId,
              playerId: playerId,
            );
            return process?.precompute(planExecutor: planExecutor);
          },
      cacheSizeReader: () => _precomputeCache.length,
      precomputeStats: _runtimeCoordinator.precomputeStats,
      throttleStats: _runtimeCoordinator.throttleStats,
      logThrottleChange: _runtimeCoordinator.logThrottleChange,
    );
  }

  Future<PreparedAiTurnProcess?> _prepareAiTurnProcess({
    required String saveId,
    required String playerId,
    int? scheduledTurn,
  }) {
    final presentationDriver = _aiTurnPresentationDriver();
    final preparer = AiTurnProcessPreparer(
      repository: ref.read(gameRepositoryProvider),
      logger: ref.read(gameLoggerProvider),
      dispatch: presentationDriver.dispatchCommand,
      planExecutor: isolatedAiPlanExecutor,
      sessionReader: () => ref.read(activeGameSessionProvider),
      networkSessionReader: () => ref.read(networkSessionProvider),
      canContinue: () => mounted,
      shouldRunLocalAiForMode: GameAiTurnAutoPilotRules.shouldRunLocalAiForMode,
      canRunScheduledAiTurn: GameAiTurnAutoPilotRules.canRunScheduledAiTurn,
      strategyRegistryFor: _strategyRegistryFor,
      rulesetReader: () {
        return GameRuleset(
          city: ref.read(cityRulesetProvider),
          technology: ref.read(technologyRulesetProvider),
        );
      },
      eventLogReader: () => ref.read(eventLogProvider),
      precomputeCache: _precomputeCache,
      strategicPlanProvider: _strategicPlanProvider,
    );
    return preparer.prepare(
      saveId: saveId,
      playerId: playerId,
      scheduledTurn: scheduledTurn,
    );
  }

  AiTurnPresentationDriver _aiTurnPresentationDriver() {
    return AiTurnPresentationDriver(
      sessionReader: () => ref.read(activeGameSessionProvider),
      stateReader: (saveId) => ref.read(gameStateProvider(saveId)).value,
      localizationReader: () => ref.read(activeRendererViewModelProvider)?.l10n,
      applyTransition: (state, effects) async {
        final renderer = ref.read(activeRendererViewModelProvider);
        if (renderer == null) return;
        await renderer.applyTransition(state, effects);
      },
      hiddenDispatch: ({required saveId, required command, required context}) {
        return ref
            .read(gameStateProvider(saveId).notifier)
            .dispatchTransition(command, context: context);
      },
    );
  }

  DateTime _nowUtc() => ref.read(gameClockProvider).nowUtc();
}
