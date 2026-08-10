import 'package:aonw_core/game/domain/objective/game_objective_catalog.dart';
import 'package:aonw_core/game/domain/objective/game_objective_model.dart';
import 'package:aonw_core/game/domain/objective/map_objective.dart';
import 'package:aonw_core/game/domain/objective/map_objective_pressure.dart';

abstract final class GameObjectiveStrategicTracker {
  static List<GameObjectiveProgress> activeForPlayer({
    required String playerId,
    required Map<String, int> dominationHoldTurnsByPlayerId,
    required int dominationRequiredHoldTurns,
    Map<String, int> scoreByPlayerId = const {},
    Map<String, GameObjectiveAdvice> scoreAdviceByPlayerId = const {},
    int? scoreRemainingTurns,
    int scorePressureWindow = 5,
    Iterable<MapObjectiveProgress> mapObjectiveProgress = const [],
  }) {
    if (playerId.isEmpty) return const [];

    final scoreObjective = _scorePressureForPlayer(
      playerId: playerId,
      scoreByPlayerId: scoreByPlayerId,
      scoreAdviceByPlayerId: scoreAdviceByPlayerId,
      scoreRemainingTurns: scoreRemainingTurns,
      scorePressureWindow: scorePressureWindow,
    );
    final dominationObjective = _dominationPressureForPlayer(
      playerId: playerId,
      dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
      requiredHoldTurns: dominationRequiredHoldTurns,
    );
    if (dominationObjective != null) {
      if (_scoreCapResolvesFirst(
        dominationObjective: dominationObjective,
        scoreObjective: scoreObjective,
        scoreRemainingTurns: scoreRemainingTurns,
      )) {
        return [scoreObjective!];
      }
      return [dominationObjective];
    }
    if (scoreObjective != null) return [scoreObjective];

    final mapObjective = _mapPressureForPlayer(
      playerId: playerId,
      mapObjectiveProgress: mapObjectiveProgress,
    );
    return mapObjective == null ? const [] : [mapObjective];
  }

  static GameObjectiveProgress? _dominationPressureForPlayer({
    required String playerId,
    required Map<String, int> dominationHoldTurnsByPlayerId,
    required int requiredHoldTurns,
  }) {
    if (requiredHoldTurns <= 0) return null;
    final playerHoldTurns = dominationHoldTurnsByPlayerId[playerId] ?? 0;
    if (playerHoldTurns > 0) {
      return _dominationProgress(
        definition: GameObjectiveCatalog.holdDominationObjective,
        holdTurns: playerHoldTurns,
        requiredHoldTurns: requiredHoldTurns,
      );
    }
    final opponentHoldTurns = _topOpponentHold(
      playerId: playerId,
      dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
    );
    if (opponentHoldTurns <= 0) return null;
    return _dominationProgress(
      definition: GameObjectiveCatalog.breakDominationHoldObjective,
      holdTurns: opponentHoldTurns,
      requiredHoldTurns: requiredHoldTurns,
    );
  }

  static GameObjectiveProgress _dominationProgress({
    required GameObjectiveDefinition definition,
    required int holdTurns,
    required int requiredHoldTurns,
  }) => GameObjectiveProgress(
    definition: definition.copyWith(targetValue: requiredHoldTurns),
    currentValue: holdTurns,
  );

  static int _topOpponentHold({
    required String playerId,
    required Map<String, int> dominationHoldTurnsByPlayerId,
  }) {
    var topHoldTurns = 0;
    for (final entry in dominationHoldTurnsByPlayerId.entries) {
      if (entry.key == playerId || entry.value <= topHoldTurns) continue;
      topHoldTurns = entry.value;
    }
    return topHoldTurns;
  }

  static bool _scoreCapResolvesFirst({
    required GameObjectiveProgress dominationObjective,
    required GameObjectiveProgress? scoreObjective,
    required int? scoreRemainingTurns,
  }) {
    if (scoreObjective == null || scoreRemainingTurns == null) return false;
    final remainingHoldTurns =
        dominationObjective.targetValue - dominationObjective.currentValue;
    return remainingHoldTurns > scoreRemainingTurns;
  }

  static GameObjectiveProgress? _scorePressureForPlayer({
    required String playerId,
    required Map<String, int> scoreByPlayerId,
    required Map<String, GameObjectiveAdvice> scoreAdviceByPlayerId,
    required int? scoreRemainingTurns,
    required int scorePressureWindow,
  }) {
    if (!_scorePressureIsActive(
      playerId: playerId,
      scoreByPlayerId: scoreByPlayerId,
      scoreRemainingTurns: scoreRemainingTurns,
      scorePressureWindow: scorePressureWindow,
    )) {
      return null;
    }

    final activeScore = scoreByPlayerId[playerId]!;
    final topScore = _topScore(scoreByPlayerId);
    final advice = scoreAdviceByPlayerId[playerId];
    if (_isSoleLeader(playerId, activeScore, topScore, scoreByPlayerId)) {
      return GameObjectiveProgress(
        definition: GameObjectiveCatalog.holdScoreLeadObjective.copyWith(
          targetValue: scorePressureWindow,
        ),
        currentValue: scorePressureWindow - scoreRemainingTurns!,
        advice: advice,
      );
    }
    return GameObjectiveProgress(
      definition: GameObjectiveCatalog.overtakeScoreLeaderObjective.copyWith(
        targetValue: topScore + 1,
      ),
      currentValue: activeScore,
      advice: advice,
    );
  }

  static bool _scorePressureIsActive({
    required String playerId,
    required Map<String, int> scoreByPlayerId,
    required int? scoreRemainingTurns,
    required int scorePressureWindow,
  }) {
    if (scoreRemainingTurns == null) return false;
    if (scoreRemainingTurns < 0) return false;
    if (scorePressureWindow <= 0) return false;
    if (scoreRemainingTurns > scorePressureWindow) return false;
    return scoreByPlayerId.containsKey(playerId);
  }

  static bool _isSoleLeader(
    String playerId,
    int activeScore,
    int topScore,
    Map<String, int> scoreByPlayerId,
  ) {
    if (activeScore != topScore) return false;
    final topPlayers = scoreByPlayerId.entries.where(
      (entry) => entry.value == topScore,
    );
    return topPlayers.length == 1 && topPlayers.single.key == playerId;
  }

  static GameObjectiveProgress? _mapPressureForPlayer({
    required String playerId,
    required Iterable<MapObjectiveProgress> mapObjectiveProgress,
  }) {
    final pressure = MapObjectivePressureRules.pressureForPlayer(
      playerId: playerId,
      progress: mapObjectiveProgress,
    );
    if (pressure == null) return null;
    return switch (pressure.kind) {
      MapObjectivePressureKind.breakOpponentHold => GameObjectiveProgress(
        definition: GameObjectiveCatalog.breakMapObjectiveHoldObjective
            .copyWith(targetValue: pressure.requiredHoldTurns),
        currentValue: pressure.currentHoldTurns,
        advice: GameObjectiveAdvice.trainUnit,
      ),
      MapObjectivePressureKind.secureOwnHold => GameObjectiveProgress(
        definition: GameObjectiveCatalog.secureMapObjective.copyWith(
          targetValue: pressure.requiredHoldTurns,
        ),
        currentValue: pressure.currentHoldTurns,
        advice: GameObjectiveAdvice.claimTerritory,
      ),
    };
  }

  static int _topScore(Map<String, int> scoreByPlayerId) {
    var topScore = 0;
    for (final score in scoreByPlayerId.values) {
      if (score > topScore) topScore = score;
    }
    return topScore;
  }
}
