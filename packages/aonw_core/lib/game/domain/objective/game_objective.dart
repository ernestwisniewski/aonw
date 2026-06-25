import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/objective/map_objective.dart';
import 'package:aonw_core/game/domain/objective/map_objective_pressure.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

enum GameObjectiveId {
  chooseResearch,
  foundCapital,
  exploreNearby,
  queueWorker,
  improveFirstHex,
  foundSecondCity,
  buildFirstBuilding,
  improveThreeHexes,
  foundThirdCity,
  exploreRegion,
  buildCombatForce,
  holdDomination,
  breakDominationHold,
  holdScoreLead,
  overtakeScoreLeader,
  secureMapObjective,
  breakMapObjectiveHold,
}

enum GameObjectiveTone {
  research,
  expansion,
  exploration,
  economy,
  victory,
  warning,
}

enum GameObjectiveAdvice {
  foundCity,
  growPopulation,
  claimTerritory,
  constructBuilding,
  trainUnit,
  unlockTechnology,
  improveField,
  collectGold,
  protectLead,
}

enum GameObjectivePhase { foundation, expansion, pressure, endgame }

enum GameObjectiveTrack { guidance, strategic }

enum GameObjectiveTargetScaling { fixed, pace }

class GameObjectiveDefinition {
  final GameObjectiveId id;
  final GameObjectivePhase phase;
  final GameObjectiveTrack track;
  final int targetValue;
  final GameObjectiveTone tone;
  final GameObjectiveTargetScaling targetScaling;

  const GameObjectiveDefinition({
    required this.id,
    required this.phase,
    this.track = GameObjectiveTrack.guidance,
    required this.targetValue,
    required this.tone,
    this.targetScaling = GameObjectiveTargetScaling.fixed,
  });

  GameObjectiveDefinition scaledFor(PaceBalance paceBalance) {
    if (targetScaling == GameObjectiveTargetScaling.fixed) return this;
    final scaledTarget = paceBalance.objectiveTarget(targetValue);
    if (scaledTarget == targetValue) return this;
    return copyWith(targetValue: scaledTarget);
  }

  GameObjectiveDefinition copyWith({
    int? targetValue,
    GameObjectiveTone? tone,
  }) {
    return GameObjectiveDefinition(
      id: id,
      phase: phase,
      track: track,
      targetValue: targetValue ?? this.targetValue,
      tone: tone ?? this.tone,
      targetScaling: targetScaling,
    );
  }
}

class GameObjectiveProgress {
  final GameObjectiveDefinition definition;
  final int currentValue;
  final GameObjectiveAdvice? advice;

  const GameObjectiveProgress({
    required this.definition,
    required this.currentValue,
    this.advice,
  });

  int get targetValue => definition.targetValue;

  int get clampedValue => _clampInt(currentValue, 0, targetValue);

  bool get completed => currentValue >= targetValue;

  double get fraction {
    if (targetValue <= 0) return 1;
    return clampedValue / targetValue;
  }

  String get progressLabel => targetValue <= 1
      ? completed
            ? 'gotowe'
            : '0/1'
      : '$clampedValue/$targetValue';

  static int _clampInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}

abstract final class GameObjectiveTracker {
  static const List<GameObjectiveDefinition> earlyGameObjectives = [
    GameObjectiveDefinition(
      id: GameObjectiveId.chooseResearch,
      phase: GameObjectivePhase.foundation,
      targetValue: 1,
      tone: GameObjectiveTone.research,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.foundCapital,
      phase: GameObjectivePhase.foundation,
      targetValue: 1,
      tone: GameObjectiveTone.expansion,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.exploreNearby,
      phase: GameObjectivePhase.foundation,
      targetValue: 28,
      tone: GameObjectiveTone.exploration,
      targetScaling: GameObjectiveTargetScaling.pace,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.queueWorker,
      phase: GameObjectivePhase.foundation,
      targetValue: 1,
      tone: GameObjectiveTone.economy,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.improveFirstHex,
      phase: GameObjectivePhase.foundation,
      targetValue: 1,
      tone: GameObjectiveTone.economy,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.foundSecondCity,
      phase: GameObjectivePhase.foundation,
      targetValue: 2,
      tone: GameObjectiveTone.expansion,
    ),
  ];

  static const List<GameObjectiveDefinition> expansionObjectives = [
    GameObjectiveDefinition(
      id: GameObjectiveId.buildFirstBuilding,
      phase: GameObjectivePhase.expansion,
      targetValue: 1,
      tone: GameObjectiveTone.economy,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.improveThreeHexes,
      phase: GameObjectivePhase.expansion,
      targetValue: 3,
      tone: GameObjectiveTone.economy,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.foundThirdCity,
      phase: GameObjectivePhase.expansion,
      targetValue: 3,
      tone: GameObjectiveTone.expansion,
    ),
  ];

