import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';

class AiStrategicPlanProvider {
  final StrategicPlanner planner;
  final int recomputeInterval;

  final Map<_StrategicPlanCacheKey, _CachedStrategicPlan> _plans = {};

  AiStrategicPlanProvider({
    this.planner = const StrategicPlanner(),
    this.recomputeInterval = 5,
  }) : assert(recomputeInterval > 0);

  StrategicPlan resolve({
    required SaveSnapshot snapshot,
    required Player player,
    required GameView view,
    required AiContext context,
    AiEmpireAssessment? assessment,
  }) {
    final ai = player.ai;
    if (ai == null) {
      throw ArgumentError.value(player.id, 'player', 'Expected an AI player');
    }

    final key = _StrategicPlanCacheKey(
      saveId: snapshot.save.id,
      playerId: player.id,
    );
    final identity = _StrategicPlanIdentity.from(
      snapshot: snapshot,
      player: player,
      persona: context.persona,
    );
    final resolvedAssessment =
        assessment ?? AiEmpireAssessment.fromView(view, context);
    final triggerSignal = _StrategicPlanTriggerSignal.from(
      view: view,
      assessment: resolvedAssessment,
    );
    final worldStateHash = _worldStateHash(snapshot);
    final cached = _plans[key];

    if (cached != null && cached.identity == identity) {
      final sameStrategicState = cached.triggerSignal == triggerSignal;
      final checkpointDue =
          view.turn - cached.checkpointPlan.computedAtTurn >= recomputeInterval;
      if (sameStrategicState && !checkpointDue) return cached.currentPlan;

      final checkpointPlan = checkpointDue ? cached.checkpointPlan : null;
      final plan = planner.build(
        view: view,
        context: context,
        assessment: resolvedAssessment,
        previousPlan: checkpointPlan,
        previousMode: cached.currentPlan.mode,
      );
      _plans[key] = _CachedStrategicPlan(
        identity: identity,
        triggerSignal: triggerSignal,
        worldStateHash: worldStateHash,
        currentPlan: plan,
        checkpointPlan: checkpointDue ? plan : cached.checkpointPlan,
      );
      return plan;
    }

    final plan = planner.build(
      view: view,
      context: context,
      assessment: resolvedAssessment,
    );
    _plans[key] = _CachedStrategicPlan(
      identity: identity,
      triggerSignal: triggerSignal,
      worldStateHash: worldStateHash,
      currentPlan: plan,
      checkpointPlan: plan,
    );
    return plan;
  }

  bool contains({required String saveId, required String playerId}) {
    return _plans.containsKey(
      _StrategicPlanCacheKey(saveId: saveId, playerId: playerId),
    );
  }

  int get length => _plans.length;

  void clear() {
    _plans.clear();
  }

  void retainWhere(bool Function(AiStrategicPlanCacheEntry entry) test) {
    _plans.removeWhere((key, cached) {
      return !test(
        AiStrategicPlanCacheEntry(
          saveId: key.saveId,
          playerId: key.playerId,
          turn: cached.currentPlan.computedAtTurn,
          worldStateHash: cached.worldStateHash,
          plan: cached.currentPlan,
        ),
      );
    });
  }
}

class AiStrategicPlanCacheEntry {
  final String saveId;
  final String playerId;
  final int turn;
  final int worldStateHash;
  final StrategicPlan plan;

  const AiStrategicPlanCacheEntry({
    required this.saveId,
    required this.playerId,
    required this.turn,
    required this.worldStateHash,
    required this.plan,
  });
}

class _StrategicPlanCacheKey {
  final String saveId;
  final String playerId;

  const _StrategicPlanCacheKey({required this.saveId, required this.playerId});

  @override
  bool operator ==(Object other) {
    return other is _StrategicPlanCacheKey &&
        other.saveId == saveId &&
        other.playerId == playerId;
  }

  @override
  int get hashCode => Object.hash(saveId, playerId);
}

class _StrategicPlanIdentity {
  final GameMode gameMode;
  final PlayerCountry country;
  final AiStrategyId strategyId;
  final AiDifficulty difficulty;
  final AiPersona configuredPersona;
  final AiPersona effectivePersona;
  final int seed;
  final int matchRulesHash;

  const _StrategicPlanIdentity({
    required this.gameMode,
    required this.country,
    required this.strategyId,
    required this.difficulty,
    required this.configuredPersona,
    required this.effectivePersona,
    required this.seed,
    required this.matchRulesHash,
  });

