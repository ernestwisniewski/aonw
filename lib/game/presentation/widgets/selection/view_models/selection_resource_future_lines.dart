import 'package:aonw/game/presentation/formatters/game_value_formatters.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_resource_category.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class SelectionResourceFutureLines {
  static List<String> build({
    required ResourceType resource,
    required SelectionResourceCategory category,
    required FieldImprovementType? improvementType,
    required TechnologyDefinition? requiredTechnology,
    required bool technologyUnlocked,
    required TechnologyRuleset technologyRuleset,
    required String Function(FieldImprovementType type) improvementName,
    required String Function(TechnologyId id) technologyName,
    required AppLocalizations l10n,
  }) {
    final lines = <String>[
      ..._unlockLines(
        improvementType: improvementType,
        requiredTechnology: requiredTechnology,
        technologyUnlocked: technologyUnlocked,
        improvementName: improvementName,
        technologyName: technologyName,
        l10n: l10n,
      ),
      for (final technology in technologyRuleset.technologies.values)
        ..._technologyLines(
          technology: technology,
          resource: resource,
          technologyName: technologyName(technology.id),
          l10n: l10n,
        ),
    ];
    if (lines.isEmpty) lines.add(_defaultLine(l10n, category));
    return _distinctPrefix(lines, limit: 3);
  }

  static Iterable<String> _unlockLines({
    required FieldImprovementType? improvementType,
    required TechnologyDefinition? requiredTechnology,
    required bool technologyUnlocked,
    required String Function(FieldImprovementType type) improvementName,
    required String Function(TechnologyId id) technologyName,
    required AppLocalizations l10n,
  }) sync* {
    if (improvementType == null || requiredTechnology == null) return;
    final techName = technologyName(requiredTechnology.id);
    final improvementLabel = improvementName(improvementType);
    yield technologyUnlocked
        ? l10n.resourceValueUnlockedByTechnology(techName, improvementLabel)
        : l10n.resourceValueUnlocksFullYieldAfterTechnology(
            techName,
            improvementLabel,
          );
  }

  static Iterable<String> _technologyLines({
    required TechnologyDefinition technology,
    required ResourceType resource,
    required String technologyName,
    required AppLocalizations l10n,
  }) sync* {
    for (final boost in technology.boosts) {
      if (!_boostMentionsResource(boost.condition, resource)) continue;
      yield l10n.resourceValueResearchBoostLine(
        technologyName,
        percent(boost.discount),
      );
    }
    for (final effect in technology.effects) {
      final line = _effectLine(
        effect: effect,
        resource: resource,
        technologyName: technologyName,
        l10n: l10n,
      );
      if (line != null) yield line;
    }
  }

  static bool _boostMentionsResource(
    TechnologyBoostCondition condition,
    ResourceType resource,
  ) {
    return switch (condition) {
      ControlsResource(:final resourceType) => resourceType == resource,
      ControlsAnyResource(:final resourceTypes) => resourceTypes.contains(
        resource,
      ),
      HasImprovementCount() || HasAnyImprovement() => false,
    };
  }

  static String? _effectLine({
    required TechnologyEffect effect,
    required ResourceType resource,
    required String technologyName,
    required AppLocalizations l10n,
  }) {
    return switch (effect) {
      StrategicResourceProductionBonus(:final resourceType, :final production)
          when resourceType == resource =>
        l10n.resourceValueTechnologyControlledResourceBonus(
          technologyName,
          production,
        ),
      _ => null,
    };
  }

  static List<String> _distinctPrefix(
    List<String> lines, {
    required int limit,
  }) {
    final result = <String>[];
    for (final line in lines) {
      if (result.contains(line)) continue;
      result.add(line);
      if (result.length >= limit) break;
    }
    return result;
  }

  static String _defaultLine(
    AppLocalizations l10n,
    SelectionResourceCategory category,
  ) {
    return switch (category) {
      SelectionResourceCategory.bonus => l10n.resourceValueCategoryBonusFuture,
      SelectionResourceCategory.luxury =>
        l10n.resourceValueCategoryLuxuryFuture,
      SelectionResourceCategory.strategic =>
        l10n.resourceValueCategoryStrategicFuture,
    };
  }
}