  static const List<GameObjectiveDefinition> pressureObjectives = [
    GameObjectiveDefinition(
      id: GameObjectiveId.exploreRegion,
      phase: GameObjectivePhase.pressure,
      targetValue: 70,
      tone: GameObjectiveTone.exploration,
      targetScaling: GameObjectiveTargetScaling.pace,
    ),
    GameObjectiveDefinition(
      id: GameObjectiveId.buildCombatForce,
      phase: GameObjectivePhase.pressure,
      targetValue: 3,
      tone: GameObjectiveTone.expansion,
      targetScaling: GameObjectiveTargetScaling.pace,
    ),
  ];

  static const holdDominationObjective = GameObjectiveDefinition(
    id: GameObjectiveId.holdDomination,
    phase: GameObjectivePhase.endgame,
    track: GameObjectiveTrack.strategic,
    targetValue: 1,
    tone: GameObjectiveTone.victory,
  );

  static const breakDominationHoldObjective = GameObjectiveDefinition(
    id: GameObjectiveId.breakDominationHold,
    phase: GameObjectivePhase.endgame,
    track: GameObjectiveTrack.strategic,
    targetValue: 1,
    tone: GameObjectiveTone.warning,
  );

  static const holdScoreLeadObjective = GameObjectiveDefinition(
    id: GameObjectiveId.holdScoreLead,
    phase: GameObjectivePhase.endgame,
    track: GameObjectiveTrack.strategic,
    targetValue: 1,
    tone: GameObjectiveTone.victory,
  );

  static const overtakeScoreLeaderObjective = GameObjectiveDefinition(
    id: GameObjectiveId.overtakeScoreLeader,
    phase: GameObjectivePhase.endgame,
    track: GameObjectiveTrack.strategic,
    targetValue: 1,
    tone: GameObjectiveTone.warning,
  );

  static const secureMapObjective = GameObjectiveDefinition(
    id: GameObjectiveId.secureMapObjective,
    phase: GameObjectivePhase.pressure,
    track: GameObjectiveTrack.strategic,
    targetValue: 1,
    tone: GameObjectiveTone.victory,
  );

  static const breakMapObjectiveHoldObjective = GameObjectiveDefinition(
    id: GameObjectiveId.breakMapObjectiveHold,
    phase: GameObjectivePhase.pressure,
    track: GameObjectiveTrack.strategic,
    targetValue: 1,
    tone: GameObjectiveTone.warning,
  );

  static const List<GameObjectiveDefinition> guidanceObjectives = [
    ...earlyGameObjectives,
    ...expansionObjectives,
    ...pressureObjectives,
  ];

  static const List<GameObjectiveDefinition> strategicObjectives = [
    holdDominationObjective,
    breakDominationHoldObjective,
    holdScoreLeadObjective,
    overtakeScoreLeaderObjective,
    secureMapObjective,
    breakMapObjectiveHoldObjective,
  ];

