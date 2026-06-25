import 'package:aonw_core/game/domain/city/city_building.dart';
import 'package:aonw_core/game/domain/city/city_building_definition.dart';
import 'package:aonw_core/game/domain/city/city_progression.dart';
import 'package:aonw_core/game/domain/city/field_improvement_definition.dart';
import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_production_definition.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

class CityRuleset {
  final CityProgression progression;
  final TileYield cityCenterYield;
  final TileYield riverYield;
  final Map<TerrainType, TileYield> terrainYields;
  final Map<ResourceType, TileYield> resourceYields;
  final Map<FieldImprovementType, FieldImprovementDefinition> improvements;
  final Map<CityBuildingType, CityBuildingDefinition> buildings;
  final Map<GameUnitType, UnitProductionDefinition> units;

  const CityRuleset({
    required this.progression,
    required this.cityCenterYield,
    required this.riverYield,
    required this.terrainYields,
    required this.resourceYields,
    required this.improvements,
    required this.buildings,
    required this.units,
  });

  CityRuleset copyWith({
    CityProgression? progression,
    TileYield? cityCenterYield,
    TileYield? riverYield,
    Map<TerrainType, TileYield>? terrainYields,
    Map<ResourceType, TileYield>? resourceYields,
    Map<FieldImprovementType, FieldImprovementDefinition>? improvements,
    Map<CityBuildingType, CityBuildingDefinition>? buildings,
    Map<GameUnitType, UnitProductionDefinition>? units,
  }) {
    return CityRuleset(
      progression: progression ?? this.progression,
      cityCenterYield: cityCenterYield ?? this.cityCenterYield,
      riverYield: riverYield ?? this.riverYield,
      terrainYields: terrainYields ?? this.terrainYields,
      resourceYields: resourceYields ?? this.resourceYields,
      improvements: improvements ?? this.improvements,
      buildings: buildings ?? this.buildings,
      units: units ?? this.units,
    );
  }

  CityBuildingDefinition buildingDefinitionFor(CityBuildingType type) {
    final definition = buildings[type];
    if (definition == null) {
      throw ArgumentError('Missing city building definition for: ${type.name}');
    }
    return definition;
  }

  UnitProductionDefinition unitDefinitionFor(GameUnitType type) {
    final definition = units[type];
    if (definition == null) {
      throw ArgumentError(
        'Missing unit production definition for: ${type.name}',
      );
    }
    return definition;
  }

  TileYield terrainYieldFor(TerrainType terrain) {
    return terrainYields[terrain] ?? TileYield.zero;
  }

  TileYield resourceYieldFor(ResourceType resource) {
    return resourceYields[resource] ?? TileYield.zero;
  }

  FieldImprovementDefinition improvementDefinitionFor(
    FieldImprovementType improvement,
  ) {
    final definition = improvements[improvement];
    if (definition == null) {
      throw ArgumentError(
        'Missing city improvement definition for: ${improvement.name}',
      );
    }
    return definition;
  }

  TileYield improvementYieldFor(FieldImprovementType improvement) {
    return improvementDefinitionFor(improvement).tileYield;
  }
}
