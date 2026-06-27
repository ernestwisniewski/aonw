import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_improvement_item.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_yield_item.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';

abstract final class FieldImprovementSelectionViewModelFactory {
  static SelectionViewModel from(
    GameSelection selection, {
    GameState? gameState,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    required AppLocalizations l10n,
    required String Function(FieldImprovementType type) improvementName,
    required String Function(GameCity city) cityName,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final improvement = selection.fieldImprovement;
    if (improvement == null) return const SelectionViewModel.empty();

    final city = _cityFor(improvement, gameState);
    final title = improvementName(improvement.type);
    final cityLabel = city == null
        ? l10n.fieldImprovementOutsideActiveCity
        : cityName(city);
    final cityRequirementLabel = city == null
        ? ''
        : l10n.resourceValueWorksForCity(cityLabel);
    final improvementYield = FieldImprovementRules.yieldFor(
      improvement.type,
      ruleset: cityRuleset,
    );
    final yieldSummary = _yieldSummary(l10n, improvementYield);
    final positiveYields = SelectionYieldItem.fromYield(
      improvementYield,
      foodLabel: l10n.yieldFoodShort,
      productionLabel: l10n.yieldProductionShort,
      goldLabel: l10n.yieldGoldShort,
      defenseLabel: l10n.yieldDefenseShort,
    ).where((item) => item.value > 0).toList(growable: false);
    final eraColumn = _eraColumnForImprovement(
      city: city,
      gameState: gameState,
      technologyRuleset: technologyRuleset,
    );

    return SelectionViewModel(
      icon: GameIcons.improvement,
      color: GameUiTheme.success,
      title: title,
      subtitle: [
        cityLabel,
        if (yieldSummary.isNotEmpty) yieldSummary,
      ].join(' • '),
      assetIcon: SelectionAssetIconViewModel.fieldImprovement(
        fieldImprovementType: improvement.type,
        fieldImprovementEraColumn: eraColumn,
      ),
      yields: positiveYields,
      yieldTitle: l10n.fieldImprovementYieldTitle,
      yieldTooltip: l10n.fieldImprovementYieldTooltip,
      tags: const [],
      improvements: [
        SelectionImprovementItem(
          type: improvement.type,
          title: title,
          yield: improvementYield,
          buildTurns: FieldImprovementRules.buildTurnsFor(
            improvement.type,
            ruleset: cityRuleset,
            paceBalance: paceBalance,
          ),
          state: SelectionImprovementState.built,
          technologyRequirement: '',
          buildingRequirement: '',
          cityRequirement: cityRequirementLabel,
        ),
      ],
      selectionKey: 'improvement:${improvement.hex.col}:${improvement.hex.row}',
      preferImprovementsTab: true,
      items: const [],
    );
  }

  static GameCity? _cityFor(
    FieldImprovement improvement,
    GameState? gameState,
  ) {
    if (gameState == null) return null;
    final builtByCityId = improvement.builtByCityId;
    if (builtByCityId != null) {
      return gameState.cityById(builtByCityId);
    }
    for (final city in gameState.cities) {
      if (city.controlsHex(improvement.hex)) return city;
    }
    return null;
  }

  static int _eraColumnForImprovement({
    required GameCity? city,
    required GameState? gameState,
    required TechnologyRuleset technologyRuleset,
  }) {
    final ownerPlayerId = city?.ownerPlayerId;
    if (ownerPlayerId == null || gameState == null) return 0;

    var dominantEra = TechnologyEra.foundation;
    for (final id
        in gameState.research.forPlayer(ownerPlayerId).unlockedTechnologyIds) {
      final definition = technologyRuleset.technologies[id];
      if (definition == null || definition.era.index <= dominantEra.index) {
        continue;
      }
      dominantEra = definition.era;
    }
    return switch (dominantEra) {
      TechnologyEra.foundation || TechnologyEra.settlement => 0,
      TechnologyEra.expansion || TechnologyEra.specialization => 1,
      TechnologyEra.industry => 2,
      TechnologyEra.strategy => 3,
    };
  }

  static String _yieldSummary(AppLocalizations l10n, TileYield yield) {
    final parts = <String>[];
    if (yield.food != 0) parts.add(l10n.resourceValueYieldFood(yield.food));
    if (yield.production != 0) {
      parts.add(l10n.resourceValueYieldProduction(yield.production));
    }
    if (yield.gold != 0) parts.add(l10n.resourceValueYieldGold(yield.gold));
    if (yield.defense != 0) {
      parts.add(l10n.resourceValueYieldDefense(yield.defense));
    }
    return parts.join(' ');
  }
}
