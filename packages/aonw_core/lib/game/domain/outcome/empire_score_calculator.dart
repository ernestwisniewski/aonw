import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/objective/map_objective.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_catalog.dart';

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
    required DomainState state,
    Iterable<MapObjectiveDefinition> mapObjectives = const [],
  }) => scoresForCollections(
    playerIds: playerIds,
    cities: state.cities,
    units: state.units,
    fieldImprovements: state.fieldImprovements,
    research: state.research,
    playerGold: state.playerGold,
    mapObjectives: mapObjectives,
    mapObjectiveHoldStatesByObjectiveId:
        state.mapObjectiveHoldStatesByObjectiveId,
  );

  Map<String, int> scoresForCollections({
    required Iterable<String> playerIds,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    required Iterable<FieldImprovement> fieldImprovements,
    required ResearchState research,
    required Map<String, int> playerGold,
    Iterable<MapObjectiveDefinition> mapObjectives = const [],
    Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId =
        const {},
  }) {
    final cityList = _stableList(cities);
    final unitList = _stableList(units);
    final improvementList = _stableList(fieldImprovements);
    final objectiveList = _stableList(mapObjectives);
    return {
      for (final playerId in _cleanPlayerIds(playerIds))
        playerId: _scoreForCollections(
          playerId: playerId,
          cities: cityList,
          units: unitList,
          fieldImprovements: improvementList,
          research: research,
          playerGold: playerGold,
          mapObjectives: objectiveList,
          mapObjectiveHoldStatesByObjectiveId:
              mapObjectiveHoldStatesByObjectiveId,
        ).total,
    };
  }

  EmpireScoreBreakdown scoreFor({
    required String playerId,
    required DomainState state,
    Iterable<MapObjectiveDefinition> mapObjectives = const [],
  }) => scoreForCollections(
    playerId: playerId,
    cities: state.cities,
    units: state.units,
    fieldImprovements: state.fieldImprovements,
    research: state.research,
    playerGold: state.playerGold,
    mapObjectives: mapObjectives,
    mapObjectiveHoldStatesByObjectiveId:
        state.mapObjectiveHoldStatesByObjectiveId,
  );

  EmpireScoreBreakdown scoreForCollections({
    required String playerId,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    required Iterable<FieldImprovement> fieldImprovements,
    required ResearchState research,
    required Map<String, int> playerGold,
    Iterable<MapObjectiveDefinition> mapObjectives = const [],
    Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId =
        const {},
  }) => _scoreForCollections(
    playerId: playerId,
    cities: _stableList(cities),
    units: _stableList(units),
    fieldImprovements: _stableList(fieldImprovements),
    research: research,
    playerGold: playerGold,
    mapObjectives: _stableList(mapObjectives),
    mapObjectiveHoldStatesByObjectiveId: mapObjectiveHoldStatesByObjectiveId,
  );

  EmpireScoreBreakdown _scoreForCollections({
    required String playerId,
    required List<GameCity> cities,
    required List<GameUnit> units,
    required List<FieldImprovement> fieldImprovements,
    required ResearchState research,
    required Map<String, int> playerGold,
    required List<MapObjectiveDefinition> mapObjectives,
    required Map<String, MapObjectiveHoldState>
    mapObjectiveHoldStatesByObjectiveId,
  }) {
    final ownedCities = [
      for (final city in cities)
        if (city.ownerPlayerId == playerId) city,
    ];
    final ownedUnits = [
      for (final unit in units)
        if (unit.ownerPlayerId == playerId) unit,
    ];
    final cityIds = {for (final city in ownedCities) city.id};
    final improvements = [
      for (final improvement in fieldImprovements)
        if (improvement.builtByCityId case final id? when cityIds.contains(id))
          improvement,
    ];
    final playerResearch = research.forPlayer(playerId);
    final gold = playerGold[playerId] ?? 0;

    return EmpireScoreBreakdown(
      playerId: playerId,
      cityScore: ownedCities.length * cityWeight,
      populationScore: _population(ownedCities) * populationWeight,
      territoryScore: _territory(ownedCities) * territoryHexWeight,
      buildingScore: _buildings(ownedCities) * buildingWeight,
      unitScore: _unitScore(ownedUnits),
      technologyScore:
          playerResearch.unlockedTechnologyIds.length * technologyWeight,
      improvementScore: improvements.length * improvementWeight,
      goldScore: goldScoreFor(gold),
      mapObjectiveScore: _mapObjectiveScore(
        playerId: playerId,
        cities: cities,
        units: units,
        mapObjectives: mapObjectives,
        mapObjectiveHoldStatesByObjectiveId:
            mapObjectiveHoldStatesByObjectiveId,
      ),
    );
  }

  int _mapObjectiveScore({
    required String playerId,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    required Iterable<MapObjectiveDefinition> mapObjectives,
    required Map<String, MapObjectiveHoldState>
    mapObjectiveHoldStatesByObjectiveId,
  }) {
    if (mapObjectives.isEmpty) return 0;
    final snapshot = MapObjectiveRules.snapshot(
      objectives: mapObjectives,
      cities: cities,
      units: units,
      holdStatesByObjectiveId: mapObjectiveHoldStatesByObjectiveId,
    );
    return snapshot.victoryPointsByPlayerId()[playerId] ?? 0;
  }

  List<T> _stableList<T>(Iterable<T> values) {
    return values is List<T> ? values : List<T>.unmodifiable(values);
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
    return UnitCatalog.scoreValueFor(type);
  }

  static int goldScoreFor(int gold) {
    if (gold <= 0) return 0;
    final score = gold ~/ goldDivisor;
    return score > maxGoldScore ? maxGoldScore : score;
  }
}
