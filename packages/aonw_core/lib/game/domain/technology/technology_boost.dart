import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/util/collection_equality.dart';

class TechnologyBoostDefinition {
  final TechnologyBoostCondition condition;
  final double discount;
  final String label;

  const TechnologyBoostDefinition({
    required this.condition,
    required this.discount,
    required this.label,
  });

  @override
  bool operator ==(Object other) =>
      other is TechnologyBoostDefinition &&
      other.condition == condition &&
      other.discount == discount &&
      other.label == label;

  @override
  int get hashCode => Object.hash(condition, discount, label);
}

sealed class TechnologyBoostCondition {
  const TechnologyBoostCondition();
}

class HasImprovementCount extends TechnologyBoostCondition {
  final FieldImprovementType improvementType;
  final int count;

  const HasImprovementCount({
    required this.improvementType,
    required this.count,
  });

  @override
  bool operator ==(Object other) =>
      other is HasImprovementCount &&
      other.improvementType == improvementType &&
      other.count == count;

  @override
  int get hashCode => Object.hash(improvementType, count);
}

class HasAnyImprovement extends TechnologyBoostCondition {
  final FieldImprovementType improvementType;

  const HasAnyImprovement(this.improvementType);

  @override
  bool operator ==(Object other) =>
      other is HasAnyImprovement && other.improvementType == improvementType;

  @override
  int get hashCode => Object.hash(HasAnyImprovement, improvementType);
}

class ControlsResource extends TechnologyBoostCondition {
  final ResourceType resourceType;

  const ControlsResource(this.resourceType);

  @override
  bool operator ==(Object other) =>
      other is ControlsResource && other.resourceType == resourceType;

  @override
  int get hashCode => Object.hash(ControlsResource, resourceType);
}

class ControlsAnyResource extends TechnologyBoostCondition {
  final Set<ResourceType> resourceTypes;

  const ControlsAnyResource(this.resourceTypes);

  @override
  bool operator ==(Object other) =>
      other is ControlsAnyResource &&
      setEquals(other.resourceTypes, resourceTypes);

  @override
  int get hashCode => Object.hashAll(
    resourceTypes.toList()..sort((a, b) => a.name.compareTo(b.name)),
  );
}
