import 'dart:convert';

import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('InitialResourceDistributionGenerator', () {
    test('is deterministic and gives every start an equal category quota', () {
      final mapData = _map();
      final units = _starts();

      final first = InitialResourceDistributionGenerator.generate(
        mapData: mapData,
        startingUnits: units,
        seed: 41,
      );
      final repeated = InitialResourceDistributionGenerator.generate(
        mapData: mapData,
        startingUnits: units,
        seed: 41,
      );
      final different = InitialResourceDistributionGenerator.generate(
        mapData: mapData,
        startingUnits: units,
        seed: 42,
      );

      expect(repeated, first);
      expect(different, isNot(first));
      expect(first.countForCategory(ResourceCategory.bonus), 2);
      expect(first.countForCategory(ResourceCategory.luxury), 2);
      expect(first.countForCategory(ResourceCategory.strategic), 2);
      expect(
        first.placements.map((placement) => placement.resource),
        everyElement(
          predicate<ResourceType>(ResourceCatalog.standard.containsKey),
        ),
      );
    });

    test('never replaces a start, objective, or authored resource', () {
      final mapData = _map(
        objectives: const [
          MapObjectiveDefinition(
            id: 'objective',
            type: MapObjectiveType.ruins,
            hex: HexCoord(col: 5, row: 3),
          ),
        ],
        authoredResource: const HexCoord(col: 6, row: 3),
      );

      final distribution = InitialResourceDistributionGenerator.generate(
        mapData: mapData,
        startingUnits: _starts(),
        seed: 99,
      );
      final occupied = {
        for (final placement in distribution.placements)
          '${placement.col}:${placement.row}',
      };

      expect(occupied, isNot(contains('1:1')));
      expect(occupied, isNot(contains('10:6')));
      expect(occupied, isNot(contains('5:3')));
      expect(occupied, isNot(contains('6:3')));
      expect(occupied.length, distribution.placements.length);
    });
  });

  test('distribution JSON and map application are lossless', () {
    final distribution = InitialResourceDistribution(
      seed: 7,
      placements: const [
        InitialResourcePlacement(col: 2, row: 2, resource: ResourceType.marble),
      ],
    );

    final restored = InitialResourceDistribution.fromJson(
      jsonDecode(jsonEncode(distribution.toJson())),
    );
    final effectiveMap = restored.applyTo(_map());

    expect(restored, distribution);
    expect(effectiveMap.tileAt(2, 2)!.resources, [ResourceType.marble]);
    expect(_map().tileAt(2, 2)!.resources, isEmpty);
  });

  test('marble belongs to the strategic economy catalog', () {
    expect(ResourceCatalog.isStrategic(ResourceType.marble), isTrue);
    expect(ResourceCatalog.strategicResources, contains(ResourceType.marble));
    expect(ResourceCatalog.isBonus(ResourceType.marble), isFalse);
  });
}

List<GameUnit> _starts() => [
  GameUnit.produced(
    id: 'settler_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.settler,
    col: 1,
    row: 1,
  ),
  GameUnit.produced(
    id: 'settler_2',
    ownerPlayerId: 'player_2',
    type: GameUnitType.settler,
    col: 10,
    row: 6,
  ),
];

WorldMap _map({
  List<MapObjectiveDefinition> objectives = const [],
  HexCoord? authoredResource,
}) => WorldMap(
  cols: 12,
  rows: 8,
  objectives: objectives,
  tiles: [
    for (var row = 0; row < 8; row++)
      for (var col = 0; col < 12; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: authoredResource == HexCoord(col: col, row: row)
              ? const [ResourceType.wheat]
              : const [],
          height: 0,
        ),
  ],
);
