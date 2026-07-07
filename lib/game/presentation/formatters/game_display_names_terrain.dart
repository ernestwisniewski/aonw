import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/terrain_type.dart';

String terrainDisplayName(AppLocalizations l10n, TerrainType terrain) {
  return switch (terrain) {
    TerrainType.ocean => l10n.terrainOcean,
    TerrainType.coast => l10n.terrainCoast,
    TerrainType.lake => l10n.terrainLake,
    TerrainType.plains => l10n.terrainPlains,
    TerrainType.grassland => l10n.terrainGrassland,
    TerrainType.desert => l10n.terrainDesert,
    TerrainType.tundra => l10n.terrainTundra,
    TerrainType.snow => l10n.terrainSnow,
    TerrainType.mountain => l10n.terrainMountain,
    TerrainType.hills => l10n.terrainHills,
    TerrainType.wetlands => l10n.terrainWetlands,
    TerrainType.jungle => l10n.terrainJungle,
    TerrainType.forest => l10n.terrainForest,
    TerrainType.river => l10n.terrainRiver,
  };
}
