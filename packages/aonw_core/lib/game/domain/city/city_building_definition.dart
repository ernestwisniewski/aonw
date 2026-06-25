import 'package:aonw_core/game/domain/city/city_building.dart';
import 'package:aonw_core/game/domain/city/city_building_effect.dart';
import 'package:aonw_core/game/domain/city/city_building_requirement.dart';

class CityBuildingDefinition {
  final CityBuildingType type;
  final int productionCost;
  final List<CityBuildingEffect> effects;
  final List<CityBuildingRequirement> requirements;

  const CityBuildingDefinition({
    required this.type,
    required this.productionCost,
    this.effects = const [],
    this.requirements = const [],
  });
}
