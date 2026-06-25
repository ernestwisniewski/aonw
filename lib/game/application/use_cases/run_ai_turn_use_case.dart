import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_recent_hostility_tracker.dart';
import 'package:aonw/game/application/services/ai_strategic_plan_provider.dart';
import 'package:aonw/game/application/services/ai_turn_runner.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/movement_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';

class RunAiTurnUseCase {
  final GameRepository repository;
  final AiStrategyRegistry strategyRegistry;
  final AiTurnRunner runner;
  final GameRuleset ruleset;
  final MapData mapData;
  final AiTurnPlanPrecomputeCache? precomputeCache;
  final AiStrategicPlanProvider? strategicPlanProvider;
  final AiRecentHostilityTracker? recentHostilityTracker;

  const RunAiTurnUseCase({
    required this.repository,
    required this.strategyRegistry,
    required this.runner,
    required this.ruleset,
    required this.mapData,
    this.precomputeCache,
    this.strategicPlanProvider,
    this.recentHostilityTracker,
  });

  Future<AiTurnPrecomputeHandle?> precompute({
    required String saveId,
    required String playerId,
    SaveSnapshot? snapshot,
    AiPlanExecutor planExecutor = syncAiPlanExecutor,
  }) async {
    final cache = precomputeCache;
    if (cache == null) return null;

    final prepared = await _prepare(
      saveId: saveId,
      playerId: playerId,
      snapshot: snapshot,
    );
    if (prepared == null) return null;

    final plan = cache.start(
      key: prepared.precomputeKey,
      planFactory: () => planExecutor(
        strategy: prepared.strategy,
        view: prepared.view,
        context: prepared.context,
      ),
    );
    return AiTurnPrecomputeHandle(key: prepared.precomputeKey, plan: plan);
  }

  Future<AiTurnReport?> execute({
    required String saveId,
    required String playerId,
    SaveSnapshot? snapshot,
    AiTerminalCommand? terminalCommand,
    Duration interCommandDelay = const Duration(milliseconds: 200),
    Future<void> Function()? onStalePrecomputeDropped,
  }) async {
    final prepared = await _prepare(
      saveId: saveId,
      playerId: playerId,
      snapshot: snapshot,
    );
    if (prepared == null) return null;

    final precomputedPlan = precomputeCache?.consume(prepared.precomputeKey);
    if (precomputedPlan == null) {
      final stalePlansDropped =
          precomputeCache?.retainWhere((key) {
            return key.saveId != prepared.snapshot.save.id ||
                key.turn != prepared.snapshot.save.turn ||
                key.playerId != playerId;
          }) ??
          0;
      if (stalePlansDropped > 0) {
        await onStalePrecomputeDropped?.call();
      }
    }

    return runner.run(
      saveId: saveId,
      playerId: playerId,
      strategy: prepared.strategy,
      context: prepared.context,
      initialState: prepared.initialState,
      view: prepared.view,
      precomputedPlan: precomputedPlan,
      terminalCommand:
          terminalCommand ??
          _terminalCommandFor(prepared.snapshot.save.gameMode),
      interCommandDelay: interCommandDelay,
    );
  }

