import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_item.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_value_formatters.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_view_model.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_type_icon.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

abstract final class UnitSelectionViewModelFactory {
  static SelectionViewModel from(
    GameSelection selection, {
    GameState? gameState,
    MapData? mapData,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    required AppLocalizations l10n,
    String Function(GameUnit unit)? unitName,
    required String Function(FieldImprovementType type) improvementName,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final unit = selection.unit;
    if (unit == null) return const SelectionViewModel.empty();

    final tile = selection.tile;
    final maxMovementPoints = UnitMovementBalance.maxMovementPointsForType(
      unit.type,
    );
    final combatStats = UnitCombatStats.derive(unit);
    final currentHp = UnitCombatHealth.currentHp(
      unit,
      effectiveStats: combatStats,
    );
    final subtitle = _subtitleFor(
      unit: unit,
      maxMovementPoints: maxMovementPoints,
      currentHp: currentHp,
      maxHp: combatStats.hp,
      l10n: l10n,
    );
    final workerAction = _workerActionFor(
      unit,
      gameState: gameState,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      l10n: l10n,
      paceBalance: paceBalance,
    );
    return SelectionViewModel(
      icon: gameIconForUnitType(unit.type),
      color: const Color(0xFFd48f74),
      title: GameText.uppercase(
        unitName?.call(unit) ?? GameDisplayNames.unit(l10n, unit),
      ),
      subtitle: subtitle,
      description: GameDisplayNames.unitDescription(l10n, unit.type),
      descriptionItems: _descriptionItemsFor(combatStats, l10n: l10n),
      assetIcon: SelectionAssetIconViewModel.unit(unit.type),
      selectionKey: 'unit:${unit.id}',
      supportsArmyDetail: unit.type == GameUnitType.commander,
      armyTroops: unit.army,
      workerAction: workerAction,
      items: [
        SelectionInfoItem(
          icon: GameIcons.attack,
          label: l10n.unitSelectionAttackLabel,
          value: '${combatStats.attack}',
          color: GameUiTheme.danger,
        ),
        SelectionInfoItem(
          icon: GameIcons.defense,
          label: l10n.unitSelectionDefenseLabel,
          value: '${combatStats.defense}',
          color: GameUiTheme.info,
        ),
        SelectionInfoItem(
          icon: GameIcons.stats,
          label: l10n.unitSelectionHpLabel,
          value: '$currentHp/${combatStats.hp}',
          color: GameUiTheme.success,
        ),
        SelectionInfoItem(
          icon: GameIcons.visibility,
          label: l10n.unitSelectionRangeLabel,
          value: '${combatStats.range}',
          color: GameUiTheme.gold,
        ),
        if (unit.workerJob != null)
          SelectionInfoItem(
            icon: GameIcons.production,
            label: l10n.unitSelectionConstructionLabel,
            value: _workerJobValue(
              unit,
              l10n: l10n,
              improvementName: improvementName,
            ),
            color: const Color(0xFFc98b53),
          ),
        if (unit.workerAssignment != null)
          SelectionInfoItem(
            icon: GameIcons.improvement,
            label: l10n.unitSelectionWorkLabel,
            value: l10n.unitSelectionFieldBonusValue,
            color: GameUiTheme.success,
          ),
        if (tile != null)
          SelectionInfoItem(
            icon: GameIcons.terrain,
            label: l10n.commonTerrain,
            value: enumLabelList(tile.terrains, empty: l10n.commonNoneLower),
            color: const Color(0xFF89b66f),
            showLabel: false,
            semanticId: SelectionInfoItemSemanticId.terrain,
          ),
      ],
    );
  }

  static WorkerActionPanelViewModel? _workerActionFor(
    GameUnit unit, {
    required GameState? gameState,
    required MapData? mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required AppLocalizations l10n,
    required PaceBalance paceBalance,
  }) {
    if (unit.type != GameUnitType.worker ||
        gameState == null ||
        mapData == null) {
      return null;
    }

    final currentUnit = gameState.selectedUnit?.id == unit.id
        ? gameState.selectedUnit!
        : unit;
    return WorkerActionPanelViewModelFactory.from(
      unit: currentUnit,
      cities: gameState.cities,
      fieldImprovements: gameState.fieldImprovements,
      mapData: mapData,
      research: gameState.research,
      pendingAction: gameState.pendingAction,
      l10n: l10n,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
  }

  static String _subtitleFor({
    required GameUnit unit,
    required int maxMovementPoints,
    required int currentHp,
    required int maxHp,
    required AppLocalizations l10n,
  }) {
    if (_isCombatUnit(unit)) {
      return l10n.unitSelectionMovementHpSubtitle(
        unit.movementPoints,
        maxMovementPoints,
        currentHp,
        maxHp,
      );
    }

    return l10n.unitSelectionMovementSubtitle(
      unit.movementPoints,
      maxMovementPoints,
    );
  }

  static bool _isCombatUnit(GameUnit unit) {
    return UnitCombatStats.derive(unit).attack > 0;
  }

  static List<SelectionInfoItem> _descriptionItemsFor(
    CombatStats combatStats, {
    required AppLocalizations l10n,
  }) {
    if (combatStats.attack <= 0) return const [];
    return [
      SelectionInfoItem(
        icon: GameIcons.attack,
        label: l10n.unitSelectionAttackLabel,
        value: '${combatStats.attack}',
        color: GameUiTheme.danger,
      ),
      SelectionInfoItem(
        icon: GameIcons.defense,
        label: l10n.unitSelectionDefenseLabel,
        value: '${combatStats.defense}',
        color: GameUiTheme.info,
      ),
    ];
  }

  static String _workerJobValue(
    GameUnit unit, {
    required AppLocalizations l10n,
    required String Function(FieldImprovementType type) improvementName,
  }) {
    final job = unit.workerJob!;
    final name = improvementName(job.improvementType);
    return l10n.unitSelectionWorkerJobTurns(name, job.remainingTurns);
  }
}
