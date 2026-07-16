import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _artifactSupplyCases =
    <({String name, WorldArtifact artifact, int expectedDelta})>[
      (
        name: 'chronicle stored in own city',
        artifact: WorldArtifact(
          id: 'own_stored_food',
          type: WorldArtifactType.firstPeoplesChronicle,
          location: WorldArtifactLocation.stored(cityId: 'city_1'),
        ),
        expectedDelta: 1,
      ),
      (
        name: 'carried chronicle',
        artifact: WorldArtifact(
          id: 'carried_food',
          type: WorldArtifactType.firstPeoplesChronicle,
          location: WorldArtifactLocation.carried(unitId: 'unit_1'),
        ),
        expectedDelta: 0,
      ),
      (
        name: 'chronicle on map',
        artifact: WorldArtifact(
          id: 'map_food',
          type: WorldArtifactType.firstPeoplesChronicle,
          location: WorldArtifactLocation.map(col: 0, row: 0),
        ),
        expectedDelta: 0,
      ),
      (
        name: 'chronicle under excavation',
        artifact: WorldArtifact(
          id: 'excavated_food',
          type: WorldArtifactType.firstPeoplesChronicle,
          location: WorldArtifactLocation.excavation(
            unitId: 'unit_1',
            col: 0,
            row: 0,
            remainingTurns: 1,
          ),
        ),
        expectedDelta: 0,
      ),
      (
        name: 'chronicle stored in foreign city',
        artifact: WorldArtifact(
          id: 'foreign_stored_food',
          type: WorldArtifactType.firstPeoplesChronicle,
          location: WorldArtifactLocation.stored(cityId: 'city_2'),
        ),
        expectedDelta: 0,
      ),
      (
        name: 'chronicle stored in dangling city',
        artifact: WorldArtifact(
          id: 'dangling_stored_food',
          type: WorldArtifactType.firstPeoplesChronicle,
          location: WorldArtifactLocation.stored(cityId: 'missing_city'),
        ),
        expectedDelta: 0,
      ),
      (
        name: 'non-food artifact stored in own city',
        artifact: WorldArtifact(
          id: 'own_stored_non_food',
          type: WorldArtifactType.merchantsSeal,
          location: WorldArtifactLocation.stored(cityId: 'city_1'),
        ),
        expectedDelta: 0,
      ),
    ];

void main() {
  test('MapData and WorldMap read views produce identical unit supply', () {
    final mapData = _mapData();
    final worldMap = _worldMapFromData(mapData);
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
          artifacts: const [],
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
          artifacts: const [],
          mapView: view,
        ),
      ),
      everyElement(isTrue),
    );
  });

  test('only an own-city stored Chronicle adds one supply', () {
    const ownCity = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Own city',
      population: 3,
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
    );
    const foreignCity = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_2',
      name: 'Foreign city',
      population: 3,
      center: CityHex(col: 2, row: 2),
    );
    final mapData = _mapData();
    final baseline = CityUnitSupplyRules.forPlayer(
      playerId: 'player_1',
      cities: const [ownCity, foreignCity],
      units: const [],
      fieldImprovements: const [],
      artifacts: const [],
      mapView: mapData,
    );
    expect(baseline.rawCapacity, lessThan(baseline.mapCapacity));
    expect(baseline.capacity, baseline.rawCapacity);
    for (final testCase in _artifactSupplyCases) {
      final supply = CityUnitSupplyRules.forPlayer(
        playerId: 'player_1',
        cities: const [ownCity, foreignCity],
        units: const [],
        fieldImprovements: const [],
        artifacts: [testCase.artifact],
        mapView: mapData,
      );

      expect(
        supply.rawCapacity,
        baseline.rawCapacity + testCase.expectedDelta,
        reason: testCase.name,
      );
      expect(
        supply.citySupplyById['city_1'],
        baseline.citySupplyById['city_1']! + testCase.expectedDelta,
        reason: testCase.name,
      );
      expect(
        supply.capacity,
        baseline.capacity + testCase.expectedDelta,
        reason: testCase.name,
      );
      expect(supply.mapCapacity, baseline.mapCapacity, reason: testCase.name);
    }
  });

  test('sparse terrain survey binds the same non-minimum map capacity', () {
    final mapData = _largeSparseMapData();
    final worldMap = _worldMapFromData(mapData);
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
          artifacts: const [],
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

WorldMap _worldMapFromData(MapData source) {
  return WorldMap.fromTileViews(
    cols: source.cols,
    rows: source.rows,
    tiles: source.tiles,
    objectives: source.objectives,
    mapName: source.mapName,
    defaultZoom: source.defaultZoom,
  );
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
