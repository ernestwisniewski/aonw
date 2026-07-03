import 'package:aonw_core/game/domain/combat/combat_stats.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_capabilities.dart';
import 'package:aonw_core/game/domain/unit/unit_production_requirement.dart';

class UnitSpec {
  final GameUnitType type;
  final int productionCost;
  final List<UnitProductionRequirement> requirements;
  final CombatStats baseStats;
  final UnitCapabilities capabilities;
  final int upkeep;

  const UnitSpec({
    required this.type,
    required this.productionCost,
    this.requirements = const [],
    required this.baseStats,
    required this.capabilities,
    required this.upkeep,
  });

  UnitSpec copyWith({
    int? productionCost,
    List<UnitProductionRequirement>? requirements,
    CombatStats? baseStats,
    UnitCapabilities? capabilities,
    int? upkeep,
  }) {
    return UnitSpec(
      type: type,
      productionCost: productionCost ?? this.productionCost,
      requirements: requirements ?? this.requirements,
      baseStats: baseStats ?? this.baseStats,
      capabilities: capabilities ?? this.capabilities,
      upkeep: upkeep ?? this.upkeep,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UnitSpec &&
        other.type == type &&
        other.productionCost == productionCost &&
        _requirementsEqual(other.requirements, requirements) &&
        other.baseStats == baseStats &&
        other.capabilities == capabilities &&
        other.upkeep == upkeep;
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      productionCost,
      Object.hashAll(requirements.map(_requirementHash)),
      baseStats,
      capabilities,
      upkeep,
    );
  }
}

bool _requirementsEqual(
  List<UnitProductionRequirement> left,
  List<UnitProductionRequirement> right,
) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (!_requirementEquals(left[i], right[i])) return false;
  }
  return true;
}

bool _requirementEquals(
  UnitProductionRequirement left,
  UnitProductionRequirement right,
) {
  return switch ((left, right)) {
    (
      UnitResourceRequirement(resources: final leftResources),
      UnitResourceRequirement(resources: final rightResources),
    ) =>
      leftResources.length == rightResources.length &&
          leftResources.containsAll(rightResources),
  };
}

int _requirementHash(UnitProductionRequirement requirement) {
  return switch (requirement) {
    UnitResourceRequirement(resources: final resources) => Object.hashAll(
      resources.toList()..sort((a, b) => a.index.compareTo(b.index)),
    ),
  };
}
