import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_resource_category.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_resource_future_lines.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_resource_improvement_assessment.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_resource_value_card.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_yield_item.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

class SelectionResourceValueCardBuilder {
  const SelectionResourceValueCardBuilder({
    required this.gameState,
    required this.l10n,
    required this.cityRuleset,
    required this.technologyRuleset,
    required this.improvementName,
    required this.technologyName,
    required this.resourceName,
    required this.cityName,
  });

  final GameClientState? gameState;
  final AppLocalizations l10n;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final String Function(FieldImprovementType type) improvementName;
  final String Function(TechnologyId id) technologyName;
  final String Function(ResourceType type) resourceName;
  final String Function(GameCity city) cityName;

  SelectionResourceValueCard build({
    required ResourceType resource,
    required MapTileView tile,
    required TileYield tileYield,
  }) {
    final category = SelectionResourceCategoryResolver.forResource(resource);
    final improvement = SelectionResourceImprovementAssessment.from(
      resource: resource,
      tile: tile,
      gameState: gameState,
      l10n: l10n,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      improvementName: improvementName,
      technologyName: technologyName,
      cityName: cityName,
    );
    return SelectionResourceValueCard(
      title: resourceName(resource),
      categoryLabel: _categoryLabel(category),
      currentSummary: _currentSummary(
        resourceYield: ResourceYieldRules.yieldFor(
          resource,
          ruleset: cityRuleset,
        ),
        tileYield: tileYield,
      ),
      currentYield: _nonZeroYieldItems(tileYield),
      improvementTitle: improvement.improvementTitle,
      improvementStatus: improvement.statusLabel,
      improvementStatusKind: improvement.statusKind,
      requiredTechnologyName: improvement.requiredTechnologyName,
      improvementYield: _nonZeroYieldItems(improvement.improvementYield),
      futureLines: _futureLines(resource, category, improvement),
      expansionReason: _expansionReason(
        resource: resource,
        category: category,
        tileYield: tileYield,
        improvementYield: improvement.improvementYield,
      ),
      accentColor: category.color,
      strategicFlow: _strategicFlow(
        resource: resource,
        tile: tile,
        improvement: improvement,
      ),
    );
  }

  SelectionStrategicResourceFlow? _strategicFlow({
    required ResourceType resource,
    required MapTileView tile,
    required SelectionResourceImprovementAssessment improvement,
  }) {
    final extraction = ResourceEconomyRuleset.standard.extractionFor(resource);
    if (extraction == null) return null;

    final hex = CityHex(col: tile.col, row: tile.row);
    final controlled =
        gameState?.cities.any(
          (city) =>
              city.ownerPlayerId == gameState!.activePlayerId &&
              city.controlsTile(hex.col, hex.row),
        ) ??
        false;
    final builtImprovement = _fieldImprovementAt(hex);
    final active =
        controlled &&
        improvement.technologyUnlocked &&
        builtImprovement?.type == extraction.improvement;
    final resourceLabel = resourceName(resource);
    final description = active
        ? l10n.resourceDetailStrategicFlowActive(
            extraction.amountPerTurn,
            resourceLabel,
          )
        : !controlled
        ? l10n.resourceDetailStrategicFlowClaim(
            extraction.amountPerTurn,
            resourceLabel,
          )
        : l10n.resourceDetailStrategicFlowImprove(
            improvementName(extraction.improvement),
            extraction.amountPerTurn,
            resourceLabel,
          );
    return SelectionStrategicResourceFlow(
      amountPerTurn: extraction.amountPerTurn,
      active: active,
      description: description,
    );
  }

  FieldImprovement? _fieldImprovementAt(CityHex hex) {
    final improvements = gameState?.fieldImprovements;
    if (improvements == null) return null;
    for (final improvement in improvements) {
      if (improvement.hex == hex) return improvement;
    }
    return null;
  }

  List<String> _futureLines(
    ResourceType resource,
    SelectionResourceCategory category,
    SelectionResourceImprovementAssessment improvement,
  ) {
    return SelectionResourceFutureLines.build(
      resource: resource,
      category: category,
      improvementType: improvement.improvementType,
      requiredTechnology: improvement.requiredTechnology,
      technologyUnlocked: improvement.technologyUnlocked,
      technologyRuleset: technologyRuleset,
      improvementName: improvementName,
      technologyName: technologyName,
      l10n: l10n,
    );
  }

  String _currentSummary({
    required TileYield resourceYield,
    required TileYield tileYield,
  }) {
    if (resourceYield == TileYield.zero) {
      return l10n.resourceValueNoBaseYieldSummary(_yieldText(tileYield));
    }
    return l10n.resourceValueBaseYieldSummary(
      _yieldText(resourceYield),
      _yieldText(tileYield),
    );
  }

  String _expansionReason({
    required ResourceType resource,
    required SelectionResourceCategory category,
    required TileYield tileYield,
    required TileYield improvementYield,
  }) {
    final combined = tileYield + improvementYield;
    if (category == SelectionResourceCategory.strategic) {
      return l10n.resourceValueExpansionStrategic;
    }
    if (combined.food >= combined.production &&
        combined.food >= combined.gold) {
      return l10n.resourceValueExpansionFood;
    }
    if (combined.production >= combined.gold) {
      return l10n.resourceValueExpansionProduction;
    }
    if (resource == ResourceType.pearls || resource == ResourceType.ivory) {
      return l10n.resourceValueExpansionTrade;
    }
    return l10n.resourceValueExpansionEconomy;
  }

  String _yieldText(TileYield yield) {
    final parts = <String>[
      if (yield.food != 0) l10n.resourceValueYieldFood(yield.food),
      if (yield.production != 0)
        l10n.resourceValueYieldProduction(yield.production),
      if (yield.gold != 0) l10n.resourceValueYieldGold(yield.gold),
      if (yield.defense != 0) l10n.resourceValueYieldDefense(yield.defense),
    ];
    return parts.isEmpty ? l10n.resourceValueZeroBaseYield : parts.join(', ');
  }

  String _categoryLabel(SelectionResourceCategory category) {
    return switch (category) {
      SelectionResourceCategory.bonus => l10n.resourceValueCategoryBonus,
      SelectionResourceCategory.luxury => l10n.resourceValueCategoryLuxury,
      SelectionResourceCategory.strategic =>
        l10n.resourceValueCategoryStrategic,
    };
  }

  List<SelectionYieldItem> _nonZeroYieldItems(TileYield yield) {
    return SelectionYieldItem.fromYield(
      yield,
      foodLabel: l10n.yieldFoodShort,
      productionLabel: l10n.yieldProductionShort,
      goldLabel: l10n.yieldGoldShort,
      defenseLabel: l10n.yieldDefenseShort,
    ).where((item) => item.value != 0).toList(growable: false);
  }
}
