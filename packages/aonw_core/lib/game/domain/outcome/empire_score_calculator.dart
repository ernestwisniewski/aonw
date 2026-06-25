import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';

class EmpireScoreBreakdown {
  final String playerId;
  final int cityScore;
  final int populationScore;
  final int territoryScore;
  final int buildingScore;
  final int unitScore;
  final int technologyScore;
  final int improvementScore;
  final int goldScore;
  final int mapObjectiveScore;

  const EmpireScoreBreakdown({
    required this.playerId,
    required this.cityScore,
    required this.populationScore,
    required this.territoryScore,
    required this.buildingScore,
    required this.unitScore,
    required this.technologyScore,
    required this.improvementScore,
    required this.goldScore,
    this.mapObjectiveScore = 0,
  });

  int get total =>
      cityScore +
      populationScore +
      territoryScore +
      buildingScore +
      unitScore +
      technologyScore +
      improvementScore +
      goldScore +
      mapObjectiveScore;
}

class EmpireScoreCalculator {
  static const int cityWeight = 40;
  static const int populationWeight = 12;
  static const int territoryHexWeight = 3;
  static const int buildingWeight = 8;
  static const int technologyWeight = 18;
  static const int improvementWeight = 5;
  static const int goldDivisor = 50;
  static const int maxGoldScore = 200;

  const EmpireScoreCalculator();

  Map<String, int> scoresFor({
    required Iterable<String> playerIds,
    required PersistentGameState state,
    Iterable<MapObjectiveDefinition> mapObjectives = const [],
  }) {
    return {
      for (final playerId in _cleanPlayerIds(playerIds))
        playerId: scoreFor(
          playerId: playerId,
          state: state,
          mapObjectives: mapObjectives,
        ).total,
    };
  }

  EmpireScoreBreakdown scoreFor({
    required String playerId,
    required PersistentGameState state,
    Iterable<MapObjectiveDefinition> mapObjectives = const [],
  }) {
    final cities = [
      for (final city in state.cities)
        if (city.ownerPlayerId == playerId) city,
    ];
    final units = [
      for (final unit in state.units)
        if (unit.ownerPlayerId == playerId) unit,
    ];
    final cityIds = {for (final city in cities) city.id};
    final improvements = [
      for (final improvement in state.fieldImprovements)
        if (improvement.builtByCityId case final id? when cityIds.contains(id))
          improvement,
    ];
    final research = state.research.forPlayer(playerId);
    final gold = state.playerGold[playerId] ?? 0;

    return EmpireScoreBreakdown(
      playerId: playerId,
      cityScore: cities.length * cityWeight,
      populationScore: _population(cities) * populationWeight,
      territoryScore: _territory(cities) * territoryHexWeight,
      buildingScore: _buildings(cities) * buildingWeight,
      unitScore: _unitScore(units),
      technologyScore: research.unlockedTechnologyIds.length * technologyWeight,
      improvementScore: improvements.length * improvementWeight,
      goldScore: goldScoreFor(gold),
      mapObjectiveScore: _mapObjectiveScore(
        playerId: playerId,
        state: state,
        mapObjectives: mapObjectives,
      ),
    );
  }

  int _mapObjectiveScore({
    required String playerId,
    required PersistentGameState state,
    required Iterable<MapObjectiveDefinition> mapObjectives,
  }) {
    if (mapObjectives.isEmpty) return 0;
    final snapshot = MapObjectiveRules.snapshot(
      objectives: mapObjectives,
      cities: state.cities,
      units: state.units,
      holdStatesByObjectiveId:
          state.runtimeState.mapObjectiveHoldStatesByObjectiveId,
    );
    return snapshot.victoryPointsByPlayerId()[playerId] ?? 0;
  }

  List<String> _cleanPlayerIds(Iterable<String> playerIds) {
    final ids = {
      for (final id in playerIds)
        if (id.isNotEmpty) id,
    }.toList()..sort();
    return ids;
  }

  int _population(List<GameCity> cities) {
    var total = 0;
    for (final city in cities) {
      total += city.population;
    }
    return total;
  }

  int _territory(List<GameCity> cities) {
    var total = 0;
    for (final city in cities) {
      total += city.territoryHexCount;
    }
    return total;
  }

  int _buildings(List<GameCity> cities) {
    var total = 0;
    for (final city in cities) {
      total += city.buildings.length;
    }
    return total;
  }

  int _unitScore(List<GameUnit> units) {
    var total = 0;
    for (final unit in units) {
      total += unitTypeScore(unit.type) + unit.experiencePoints ~/ 5;
    }
    return total;
  }

  static int unitTypeScore(GameUnitType type) {
    return switch (type) {
      GameUnitType.commander => 30,
      GameUnitType.warrior => 15,
      GameUnitType.archer => 17,
      GameUnitType.settler => 18,
      GameUnitType.worker => 12,
      GameUnitType.merchant => 14,
      GameUnitType.scout => 10,
      GameUnitType.spearman => 18,
      GameUnitType.cavalry => 24,
      GameUnitType.catapult => 25,
      GameUnitType.heavyInfantry => 30,
      GameUnitType.fieldCannon => 35,
      GameUnitType.rifleman => 38,
      GameUnitType.tank => 50,
      GameUnitType.scoutShip => 20,
      GameUnitType.warship => 40,
      GameUnitType.reconPlane => 36,
    };
  }

  static int goldScoreFor(int gold) {
    if (gold <= 0) return 0;
    final score = gold ~/ goldDivisor;
    return score > maxGoldScore ? maxGoldScore : score;
  }
}
