import 'package:aonw_core/game/domain/city/city_building.dart';
import 'package:aonw_core/game/domain/city/city_building_definition.dart';
import 'package:aonw_core/game/domain/city/city_building_effect.dart';
import 'package:aonw_core/game/domain/city/city_building_requirement.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

part 'city_building_catalog_archive_to_conscription.dart';
part 'city_building_catalog_border_fort_to_world_fair.dart';
part 'city_building_catalog_granary_to_monument.dart';

abstract final class CityBuildingCatalog {
  static const standard = <CityBuildingType, CityBuildingDefinition>{
    ..._granaryToMonumentBuildings,
    ..._archiveToConscriptionBuildings,
    ..._borderFortToWorldFairBuildings,
  };
}
