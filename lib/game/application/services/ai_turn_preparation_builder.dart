import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_recent_hostility_tracker.dart';
import 'package:aonw/game/application/services/ai_strategic_plan_provider.dart';
import 'package:aonw/game/domain/ai/city_threat_assessor.dart';
import 'package:aonw/game/domain/ai/pressure_target_resolver.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/movement/movement_reducer.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class AiTurnPreparationBuilder {
  final GameRepository repository;
  final AiStrategyRegistry strategyRegistry;
  final GameRuleset ruleset;
  final MapReadView mapData;
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
    final player = _aiPlayerFor(resolvedSnapshot, saveId, playerId);
    if (player == null) return null;
    final domain = resolvedSnapshot.domain;
    final session = resolvedSnapshot.session;
    final metadata = resolvedSnapshot.metadata;
    final ai = player.ai!;
    const civRegistry = CivilizationProfileRegistry();
    final civProfile = civRegistry.profileFor(player.country);
    final initialState = resolvedSnapshot.toGameState(
      activePlayerId: playerId,
      activePlayerCanAct: true,
    );
    final movementPreparationCommands = _preparationCommandsFor(
      gameMode: session.gameMode,
      playerId: playerId,
    );
    final planningState = _planningState(
      initialState: initialState,
      gameMode: session.gameMode,
      playerId: playerId,
    );
    final planningSnapshot = resolvedSnapshot.withGameState(planningState);
    final planningDomain = planningSnapshot.canonical.domain;
    final effectiveRuleset = ruleset.copyWith(
      paceBalance: domain.matchRules.paceBalance,
    );
    final loggedHostilePlayerIds =
        await recentHostilityTracker?.hostilePlayerIds(
          snapshot: planningSnapshot,
          playerId: playerId,
        ) ??
        const <String>{};
    final pressureTargets = pressureTargetResolver.resolve(
      players: domain.participants,
      playerId: playerId,
      state: planningDomain,
      turn: domain.turn,
      matchRules: domain.matchRules,
      mapObjectives: mapData.objectives,
    );
    final cityThreats = cityThreatAssessor.assess(
      state: planningDomain,
      playerId: playerId,
    );
    final view = _aiPlanningView(
      snapshot: planningSnapshot,
      domain: planningDomain,
      playerId: playerId,
      mapData: mapData,
      ruleset: effectiveRuleset,
      activeHostilePlayerIds: cityThreats.activeHostilePlayerIds,
      recentHostilePlayerIds: loggedHostilePlayerIds,
      pressureTargetPlayerIds: pressureTargets.playerIds,
      pendingCityAttackThreats: cityThreats.pendingCityAttackThreats,
    );
    final hegemonyContext = _hegemonyContextFor(
      planningDomain,
      playerId: playerId,
      mapData: view.mapData,
    );
    var context = AiContext(
      ruleset: effectiveRuleset,
      mapData: view.mapData,
      turn: domain.turn,
      rng: AiRng.fromTurn(
        turn: domain.turn,
        playerId: playerId,
        baseSeed: ai.seed,
      ),
      persona: ai.personaForProfile(civProfile),
      difficulty: ai.difficulty,
      civProfile: civProfile,
      scoreRace: pressureTargets.scoreRace,
      deadline: _deadlineFor(
        gameMode: session.gameMode,
        savedAt: metadata.savedAtUtc,
        rawTurnStartedAt: resolvedSnapshot.persistedTurnStartedAt,
      ),
      ownControlPercent: hegemonyContext.controlPercent,
      knownPlayerCount: hegemonyContext.playerCount,
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

  Player? _aiPlayerFor(SaveSnapshot snapshot, String saveId, String playerId) {
    if (snapshot.metadata.id != saveId) return null;
    final player = snapshot.domain.participants.byId(playerId);
    if (player?.kind != PlayerKind.ai || player?.ai == null) return null;
    return player;
  }

  ({double controlPercent, int playerCount}) _hegemonyContextFor(
    DomainState state, {
    required String playerId,
    required MapReadView mapData,
  }) => StabilityInputBuilder.hegemonyContextFromCollections(
    cities: state.cities,
    knownPlayerIds: state.participants.map((player) => player.id),
    playerId: playerId,
    mapData: mapData,
  );

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

  static GameView _aiPlanningView({
    required SaveSnapshot snapshot,
    required DomainState domain,
    required String playerId,
    required MapReadView mapData,
    required GameRuleset ruleset,
    required Iterable<String> activeHostilePlayerIds,
    required Iterable<String> recentHostilePlayerIds,
    required Iterable<String> pressureTargetPlayerIds,
    required Iterable<PendingCityAttackThreat> pendingCityAttackThreats,
  }) {
    final canonical = snapshot.canonical;
    return GameView.fromDomainState(
      domain,
      forPlayerId: playerId,
      turn: domain.turn,
      mapData: mapData,
      ruleset: ruleset,
      engineSnapshot: canonical,
      activeHostilePlayerIds: activeHostilePlayerIds,
      recentHostilePlayerIds: recentHostilePlayerIds,
      pressureTargetPlayerIds: pressureTargetPlayerIds,
      defaultNeutralPlayerIds: _defaultNeutralPlayerIds(
        domain.participants,
        playerId: playerId,
      ),
      pendingCityAttackThreats: pendingCityAttackThreats,
      forcedVisibleEnemyUnitIds: pendingCityAttackThreats.map(
        (threat) => threat.attackerUnitId,
      ),
      ignoreFogOfWar: true,
    );
  }

  static DateTime? _deadlineFor({
    required GameMode gameMode,
    required DateTime savedAt,
    required DateTime? rawTurnStartedAt,
  }) {
    if (gameMode != GameMode.multiplayer) return null;
    final startedAt = rawTurnStartedAt ?? savedAt;
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
