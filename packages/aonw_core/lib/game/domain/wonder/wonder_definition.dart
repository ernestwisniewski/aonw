import 'package:aonw_core/game/domain/technology/technology_id.dart';
import 'package:aonw_core/game/domain/wonder/wonder_effect.dart';
import 'package:aonw_core/game/domain/wonder/wonder_requirement.dart';
import 'package:aonw_core/game/domain/wonder/wonder_type.dart';

class WonderDefinition {
  const WonderDefinition({
    required this.type,
    required this.productionCost,
    required this.unlockTech,
    this.requirements = const [],
    this.standingEffects = const [],
    this.completionEffects = const [],
  });

  final WonderType type;
  final int productionCost;
  final TechnologyId unlockTech;
  final List<WonderRequirement> requirements;
  final List<WonderStandingEffect> standingEffects;
  final List<WonderCompletionEffect> completionEffects;
}
