import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_recent_hostility_tracker.dart';
import 'package:aonw/game/application/services/ai_strategic_plan_provider.dart';
import 'package:aonw/game/domain/ai/city_threat_assessor.dart';
import 'package:aonw/game/domain/ai/pressure_target_resolver.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/movement_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';

final class AiTurnPreparationBuilder {
  final GameRepository repository;
  final AiStrategyRegistry strategyRegistry;
  final GameRuleset ruleset;
  final MapData mapData;
  final AiStrategicPlanProvider? strategicPlanProvider;
  final AiRecentHostilityTracker? recentHostilityTracker;
  final PressureTargetResolver pressureTargetResolver;
  final CityThreatAssessor cityThreatAssessor;

  const AiTurnPreparationBuilder({
    required this.repository,
    required this.strategyRegistry,
    required this.ruleset,
    required this.mapData,
    this.strategicPlanProvider,
    this.recentHostilityTracker,
    this.pressureTargetResolver = const PressureTargetResolver(),
    this.cityThreatAssessor = const CityThreatAssessor(),
  });

  Future<PreparedAiTurn?> prepare({
    required String saveId,
    required String playerId,
    SaveSnapshot? snapshot,
  }) async {
    final resolvedSnapshot = snapshot ?? await repository.load(saveId);
    if (resolvedSnapshot.save.id != saveId) return null;

    final player = _playerById(resolvedSnapshot.save.players, playerId);
    if (player == null || player.kind != PlayerKind.ai || player.ai == null) {
      return null;
    }

    final ai = player.ai!;
    const civRegistry = CivilizationProfileRegistry();
    final civProfile = civRegistry.profileFor(player.country);
    final initialState = resolvedSnapshot.toGameState(
      activePlayerId: playerId,
      activePlayerCanAct: true,
    );
    final movementPreparationCommands = _preparationCommandsFor(
      gameMode: resolvedSnapshot.save.gameMode,
      playerId: playerId,
    );
    final planningState = _planningState(
      initialState: initialState,
      gameMode: resolvedSnapshot.save.gameMode,
      playerId: playerId,
    );
    final planningSnapshot = SaveSnapshot.fromGameState(
      save: resolvedSnapshot.save,
      state: planningState,
      eventLogOffset: resolvedSnapshot.eventLogOffset,
    );
    final planningPersistentState = planningSnapshot.persistentState;
    final effectiveRuleset = ruleset.copyWith(
      paceBalance: resolvedSnapshot.save.matchRules.paceBalance,
    );
    final loggedHostilePlayerIds =
        await recentHostilityTracker?.hostilePlayerIds(
          snapshot: planningSnapshot,
          playerId: playerId,
        ) ??
        const <String>{};
    final pressureTargets = pressureTargetResolver.resolve(
      players: resolvedSnapshot.save.players,
      playerId: playerId,
      state: planningPersistentState,
      turn: resolvedSnapshot.save.turn,
      matchRules: resolvedSnapshot.save.matchRules,
      mapData: mapData,
    );
    final cityThreats = cityThreatAssessor.assess(
      state: planningPersistentState,
      playerId: playerId,
    );
    final view = GameView.fromPersistentState(
      planningPersistentState,
      forPlayerId: playerId,
      turn: resolvedSnapshot.save.turn,
      mapData: mapData,
      ruleset: effectiveRuleset,
      activeHostilePlayerIds: cityThreats.activeHostilePlayerIds,
      recentHostilePlayerIds: loggedHostilePlayerIds,
      pressureTargetPlayerIds: pressureTargets.playerIds,
      defaultNeutralPlayerIds: _defaultNeutralPlayerIds(
        resolvedSnapshot.save.players,
        playerId: playerId,
      ),
      pendingCityAttackThreats: cityThreats.pendingCityAttackThreats,
      forcedVisibleEnemyUnitIds: cityThreats.pendingCityAttackThreats.map(
        (threat) => threat.attackerUnitId,
      ),
      ignoreFogOfWar: true,
    );
    var context = AiContext(
      ruleset: effectiveRuleset,
      mapData: mapData,
      turn: resolvedSnapshot.save.turn,
      rng: AiRng.fromTurn(
        turn: resolvedSnapshot.save.turn,
        playerId: playerId,
        baseSeed: ai.seed,
      ),
      persona: ai.personaForProfile(civProfile),
      difficulty: ai.difficulty,
      civProfile: civProfile,
      scoreRace: pressureTargets.scoreRace,
      deadline: _deadlineFor(
        resolvedSnapshot.save,
        resolvedSnapshot.runtimeState.turnStartedAt,
      ),
    );
    final assessment = AiEmpireAssessment.fromView(view, context);
    final strategicPlan =
        strategicPlanProvider?.resolve(
          snapshot: planningSnapshot,
          player: player,
          view: view,
          context: context,
          assessment: assessment,
        ) ??
        const StrategicPlanner().build(
          view: view,
          context: context,
          assessment: assessment,
        );
    context = context.copyWith(strategicPlan: strategicPlan);
    final preparationCommands = [
      ...movementPreparationCommands,
      ...const DiplomacyAiPolicy().commandsFor(view, context),
    ];

    return PreparedAiTurn(
      snapshot: resolvedSnapshot,
      initialState: initialState,
      view: view,
      context: context,
      strategy: _strategyWithPreparation(
        strategyRegistry.resolve(ai.strategyId),
        preparationCommands,
      ),
      precomputeKey: AiTurnPlanPrecomputeKey.fromSnapshot(
        snapshot: resolvedSnapshot,
        player: player,
      ),
    );
  }

