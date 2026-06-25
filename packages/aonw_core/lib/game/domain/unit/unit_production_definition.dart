import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_production_requirement.dart';

class UnitProductionDefinition {
  final GameUnitType type;
  final int productionCost;
  final List<UnitProductionRequirement> requirements;

  const UnitProductionDefinition({
    required this.type,
    required this.productionCost,
    this.requirements = const [],
  });
}
