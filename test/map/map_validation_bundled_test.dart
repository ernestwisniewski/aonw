import 'dart:io';

import 'package:aonw/map/persistence/map_loader.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bundled map validation', () {
    const expectedMaxPlayers = {
      'verdantia': 4,
      'myranth': 3,
      'terenos': 3,
      'dravonia': 4,
    };

    for (final entry in expectedMaxPlayers.entries) {
      final mapName = entry.key;
      final maxPlayers = entry.value;

      test('$mapName passes up to its player capacity', () async {
        final mapData = await _loadBundledMap(mapName);
        expect(
          MapPlayerCapacityRules.maxPlayersForWorldMap(mapData),
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
        'dravonia': 28,
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
            'dravonia': {
              ResourceType.horses: 4,
              ResourceType.iron: 4,
              ResourceType.coal: 2,
              ResourceType.oil: 2,
              ResourceType.aluminium: 4,
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

    test(
      'dravonia balances resource access across four start regions',
      () async {
        final mapData = await _loadBundledMap('dravonia');
        final result = MapValidator.validate(mapData: mapData, playerCount: 4);

        expect(result.errors, isEmpty);
        expect(result.startSites, hasLength(4));
        _expectDravoniaStartSites(result.startSites);
        _expectDravoniaResourceAccess(mapData, result.startSites);
        _expectDravoniaShortGameWarnings(mapData);
      },
    );

    test('dravonia passable land and objectives form one component', () async {
      final mapData = await _loadBundledMap('dravonia');
      _expectConnectedPassableLand(mapData);
    });

    test('bundled maps define valid map objectives', () async {
      for (final mapName in expectedMaxPlayers.keys) {
        final mapData = await _loadBundledMap(mapName);
        final ids = <String>{};
        final hexes = <HexCoord>{};

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

    test('bundled maps use one canonical primary terrain per tile', () async {
      for (final mapName in expectedMaxPlayers.keys) {
        final mapData = await _loadBundledMap(mapName);

        for (final tile in mapData.tiles) {
          expect(
            _primaryTerrains,
            contains(tile.terrains.first),
            reason: '$mapName ${tile.col},${tile.row} primary terrain',
          );
          expect(
            tile.terrains.skip(1),
            everyElement(isIn(_terrainFeatures)),
            reason: '$mapName ${tile.col},${tile.row} terrain features',
          );
          expect(
            tile.terrains.toSet(),
            hasLength(tile.terrains.length),
            reason: '$mapName ${tile.col},${tile.row} unique terrains',
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
          TerrainType.snow,
          TerrainType.forest,
          TerrainType.river,
        ]);

        final pathfinder = UnitMovementPathfinder(
          mapData: mapData,
          units: [warrior],
        );
        final plan = pathfinder.plan(unit: warrior, targetTile: target!);
        final movementCosts = pathfinder.movementCostsFrom(
          unit: warrior,
          maxCost: warrior.movementUnits,
        );

        expect(plan, isNotNull);
        expect(plan!.totalCost, 6);
        expect(plan.canMoveNow, isTrue);
        expect(plan.remainingMovementUnitsAfterStep(plan.steps.last), 0);
        expect(movementCosts[(col: 16, row: 3)], 6);
      },
    );

    test('bundled map assets are JPEG-only outside JSON metadata', () {
      final pngFiles = Directory('assets/runtime/maps')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.png'))
          .map((file) => file.path)
          .toList();

      expect(pngFiles, isEmpty);
    });
  });
}

const _primaryTerrains = {
  TerrainType.ocean,
  TerrainType.coast,
  TerrainType.lake,
  TerrainType.plains,
  TerrainType.grassland,
  TerrainType.desert,
  TerrainType.tundra,
  TerrainType.snow,
  TerrainType.mountain,
};

const _terrainFeatures = {
  TerrainType.hills,
  TerrainType.wetlands,
  TerrainType.jungle,
  TerrainType.forest,
  TerrainType.river,
};

Future<WorldMap> _loadBundledMap(String mapName) async {
  final file = File('content/maps/$mapName/map.json');
  return MapLoader.fromJson(await file.readAsString());
}

Map<ResourceType, int> _resourceCounts(WorldMap mapData) {
  final counts = <ResourceType, int>{};
  for (final tile in mapData.tiles) {
    for (final resource in tile.resources) {
      counts[resource] = (counts[resource] ?? 0) + 1;
    }
  }
  return counts;
}

const _dravoniaMaxStrategicDistance = <ResourceType, int>{
  ResourceType.horses: 3,
  ResourceType.iron: 3,
  ResourceType.aluminium: 9,
  ResourceType.oil: 14,
  ResourceType.coal: 12,
  ResourceType.uranium: 14,
};

void _expectDravoniaStartSites(List<MapStartSiteReport> startSites) {
  expect(startSites.map(_startSiteSnapshot).toList(), const [
    (
      warriorCol: 10,
      warriorRow: 7,
      settlerCol: 10,
      settlerRow: 6,
      passableRing: 7,
      foodRing: 1,
      controlled: 18,
    ),
    (
      warriorCol: 30,
      warriorRow: 22,
      settlerCol: 30,
      settlerRow: 21,
      passableRing: 7,
      foodRing: 1,
      controlled: 18,
    ),
    (
      warriorCol: 30,
      warriorRow: 7,
      settlerCol: 30,
      settlerRow: 6,
      passableRing: 7,
      foodRing: 1,
      controlled: 18,
    ),
    (
      warriorCol: 10,
      warriorRow: 22,
      settlerCol: 10,
      settlerRow: 21,
      passableRing: 7,
      foodRing: 1,
      controlled: 18,
    ),
  ]);
}

({
  int warriorCol,
  int warriorRow,
  int settlerCol,
  int settlerRow,
  int passableRing,
  int foodRing,
  int controlled,
})
_startSiteSnapshot(MapStartSiteReport site) => (
  warriorCol: site.warrior.col,
  warriorRow: site.warrior.row,
  settlerCol: site.settler.col,
  settlerRow: site.settler.row,
  passableRing: site.passableTilesInFirstRing,
  foodRing: site.foodResourcesInFirstRing,
  controlled: site.controlledCandidates,
);

void _expectDravoniaResourceAccess(
  WorldMap mapData,
  List<MapStartSiteReport> startSites,
) {
  for (final site in startSites) {
    _expectDravoniaStartResourceAccess(mapData, site);
  }
}

void _expectDravoniaStartResourceAccess(
  WorldMap mapData,
  MapStartSiteReport site,
) {
  for (final entry in _dravoniaMaxStrategicDistance.entries) {
    expect(
      _nearestResourceDistance(mapData, site.settler, entry.key),
      lessThanOrEqualTo(entry.value),
      reason: 'dravonia start ${site.playerIndex + 1} ${entry.key.name} access',
    );
  }
  expect(
    _nearbyLuxuryCount(mapData, site.settler),
    greaterThanOrEqualTo(2),
    reason: 'dravonia start ${site.playerIndex + 1} luxury variety',
  );
}

int? _nearestResourceDistance(
  WorldMap mapData,
  HexCoordinate origin,
  ResourceType resource,
) {
  int? nearest;
  for (final tile in mapData.tiles) {
    if (!tile.resources.contains(resource)) continue;
    final distance = HexDistance.between(
      origin,
      HexCoordinate(col: tile.col, row: tile.row),
    );
    if (nearest == null || distance < nearest) nearest = distance;
  }
  return nearest;
}

int _nearbyLuxuryCount(WorldMap mapData, HexCoordinate origin) {
  var count = 0;
  for (final tile in mapData.tiles) {
    final distance = HexDistance.between(
      origin,
      HexCoordinate(col: tile.col, row: tile.row),
    );
    if (distance > 6) continue;
    count += tile.resources
        .where(StabilitySourceCatalog.luxuryResources.contains)
        .length;
  }
  return count;
}

void _expectDravoniaShortGameWarnings(WorldMap mapData) {
  final shortGame = MapValidator.validate(
    mapData: mapData,
    playerCount: 4,
    gameLength: GameLengthConfig.standard60,
  );
  expect(
    shortGame.warnings.map((issue) => issue.code),
    containsAll(['short_game_slow_first_contact', 'short_game_large_map']),
  );
}

void _expectConnectedPassableLand(WorldMap mapData) {
  final passable = {
    for (final tile in mapData.tiles)
      if (UnitMovementCostRules.costToEnterTile(tile).passable)
        HexCoordinate(col: tile.col, row: tile.row),
  };
  final frontier = <HexCoordinate>[passable.first];
  final reachable = <HexCoordinate>{passable.first};
  for (var index = 0; index < frontier.length; index++) {
    _visitPassableNeighbors(
      mapData: mapData,
      origin: frontier[index],
      passable: passable,
      reachable: reachable,
      frontier: frontier,
    );
  }

  expect(reachable, passable);
  expect(
    mapData.objectives.map(
      (objective) =>
          HexCoordinate(col: objective.hex.col, row: objective.hex.row),
    ),
    everyElement(isIn(reachable)),
  );
}

void _visitPassableNeighbors({
  required WorldMap mapData,
  required HexCoordinate origin,
  required Set<HexCoordinate> passable,
  required Set<HexCoordinate> reachable,
  required List<HexCoordinate> frontier,
}) {
  for (final neighbor in HexNeighbors.existingAround(origin, mapData)) {
    if (passable.contains(neighbor) && reachable.add(neighbor)) {
      frontier.add(neighbor);
    }
  }
}
