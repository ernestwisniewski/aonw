import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_specialization.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/resource_visibility_rules.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class CitySpecializationScorer {
  static Map<CitySpecializationType, double> localScores({
    required GameCity city,
    required MapData mapData,
    required ResearchState research,
  }) {
    final scores = <CitySpecializationType, double>{};
    for (final hex in _uniqueHexes(city.territoryHexes)) {
      final tile = mapData.tileAt(hex.col, hex.row);
      if (tile == null) continue;
      _scoreTerrains(scores, tile.terrains);
      _scoreResources(
        scores,
        resources: tile.resources,
        city: city,
        research: research,
      );
    }
    return scores;
  }

  static CitySpecializationType? bestLocalFit({
    required GameCity city,
    required MapData mapData,
    required ResearchState research,
  }) {
    final scores = localScores(
      city: city,
      mapData: mapData,
      research: research,
    );
    if (scores.isEmpty) return null;
    return _bestSpecialization(scores);
  }

  static Iterable<CityHex> _uniqueHexes(Iterable<CityHex> hexes) sync* {
    final visited = <String>{};
    for (final hex in hexes) {
      if (visited.add('${hex.col},${hex.row}')) yield hex;
    }
  }

  static void _scoreTerrains(
    Map<CitySpecializationType, double> scores,
    List<TerrainType> terrains,
  ) {
    for (final terrain in terrains) {
      switch (terrain) {
        case TerrainType.coast:
        case TerrainType.lake:
        case TerrainType.ocean:
          _add(scores, CitySpecializationType.commerce, 0.9);
        case TerrainType.river:
          _add(scores, CitySpecializationType.growth, 0.35);
          _add(scores, CitySpecializationType.commerce, 0.2);
        case TerrainType.grassland:
        case TerrainType.wetlands:
          _add(scores, CitySpecializationType.growth, 0.25);
        case TerrainType.hills:
          _add(scores, CitySpecializationType.industry, 0.45);
          _add(scores, CitySpecializationType.military, 0.15);
        case TerrainType.mountain:
          _add(scores, CitySpecializationType.industry, 0.3);
          _add(scores, CitySpecializationType.science, 0.25);
        case TerrainType.forest:
          _add(scores, CitySpecializationType.industry, 0.2);
        case TerrainType.plains:
        case TerrainType.desert:
        case TerrainType.tundra:
        case TerrainType.snow:
        case TerrainType.jungle:
          break;
      }
    }
  }

  static void _scoreResources(
    Map<CitySpecializationType, double> scores, {
    required List<ResourceType> resources,
    required GameCity city,
    required ResearchState research,
  }) {
    for (final resource in resources) {
      if (!ResourceVisibilityRules.isRevealed(
        resource: resource,
        playerId: city.ownerPlayerId,
        research: research,
      )) {
        continue;
      }
      if (_foodResources.contains(resource)) {
        _add(scores, CitySpecializationType.growth, 0.8);
      } else if (_luxuryResources.contains(resource)) {
        _add(scores, CitySpecializationType.commerce, 0.65);
      } else if (_strategicResources.contains(resource)) {
        _add(scores, CitySpecializationType.military, 0.55);
        _add(scores, CitySpecializationType.industry, 0.45);
      }
    }
  }

  static CitySpecializationType _bestSpecialization(
    Map<CitySpecializationType, double> scores,
  ) {
    const preferenceOrder = [
      CitySpecializationType.industry,
      CitySpecializationType.military,
      CitySpecializationType.growth,
      CitySpecializationType.commerce,
      CitySpecializationType.science,
    ];

    var best = preferenceOrder.first;
    var bestScore = scores[best] ?? 0;
    for (final type in preferenceOrder.skip(1)) {
      final score = scores[type] ?? 0;
      if (score > bestScore) {
        best = type;
        bestScore = score;
      }
    }
    return best;
  }

  static void _add(
    Map<CitySpecializationType, double> scores,
    CitySpecializationType type,
    double value,
  ) {
    scores[type] = (scores[type] ?? 0) + value;
  }
}

const _foodResources = {
  ResourceType.wheat,
  ResourceType.fish,
  ResourceType.deer,
  ResourceType.sheep,
  ResourceType.rice,
  ResourceType.cow,
  ResourceType.apple,
  ResourceType.banana,
  ResourceType.citrus,
};

const _luxuryResources = {
  ResourceType.gold,
  ResourceType.silver,
  ResourceType.gems,
  ResourceType.silk,
  ResourceType.spices,
  ResourceType.cotton,
  ResourceType.grapes,
  ResourceType.ivory,
  ResourceType.pearls,
  ResourceType.coffee,
  ResourceType.cocoa,
  ResourceType.tobacco,
  ResourceType.sugar,
};

const _strategicResources = {
  ResourceType.iron,
  ResourceType.coal,
  ResourceType.oil,
  ResourceType.aluminium,
  ResourceType.uranium,
  ResourceType.horses,
  ResourceType.marble,
};