  Future<_PreparedAiTurn?> _prepare({
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
    final effectiveRuleset = ruleset.copyWith(
      paceBalance: resolvedSnapshot.save.matchRules.paceBalance,
    );
    final loggedHostilePlayerIds =
        await recentHostilityTracker?.hostilePlayerIds(
          snapshot: planningSnapshot,
          playerId: playerId,
        ) ??
        const <String>{};
    final activeHostilePlayerIds = _pendingHostilePlayerIds(
      snapshot: planningSnapshot,
      playerId: playerId,
    );
    final scoreRace = _scoreRaceFor(
      snapshot: planningSnapshot,
      playerId: playerId,
      mapData: mapData,
    );
    final pressureTargetPlayerIds = {
      ..._pressureTargetPlayerIds(
        resolvedSnapshot.save.players,
        playerId: playerId,
        diplomacy: planningSnapshot.runtimeState.diplomacy,
      ),
      ..._culturalPressureTargetPlayerIds(planningSnapshot, playerId: playerId),
      ..._scorePressureTargetPlayerIds(
        scoreRace: scoreRace,
        playerId: playerId,
        diplomacy: planningSnapshot.runtimeState.diplomacy,
      ),
    };
    final pendingCityAttackThreats = _pendingCityAttackThreats(
      snapshot: planningSnapshot,
      playerId: playerId,
    );
    final view = GameView.fromPersistentState(
      planningSnapshot.persistentState,
      forPlayerId: playerId,
      turn: resolvedSnapshot.save.turn,
      mapData: mapData,
      ruleset: effectiveRuleset,
      activeHostilePlayerIds: activeHostilePlayerIds,
      recentHostilePlayerIds: loggedHostilePlayerIds,
      pressureTargetPlayerIds: pressureTargetPlayerIds,
      defaultNeutralPlayerIds: _defaultNeutralPlayerIds(
        resolvedSnapshot.save.players,
        playerId: playerId,
      ),
      pendingCityAttackThreats: pendingCityAttackThreats,
      forcedVisibleEnemyUnitIds: pendingCityAttackThreats.map(
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
      scoreRace: scoreRace,
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

    return _PreparedAiTurn(
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

  static AiTerminalCommand _terminalCommandFor(GameMode gameMode) {
    return switch (gameMode) {
      GameMode.hotSeat => AiTerminalCommand.endTurn,
      GameMode.multiplayer => AiTerminalCommand.submitTurn,
    };
  }

  static DateTime? _deadlineFor(GameSave save, DateTime? turnStartedAt) {
    if (save.gameMode != GameMode.multiplayer) return null;
    final startedAt = turnStartedAt ?? save.savedAt;
    return startedAt.toUtc().add(const Duration(seconds: 115));
  }

  static Set<String> _pendingHostilePlayerIds({
    required SaveSnapshot snapshot,
    required String playerId,
  }) {
    final hostilePlayerIds = <String>{};
    for (final attack in snapshot.runtimeState.intendedAttacks) {
      if (attack.declaringPlayerId == playerId) continue;
      if (_targetsPlayer(snapshot, playerId: playerId, attack: attack)) {
        hostilePlayerIds.add(attack.declaringPlayerId);
      }
    }
    return hostilePlayerIds;
  }

  static bool _targetsPlayer(
    SaveSnapshot snapshot, {
    required String playerId,
    required IntendedAttack attack,
  }) {
    for (final unit in snapshot.units) {
      if (unit.ownerPlayerId == playerId &&
          unit.col == attack.defenderCol &&
          unit.row == attack.defenderRow) {
        return true;
      }
    }
    for (final city in snapshot.cities) {
      if (city.ownerPlayerId == playerId &&
          city.center.col == attack.defenderCol &&
          city.center.row == attack.defenderRow) {
        return true;
      }
    }
    return false;
  }

  static Set<String> _pressureTargetPlayerIds(
    Iterable<Player> players, {
    required String playerId,
    required DiplomacyState diplomacy,
  }) {
    return {
      for (final player in players)
        if (_shouldPressureHumanPlayer(
          player: player,
          playerId: playerId,
          diplomacy: diplomacy,
        ))
          player.id,
    };
  }

  static ScoreRaceAnalysis? _scoreRaceFor({
    required SaveSnapshot snapshot,
    required String playerId,
    required MapData mapData,
  }) {
    final victory = snapshot.save.matchRules.victory;
    return const ScoreRaceAnalyzer().analyzeForPlayer(
      playerId: playerId,
      playerIds: snapshot.save.players.map((player) => player.id),
      state: snapshot.persistentState,
      turn: snapshot.save.turn,
      turnLimit: victory.turnLimit,
      scoreFallbackEnabled: victory.scoreFallbackEnabled,
      mapData: mapData,
    );
  }

  static Set<String> _scorePressureTargetPlayerIds({
    required ScoreRaceAnalysis? scoreRace,
    required String playerId,
    required DiplomacyState diplomacy,
  }) {
    final targetIds = scoreRace?.pressureTargetPlayerIds() ?? const {};
    return {
      for (final targetId in targetIds)
        if (_canPressureScoreTarget(
          targetId: targetId,
          playerId: playerId,
          diplomacy: diplomacy,
        ))
          targetId,
    };
  }

  static bool _canPressureScoreTarget({
    required String targetId,
    required String playerId,
    required DiplomacyState diplomacy,
  }) {
    if (targetId.isEmpty || targetId == playerId) return false;
    final status = diplomacy.statusBetween(playerId, targetId);
    if (status == DiplomaticRelationStatus.friendly ||
        status == DiplomaticRelationStatus.truce) {
      return false;
    }
    final relationKey = DiplomacyState.relationKey(playerId, targetId);
    if (status == DiplomaticRelationStatus.neutral &&
        relationKey.isNotEmpty &&
        diplomacy.relations.containsKey(relationKey)) {
      return false;
    }
    return true;
  }

  static Set<String> _culturalPressureTargetPlayerIds(
    SaveSnapshot snapshot, {
    required String playerId,
  }) {
    if (!snapshot.save.matchRules.victory.culturalEnabled) return const {};
    final threshold = _culturalPressureArtifactThreshold(
      snapshot.save.matchRules.victory.culturalRequiredArtifacts,
    );
    final cityOwnerById = {
      for (final city in snapshot.cities) city.id: city.ownerPlayerId,
    };
    final typesByPlayerId = <String, Set<WorldArtifactType>>{};
    for (final artifact in snapshot.artifacts) {
      final cityId = artifact.location.cityId;
      if (!artifact.location.isStored || cityId == null) continue;
      final ownerPlayerId = cityOwnerById[cityId];
      if (ownerPlayerId == null || ownerPlayerId == playerId) continue;
      typesByPlayerId.putIfAbsent(ownerPlayerId, () => {}).add(artifact.type);
    }
    return {
      for (final entry in typesByPlayerId.entries)
        if (entry.value.length >= threshold) entry.key,
    };
  }

  static int _culturalPressureArtifactThreshold(int requiredArtifactCount) {
    final threshold = requiredArtifactCount - 2;
    if (threshold < 1) return 1;
    return threshold;
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

  static bool _shouldPressureHumanPlayer({
    required Player player,
    required String playerId,
    required DiplomacyState diplomacy,
  }) {
    if (player.id == playerId || player.kind != PlayerKind.human) {
      return false;
    }

    final status = diplomacy.statusBetween(playerId, player.id);
    if (status == DiplomaticRelationStatus.hostile ||
        status == DiplomaticRelationStatus.war) {
      return true;
    }
    if (status == DiplomaticRelationStatus.friendly ||
        status == DiplomaticRelationStatus.truce) {
      return false;
    }

    final relationKey = DiplomacyState.relationKey(playerId, player.id);
    return relationKey.isNotEmpty &&
        !diplomacy.relations.containsKey(relationKey);
  }

  static List<PendingCityAttackThreat> _pendingCityAttackThreats({
    required SaveSnapshot snapshot,
    required String playerId,
  }) {
    final unitsById = {for (final unit in snapshot.units) unit.id: unit};
    final threats = <PendingCityAttackThreat>[];
    for (final attack in snapshot.runtimeState.intendedAttacks) {
      if (attack.declaringPlayerId == playerId) continue;
      final attacker = unitsById[attack.attackerUnitId];
      if (attacker == null || attacker.ownerPlayerId == playerId) continue;
      final city = _cityAt(
        snapshot,
        playerId: playerId,
        col: attack.defenderCol,
        row: attack.defenderRow,
      );
      if (city == null) continue;
      threats.add(
        PendingCityAttackThreat(
          attackerPlayerId: attack.declaringPlayerId,
          attackerUnitId: attack.attackerUnitId,
          attackerHex: HexCoordinate(col: attacker.col, row: attacker.row),
          cityId: city.id,
          cityCenter: city.center,
        ),
      );
    }
    return List.unmodifiable(threats);
  }

  static GameCity? _cityAt(
    SaveSnapshot snapshot, {
    required String playerId,
    required int col,
    required int row,
  }) {
    for (final city in snapshot.cities) {
      if (city.ownerPlayerId == playerId &&
          city.center.col == col &&
          city.center.row == row) {
        return city;
      }
    }
    return null;
  }
}

class _PreparedAiTurn {
  final SaveSnapshot snapshot;
  final GameState initialState;
  final GameView view;
  final AiContext context;
  final AiStrategy strategy;
  final AiTurnPlanPrecomputeKey precomputeKey;

  const _PreparedAiTurn({
    required this.snapshot,
    required this.initialState,
    required this.view,
    required this.context,
    required this.strategy,
    required this.precomputeKey,
  });
}

class _PreparedAiStrategy implements AiStrategy {
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
