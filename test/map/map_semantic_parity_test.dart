import 'dart:convert';
import 'dart:io';

import 'package:aonw/map/persistence/map_loader.dart';
import 'package:aonw_core/domain/map_objective_definition.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/terrain.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/current_content_legacy_fixture.dart';

void main() {
  test(
    'canonical maps preserve all effective pre-cutover tile semantics',
    () async {
      final fixture =
          jsonDecode(
                await File(
                  'test/fixtures/map_semantic_parity_v1.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      expect(fixture['fixtureVersion'], 1);
      final expectedMaps = fixture['maps'] as Map<String, dynamic>;
      var totalTiles = 0;

      for (final entry in expectedMaps.entries) {
        final map = MapLoader.fromJson(
          await loadCurrentMapAsLegacyFixture(entry.key),
        );
        totalTiles += map.tiles.length;
        expect(
          _digests(map.tiles, map.objectives),
          entry.value,
          reason: '${entry.key} effective semantics',
        );
      }

      expect(totalTiles, fixture['totalTiles']);
      expect(totalTiles, 2575);
    },
  );

  test(
    'production terrain consumers do not infer semantics from tag order',
    () {
      final violations = <String>[];
      for (final root in [
        'packages/aonw_core/lib',
        'lib',
        'server/lib',
        'tool',
      ]) {
        for (final file
            in Directory(root)
                .listSync(recursive: true)
                .whereType<File>()
                .where((file) => file.path.endsWith('.dart'))) {
          if (_orderAwareDomainFiles.any(file.path.endsWith)) continue;
          final lines = file.readAsLinesSync();
          for (var index = 0; index < lines.length; index++) {
            final line = lines[index];
            if (_orderDependentTerrainPatterns.any(
              (pattern) => pattern.hasMatch(line),
            )) {
              violations.add('${file.path}:${index + 1}: ${line.trim()}');
            }
          }
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    },
  );
}

Map<String, Object?> _digests(
  List<WorldTile> tiles,
  List<MapObjectiveDefinition> objectives,
) {
  final sortedTiles = [...tiles]
    ..sort((left, right) {
      final row = left.row.compareTo(right.row);
      return row != 0 ? row : left.col.compareTo(right.col);
    });
  final sortedObjectives = [...objectives]
    ..sort((left, right) => left.id.compareTo(right.id));
  final semantic = <Object?>[];
  final movement = <Object?>[];
  final yields = <Object?>[];
  final combatAndTags = <Object?>[];
  final resourcesAndObjectives = <Object?>[];

  for (final tile in sortedTiles) {
    final coordinate = [tile.col, tile.row];
    semantic.add([
      ...coordinate,
      tile.terrains.map((value) => value.name).toList(),
      tile.displayTerrain.name,
      tile.yieldTerrain.name,
      tile.terrainTags.map((value) => value.name).toList(),
      tile.height,
    ]);
    final profile = TileTerrainProfileRules.fromTile(tile);
    movement.add([
      ...coordinate,
      profile.base?.name,
      _names(profile.features),
      _names(profile.modifiers),
      _names(profile.blockers),
      for (final unitType in GameUnitType.values) _movementCost(unitType, tile),
    ]);
    final tileYield = TileYieldRules.forTile(tile);
    yields.add([
      ...coordinate,
      tileYield.food,
      tileYield.production,
      tileYield.gold,
      tileYield.defense,
    ]);
    combatAndTags.add([
      ...coordinate,
      tile.terrainTags.map((value) => value.name).toList(),
      for (final terrain in tile.terrainTags)
        _combatStats(CombatRuleset.standard.terrainStatsFor(terrain)),
    ]);
    final resources = tile.resources.map((value) => value.name).toList()
      ..sort();
    resourcesAndObjectives.add([...coordinate, resources]);
  }
  resourcesAndObjectives.add([
    'objectives',
    for (final objective in sortedObjectives)
      [
        objective.id,
        objective.type.name,
        objective.hex.col,
        objective.hex.row,
        objective.requiredHoldTurns,
        objective.victoryPoints,
        objective.goldPerTurn,
      ],
  ]);
  return {
    'tileCount': sortedTiles.length,
    'semanticSha256': _digest(semantic),
    'movementAndPassabilitySha256': _digest(movement),
    'yieldSha256': _digest(yields),
    'combatAndTagsSha256': _digest(combatAndTags),
    'resourcesAndObjectivesSha256': _digest(resourcesAndObjectives),
  };
}

List<Object> _movementCost(GameUnitType unitType, WorldTile tile) {
  final cost = UnitMovementCostRules.costToEnterTile(tile, unitType: unitType);
  return [unitType.name, cost.blocked, cost.value];
}

List<int> _combatStats(CombatStats stats) => [
  stats.attack,
  stats.defense,
  stats.hp,
  stats.range,
  stats.mobility,
];

List<String> _names(Iterable<TerrainType> values) {
  final names = values.map((value) => value.name).toList()..sort();
  return names;
}

String _digest(Object? value) =>
    sha256.convert(utf8.encode(jsonEncode(value))).toString();

const _orderAwareDomainFiles = [
  'map/domain/tile_terrain_semantics.dart',
  'domain/world_map_invariants.dart',
  'map/domain/terrain_type.dart',
];

final _orderDependentTerrainPatterns = [
  RegExp(r'primaryTerrain'),
  RegExp(r'(?:terrains|terrainTags)\s*\[\s*0\s*\]'),
  RegExp(r'(?:terrains|terrainTags)\.(?:first|firstWhere|firstOrNull)\b'),
];
