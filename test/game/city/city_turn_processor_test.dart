import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _grassMap() => MapData(
  cols: 4,
  rows: 4,
  tiles: [
    for (var row = 0; row < 4; row++)
      for (var col = 0; col < 4; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

GameCity _city({
  int storedFood = 0,
  int population = 3,
  int maxHexes = GameCity.defaultStartMaxHexes,
  int territoryRadius = GameCity.defaultStartTerritoryRadius,
  Set<CityBuildingType> buildings = const {},
}) {
  return GameCity(
    id: 'city',
    ownerPlayerId: 'player_1',
    name: 'City',
    population: population,
    storedFood: storedFood,
    maxHexes: maxHexes,
    territoryRadius: territoryRadius,
    center: const CityHex(col: 1, row: 1),
    controlledHexes: const [CityHex(col: 2, row: 1), CityHex(col: 1, row: 2)],
    buildings: buildings,
  );
}

void main() {
  group('CityTurnProcessor', () {
    test('stores positive net food without auto-building improvements', () {
      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [_city()],
        fieldImprovements: const [],
        mapData: _grassMap(),
      );

      expect(result.cities.single.storedFood, 3);
      expect(result.cities.single.population, 3);
      expect(result.events, isEmpty);
      expect(result.changed, isTrue);
    });

    test('grows population and claims one food-driven territory hex', () {
      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [_city(storedFood: 28)],
        fieldImprovements: const [],
        mapData: _grassMap(),
        paceBalance: PaceBalance.long120,
      );

      final city = result.cities.single;
      expect(city.population, 4);
      expect(city.storedFood, 0);
      expect(city.territoryHexCount, 4);
      expect(result.fieldImprovements, isEmpty);
      expect(
        result.events.map((event) => event.type),
        containsAll([CityTurnEventType.grew, CityTurnEventType.claimedHex]),
      );
    });

    test('housing building increases effective territory limit', () {
      final city = _city(buildings: {CityBuildingType.housing});

      expect(CityBuildingRules.effectiveMaxHexes(city), 8);
    });

    test('reports gold gained from city economy', () {
      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [
          _city(buildings: {CityBuildingType.merchantHall}),
        ],
        fieldImprovements: const [],
        mapData: _grassMap(),
      );

      expect(result.goldGained, 2);
    });

    test('activates mid-game city cap from population tier', () {
      final result = CityTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [
          _city(population: 6, maxHexes: CityProgressionCatalog.startMaxHexes),
        ],
        fieldImprovements: const [],
        mapData: _grassMap(),
      );

      expect(
        result.cities.single.maxHexes,
        CityProgressionCatalog.midGameMaxHexes,
      );
    });
  });
}