  factory _StrategicPlanIdentity.from({
    required SaveSnapshot snapshot,
    required Player player,
    required AiPersona persona,
  }) {
    final ai = player.ai!;
    return _StrategicPlanIdentity(
      gameMode: snapshot.save.gameMode,
      country: player.country,
      strategyId: ai.strategyId,
      difficulty: ai.difficulty,
      configuredPersona: ai.persona,
      effectivePersona: persona,
      seed: ai.seed,
      matchRulesHash: snapshot.save.matchRules.hashCode,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _StrategicPlanIdentity &&
        other.gameMode == gameMode &&
        other.country == country &&
        other.strategyId == strategyId &&
        other.difficulty == difficulty &&
        other.configuredPersona == configuredPersona &&
        other.effectivePersona == effectivePersona &&
        other.seed == seed &&
        other.matchRulesHash == matchRulesHash;
  }

  @override
  int get hashCode {
    return Object.hash(
      gameMode,
      country,
      strategyId,
      difficulty,
      configuredPersona,
      effectivePersona,
      seed,
      matchRulesHash,
    );
  }
}

class _StrategicPlanTriggerSignal {
  final int ownCityHash;
  final int ownWorkerHash;
  final int ownSettlerHash;
  final int ownMilitaryHash;
  final int visibleEnemyMilitaryHash;
  final int activeHostilePlayerHash;
  final int recentHostilePlayerHash;
  final int desiredCityCount;
  final int desiredWorkerCount;
  final int desiredMilitaryCount;

  const _StrategicPlanTriggerSignal({
    required this.ownCityHash,
    required this.ownWorkerHash,
    required this.ownSettlerHash,
    required this.ownMilitaryHash,
    required this.visibleEnemyMilitaryHash,
    required this.activeHostilePlayerHash,
    required this.recentHostilePlayerHash,
    required this.desiredCityCount,
    required this.desiredWorkerCount,
    required this.desiredMilitaryCount,
  });

  factory _StrategicPlanTriggerSignal.from({
    required GameView view,
    required AiEmpireAssessment assessment,
  }) {
    return _StrategicPlanTriggerSignal(
      ownCityHash: _hashIds(view.ownCities.map((city) => city.id)),
      ownWorkerHash: _hashIds(
        view.ownUnits
            .where((unit) => unit.isWorker)
            .map((unit) => _unitStateKey(unit)),
      ),
      ownSettlerHash: _hashIds(
        view.ownUnits
            .where(
              (unit) => unit.type == GameUnitType.settler || unit.hasSettlers,
            )
            .map((unit) => _unitStateKey(unit)),
      ),
      ownMilitaryHash: _hashIds(
        view.ownUnits
            .where(_isMilitaryUnit)
            .map((unit) => '${unit.id}:${unit.hitPoints}'),
      ),
      visibleEnemyMilitaryHash: _hashIds(
        view.visibleEnemyUnits.where(_isMilitaryUnit).map(_unitStateKey),
      ),
      activeHostilePlayerHash: _hashIds(view.activeHostilePlayerIds),
      recentHostilePlayerHash: _hashIds(view.recentHostilePlayerIds),
      desiredCityCount: assessment.desiredCityCount,
      desiredWorkerCount: assessment.desiredWorkerCount,
      desiredMilitaryCount: assessment.desiredMilitaryCount,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _StrategicPlanTriggerSignal &&
        other.ownCityHash == ownCityHash &&
        other.ownWorkerHash == ownWorkerHash &&
        other.ownSettlerHash == ownSettlerHash &&
        other.ownMilitaryHash == ownMilitaryHash &&
        other.visibleEnemyMilitaryHash == visibleEnemyMilitaryHash &&
        other.activeHostilePlayerHash == activeHostilePlayerHash &&
        other.recentHostilePlayerHash == recentHostilePlayerHash &&
        other.desiredCityCount == desiredCityCount &&
        other.desiredWorkerCount == desiredWorkerCount &&
        other.desiredMilitaryCount == desiredMilitaryCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      ownCityHash,
      ownWorkerHash,
      ownSettlerHash,
      ownMilitaryHash,
      visibleEnemyMilitaryHash,
      activeHostilePlayerHash,
      recentHostilePlayerHash,
      desiredCityCount,
      desiredWorkerCount,
      desiredMilitaryCount,
    );
  }
}

class _CachedStrategicPlan {
  final _StrategicPlanIdentity identity;
  final _StrategicPlanTriggerSignal triggerSignal;
  final int worldStateHash;
  final StrategicPlan currentPlan;
  final StrategicPlan checkpointPlan;

  const _CachedStrategicPlan({
    required this.identity,
    required this.triggerSignal,
    required this.worldStateHash,
    required this.currentPlan,
    required this.checkpointPlan,
  });
}

int _worldStateHash(SaveSnapshot snapshot) {
  return snapshot.persistentState
      .copyWith(runtimeState: GameRuntimeState.empty)
      .hashCode;
}

bool _isMilitaryUnit(GameUnit unit) {
  return !unit.isWorker &&
      unit.type != GameUnitType.settler &&
      !unit.hasSettlers;
}

String _unitStateKey(GameUnit unit) {
  return '${unit.id}:${unit.col}:${unit.row}:${unit.hitPoints}';
}

int _hashIds(Iterable<String> values) {
  final sorted = values.toList()..sort();
  return Object.hashAll(sorted);
}
