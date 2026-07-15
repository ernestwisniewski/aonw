import 'dart:collection';

import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('persistent rush forwards artifacts into its yield calculation', () {
    final granaryCost = CityProductionRules.targetCost(
      const BuildingProductionTarget(CityBuildingType.granary),
    );
    final artifacts = _TrackingArtifactList([
      const WorldArtifact(
        id: 'artifact.firstPeoplesChronicle',
        type: WorldArtifactType.firstPeoplesChronicle,
        location: WorldArtifactLocation.stored(cityId: 'city_1'),
      ),
    ]);
    final state = PersistentGameState(
      cities: [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: const CityHex(col: 1, row: 1),
          productionQueue: CityProductionQueue.building(
            buildingType: CityBuildingType.granary,
            investedProduction: granaryCost - 1,
          ),
        ),
      ],
      artifacts: artifacts,
      playerGold: const {'player_1': 2},
    );

    final result = const PersistentCityProductionResolver().rushProduction(
      state: state,
      command: const RushProductionCommand('city_1'),
      actorPlayerId: 'player_1',
      worldMap: _worldMap(),
    );

    expect(result.accepted, isTrue);
    expect(artifacts.iterationCount, greaterThan(0));
  });
}

WorldMap _worldMap() {
  return WorldMap(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          WorldTile(
            coordinate: HexCoord(col: col, row: row),
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

final class _TrackingArtifactList extends ListBase<WorldArtifact> {
  _TrackingArtifactList(Iterable<WorldArtifact> items)
    : _items = List.of(items);

  final List<WorldArtifact> _items;
  int iterationCount = 0;

  @override
  Iterator<WorldArtifact> get iterator {
    iterationCount++;
    return _items.iterator;
  }

  @override
  int get length => _items.length;

  @override
  set length(int value) => _items.length = value;

  @override
  WorldArtifact operator [](int index) => _items[index];

  @override
  void operator []=(int index, WorldArtifact value) => _items[index] = value;
}
