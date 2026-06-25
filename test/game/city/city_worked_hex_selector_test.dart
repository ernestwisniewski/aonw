import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

TileData _tile({
  required int col,
  required int row,
  List<TerrainType> terrains = const [TerrainType.grassland],
  List<ResourceType> resources = const [],
}) {
  return TileData(
    col: col,
    row: row,
    terrains: terrains,
    resources: resources,
    height: 0,
  );
}

MapData _map() {
  return MapData(
    cols: 4,
    rows: 4,
    tiles: [
      _tile(col: 1, row: 1),
      _tile(col: 2, row: 1, resources: const [ResourceType.wheat]),
      _tile(col: 1, row: 2, terrains: const [TerrainType.hills]),
      _tile(col: 0, row: 1, terrains: const [TerrainType.desert]),
    ],
  );
}

GameCity _city({int population = 1, List<CityHex> workedHexes = const []}) {
  return GameCity(
    id: 'city',
    ownerPlayerId: 'player_1',
    name: 'City',
    population: population,
    center: const CityHex(col: 1, row: 1),
    controlledHexes: const [
      CityHex(col: 2, row: 1),
      CityHex(col: 1, row: 2),
      CityHex(col: 0, row: 1),
    ],
    workedHexes: workedHexes,
  );
}

void main() {
  group('CityWorkedHexSelector', () {
    test(
      'automatically selects the best controlled hexes up to population',
      () {
        final selected = CityWorkedHexSelector.effectiveWorkedHexes(
          city: _city(population: 2),
          mapData: _map(),
        );

        expect(selected, const [
          CityHex(col: 2, row: 1),
          CityHex(col: 1, row: 2),
        ]);
      },
    );

    test('keeps valid manual worked hexes and fills remaining slots', () {
      final selected = CityWorkedHexSelector.effectiveWorkedHexes(
        city: _city(
          population: 2,
          workedHexes: const [CityHex(col: 1, row: 2)],
        ),
        mapData: _map(),
      );

      expect(selected, const [
        CityHex(col: 1, row: 2),
        CityHex(col: 2, row: 1),
      ]);
    });

    test('reads worked hex limit from injected progression', () {
      final ruleset = CityRulesets.standard.copyWith(
        progression: const CityProgression(
          startPopulation: 3,
          startStoredFood: 0,
          startMaxHexes: 6,
          midGameMaxHexes: 8,
          lateGameMaxHexes: 10,
          startTerritoryRadius: 2,
          expandedTerritoryRadius: 3,
          foodUpkeepPerPopulation: 1,
          growthBaseCost: 10,
          growthCostPerPopulation: 4,
          growthCostPerControlledHex: 3,
          workedHexLimitBase: 1,
          workedHexesPerPopulation: 0,
        ),
      );

      final selected = CityWorkedHexSelector.effectiveWorkedHexes(
        city: _city(population: 3),
        mapData: _map(),
        ruleset: ruleset,
      );

      expect(selected, const [CityHex(col: 2, row: 1)]);
    });
  });

  group('CityYieldCalculator', () {
    test('uses city center plus effective worked hexes, not all territory', () {
      final yield = CityYieldCalculator.totalFor(
        _city(population: 1, workedHexes: const [CityHex(col: 1, row: 2)]),
        _map(),
      );

      expect(
        yield,
        const TileYield(food: 2, production: 3, gold: 0, defense: 0),
      );
    });

    test('adds assigned worker bonus to improved city hex', () {
      final yield = CityYieldCalculator.totalFor(
        _city(population: 1),
        _map(),
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 2, row: 1),
            type: FieldImprovementType.farm,
            builtByCityId: 'city',
          ),
        ],
        units: [
          GameUnit(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            name: GameUnitType.worker.defaultNameToken,
            col: 2,
            row: 1,
            workerAssignment: const WorkerAssignment(
              targetHex: CityHex(col: 2, row: 1),
            ),
          ),
        ],
      );

      expect(
        yield,
        const TileYield(food: 10, production: 1, gold: 0, defense: 0),
      );
    });

    test('passive improvements only add partial improvement yield', () {
      final yield = CityYieldCalculator.totalFor(
        _city(population: 1, workedHexes: const [CityHex(col: 1, row: 2)]),
        _map(),
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 2, row: 1),
            type: FieldImprovementType.farm,
            builtByCityId: 'city',
          ),
        ],
      );

      expect(
        yield,
        const TileYield(food: 3, production: 3, gold: 0, defense: 0),
      );
    });

    test('assigned workers activate full tile yield without population', () {
      final yield = CityYieldCalculator.totalFor(
        _city(population: 1, workedHexes: const [CityHex(col: 1, row: 2)]),
        _map(),
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 2, row: 1),
            type: FieldImprovementType.farm,
            builtByCityId: 'city',
          ),
        ],
        units: [
          GameUnit(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            name: GameUnitType.worker.defaultNameToken,
            col: 2,
            row: 1,
            workerAssignment: const WorkerAssignment(
              targetHex: CityHex(col: 2, row: 1),
            ),
          ),
        ],
      );

      expect(
        yield,
        const TileYield(food: 10, production: 3, gold: 0, defense: 0),
      );
    });

    test(
      'breakdown separates center, population, workers and passive yields',
      () {
        final city = _city(
          population: 1,
          workedHexes: const [CityHex(col: 1, row: 2)],
        );
        const fieldImprovements = [
          FieldImprovement(
            hex: CityHex(col: 2, row: 1),
            type: FieldImprovementType.farm,
            builtByCityId: 'city',
          ),
          FieldImprovement(
            hex: CityHex(col: 0, row: 1),
            type: FieldImprovementType.farm,
            builtByCityId: 'city',
          ),
        ];
        final units = [
          GameUnit(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            name: GameUnitType.worker.defaultNameToken,
            col: 2,
            row: 1,
            workerAssignment: const WorkerAssignment(
              targetHex: CityHex(col: 2, row: 1),
            ),
          ),
        ];

        final breakdown = CityYieldCalculator.breakdownFor(
          city,
          _map(),
          fieldImprovements: fieldImprovements,
          units: units,
        );

        expect(
          breakdown.centerYield,
          const TileYield(food: 2, production: 1, gold: 0, defense: 0),
        );
        expect(
          breakdown.populationYield,
          const TileYield(food: 0, production: 2, gold: 0, defense: 0),
        );
        expect(
          breakdown.workerYield,
          const TileYield(food: 8, production: 0, gold: 0, defense: 0),
        );
        expect(
          breakdown.passiveImprovementYield,
          const TileYield(food: 1, production: 0, gold: 0, defense: 0),
        );
        expect(
          breakdown.total,
          CityYieldCalculator.totalFor(
            city,
            _map(),
            fieldImprovements: fieldImprovements,
            units: units,
          ),
        );
      },
    );
  });
}
