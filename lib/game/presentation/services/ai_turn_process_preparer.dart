import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_planning_deadline_policy.dart';
import 'package:aonw/game/application/services/ai_recent_hostility_tracker.dart';
import 'package:aonw/game/application/services/ai_strategic_plan_provider.dart';
import 'package:aonw/game/application/services/ai_turn_command_executor.dart';
import 'package:aonw/game/application/services/ai_turn_runner.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/multiplayer_save_origin.dart';
import 'package:aonw/game/application/use_cases/run_ai_turn_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';

typedef AiTurnSessionReader = GameSession? Function();

typedef AiTurnNetworkSessionReader = NetworkSession? Function();

typedef AiTurnCanContinue = bool Function();

typedef AiTurnRulesetReader = GameRuleset Function();

typedef AiTurnEventLogReader = EventLog Function();

typedef ScheduledAiTurnValidator =
    bool Function({
      required GameSave save,
      required int scheduledTurn,
      required String playerId,
    });

typedef LocalAiRuntimeModeValidator =
    bool Function({
      required GameMode gameMode,
      required String saveId,
      required NetworkSession? networkSession,
    });

typedef AiTurnStrategyRegistryFactory =
    AiStrategyRegistry Function({
      required String playerId,
      required GameSave save,
      required GameClientState gameState,
      required NetworkSession? networkSession,
    });

final class PreparedAiTurnProcess {
  final GameRepository repository;
  final RunAiTurnUseCase useCase;
  final CanonicalGameSnapshot snapshot;
  final String saveId;
  final String playerId;

  const PreparedAiTurnProcess({
    required this.repository,
    required this.useCase,
    required this.snapshot,
    required this.saveId,
    required this.playerId,
  });

  Future<AiTurnPrecomputeHandle?> precompute({
    AiPlanExecutor planExecutor = syncAiPlanExecutor,
  }) {
    return useCase.precompute(
      saveId: saveId,
      playerId: playerId,
      snapshot: snapshot,
      planExecutor: planExecutor,
    );
  }

  Future<AiTurnReport?> execute({
    AiTerminalCommand? terminalCommand,
    Duration interCommandDelay = const Duration(milliseconds: 200),
    Future<void> Function()? onStalePrecomputeDropped,
  }) {
    return useCase.execute(
      saveId: saveId,
      playerId: playerId,
      snapshot: snapshot,
      terminalCommand: terminalCommand,
      interCommandDelay: interCommandDelay,
      onStalePrecomputeDropped: onStalePrecomputeDropped,
    );
  }
}

final class AiTurnProcessPreparer {
  final GameRepository repository;
  final GameLogger logger;
  final AiCommandDispatcher dispatch;
  final AiPlanExecutor planExecutor;
  final AiTurnSessionReader sessionReader;
  final AiTurnNetworkSessionReader networkSessionReader;
  final AiTurnCanContinue canContinue;
  final LocalAiRuntimeModeValidator shouldRunLocalAiForMode;
  final ScheduledAiTurnValidator canRunScheduledAiTurn;
  final AiTurnStrategyRegistryFactory strategyRegistryFor;
  final AiTurnRulesetReader rulesetReader;
  final AiTurnEventLogReader eventLogReader;
  final AiTurnPlanPrecomputeCache precomputeCache;
  final AiStrategicPlanProvider strategicPlanProvider;

  const AiTurnProcessPreparer({
    required this.repository,
    required this.logger,
    required this.dispatch,
    required this.planExecutor,
    required this.sessionReader,
    required this.networkSessionReader,
    required this.canContinue,
    required this.shouldRunLocalAiForMode,
    required this.canRunScheduledAiTurn,
    required this.strategyRegistryFor,
    required this.rulesetReader,
    required this.eventLogReader,
    required this.precomputeCache,
    required this.strategicPlanProvider,
  });

  Future<PreparedAiTurnProcess?> prepare({
    required String saveId,
    required String playerId,
    int? scheduledTurn,
  }) async {
    if (!_hasUsableInitialSession(saveId)) return null;

    final snapshot = await repository.load(saveId);
    if (!canContinue()) return null;
    final networkSession = networkSessionReader();
    if (isNetworkBackedGameSave(
      save: snapshot.save,
      networkSession: networkSession,
    )) {
      return null;
    }

    final currentSession = _usableCurrentSession(saveId, networkSession);
    if (currentSession == null) return null;
    if (!_scheduledTurnIsCurrent(
      snapshot: snapshot,
      playerId: playerId,
      scheduledTurn: scheduledTurn,
    )) {
      return null;
    }

    return _buildPreparedProcess(
      snapshot: snapshot,
      session: currentSession,
      networkSession: networkSession,
      saveId: saveId,
      playerId: playerId,
    );
  }

  bool _hasUsableInitialSession(String saveId) {
    final session = sessionReader();
    return session != null &&
        _canUseSession(session, saveId, networkSessionReader());
  }

  GameSession? _usableCurrentSession(
    String saveId,
    NetworkSession? networkSession,
  ) {
    final session = sessionReader();
    if (session == null || !_canUseSession(session, saveId, networkSession)) {
      return null;
    }
    return session;
  }

  bool _scheduledTurnIsCurrent({
    required CanonicalGameSnapshot snapshot,
    required String playerId,
    required int? scheduledTurn,
  }) {
    if (scheduledTurn == null ||
        canRunScheduledAiTurn(
          save: snapshot.save,
          scheduledTurn: scheduledTurn,
          playerId: playerId,
        )) {
      return true;
    }
    logger.info(
      'AI Runtime',
      'scheduled AI turn skipped because snapshot changed '
          'player=$playerId scheduledTurn=$scheduledTurn '
          'currentTurn=${snapshot.save.turn} '
          'state=${snapshot.save.playerStates[playerId]}',
    );
    return false;
  }

  PreparedAiTurnProcess _buildPreparedProcess({
    required CanonicalGameSnapshot snapshot,
    required GameSession session,
    required NetworkSession? networkSession,
    required String saveId,
    required String playerId,
  }) {
    final currentState = snapshot.toClientState(
      activePlayerId: playerId,
      activePlayerCanAct: true,
    );
    return PreparedAiTurnProcess(
      repository: repository,
      snapshot: snapshot,
      saveId: saveId,
      playerId: playerId,
      useCase: RunAiTurnUseCase(
        repository: repository,
        strategyRegistry: strategyRegistryFor(
          playerId: playerId,
          save: snapshot.save,
          gameState: currentState,
          networkSession: networkSession,
        ),
        runner: AiTurnRunner(
          dispatch: dispatch,
          logger: logger,
          planExecutor: planExecutor,
        ),
        ruleset: rulesetReader(),
        mapData: session.mapData,
        planningDeadlinePolicy: AiPlanningDeadlinePolicy.unbounded,
        precomputeCache: precomputeCache,
        strategicPlanProvider: strategicPlanProvider,
        recentHostilityTracker: AiRecentHostilityTracker(
          eventLog: eventLogReader(),
        ),
      ),
    );
  }

  bool _canUseSession(
    GameSession session,
    String saveId,
    NetworkSession? networkSession,
  ) {
    if (session.saveId != saveId) return false;
    return shouldRunLocalAiForMode(
      gameMode: session.gameMode,
      saveId: saveId,
      networkSession: networkSession,
    );
  }
}
