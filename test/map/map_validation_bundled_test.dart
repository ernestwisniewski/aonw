import 'dart:io';

import 'package:aonw/map/persistence/map_loader.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bundled map validation', () {
    const expectedMaxPlayers = {'verdantia': 4, 'myranth': 3, 'terenos': 3};

    for (final entry in expectedMaxPlayers.entries) {
      final mapName = entry.key;
      final maxPlayers = entry.value;

      test('$mapName passes up to its player capacity', () async {
        final mapData = await _loadBundledMap(mapName);
        expect(
          MapPlayerCapacityRules.maxPlayersForMapData(mapData),
          maxPlayers,
        );

        for (var playerCount = 2; playerCount <= maxPlayers; playerCount++) {
          final result = MapValidator.validate(
            mapData: mapData,
            playerCount: playerCount,
          );

          expect(
            result.errors,
            isEmpty,
            reason:
                '$mapName/$playerCount errors: ${result.errors.map((issue) => issue.code).join(', ')}',
          );
        }
      });
    }

    test('verdantia warns for very short 2-player games', () async {
      final mapData = await _loadBundledMap('verdantia');
      final result = MapValidator.validate(
        mapData: mapData,
        playerCount: 2,
        gameLength: GameLengthConfig.standard60,
      );

      expect(result.errors, isEmpty);
      expect(
        result.warnings.map((issue) => issue.code),
        containsAll(['short_game_slow_first_contact', 'short_game_large_map']),
      );
    });

    test('bundled maps have strategic unit supply ceilings', () async {
      const expectedUnitSupplyCaps = {
        'terenos': 17,
        'myranth': 22,
        'verdantia': 25,
      };

      for (final entry in expectedUnitSupplyCaps.entries) {
        final mapData = await _loadBundledMap(entry.key);

        expect(
          CityUnitSupplyRules.maxCapacityForMap(mapData),
          entry.value,
          reason: '${entry.key} unit supply cap',
        );
      }
    });

    test('bundled maps keep access to gated strategic resources', () async {
      const expectedStrategicResourceMinimums =
          <String, Map<ResourceType, int>>{
            'verdantia': {
              ResourceType.horses: 2,
              ResourceType.iron: 2,
              ResourceType.coal: 2,
              ResourceType.oil: 2,
              ResourceType.aluminium: 2,
              ResourceType.uranium: 1,
            },
            'myranth': {
              ResourceType.horses: 2,
              ResourceType.iron: 2,
              ResourceType.coal: 2,
              ResourceType.oil: 2,
              ResourceType.aluminium: 1,
              ResourceType.uranium: 1,
            },
            'terenos': {
              ResourceType.horses: 2,
              ResourceType.iron: 2,
              ResourceType.coal: 1,
              ResourceType.oil: 1,
              ResourceType.aluminium: 1,
              ResourceType.uranium: 1,
            },
          };

      for (final entry in expectedStrategicResourceMinimums.entries) {
        final mapName = entry.key;
        final mapData = await _loadBundledMap(mapName);
        final resourceCounts = _resourceCounts(mapData);

        for (final resourceEntry in entry.value.entries) {
          expect(
            resourceCounts[resourceEntry.key] ?? 0,
            greaterThanOrEqualTo(resourceEntry.value),
            reason: '$mapName ${resourceEntry.key.name} access',
          );
        }
      }
    });

    test('bundled maps define valid map objectives', () async {
      for (final mapName in expectedMaxPlayers.keys) {
        final mapData = await _loadBundledMap(mapName);
        final ids = <String>{};
        final hexes = <CityHex>{};

        expect(mapData.objectives, isNotEmpty, reason: '$mapName objectives');
        for (final objective in mapData.objectives) {
          expect(ids.add(objective.id), isTrue, reason: objective.id);
          expect(hexes.add(objective.hex), isTrue, reason: objective.id);
          expect(
            mapData.tileAt(objective.hex.col, objective.hex.row),
            isNotNull,
            reason: '$mapName ${objective.id} hex exists',
          );
          expect(objective.requiredHoldTurns, greaterThan(0));
          expect(
            objective.victoryPoints + objective.goldPerTurn,
            greaterThan(0),
            reason: '$mapName ${objective.id} reward',
          );
        }
      }
    });

    test(
      'myranth snowy northeast remains traversable for land units',
      () async {
        final mapData = await _loadBundledMap('myranth');
        final warrior = GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 15,
          row: 3,
        );
        final target = mapData.tileAt(16, 3);

        expect(target?.terrains, [
          TerrainType.river,
          TerrainType.snow,
          TerrainType.forest,
          TerrainType.tundra,
        ]);

        final pathfinder = UnitMovementPathfinder(
          mapData: mapData,
          units: [warrior],
        );
        final plan = pathfinder.plan(unit: warrior, targetTile: target!);
        final movementCosts = pathfinder.movementCostsFrom(
          unit: warrior,
          maxCost: warrior.movementPoints,
        );

        expect(plan, isNotNull);
        expect(plan!.totalCost, 3);
        expect(plan.canMoveNow, isTrue);
        expect(plan.remainingMovementPointsAfterStep(plan.steps.last), 0);
        expect(movementCosts[(col: 16, row: 3)], 3);
      },
    );

    test('bundled map assets are JPEG-only outside JSON metadata', () {
      final pngFiles = Directory('assets/maps')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.png'))
          .map((file) => file.path)
          .toList();

      expect(pngFiles, isEmpty);
    });
  });
}

Future<MapData> _loadBundledMap(String mapName) async {
  final file = File('assets/maps/$mapName/map.json');
  return MapLoader.fromJson(await file.readAsString());
}

Map<ResourceType, int> _resourceCounts(MapData mapData) {
  final counts = <ResourceType, int>{};
  for (final tile in mapData.tiles) {
    for (final resource in tile.resources) {
      counts[resource] = (counts[resource] ?? 0) + 1;
    }
  }
  return counts;
}
