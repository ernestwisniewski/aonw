import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('MapData and WorldMap read views produce identical unit supply', () {
    final mapData = _mapData();
    final worldMap = LegacyWorldMapAdapter.fromMapData(mapData);
    final views = <MapReadView>[mapData, WorldMapReadView(worldMap)];
    final city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      population: 3,
      center: const CityHex(col: 1, row: 1),
      controlledHexes: const [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
      productionQueue: CityProductionQueue.unit(
        unitType: GameUnitType.worker,
        investedProduction: 0,
      ),
    );
    final units = [
      GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 1,
        row: 1,
      ),
    ];

    final breakdowns = [
      for (final view in views)
        CityUnitSupplyRules.forPlayer(
          playerId: 'player_1',
          cities: [city],
          units: units,
          fieldImprovements: const [],
          mapView: view,
        ),
    ];

    expect(_snapshot(breakdowns[1]), _snapshot(breakdowns[0]));
    expect(
      views.map(
        (view) => CityUnitSupplyRules.canQueueUnit(
          playerId: 'player_1',
          unitType: GameUnitType.warrior,
          cities: [city],
          units: units,
          fieldImprovements: const [],
          mapView: view,
        ),
      ),
      everyElement(isTrue),
    );
  });

  test('sparse terrain survey binds the same non-minimum map capacity', () {
    final mapData = _largeSparseMapData();
    final worldMap = LegacyWorldMapAdapter.fromMapData(mapData);
    final views = <MapReadView>[mapData, WorldMapReadView(worldMap)];
    final cities = [
      for (var index = 0; index < 4; index++)
        GameCity(
          id: 'city_$index',
          ownerPlayerId: 'player_1',
          name: 'City $index',
          population: 3,
          center: const CityHex(col: 0, row: 0),
          controlledHexes: const [
            CityHex(col: 1, row: 0),
            CityHex(col: 2, row: 0),
          ],
        ),
    ];

    final breakdowns = [
      for (final view in views)
        CityUnitSupplyRules.forPlayer(
          playerId: 'player_1',
          cities: cities,
          units: const [],
          fieldImprovements: const [],
          mapView: view,
        ),
    ];

    expect(views.map((view) => view.tileCount), everyElement(219));
    expect(views.map(CityUnitSupplyRules.maxCapacityForMap), everyElement(18));
    expect(_snapshot(breakdowns[1]), _snapshot(breakdowns[0]));
    expect(breakdowns[0].rawCapacity, greaterThan(18));
    expect(breakdowns[0].mapCapacity, 18);
    expect(breakdowns[0].capacity, 18);
  });
}

Map<String, Object> _snapshot(CityUnitSupplyBreakdown breakdown) => {
  'capacity': breakdown.capacity,
  'rawCapacity': breakdown.rawCapacity,
  'mapCapacity': breakdown.mapCapacity,
  'unitSupplyUsed': breakdown.unitSupplyUsed,
  'queuedSupplyUsed': breakdown.queuedSupplyUsed,
  'citySupplyById': breakdown.citySupplyById,
  'usedSupplyByType': breakdown.usedSupplyByType,
};

MapData _mapData() {
  return MapData(
    cols: 3,
    rows: 3,
    mapName: 'myranth',
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          TileData(
            col: col,
            row: row,
            terrains: col == 2 && row == 2
                ? const [TerrainType.ocean]
                : const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

MapData _largeSparseMapData() {
  return MapData(
    cols: 30,
    rows: 20,
    mapName: 'supply-cap-survey',
    tiles: [
      for (var index = 0; index < 219; index++)
        TileData(
          col: index % 30,
          row: index ~/ 30,
          terrains: index < 160
              ? const [TerrainType.grassland]
              : const [TerrainType.ocean],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
