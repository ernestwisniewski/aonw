import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';

class AiTurnPlanPrecomputeKey {
  final String saveId;
  final int turn;
  final GameMode gameMode;
  final String playerId;
  final PlayerCountry country;
  final AiStrategyId strategyId;
  final AiDifficulty difficulty;
  final AiPersona persona;
  final int seed;
  final int matchRulesHash;
  final int worldStateHash;

  const AiTurnPlanPrecomputeKey({
    required this.saveId,
    required this.turn,
    required this.gameMode,
    required this.playerId,
    required this.country,
    required this.strategyId,
    required this.difficulty,
    required this.persona,
    required this.seed,
    required this.matchRulesHash,
    required this.worldStateHash,
  });

  factory AiTurnPlanPrecomputeKey.fromSnapshot({
    required SaveSnapshot snapshot,
    required Player player,
  }) {
    final ai = player.ai;
    if (ai == null) {
      throw ArgumentError.value(player.id, 'player', 'Expected an AI player');
    }

    return AiTurnPlanPrecomputeKey(
      saveId: snapshot.save.id,
      turn: snapshot.save.turn,
      gameMode: snapshot.save.gameMode,
      playerId: player.id,
      country: player.country,
      strategyId: ai.strategyId,
      difficulty: ai.difficulty,
      persona: ai.persona,
      seed: ai.seed,
      matchRulesHash: snapshot.save.matchRules.hashCode,
      worldStateHash: _worldStateHash(snapshot),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AiTurnPlanPrecomputeKey &&
        other.saveId == saveId &&
        other.turn == turn &&
        other.gameMode == gameMode &&
        other.playerId == playerId &&
        other.country == country &&
        other.strategyId == strategyId &&
        other.difficulty == difficulty &&
        other.persona == persona &&
        other.seed == seed &&
        other.matchRulesHash == matchRulesHash &&
        other.worldStateHash == worldStateHash;
  }

  @override
  int get hashCode => Object.hash(
    saveId,
    turn,
    gameMode,
    playerId,
    country,
    strategyId,
    difficulty,
    persona,
    seed,
    matchRulesHash,
    worldStateHash,
  );

  @override
  String toString() {
    return 'AiTurnPlanPrecomputeKey(saveId: $saveId, turn: $turn, '
        'playerId: $playerId, strategyId: ${strategyId.name}, '
        'worldStateHash: $worldStateHash)';
  }

  static int _worldStateHash(SaveSnapshot snapshot) {
    final tacticalRuntimeState = GameRuntimeState(
      intendedAttacks: snapshot.runtimeState.intendedAttacks,
    );
    return snapshot.persistentState
        .copyWith(runtimeState: tacticalRuntimeState)
        .hashCode;
  }
}

class AiTurnPrecomputeHandle {
  final AiTurnPlanPrecomputeKey key;
  final Future<AiTurnPlan> plan;

  const AiTurnPrecomputeHandle({required this.key, required this.plan});
}

class AiTurnPlanPrecomputeCache {
  final Map<AiTurnPlanPrecomputeKey, _CachedAiTurnPlan> _plans = {};

  Future<AiTurnPlan> start({
    required AiTurnPlanPrecomputeKey key,
    required Future<AiTurnPlan> Function() planFactory,
  }) {
    final existing = _plans[key];
    if (existing != null) return existing.plan;

    late final Future<AiTurnPlan> future;
    future = () async {
      try {
        return await planFactory();
      } catch (_) {
        if (identical(_plans[key]?.plan, future)) {
          _plans.remove(key);
        }
        rethrow;
      }
    }();
    _plans[key] = _CachedAiTurnPlan(future);
    return future;
  }

  Future<AiTurnPlan>? consume(AiTurnPlanPrecomputeKey key) {
    return _plans.remove(key)?.plan;
  }

  bool contains(AiTurnPlanPrecomputeKey key) => _plans.containsKey(key);

  int get length => _plans.length;

  void clear() {
    _plans.clear();
  }

  int retainWhere(bool Function(AiTurnPlanPrecomputeKey key) test) {
    final previousLength = _plans.length;
    _plans.removeWhere((key, _) => !test(key));
    return previousLength - _plans.length;
  }
}

class _CachedAiTurnPlan {
  final Future<AiTurnPlan> plan;

  const _CachedAiTurnPlan(this.plan);
}