  static List<GameObjectiveProgress> progressForPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    required Iterable<FieldImprovement> fieldImprovements,
    required FogOfWarState fogOfWar,
    required ResearchState research,
    Iterable<GameObjectiveDefinition> definitions = guidanceObjectives,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    return [
      for (final definition in definitions)
        GameObjectiveProgress(
          definition: definition.scaledFor(paceBalance),
          currentValue: _currentValueFor(
            definition.id,
            playerId: playerId,
            cities: cities,
            units: units,
            fieldImprovements: fieldImprovements,
            fogOfWar: fogOfWar,
            research: research,
          ),
        ),
    ];
  }

  static List<GameObjectiveProgress> earlyGameProgressForPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    required Iterable<FieldImprovement> fieldImprovements,
    required FogOfWarState fogOfWar,
    required ResearchState research,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    return progressForPlayer(
      playerId: playerId,
      cities: cities,
      units: units,
      fieldImprovements: fieldImprovements,
      fogOfWar: fogOfWar,
      research: research,
      definitions: earlyGameObjectives,
      paceBalance: paceBalance,
    );
  }

  static List<GameObjectiveProgress> activeObjectivesForPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    required Iterable<FieldImprovement> fieldImprovements,
    required FogOfWarState fogOfWar,
    required ResearchState research,
    PaceBalance paceBalance = PaceBalance.unlimited,
    Map<String, int> dominationHoldTurnsByPlayerId = const {},
    int dominationRequiredHoldTurns = 0,
    Map<String, int> scoreByPlayerId = const {},
    Map<String, GameObjectiveAdvice> scoreAdviceByPlayerId = const {},
    int? scoreRemainingTurns,
    int scorePressureWindow = 5,
    Iterable<MapObjectiveProgress> mapObjectiveProgress = const [],
    int limit = 3,
  }) {
    if (limit <= 0) return const [];

    final strategic = activeStrategicObjectivesForPlayer(
      playerId: playerId,
      dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
      dominationRequiredHoldTurns: dominationRequiredHoldTurns,
      scoreByPlayerId: scoreByPlayerId,
      scoreAdviceByPlayerId: scoreAdviceByPlayerId,
      scoreRemainingTurns: scoreRemainingTurns,
      scorePressureWindow: scorePressureWindow,
      mapObjectiveProgress: mapObjectiveProgress,
    );
    final progress = progressForPlayer(
      playerId: playerId,
      cities: cities,
      units: units,
      fieldImprovements: fieldImprovements,
      fogOfWar: fogOfWar,
      research: research,
      paceBalance: paceBalance,
    );
    return [
      ...strategic.take(limit),
      ..._activeFrom(progress, limit: limit - strategic.length),
    ];
  }

  static List<GameObjectiveProgress> activeStrategicObjectivesForPlayer({
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

    final scoreObjective = _scorePressureObjectiveForPlayer(
      playerId: playerId,
      scoreByPlayerId: scoreByPlayerId,
      scoreAdviceByPlayerId: scoreAdviceByPlayerId,
      scoreRemainingTurns: scoreRemainingTurns,
      scorePressureWindow: scorePressureWindow,
    );
    final mapObjective = _mapObjectivePressureForPlayer(
      playerId: playerId,
      mapObjectiveProgress: mapObjectiveProgress,
    );

    if (dominationRequiredHoldTurns > 0) {
      final playerHoldTurns = dominationHoldTurnsByPlayerId[playerId] ?? 0;
      if (playerHoldTurns > 0) {
        if (_scoreCapResolvesBeforeDomination(
          holdTurns: playerHoldTurns,
          requiredHoldTurns: dominationRequiredHoldTurns,
          scoreRemainingTurns: scoreRemainingTurns,
          scoreObjective: scoreObjective,
        )) {
          return [scoreObjective!];
        }
        return [
          GameObjectiveProgress(
            definition: holdDominationObjective.copyWith(
              targetValue: dominationRequiredHoldTurns,
            ),
            currentValue: playerHoldTurns,
          ),
        ];
      }

      final opponentHoldTurns = _topOpponentHold(
        playerId: playerId,
        dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
      );
      if (opponentHoldTurns > 0) {
        if (_scoreCapResolvesBeforeDomination(
          holdTurns: opponentHoldTurns,
          requiredHoldTurns: dominationRequiredHoldTurns,
          scoreRemainingTurns: scoreRemainingTurns,
          scoreObjective: scoreObjective,
        )) {
          return [scoreObjective!];
        }
        return [
          GameObjectiveProgress(
            definition: breakDominationHoldObjective.copyWith(
              targetValue: dominationRequiredHoldTurns,
            ),
            currentValue: opponentHoldTurns,
          ),
        ];
      }
    }

    if (scoreObjective != null) return [scoreObjective];
    return mapObjective == null ? const [] : [mapObjective];
  }

  static List<GameObjectiveProgress> activeEarlyGameObjectivesForPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    required Iterable<FieldImprovement> fieldImprovements,
    required FogOfWarState fogOfWar,
    required ResearchState research,
    PaceBalance paceBalance = PaceBalance.unlimited,
    int limit = 3,
  }) {
    final progress = earlyGameProgressForPlayer(
      playerId: playerId,
      cities: cities,
      units: units,
      fieldImprovements: fieldImprovements,
      fogOfWar: fogOfWar,
      research: research,
      paceBalance: paceBalance,
    );
    return _activeFrom(progress, limit: limit);
  }

  static List<GameObjectiveProgress> _activeFrom(
    Iterable<GameObjectiveProgress> progress, {
    required int limit,
  }) {
    if (limit <= 0) return const [];

    return progress
        .where(
          (objective) =>
              objective.definition.track == GameObjectiveTrack.guidance &&
              !objective.completed,
        )
        .take(limit)
        .toList();
  }

  static int _currentValueFor(
    GameObjectiveId id, {
    required String playerId,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    required Iterable<FieldImprovement> fieldImprovements,
    required FogOfWarState fogOfWar,
    required ResearchState research,
  }) {
    final playerCities = [
      for (final city in cities)
        if (city.ownerPlayerId == playerId) city,
    ];
    final cityIds = {for (final city in playerCities) city.id};

    return switch (id) {
      GameObjectiveId.chooseResearch =>
        _hasResearchDirection(research.forPlayer(playerId)) ? 1 : 0,
      GameObjectiveId.foundCapital => playerCities.length,
      GameObjectiveId.exploreNearby =>
        fogOfWar.fogForPlayer(playerId).discoveredHexes.length,
      GameObjectiveId.queueWorker => _workerCountForPlayer(
        playerId: playerId,
        cities: playerCities,
        units: units,
      ),
      GameObjectiveId.improveFirstHex =>
        fieldImprovements
            .where((improvement) => cityIds.contains(improvement.builtByCityId))
            .length,
      GameObjectiveId.foundSecondCity => playerCities.length,
      GameObjectiveId.buildFirstBuilding => playerCities.fold<int>(
        0,
        (total, city) => total + city.buildings.length,
      ),
      GameObjectiveId.improveThreeHexes =>
        fieldImprovements
            .where((improvement) => cityIds.contains(improvement.builtByCityId))
            .length,
      GameObjectiveId.foundThirdCity => playerCities.length,
      GameObjectiveId.exploreRegion =>
        fogOfWar.fogForPlayer(playerId).discoveredHexes.length,
      GameObjectiveId.buildCombatForce => _combatUnitCountForPlayer(
        playerId: playerId,
        units: units,
      ),
      GameObjectiveId.holdDomination ||
      GameObjectiveId.breakDominationHold ||
      GameObjectiveId.holdScoreLead ||
      GameObjectiveId.overtakeScoreLeader ||
      GameObjectiveId.secureMapObjective ||
      GameObjectiveId.breakMapObjectiveHold => 0,
    };
  }

  static bool _hasResearchDirection(PlayerResearchState research) {
    return research.activeTechnologyId != null ||
        research.unlockedTechnologyIds.isNotEmpty;
  }

  static int _workerCountForPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
  }) {
    var count = 0;
    for (final unit in units) {
      if (unit.ownerPlayerId == playerId && unit.type == GameUnitType.worker) {
        count++;
      }
    }
    for (final city in cities) {
      final target = city.productionQueue?.target;
      if (target is UnitProductionTarget &&
          target.unitType == GameUnitType.worker) {
        count++;
      }
    }
    return count;
  }

  static int _combatUnitCountForPlayer({
    required String playerId,
    required Iterable<GameUnit> units,
  }) {
    var count = 0;
    for (final unit in units) {
      if (unit.ownerPlayerId != playerId) continue;
      if (_isCivilianUnit(unit.type)) continue;
      count++;
    }
    return count;
  }

  static bool _isCivilianUnit(GameUnitType type) {
    return switch (type) {
      GameUnitType.settler || GameUnitType.worker || GameUnitType.scout => true,
      _ => false,
    };
  }

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

  static bool _scoreCapResolvesBeforeDomination({
    required int holdTurns,
    required int requiredHoldTurns,
    required int? scoreRemainingTurns,
    required GameObjectiveProgress? scoreObjective,
  }) {
    if (scoreObjective == null || scoreRemainingTurns == null) return false;

    final remainingHoldTurns = requiredHoldTurns - holdTurns;
    return remainingHoldTurns > scoreRemainingTurns;
  }

  static GameObjectiveProgress? _scorePressureObjectiveForPlayer({
    required String playerId,
    required Map<String, int> scoreByPlayerId,
    required Map<String, GameObjectiveAdvice> scoreAdviceByPlayerId,
    required int? scoreRemainingTurns,
    required int scorePressureWindow,
  }) {
    if (scoreRemainingTurns == null ||
        scoreRemainingTurns < 0 ||
        scorePressureWindow <= 0 ||
        scoreRemainingTurns > scorePressureWindow ||
        !scoreByPlayerId.containsKey(playerId)) {
      return null;
    }

    final activeScore = scoreByPlayerId[playerId]!;
    final topScore = _topScore(scoreByPlayerId);
    final topPlayers = [
      for (final entry in scoreByPlayerId.entries)
        if (entry.value == topScore) entry.key,
    ];
    final activeSoleLeader =
        activeScore == topScore &&
        topPlayers.length == 1 &&
        topPlayers.single == playerId;

    if (activeSoleLeader) {
      final elapsedPressureTurns = scorePressureWindow - scoreRemainingTurns;
      return GameObjectiveProgress(
        definition: holdScoreLeadObjective.copyWith(
          targetValue: scorePressureWindow,
        ),
        currentValue: elapsedPressureTurns,
        advice: scoreAdviceByPlayerId[playerId],
      );
    }

    return GameObjectiveProgress(
      definition: overtakeScoreLeaderObjective.copyWith(
        targetValue: topScore + 1,
      ),
      currentValue: activeScore,
      advice: scoreAdviceByPlayerId[playerId],
    );
  }

  static GameObjectiveProgress? _mapObjectivePressureForPlayer({
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
        definition: breakMapObjectiveHoldObjective.copyWith(
          targetValue: pressure.requiredHoldTurns,
        ),
        currentValue: pressure.currentHoldTurns,
        advice: GameObjectiveAdvice.trainUnit,
      ),
      MapObjectivePressureKind.secureOwnHold => GameObjectiveProgress(
        definition: secureMapObjective.copyWith(
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
