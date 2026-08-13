import 'dart:math' as math;

import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_cost_rules.dart';
import 'package:aonw_core/game/domain/resource/initial_resource_distribution.dart';
import 'package:aonw_core/game/domain/resource/resource_definition.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

/// Creates a small, fair and replay-stable resource variation for a new match.
///
/// Every starting position gets at most one bonus, luxury and strategic
/// placement. Positions and types vary with [seed], while equal category
/// quotas keep one player from receiving a systematically richer start.
abstract final class InitialResourceDistributionGenerator {
  static InitialResourceDistribution generate({
    required WorldMap mapData,
    required Iterable<GameUnit> startingUnits,
    required int seed,
  }) {
    final units = List<GameUnit>.of(startingUnits);
    final anchors = _startingAnchors(units);
    if (anchors.isEmpty || mapData.tiles.isEmpty) {
      return InitialResourceDistribution(seed: seed, placements: const []);
    }

    final unavailable = <String>{
      for (final unit in units) _key(unit.col, unit.row),
      for (final objective in mapData.objectives)
        _key(objective.hex.col, objective.hex.row),
      for (final tile in mapData.tiles)
        if (tile.resources.isNotEmpty) _key(tile.col, tile.row),
    };
    final placements = <InitialResourcePlacement>[];
    final rng = _ResourceDistributionRng(seed ^ 0x6D2B79F5);

    for (final category in const [
      ResourceCategory.bonus,
      ResourceCategory.luxury,
      ResourceCategory.strategic,
    ]) {
      final offset = rng.nextInt(anchors.length);
      for (var step = 0; step < anchors.length; step++) {
        final anchor = anchors[(offset + step) % anchors.length];
        final candidate = _pickCandidate(
          mapData: mapData,
          anchor: anchor,
          category: category,
          unavailable: unavailable,
          rng: rng,
        );
        if (candidate == null) continue;
        final resources = _compatibleResources(candidate, category);
        final resource = resources[rng.nextInt(resources.length)];
        placements.add(
          InitialResourcePlacement(
            col: candidate.col,
            row: candidate.row,
            resource: resource,
          ),
        );
        unavailable.add(_key(candidate.col, candidate.row));
      }
    }

    return InitialResourceDistribution(seed: seed, placements: placements);
  }

  static List<({int col, int row})> _startingAnchors(Iterable<GameUnit> units) {
    final byPlayer = <String, GameUnit>{};
    for (final unit in units) {
      if (unit.ownerPlayerId.isEmpty) continue;
      final current = byPlayer[unit.ownerPlayerId];
      if (current == null || unit.type == GameUnitType.settler) {
        byPlayer[unit.ownerPlayerId] = unit;
      }
    }
    return [for (final unit in byPlayer.values) (col: unit.col, row: unit.row)];
  }

  static WorldTile? _pickCandidate({
    required WorldMap mapData,
    required ({int col, int row}) anchor,
    required ResourceCategory category,
    required Set<String> unavailable,
    required _ResourceDistributionRng rng,
  }) {
    final range = _preferredRange(category);
    final eligible = [
      for (final tile in mapData.tiles)
        if (!unavailable.contains(_key(tile.col, tile.row)) &&
            _compatibleResources(tile, category).isNotEmpty)
          tile,
    ];
    if (eligible.isEmpty) return null;
    final preferred = [
      for (final tile in eligible)
        if (_distance(tile, anchor) >= range.min &&
            _distance(tile, anchor) <= range.max)
          tile,
    ];
    final pool = preferred.isEmpty ? eligible : preferred;
    final scored =
        [
          for (final tile in pool)
            (
              tile: tile,
              score:
                  (_distance(tile, anchor) - range.target).abs() * 100 +
                  rng.nextInt(71),
            ),
        ]..sort((left, right) {
          final score = left.score.compareTo(right.score);
          if (score != 0) return score;
          final row = left.tile.row.compareTo(right.tile.row);
          if (row != 0) return row;
          return left.tile.col.compareTo(right.tile.col);
        });
    final shortlistLength = math.min(4, scored.length);
    return scored[rng.nextInt(shortlistLength)].tile;
  }

  static ({int min, int max, int target}) _preferredRange(
    ResourceCategory category,
  ) => switch (category) {
    ResourceCategory.bonus => (min: 1, max: 3, target: 2),
    ResourceCategory.luxury => (min: 2, max: 5, target: 3),
    ResourceCategory.strategic => (min: 3, max: 7, target: 5),
  };

  static int _distance(WorldTile tile, ({int col, int row}) anchor) =>
      HexDistance.between(
        HexCoordinate(col: tile.col, row: tile.row),
        HexCoordinate(col: anchor.col, row: anchor.row),
      );

