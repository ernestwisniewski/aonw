import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/objective/game_objective_model.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

enum _ObjectiveMetric {
  research,
  cityCount,
  discovery,
  workerCount,
  improvementCount,
  buildingCount,
  combatUnitCount,
  stability,
  inactive,
}

const _metricByObjective = <GameObjectiveId, _ObjectiveMetric>{
  GameObjectiveId.chooseResearch: _ObjectiveMetric.research,
  GameObjectiveId.foundCapital: _ObjectiveMetric.cityCount,
  GameObjectiveId.exploreNearby: _ObjectiveMetric.discovery,
  GameObjectiveId.queueWorker: _ObjectiveMetric.workerCount,
  GameObjectiveId.improveFirstHex: _ObjectiveMetric.improvementCount,
  GameObjectiveId.foundSecondCity: _ObjectiveMetric.cityCount,
  GameObjectiveId.buildFirstBuilding: _ObjectiveMetric.buildingCount,
  GameObjectiveId.improveThreeHexes: _ObjectiveMetric.improvementCount,
  GameObjectiveId.foundThirdCity: _ObjectiveMetric.cityCount,
  GameObjectiveId.exploreRegion: _ObjectiveMetric.discovery,
  GameObjectiveId.buildCombatForce: _ObjectiveMetric.combatUnitCount,
  GameObjectiveId.raiseStability: _ObjectiveMetric.stability,
  GameObjectiveId.holdDomination: _ObjectiveMetric.inactive,
  GameObjectiveId.breakDominationHold: _ObjectiveMetric.inactive,
  GameObjectiveId.holdScoreLead: _ObjectiveMetric.inactive,
  GameObjectiveId.overtakeScoreLeader: _ObjectiveMetric.inactive,
  GameObjectiveId.secureMapObjective: _ObjectiveMetric.inactive,
  GameObjectiveId.breakMapObjectiveHold: _ObjectiveMetric.inactive,
};

abstract final class GameObjectiveProgressEvaluator {
  static int currentValueFor(
    GameObjectiveId id, {
    required String playerId,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    required Iterable<FieldImprovement> fieldImprovements,
    required FogOfWarState fogOfWar,
    required ResearchState research,
    int playerStabilityNet = 0,
  }) {
    final playerCities = _citiesForPlayer(playerId, cities);
    final metric = _metricByObjective[id]!;
    return switch (metric) {
      _ObjectiveMetric.research => _researchProgress(
        research.forPlayer(playerId),
      ),
      _ObjectiveMetric.cityCount => playerCities.length,
      _ObjectiveMetric.discovery =>
        fogOfWar.fogForPlayer(playerId).discoveredHexes.length,
      _ObjectiveMetric.workerCount => _workerCountForPlayer(
        playerId: playerId,
        cities: playerCities,
        units: units,
      ),
      _ObjectiveMetric.improvementCount => _improvementCountForCities(
        playerCities,
        fieldImprovements,
      ),
      _ObjectiveMetric.buildingCount => _buildingCount(playerCities),
      _ObjectiveMetric.combatUnitCount => _combatUnitCountForPlayer(
        playerId: playerId,
        units: units,
      ),
      _ObjectiveMetric.stability => _stabilityProgress(playerStabilityNet),
      _ObjectiveMetric.inactive => 0,
    };
  }

  static List<GameCity> _citiesForPlayer(
    String playerId,
    Iterable<GameCity> cities,
  ) => [
    for (final city in cities)
      if (city.ownerPlayerId == playerId) city,
  ];

  static int _researchProgress(PlayerResearchState research) =>
      research.activeTechnologyId != null ||
          research.unlockedTechnologyIds.isNotEmpty
      ? 1
      : 0;

  static int _improvementCountForCities(
    Iterable<GameCity> cities,
    Iterable<FieldImprovement> improvements,
  ) {
    final cityIds = {for (final city in cities) city.id};
    return improvements
        .where((improvement) => cityIds.contains(improvement.builtByCityId))
        .length;
  }

  static int _buildingCount(Iterable<GameCity> cities) =>
      cities.fold<int>(0, (total, city) => total + city.buildings.length);

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
      if (unit.ownerPlayerId != playerId || _isCivilianUnit(unit.type)) {
        continue;
      }
      count++;
    }
    return count;
  }

  static bool _isCivilianUnit(GameUnitType type) => switch (type) {
    GameUnitType.settler || GameUnitType.worker || GameUnitType.scout => true,
    _ => false,
  };

  static int _stabilityProgress(int playerStabilityNet) =>
      playerStabilityNet >= 0 ? 1 : 0;
}
