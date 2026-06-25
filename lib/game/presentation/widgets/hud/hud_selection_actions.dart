import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/turn_eta.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/widgets.dart';

part 'hud_selection_action_rules.dart';
part 'hud_selection_action_spec.dart';
part 'hud_selection_artifact_action_specs.dart';
part 'hud_selection_unit_action_groups.dart';
part 'hud_selection_unit_mode_action_specs.dart';
part 'hud_selection_unit_merchant_action_specs.dart';
part 'hud_selection_unit_action_specs.dart';

List<Widget> buildHudSelectionActionChips({
  required GameState? gameState,
  required MapData mapData,
  required String activePlayerId,
  required bool actionsLocked,
  required bool moveModeActive,
  required bool armyDetailActive,
  required WorkerActionPanelViewModel? workerAction,
  required bool cityBuildingsModeActive,
  required bool cityDescriptionActive,
  required bool cityBuildingsDetailActive,
  required AppLocalizations l10n,
  required CityRuleset cityRuleset,
  required TechnologyRuleset technologyRuleset,
  required bool canStartCityFounding,
  required bool cityFoundingActive,
  required VoidCallback onMoveSelectedUnit,
  required VoidCallback onAutoExploreSelectedUnit,
  required VoidCallback onStartAttackTargeting,
  required VoidCallback onCancelAttackTargeting,
  required VoidCallback onShowArmy,
  required VoidCallback onStartWorkerActionSelection,
  required VoidCallback onCancelWorkerActionSelection,
  required VoidCallback onCancelWorkerJob,
  required VoidCallback onStartMerchantTradeRouteSelection,
  required VoidCallback onCancelMerchantTradeRouteSelection,
  required ValueChanged<String> onAssignMerchantTradeRoute,
  required VoidCallback onStartMerchantMoveToCitySelection,
  required VoidCallback onCancelMerchantMoveToCitySelection,
  required ValueChanged<String> onMoveMerchantToCity,
  required VoidCallback onStartArtifactExcavation,
  required VoidCallback onStoreArtifactInCity,
  required VoidCallback onStartCityFounding,
  required VoidCallback onConfirmCityFounding,
  required VoidCallback onCancelCityFounding,
  required VoidCallback onSkipSelectedUnitTurn,
  required VoidCallback onFortifySelectedUnit,
  required VoidCallback onCancelSelectedUnitAction,
  required VoidCallback onToggleCityDescription,
  required VoidCallback onToggleCityBuildingDetails,
  required VoidCallback onStartCityExpansionSelection,
  required VoidCallback onCancelCityExpansionSelection,
  required VoidCallback onToggleCityBuildings,
}) {
  final selection = gameState?.selection;
  final unit = gameState?.selectedUnit ?? selection?.unit;
  final ownedUnitSelected =
      selection?.type == GameSelectionType.unit &&
      unit != null &&
      unit.ownerPlayerId == activePlayerId;

  if (ownedUnitSelected) {
    final activeModeActions = _activeUnitModeActionsFor(
      unit: unit,
      gameState: gameState,
      workerAction: workerAction,
      cityFoundingActive: cityFoundingActive,
      actionsLocked: actionsLocked,
      l10n: l10n,
      onCancelAttackTargeting: onCancelAttackTargeting,
      onCancelWorkerActionSelection: onCancelWorkerActionSelection,
      onCancelWorkerJob: onCancelWorkerJob,
      mapData: mapData,
      onCancelMerchantTradeRouteSelection: onCancelMerchantTradeRouteSelection,
      onAssignMerchantTradeRoute: onAssignMerchantTradeRoute,
      onCancelMerchantMoveToCitySelection: onCancelMerchantMoveToCitySelection,
      onMoveMerchantToCity: onMoveMerchantToCity,
      onConfirmCityFounding: onConfirmCityFounding,
      onCancelCityFounding: onCancelCityFounding,
      onCancelSelectedUnitAction: onCancelSelectedUnitAction,
    );
    if (activeModeActions != null) {
      return [for (final action in activeModeActions) action.toChip()];
    }

    return _widgetsFromActionGroups(
      _unitActionGroups(
        unit: unit,
        gameState: gameState,
        selection: selection,
        mapData: mapData,
        actionsLocked: actionsLocked,
        moveModeActive: moveModeActive,
        armyDetailActive: armyDetailActive,
        workerAction: workerAction,
        canStartCityFounding: canStartCityFounding,
        cityFoundingActive: cityFoundingActive,
        l10n: l10n,
        onMoveSelectedUnit: onMoveSelectedUnit,
        onAutoExploreSelectedUnit: onAutoExploreSelectedUnit,
        onStartAttackTargeting: onStartAttackTargeting,
        onCancelAttackTargeting: onCancelAttackTargeting,
        onShowArmy: onShowArmy,
        onStartWorkerActionSelection: onStartWorkerActionSelection,
        onCancelWorkerActionSelection: onCancelWorkerActionSelection,
        onCancelWorkerJob: onCancelWorkerJob,
        onStartMerchantTradeRouteSelection: onStartMerchantTradeRouteSelection,
        onCancelMerchantTradeRouteSelection:
            onCancelMerchantTradeRouteSelection,
        onStartMerchantMoveToCitySelection: onStartMerchantMoveToCitySelection,
        onCancelMerchantMoveToCitySelection:
            onCancelMerchantMoveToCitySelection,
        onStartArtifactExcavation: onStartArtifactExcavation,
        onStoreArtifactInCity: onStoreArtifactInCity,
        onStartCityFounding: onStartCityFounding,
        onCancelCityFounding: onCancelCityFounding,
        onSkipSelectedUnitTurn: onSkipSelectedUnitTurn,
        onFortifySelectedUnit: onFortifySelectedUnit,
        onCancelSelectedUnitAction: onCancelSelectedUnitAction,
      ),
    );
  }

  final actions = <Widget>[];
  final lockedReason = actionsLocked ? l10n.selectionActionLockedReason : null;
  final city = selection?.city;
  final ownedCitySelected =
      selection?.type == GameSelectionType.city &&
      city != null &&
      city.ownerPlayerId == activePlayerId;
  if (ownedCitySelected) {
    actions
      ..add(
        SelectionCommandChip(
          icon: GameIcons.stats,
          actionId: 'description',
          label: l10n.commonDescription,
          color: _cityActionColor,
          active: cityDescriptionActive,
          onTap: onToggleCityDescription,
        ),
      )
      ..add(
        SelectionCommandChip(
          icon: GameIcons.city,
          actionId: 'buildings',
          label: l10n.buildingsSection,
          color: _cityActionColor,
          active: cityBuildingsDetailActive,
          onTap: onToggleCityBuildingDetails,
        ),
      )
      ..add(const SelectionActionGroupBreak());

    final expansionAction = _cityExpansionActionFor(
      city: city,
      gameState: gameState,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      onStartCityExpansionSelection: onStartCityExpansionSelection,
      onCancelCityExpansionSelection: onCancelCityExpansionSelection,
    );
    if (expansionAction != null) {
      actions.add(
        SelectionCommandChip(
          icon: GameIcons.workedHexes,
          actionId: 'cityGrowth',
          label: expansionAction.active
              ? l10n.selectionActionCancelCityGrowth
              : l10n.selectionActionCityGrowth,
          color: expansionAction.active ? GameUiTheme.danger : _cityActionColor,
          active: expansionAction.active,
          dangerOutlined: expansionAction.active,
          enabled: lockedReason == null,
          disabledReason: lockedReason,
          onTap: expansionAction.onTap,
        ),
      );
    }

    actions.add(
      SelectionCommandChip(
        icon: GameIcons.production,
        actionId: 'production',
        label: l10n.selectionActionProduction,
        color: _cityActionColor,
        active: cityBuildingsModeActive,
        enabled: lockedReason == null,
        disabledReason: lockedReason,
        onTap: onToggleCityBuildings,
      ),
    );
  }

  return actions;
}

const _cityActionColor = GameUiTheme.gold;

({bool active, VoidCallback onTap})? _cityExpansionActionFor({
  required GameCity city,
  required GameState? gameState,
  required CityRuleset cityRuleset,
  required TechnologyRuleset technologyRuleset,
  required VoidCallback onStartCityExpansionSelection,
  required VoidCallback onCancelCityExpansionSelection,
}) {
  final pendingAction = gameState?.pendingAction;
  final active =
      pendingAction is PendingCityExpansionSelection &&
      pendingAction.cityId == city.id;
  if (active) {
    return (active: true, onTap: onCancelCityExpansionSelection);
  }
  final technologyEffects = TechnologyEffectSummary.forPlayer(
    playerId: city.ownerPlayerId,
    research: gameState?.research ?? ResearchState.empty,
    ruleset: technologyRuleset,
  );
  final maxHexes = CityTechnologyEffectRules.effectiveMaxHexes(
    city,
    ruleset: cityRuleset,
    effects: technologyEffects,
  );
  if (city.territoryHexCount >= maxHexes) return null;
  return (active: false, onTap: onStartCityExpansionSelection);
}
