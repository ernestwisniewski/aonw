import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

final class StrategicResourceExtractionRule {
  const StrategicResourceExtractionRule({
    required this.resource,
    required this.improvement,
    required this.amountPerTurn,
  });

  final ResourceType resource;
  final FieldImprovementType improvement;
  final int amountPerTurn;
}

final class ResourceEconomyRuleset {
  const ResourceEconomyRuleset({required this.extractionRules});

  final Map<ResourceType, StrategicResourceExtractionRule> extractionRules;

  static const standard = ResourceEconomyRuleset(
    extractionRules: {
      ResourceType.oil: StrategicResourceExtractionRule(
        resource: ResourceType.oil,
        improvement: FieldImprovementType.oilWell,
        amountPerTurn: 1,
      ),
      ResourceType.aluminium: StrategicResourceExtractionRule(
        resource: ResourceType.aluminium,
        improvement: FieldImprovementType.bauxiteMine,
        amountPerTurn: 1,
      ),
    },
  );

  StrategicResourceExtractionRule? extractionFor(ResourceType resource) =>
      extractionRules[resource];
}
