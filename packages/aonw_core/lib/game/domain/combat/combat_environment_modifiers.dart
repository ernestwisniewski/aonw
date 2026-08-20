part of 'combat_modifier_collector.dart';

List<CombatModifier> _terrainModifiers({
  required MapTileView tile,
  required CombatRuleset ruleset,
}) {
  final modifiers = <CombatModifier>[];
  for (final terrain in tile.terrainTags) {
    modifiers.addAll(
      _modifiersFromStats(
        stats: ruleset.terrainStatsFor(terrain),
        labelPrefix: 'terrain.${terrain.name}',
        create: ({required label, required target, required delta}) =>
            TerrainModifier(label: label, target: target, delta: delta),
      ),
    );
  }
  return modifiers;
}

bool _hasDefensiveTerrain(MapTileView tile) {
  return tile.terrainTags.any(_defensiveTerrain.contains);
}

bool _hasRoughTerrain(MapTileView tile) {
  return tile.terrainTags.any(_roughTerrain.contains);
}

bool _hasOpenTerrain(MapTileView tile) {
  return tile.terrainTags.any(_openTerrain.contains) && !_hasRoughTerrain(tile);
}

List<CombatModifier> _fortificationModifiers({
  required GameCity? defendedCity,
  required CombatRuleset ruleset,
}) {
  if (defendedCity == null || ruleset.defendedCityDefenseBonus == 0) {
    return const [];
  }
  return [
    FortificationModifier(
      label: 'city.${defendedCity.id}.garrison',
      target: CombatStatTarget.defense,
      delta: ruleset.defendedCityDefenseBonus,
    ),
  ];
}

const _defensiveTerrain = {
  TerrainType.forest,
  TerrainType.jungle,
  TerrainType.hills,
  TerrainType.wetlands,
  TerrainType.mountain,
};

const _roughTerrain = {
  TerrainType.forest,
  TerrainType.jungle,
  TerrainType.hills,
  TerrainType.wetlands,
  TerrainType.mountain,
};

const _openTerrain = {
  TerrainType.plains,
  TerrainType.grassland,
  TerrainType.desert,
  TerrainType.tundra,
  TerrainType.snow,
};