  GameState _planningState({
    required GameState initialState,
    required GameMode gameMode,
    required String playerId,
  }) {
    if (gameMode != GameMode.hotSeat) return initialState;

    return MovementReducer.resetUnitMovementForNewTurn(
      initialState,
      mapData,
      playerId: playerId,
    ).state;
  }

  static List<GameCommand> _preparationCommandsFor({
    required GameMode gameMode,
    required String playerId,
  }) {
    return switch (gameMode) {
      GameMode.hotSeat => [ResetUnitMovementCommand(playerId: playerId)],
      GameMode.multiplayer => const [],
    };
  }

  static AiStrategy _strategyWithPreparation(
    AiStrategy strategy,
    List<GameCommand> preparationCommands,
  ) {
    if (preparationCommands.isEmpty) return strategy;
    return _PreparedAiStrategy(strategy, preparationCommands);
  }

  static Player? _playerById(List<Player> players, String playerId) {
    for (final player in players) {
      if (player.id == playerId) return player;
    }
    return null;
  }

  static DateTime? _deadlineFor(GameSave save, DateTime? turnStartedAt) {
    if (save.gameMode != GameMode.multiplayer) return null;
    final startedAt = turnStartedAt ?? save.savedAt;
    return startedAt.toUtc().add(const Duration(seconds: 115));
  }

  static Set<String> _defaultNeutralPlayerIds(
    Iterable<Player> players, {
    required String playerId,
  }) {
    return {
      for (final player in players)
        if (player.id != playerId && player.kind != PlayerKind.human) player.id,
    };
  }
}

final class PreparedAiTurn {
  final SaveSnapshot snapshot;
  final GameState initialState;
  final GameView view;
  final AiContext context;
  final AiStrategy strategy;
  final AiTurnPlanPrecomputeKey precomputeKey;

  const PreparedAiTurn({
    required this.snapshot,
    required this.initialState,
    required this.view,
    required this.context,
    required this.strategy,
    required this.precomputeKey,
  });
}

final class _PreparedAiStrategy implements AiStrategy {
  final AiStrategy delegate;
  final List<GameCommand> preparationCommands;

  _PreparedAiStrategy(this.delegate, Iterable<GameCommand> preparationCommands)
    : preparationCommands = List.unmodifiable(preparationCommands);

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    final plan = delegate.plan(view, context);
    return AiTurnPlan(commands: [...preparationCommands, ...plan.commands]);
  }
}
