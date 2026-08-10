import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/game/domain/technology/technology_boost.dart';
import 'package:aonw_core/game/domain/technology/technology_definition.dart';
import 'package:aonw_core/game/domain/technology/technology_effect.dart';
import 'package:aonw_core/game/domain/technology/technology_era.dart';
import 'package:aonw_core/game/domain/technology/technology_id.dart';
import 'package:aonw_core/game/domain/technology/technology_tree_position.dart';
import 'package:aonw_core/game/domain/technology/technology_unlock.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder/wonder_type.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

part 'technology_catalog_foundation_to_navigation.dart';
part 'technology_catalog_irrigation_to_bureaucracy.dart';
part 'technology_catalog_nationalism_to_nuclear_physics.dart';

abstract final class TechnologyCatalog {
  static const standard = <TechnologyId, TechnologyDefinition>{
    ..._foundationToNavigationTechnologies,
    ..._irrigationToBureaucracyTechnologies,
    ..._nationalismToNuclearPhysicsTechnologies,
  };
}
