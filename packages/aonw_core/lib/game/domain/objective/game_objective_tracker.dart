import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/objective/game_objective_catalog.dart';
import 'package:aonw_core/game/domain/objective/game_objective_model.dart';
import 'package:aonw_core/game/domain/objective/game_objective_progress_evaluator.dart';
import 'package:aonw_core/game/domain/objective/game_objective_strategic_tracker.dart';
import 'package:aonw_core/game/domain/objective/map_objective.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class GameObjectiveTracker {
  static const earlyGameObjectives = GameObjectiveCatalog.earlyGameObjectives;
  static const expansionObjectives = GameObjectiveCatalog.expansionObjectives;
  static const pressureObjectives = GameObjectiveCatalog.pressureObjectives;
  static const holdDominationObjective =
      GameObjectiveCatalog.holdDominationObjective;
  static const breakDominationHoldObjective =
      GameObjectiveCatalog.breakDominationHoldObjective;
  static const holdScoreLeadObjective =
      GameObjectiveCatalog.holdScoreLeadObjective;
  static const overtakeScoreLeaderObjective =
      GameObjectiveCatalog.overtakeScoreLeaderObjective;
  static const secureMapObjective = GameObjectiveCatalog.secureMapObjective;
  static const breakMapObjectiveHoldObjective =
      GameObjectiveCatalog.breakMapObjectiveHoldObjective;
  static const guidanceObjectives = GameObjectiveCatalog.guidanceObjectives;
  static const strategicObjectives = GameObjectiveCatalog.strategicObjectives;

  static List<GameObjectiveProgress> progressForPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    required Iterable<FieldImprovement> fieldImprovements,
    required FogOfWarState fogOfWar,
    required ResearchState research,
    Iterable<GameObjectiveDefinition> definitions = guidanceObjectives,
    PaceBalance paceBalance = PaceBalance.unlimited,
    int playerStabilityNet = 0,
  }) {
    return [
      for (final definition in definitions)
        GameObjectiveProgress(
          definition: definition.scaledFor(paceBalance),
          currentValue: GameObjectiveProgressEvaluator.currentValueFor(
            definition.id,
            playerId: playerId,
            cities: cities,
            units: units,
            fieldImprovements: fieldImprovements,
            fogOfWar: fogOfWar,
            research: research,
            playerStabilityNet: playerStabilityNet,
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
    int playerStabilityNet = 0,
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
      playerStabilityNet: playerStabilityNet,
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
    return GameObjectiveStrategicTracker.activeForPlayer(
      playerId: playerId,
      dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
      dominationRequiredHoldTurns: dominationRequiredHoldTurns,
      scoreByPlayerId: scoreByPlayerId,
      scoreAdviceByPlayerId: scoreAdviceByPlayerId,
      scoreRemainingTurns: scoreRemainingTurns,
      scorePressureWindow: scorePressureWindow,
      mapObjectiveProgress: mapObjectiveProgress,
    );
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
}