  static List<ResourceType> _compatibleResources(
    WorldTile tile,
    ResourceCategory category,
  ) {
    if (UnitMovementCostRules.costToEnterTile(tile).blocked) return const [];
    final terrains = tile.terrains.toSet();
    final profile = _resourceProfile(terrains);
    return switch (category) {
      ResourceCategory.bonus => profile.bonus,
      ResourceCategory.luxury => profile.luxury,
      ResourceCategory.strategic => profile.strategic,
    };
  }

  static _ResourceProfile _resourceProfile(Set<TerrainType> terrains) {
    if (terrains.any(_waterTerrains.contains)) return _waterProfile;
    if (terrains.contains(TerrainType.desert)) return _desertProfile;
    if (terrains.contains(TerrainType.snow) ||
        terrains.contains(TerrainType.tundra)) {
      return _coldProfile;
    }
    if (terrains.contains(TerrainType.jungle)) return _jungleProfile;
    if (terrains.contains(TerrainType.forest)) return _forestProfile;
    if (terrains.contains(TerrainType.wetlands)) return _wetlandsProfile;
    if (terrains.contains(TerrainType.hills)) return _hillsProfile;
    return _openLandProfile;
  }

  static String _key(int col, int row) => '$col:$row';
}

typedef _ResourceProfile = ({
  List<ResourceType> bonus,
  List<ResourceType> luxury,
  List<ResourceType> strategic,
});

const _waterTerrains = {TerrainType.ocean, TerrainType.coast, TerrainType.lake};

const _waterProfile = (
  bonus: [ResourceType.fish],
  luxury: [ResourceType.pearls],
  strategic: [ResourceType.oil],
);
const _desertProfile = (
  bonus: [ResourceType.sheep, ResourceType.citrus],
  luxury: [
    ResourceType.gold,
    ResourceType.silver,
    ResourceType.gems,
    ResourceType.spices,
    ResourceType.ivory,
  ],
  strategic: [
    ResourceType.oil,
    ResourceType.uranium,
    ResourceType.horses,
    ResourceType.marble,
  ],
);
const _coldProfile = (
  bonus: [ResourceType.deer, ResourceType.sheep],
  luxury: [ResourceType.silver, ResourceType.gems, ResourceType.ivory],
  strategic: [ResourceType.coal, ResourceType.oil, ResourceType.uranium],
);
const _jungleProfile = (
  bonus: [ResourceType.banana, ResourceType.citrus, ResourceType.rice],
  luxury: [
    ResourceType.gems,
    ResourceType.spices,
    ResourceType.coffee,
    ResourceType.cocoa,
    ResourceType.sugar,
    ResourceType.ivory,
  ],
  strategic: [
    ResourceType.aluminium,
    ResourceType.coal,
    ResourceType.iron,
    ResourceType.horses,
  ],
);
const _forestProfile = (
  bonus: [ResourceType.deer, ResourceType.apple, ResourceType.sheep],
  luxury: [
    ResourceType.silk,
    ResourceType.cotton,
    ResourceType.grapes,
    ResourceType.coffee,
    ResourceType.cocoa,
    ResourceType.tobacco,
  ],
  strategic: [
    ResourceType.coal,
    ResourceType.iron,
    ResourceType.horses,
    ResourceType.marble,
  ],
);
const _wetlandsProfile = (
  bonus: [ResourceType.rice, ResourceType.fish],
  luxury: [ResourceType.silk, ResourceType.spices, ResourceType.sugar],
  strategic: [ResourceType.oil, ResourceType.coal, ResourceType.uranium],
);
const _hillsProfile = (
  bonus: [ResourceType.deer, ResourceType.sheep, ResourceType.apple],
  luxury: [
    ResourceType.gold,
    ResourceType.silver,
    ResourceType.gems,
    ResourceType.ivory,
  ],
  strategic: [
    ResourceType.iron,
    ResourceType.coal,
    ResourceType.aluminium,
    ResourceType.uranium,
    ResourceType.marble,
  ],
);
const _openLandProfile = (
  bonus: [
    ResourceType.wheat,
    ResourceType.sheep,
    ResourceType.cow,
    ResourceType.apple,
    ResourceType.citrus,
  ],
  luxury: [
    ResourceType.silk,
    ResourceType.cotton,
    ResourceType.grapes,
    ResourceType.tobacco,
    ResourceType.sugar,
    ResourceType.gold,
  ],
  strategic: [
    ResourceType.horses,
    ResourceType.iron,
    ResourceType.coal,
    ResourceType.aluminium,
    ResourceType.uranium,
    ResourceType.marble,
  ],
);

final class _ResourceDistributionRng {
  static const int _mask32 = 0xFFFFFFFF;
  static const int _multiplier = 1664525;
  static const int _increment = 1013904223;

  _ResourceDistributionRng(int seed) : _state = seed & _mask32;

  int _state;

  int nextInt(int maxExclusive) {
    if (maxExclusive <= 0) {
      throw ArgumentError.value(maxExclusive, 'maxExclusive', 'Must be > 0.');
    }
    _state = (_state * _multiplier + _increment) & _mask32;
    return _state % maxExclusive;
  }
}
