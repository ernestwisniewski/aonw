import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map() => MapData(
  cols: 4,
  rows: 4,
  tiles: [
    for (var row = 0; row < 4; row++)
      for (var col = 0; col < 4; col++)
        TileData(
          col: col,
          row: row,
          terrains: switch ((col, row)) {
            (2, 1) => const [TerrainType.hills],
            _ => const [TerrainType.grassland],
          },
          resources: const [],
          height: 0,
        ),
  ],
);

GameCity _city() => const GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'City',
  center: CityHex(col: 0, row: 0),
  controlledHexes: [CityHex(col: 1, row: 1), CityHex(col: 2, row: 1)],
);

GameUnit _worker({int col = 1, int row = 1}) => GameUnit(
  id: 'worker_1',
  ownerPlayerId: 'player_1',
  type: GameUnitType.worker,
  name: GameUnitType.worker.defaultNameToken,
  col: col,
  row: row,
);

ResearchState _research(Set<TechnologyId> unlocked) {
  return ResearchState(
    players: {'player_1': PlayerResearchState(unlockedTechnologyIds: unlocked)},
  );
}

void main() {
  group('WorkerImprovementRules', () {
    test('allows farm on owned grassland with agriculture unlocked', () {
      final legality = WorkerImprovementRules.evaluate(
        unit: _worker(),
        improvementType: FieldImprovementType.farm,
        cities: [_city()],
        fieldImprovements: const [],
        mapData: _map(),
        research: _research({TechnologyId.agriculture}),
      );

      expect(legality.allowed, isTrue);
      expect(legality.blocker, isNull);
    });

    test('blocks mine until mining technology is unlocked', () {
      final legality = WorkerImprovementRules.evaluate(
        unit: _worker(col: 2, row: 1),
        improvementType: FieldImprovementType.mine,
        cities: [_city()],
        fieldImprovements: const [],
        mapData: _map(),
        research: ResearchState.empty,
      );

      expect(legality.allowed, isFalse);
      expect(legality.blocker, WorkerImprovementBlocker.technologyLocked);
      expect(legality.requiredTechnology?.id, TechnologyId.mining);
    });

    test('blocks improvement on tile adjacent to city but outside borders', () {
      final legality = WorkerImprovementRules.evaluate(
        unit: _worker(col: 1, row: 0),
        improvementType: FieldImprovementType.farm,
        cities: [_city()],
        fieldImprovements: const [],
        mapData: _map(),
        research: _research({TechnologyId.agriculture}),
      );

      expect(legality.allowed, isFalse);
      expect(legality.blocker, WorkerImprovementBlocker.outsideOwnedTerritory);
    });

    test('allows fishing boats on controlled coastal fish', () {
      final coastalMap = MapData(
        cols: 4,
        rows: 4,
        tiles: [
          for (var row = 0; row < 4; row++)
            for (var col = 0; col < 4; col++)
              TileData(
                col: col,
                row: row,
                terrains: col == 1 && row == 0
                    ? const [TerrainType.coast]
                    : const [TerrainType.grassland],
                resources: col == 1 && row == 0
                    ? const [ResourceType.fish]
                    : const [],
                height: 0,
              ),
        ],
      );

      final legality = WorkerImprovementRules.evaluate(
        unit: _worker(col: 1, row: 0),
        improvementType: FieldImprovementType.fishingBoats,
        cities: [
          _city().copyWith(
            controlledHexes: [
              ..._city().controlledHexes,
              const CityHex(col: 1, row: 0),
            ],
          ),
        ],
        fieldImprovements: const [],
        mapData: coastalMap,
        research: _research({TechnologyId.fishing}),
      );

      expect(legality.allowed, isTrue);
      expect(legality.city?.id, 'city_1');
    });

    test('allows pearl divers on controlled coastal pearls', () {
      final coastalMap = MapData(
        cols: 4,
        rows: 4,
        tiles: [
          for (var row = 0; row < 4; row++)
            for (var col = 0; col < 4; col++)
              TileData(
                col: col,
                row: row,
                terrains: col == 1 && row == 0
                    ? const [TerrainType.coast]
                    : const [TerrainType.grassland],
                resources: col == 1 && row == 0
                    ? const [ResourceType.pearls]
                    : const [],
                height: 0,
              ),
        ],
      );

      final legality = WorkerImprovementRules.evaluate(
        unit: _worker(col: 1, row: 0),
        improvementType: FieldImprovementType.pearlDivers,
        cities: [
          _city().copyWith(
            controlledHexes: [
              ..._city().controlledHexes,
              const CityHex(col: 1, row: 0),
            ],
          ),
        ],
        fieldImprovements: const [],
        mapData: coastalMap,
        research: _research({TechnologyId.navigation}),
      );

      expect(legality.allowed, isTrue);
      expect(legality.city?.id, 'city_1');
    });

    test('blocks improvements outside owned territory', () {
      final legality = WorkerImprovementRules.evaluate(
        unit: _worker(col: 3, row: 3),
        improvementType: FieldImprovementType.farm,
        cities: [_city()],
        fieldImprovements: const [],
        mapData: _map(),
        research: _research({TechnologyId.agriculture}),
      );

      expect(legality.allowed, isFalse);
      expect(legality.blocker, WorkerImprovementBlocker.outsideOwnedTerritory);
    });

    test('blocks starting an improvement where one already exists', () {
      final legality = WorkerImprovementRules.evaluate(
        unit: _worker(),
        improvementType: FieldImprovementType.farm,
        cities: [_city()],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 1, row: 1),
            type: FieldImprovementType.farm,
          ),
        ],
        mapData: _map(),
        research: _research({TechnologyId.agriculture}),
      );

      expect(legality.allowed, isFalse);
      expect(legality.blocker, WorkerImprovementBlocker.existingImprovement);
    });
  });
}
