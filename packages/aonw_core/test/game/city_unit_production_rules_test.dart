import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CityUnitProductionRules', () {
    test('only merchants can spawn on an occupied city center', () {
      final city = _city();
      final garrison = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: city.center.col,
        row: city.center.row,
      );
      final mapData = _mapData();

      final warrior = CityUnitProductionRules.produce(
        city: city,
        unitType: GameUnitType.warrior,
        units: [garrison],
        mapData: mapData,
      );
      final merchant = CityUnitProductionRules.produce(
        city: city,
        unitType: GameUnitType.merchant,
        units: [garrison],
        mapData: mapData,
      );

      expect(warrior, isNull);
      expect(merchant?.type, GameUnitType.merchant);
      expect(merchant?.col, city.center.col);
      expect(merchant?.row, city.center.row);
    });

    test('rejects naval production on coast without adjacent ocean', () {
      final city = _navalCity();
      final mapData = _mapData(
        cols: 4,
        rows: 3,
        coast: {const CityHex(col: 2, row: 1)},
      );

      expect(
        CityUnitProductionRules.canProduceInCity(
          city: city,
          unitType: GameUnitType.scoutShip,
          mapData: mapData,
        ),
        isFalse,
      );
      expect(
        CityUnitProductionRules.produce(
          city: city,
          unitType: GameUnitType.scoutShip,
          units: const [],
          mapData: mapData,
        ),
        isNull,
      );
    });

    test('produces naval units on coast adjacent to ocean', () {
      final city = _navalCity();
      final mapData = _mapData(
        cols: 4,
        rows: 3,
        coast: {const CityHex(col: 2, row: 1)},
        ocean: {const CityHex(col: 3, row: 1)},
      );

      final ship = CityUnitProductionRules.produce(
        city: city,
        unitType: GameUnitType.scoutShip,
        units: const [],
        mapData: mapData,
      );

      expect(
        CityUnitProductionRules.canProduceInCity(
          city: city,
          unitType: GameUnitType.scoutShip,
          mapData: mapData,
        ),
        isTrue,
      );
      expect(ship?.type, GameUnitType.scoutShip);
      expect(ship?.col, 2);
      expect(ship?.row, 1);
    });
  });
}

GameCity _city() {
  return const GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'City',
    center: CityHex(col: 0, row: 0),
  );
}

GameCity _navalCity() {
  return const GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'City',
    center: CityHex(col: 1, row: 1),
    controlledHexes: [CityHex(col: 2, row: 1)],
  );
}

MapData _mapData({
  int cols = 1,
  int rows = 1,
  Set<CityHex> coast = const {},
  Set<CityHex> ocean = const {},
}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains: _terrainFor(
              CityHex(col: col, row: row),
              coast: coast,
              ocean: ocean,
            ),
            resources: const [],
            height: 0,
          ),
    ],
  );
}

List<TerrainType> _terrainFor(
  CityHex hex, {
  required Set<CityHex> coast,
  required Set<CityHex> ocean,
}) {
  if (ocean.contains(hex)) return const [TerrainType.ocean];
  if (coast.contains(hex)) return const [TerrainType.coast];
  return const [TerrainType.grassland];
}
