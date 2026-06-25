import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/hex_assessment.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/hex_assessment_presenter.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_improvement_item.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_item.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_resource_value_card_factory.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_value_formatters.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_yield_item.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';

abstract final class TileSelectionViewModelFactory {
  static SelectionViewModel from(
    SelectedTile? tile, {
    GameState? gameState,
    MapData? mapData,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    required AppLocalizations l10n,
    required String Function(FieldImprovementType type) improvementName,
    required String Function(TechnologyId id) technologyName,
    required String Function(ResourceType type) resourceName,
    required String Function(GameCity city) cityName,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    if (tile == null) return const SelectionViewModel.empty();

    final tileData = selectedTileData(tile);
    final assessment = HexAssessmentRules.assess(tileData);
    final profile = HexProfileViewModel.fromAssessment(assessment, l10n);
    final improvements = _improvementsFor(
      tile: tileData,
      gameState: gameState,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      l10n: l10n,
      improvementName: improvementName,
      technologyName: technologyName,
      cityName: cityName,
      paceBalance: paceBalance,
    );
    final resourceValueCards = SelectionResourceValueCardFactory.fromTile(
      tile: tileData,
      assessment: assessment,
      gameState: gameState,
      l10n: l10n,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      improvementName: improvementName,
      technologyName: technologyName,
      resourceName: resourceName,
      cityName: cityName,
    );

    return SelectionViewModel(
      icon: profile.icon,
      color: profile.color,
      title: profile.title,
      subtitle: profile.subtitle,
      description: profile.description,
      yields: SelectionYieldItem.fromYield(
        assessment.yield,
        foodLabel: l10n.yieldFoodShort,
        productionLabel: l10n.yieldProductionShort,
        goldLabel: l10n.yieldGoldShort,
        defenseLabel: l10n.yieldDefenseShort,
      ),
      yieldTitle: l10n.tileSelectionYieldTitle,
      yieldTooltip: l10n.tileSelectionYieldTooltip,
      tags: profile.tags,
      improvements: improvements,
      resourceValueCards: resourceValueCards,
      selectionKey: 'tile:${tileData.col}:${tileData.row}',
      preferImprovementsTab: improvements.isNotEmpty,
      items: [
        SelectionInfoItem(
          icon: GameIcons.terrain,
          label: l10n.commonTerrain,
          value: enumLabelList(tile.terrains, empty: l10n.commonNoneLower),
          color: const Color(0xFF89b66f),
          semanticId: SelectionInfoItemSemanticId.terrain,
        ),
        if (tile.resources.isNotEmpty)
          SelectionInfoItem(
            icon: GameIcons.resources,
            label: l10n.commonResources,
            value: _resourceLabelList(
              tile.resources,
              resourceName,
              noneLabel: l10n.commonNoneLower,
            ),
            color: const Color(0xFFd1b35d),
            semanticId: SelectionInfoItemSemanticId.resources,
          ),
        ...profile.detailItems,
        SelectionInfoItem(
          icon: GameIcons.layers,
          label: l10n.gameOptionHeight,
          value: '${tile.height}',
          color: GameUiTheme.accent,
          semanticId: SelectionInfoItemSemanticId.height,
        ),
      ],
    );
  }

  static String _resourceLabelList(
    Iterable<ResourceType> values,
    String Function(ResourceType type) resourceName, {
    required String noneLabel,
  }) {
    if (values.isEmpty) return noneLabel;
    return values.map(resourceName).join(' + ');
  }

  static List<SelectionImprovementItem> _improvementsFor({
    required TileData tile,
    required GameState? gameState,
    required MapData? mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required AppLocalizations l10n,
    required String Function(FieldImprovementType type) improvementName,
    required String Function(TechnologyId id) technologyName,
    required String Function(GameCity city) cityName,
    required PaceBalance paceBalance,
  }) {
    final items = <SelectionImprovementItem>[];
    for (final type in FieldImprovementType.values) {
      final terrainRequirement = FieldImprovementRules.requirementFailureFor(
        type,
        tile,
        ruleset: cityRuleset,
      );
      if (terrainRequirement != null) continue;

      final requiredTechnology =
          TechnologyUnlockQuery.unlockingTechnologyForFieldImprovement(
            improvementType: type,
            ruleset: technologyRuleset,
          );
      final technologyUnlocked =
          requiredTechnology == null ||
          gameState?.research
                  .forPlayer(gameState.activePlayerId)
                  .hasUnlocked(requiredTechnology.id) ==
              true;
      final technologyRequirement = requiredTechnology == null
          ? ''
          : _technologyRequirement(
              l10n: l10n,
              technologyName: technologyName(requiredTechnology.id),
            );
      final cityStatus = _cityStatusFor(
        tile: tile,
        gameState: gameState,
        l10n: l10n,
        cityName: cityName,
      );
      final state = _stateFor(
        technologyUnlocked: technologyUnlocked,
        cityStatus: cityStatus,
      );

      items.add(
        SelectionImprovementItem(
          type: type,
          title: improvementName(type),
          yield: FieldImprovementRules.yieldFor(type, ruleset: cityRuleset),
          buildTurns: FieldImprovementRules.buildTurnsFor(
            type,
            ruleset: cityRuleset,
            paceBalance: paceBalance,
          ),
          state: state,
          technologyRequirement: technologyRequirement,
          buildingRequirement: cityStatus.buildingRequirement,
          cityRequirement: cityStatus.cityRequirement,
        ),
      );
    }

    items.sort((a, b) {
      final state = a.state.index.compareTo(b.state.index);
      if (state != 0) return state;
      return a.type.index.compareTo(b.type.index);
    });
    return items;
  }

  static String _technologyRequirement({
    required AppLocalizations l10n,
    required String technologyName,
  }) {
    return l10n.resourceValueRequiresTechnology(technologyName);
  }

  static _TileCityStatus _cityStatusFor({
    required TileData tile,
    required GameState? gameState,
    required AppLocalizations l10n,
    required String Function(GameCity city) cityName,
  }) {
    if (gameState == null) {
      return _TileCityStatus(
        cityRequirement: l10n.resourceValueSelectWorkerOrCity,
        buildingRequirement: '',
        hasCityAccess: false,
      );
    }

    final hex = CityHex(col: tile.col, row: tile.row);
    if (gameState.fieldImprovements.any(
      (improvement) => improvement.hex == hex,
    )) {
      return _TileCityStatus(
        cityRequirement: l10n.resourceValueTileAlreadyImproved,
        buildingRequirement: '',
        hasCityAccess: false,
      );
    }
    if (gameState.cities.any((city) => city.center == hex)) {
      return _TileCityStatus(
        cityRequirement: l10n.resourceValueCityCenter,
        buildingRequirement: '',
        hasCityAccess: false,
      );
    }

    final activePlayerId = gameState.activePlayerId;
    final city = WorkerImprovementRules.cityForImprovementHex(
      playerId: activePlayerId,
      hex: hex,
      cities: gameState.cities,
    );
    if (city != null) {
      final name = cityName(city);
      return _TileCityStatus(
        cityRequirement: l10n.resourceValueWorksForCity(name),
        buildingRequirement: '',
        hasCityAccess: true,
      );
    }

    return _TileCityStatus(
      cityRequirement: l10n.resourceValueOutsideCityBorders,
      buildingRequirement: '',
      hasCityAccess: false,
    );
  }

  static SelectionImprovementState _stateFor({
    required bool technologyUnlocked,
    required _TileCityStatus cityStatus,
  }) {
    if (!cityStatus.hasCityAccess) {
      return cityStatus.buildingRequirement.isEmpty
          ? SelectionImprovementState.needsCity
          : SelectionImprovementState.blocked;
    }
    if (!technologyUnlocked) return SelectionImprovementState.needsTechnology;
    return SelectionImprovementState.available;
  }
}

class _TileCityStatus {
  final String cityRequirement;
  final String buildingRequirement;
  final bool hasCityAccess;

  const _TileCityStatus({
    required this.cityRequirement,
    required this.buildingRequirement,
    required this.hasCityAccess,
  });
}
