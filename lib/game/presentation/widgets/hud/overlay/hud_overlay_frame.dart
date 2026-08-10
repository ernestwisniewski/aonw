import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/turn/turn_reducer.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_minimized_popups_provider.dart';
import 'package:aonw/game/presentation/providers/map/map_inspection_provider.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/hud/city/hud_city_founding_availability.dart';
import 'package:aonw/game/presentation/widgets/hud/city/hud_city_production_context.dart';
import 'package:aonw/game/presentation/widgets/hud/combat/hud_combat_preview.dart';
import 'package:aonw/game/presentation/widgets/hud/layout/hud_layout_metrics.dart';
import 'package:aonw/game/presentation/widgets/hud/mode_banner/hud_mode_banner.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/hud_objective_summary.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/hud_score_pressure_context.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_activity_log_entries.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_modes.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_active_technology_summary.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_economy_forecast.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_summary.dart';
import 'package:aonw/game/presentation/widgets/hud/selection/hud_selection_detail_sync.dart';
import 'package:aonw/game/presentation/widgets/hud/selection/hud_selection_info_model.dart';
import 'package:aonw/game/presentation/widgets/hud/turn/hud_player_action_state.dart';
import 'package:aonw/game/presentation/widgets/hud/turn/turn_action_hint.dart';
import 'package:aonw/game/presentation/widgets/hud/turn/turn_hint_objective_matcher.dart';
import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_step.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/player_color_theme.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

part 'hud_overlay_frame_helpers.dart';

class HudOverlayFrame {
  const HudOverlayFrame({
    required this.activePlayerCanAct,
    required this.moveModeActive,
    required this.cityFoundingDraft,
    required this.modes,
    required this.activePlayerName,
    required this.activePlayerColor,
    required this.readyToEndTurn,
    required this.playerActionState,
    required this.resourceSummary,
    required this.activeTechnologySummary,
    required this.remainingActionCount,
    required this.currentActionIndex,
    required this.turnActionOptions,
    required this.activityLogEntries,
    required this.layoutMetrics,
    required this.canStartCityFounding,
    required this.cityProductionContext,
    required this.objectiveSummary,
    required this.turnHintLabel,
    required this.nextActionObjectiveAdvice,
    required this.selectedInfoModel,
    required this.mapInspection,
    required this.inspectingMap,
    required this.selectionInfoModel,
    required this.visibleOpenSelectionDetailChipId,
    required this.selectionDetailSync,
    required this.researchAvailable,
    required this.resolvedModeBannerSpec,
    required this.modeBannerPopupId,
    required this.modeBannerSpec,
    required this.combatPreview,
    required this.largePanelOpen,
    required this.coachmarksActive,
    required this.coachmarksEnabled,
    required this.coachmarkContext,
  });

  final bool activePlayerCanAct;
  final bool moveModeActive;
  final CityFoundingDraft? cityFoundingDraft;
  final HudPanelModes modes;
  final String? activePlayerName;
  final Color? activePlayerColor;
  final bool readyToEndTurn;
  final HudPlayerActionState playerActionState;
  final HudResourceSummary resourceSummary;
  final HudActiveTechnologySummary activeTechnologySummary;
  final int remainingActionCount;
  final int currentActionIndex;
  final List<HudTurnActionOption> turnActionOptions;
  final List<GameEventNotification> activityLogEntries;
  final HudLayoutMetrics layoutMetrics;
  final bool canStartCityFounding;
  final HudCityProductionContext cityProductionContext;
  final HudObjectiveSummary objectiveSummary;
  final String? turnHintLabel;
  final GameObjectiveAdvice? nextActionObjectiveAdvice;
  final SelectionViewModel? selectedInfoModel;
  final MapInspectionState mapInspection;
  final bool inspectingMap;
  final SelectionViewModel? selectionInfoModel;
  final String? visibleOpenSelectionDetailChipId;
  final HudSelectionDetailSync selectionDetailSync;
  final bool researchAvailable;
  final HudModeBannerSpec? resolvedModeBannerSpec;
  final String? modeBannerPopupId;
  final HudModeBannerSpec? modeBannerSpec;
  final HudCombatPreview? combatPreview;
  final bool largePanelOpen;
  final bool coachmarksActive;
  final bool coachmarksEnabled;
  final FirstTurnCoachmarkContext coachmarkContext;

  factory HudOverlayFrame.from({
    required Size viewportSize,
    required GameSession session,
    required GameSave gameSave,
    required PlayerControlState playerControl,
    required GameClientState? gameState,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    StabilityRuleset stabilityRuleset = StabilityRuleset.standard,
    HudResourceEconomyForecastCache? economyForecastCache,
    required HudPanelModes panelModes,
    required TopResourcePopupType? openResourceBreakdown,
    required TechnologyPanelViewModel technologyViewModel,
    required List<GameEventNotification> activityLog,
    required AppLocalizations l10n,
    required MapInspectionState mapInspection,
    required String? openSelectionDetailChipId,
    required HudMinimizedPopupsState minimizedPopups,
  }) {
    final activePlayerId = playerControl.activePlayerId;
    final selection = gameState?.selection?.withVisibleResources(
      playerId: activePlayerId,
      research: gameState.research,
    );
    final moveModeActive = gameState?.moveCommandActive ?? false;
    final cityFoundingDraft = gameState?.cityFoundingDraft;
    final modes = normalizeHudPanelModes(
      current: panelModes,
      gameState: gameState,
    );
    final activePlayer = _activePlayer(gameSave, activePlayerId);
    final activePlayerName = activePlayer == null
        ? null
        : GameDisplayNames.player(l10n, activePlayer);
    final activePlayerColor = activePlayer == null
        ? null
        : PlayerColorTheme.resolve(activePlayer.colorValue);
    final readyToEndTurn = hudPlayerReadyToEndTurn(
      gameState: gameState,
      activePlayerId: activePlayerId,
      technologyViewModel: technologyViewModel,
    );
    final playerActionState = HudPlayerActionState.from(
      gameState: gameState,
      gameSave: gameSave,
      activePlayerId: activePlayerId,
      activePlayerCanAct: playerControl.canAct,
    );
    final resourceSummary = HudResourceSummary.fromGameState(
      state: gameState,
      playerId: activePlayerId,
      mapData: session.mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityRuleset: stabilityRuleset,
      economyForecastCache: economyForecastCache,
    );
    final activeTechnologySummary = HudActiveTechnologySummary.fromViewModel(
      viewModel: technologyViewModel,
      l10n: l10n,
      currentTurn: gameSave.turn,
    );
    final remainingActionCount = TurnReducer.pendingTurnActionCount(
      gameState,
      activePlayerId,
      session.mapData,
      technologyRuleset: technologyRuleset,
    );
    final currentActionIndex = TurnReducer.currentPendingTurnActionIndex(
      gameState,
      activePlayerId,
      session.mapData,
      technologyRuleset: technologyRuleset,
    );
    final turnActionOptions = hudTurnActionOptions(
      l10n: l10n,
      gameState: gameState,
      activePlayerId: activePlayerId,
      mapTiles: session.mapData,
      technologyRuleset: technologyRuleset,
      technologyViewModel: technologyViewModel,
    );
    final activityLogEntries = HudActivityLogEntries.visibleTo(
      entries: activityLog,
      activePlayerId: activePlayerId,
    );
    final layoutMetrics = HudLayoutMetrics.fromSize(
      size: viewportSize,
      canShowGlobalActions: playerActionState.canShowGlobalActions,
      showTopResources: playerActionState.showTopResources,
    );
    final canStartCityFounding = HudCityFoundingAvailability.canStart(
      state: gameState,
      mapTiles: session.mapData,
    );
    final cityProductionContext = HudCityProductionContext.from(
      modes: modes,
      selection: selection,
    );
    final scorePressure = HudScorePressureContext.from(
      gameSave: gameSave,
      gameState: gameState,
      mapData: session.mapData,
    );
    final objectiveSummary = HudObjectiveSummary.fromGameState(
      state: gameState,
      mapData: session.mapData,
      activePlayerId: activePlayerId,
      modes: modes,
      cityProductionOpen: cityProductionContext.city != null,
      resourceBreakdownOpen: openResourceBreakdown != null,
      paceBalance: gameSave.matchRules.paceBalance,
      dominationRequiredHoldTurns: gameSave.matchRules.victory.dominationEnabled
          ? gameSave.matchRules.victory.dominationHoldTurns
          : 0,
      scoreByPlayerId: scorePressure.scoreByPlayerId,
      scoreAdviceByPlayerId: scorePressure.adviceByPlayerId,
      scoreBreakdownByPlayerId: scorePressure.breakdownByPlayerId,
      scoreRemainingTurns: scorePressure.remainingTurns,
    );
    final turnHintLabel = hudTurnHintLabel(
      l10n: l10n,
      gameState: gameState,
      activePlayerId: activePlayerId,
      activePlayerCanAct: playerControl.canAct,
      actionsLocked: playerActionState.actionsLocked,
      readyToEndTurn: readyToEndTurn,
      technologyViewModel: technologyViewModel,
      activeObjectives: objectiveSummary.activeObjectives,
    );
    final nextActionObjectiveAdvice =
        hudTurnHintIsObjective(l10n, turnHintLabel)
        ? hudActiveScoreAdvice(objectiveSummary.activeObjectives)
        : null;
    final selectedInfoModel = HudSelectionInfoModelFactory.from(
      selection: selection,
      gameState: gameState,
      mapData: session.mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityRuleset: stabilityRuleset,
      l10n: l10n,
      currentTurn: gameSave.turn,
      paceBalance: gameSave.matchRules.paceBalance,
    );
    final inspectedInfoModel = HudSelectionInfoModelFactory.from(
      selection: mapInspection.selection,
      gameState: gameState,
      mapData: session.mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityRuleset: stabilityRuleset,
      l10n: l10n,
      currentTurn: gameSave.turn,
      paceBalance: gameSave.matchRules.paceBalance,
    );
    final inspectingMap =
        inspectedInfoModel != null || mapInspection.artifact != null;
    final selectionInfoModel = inspectedInfoModel ?? selectedInfoModel;
    final visibleOpenSelectionDetailChipId = inspectingMap
        ? mapInspection.openChipId
        : openSelectionDetailChipId;
    final selectionDetailSync = HudSelectionDetailSync.fromSelection(
      selection: selectedInfoModel,
      openChipId: openSelectionDetailChipId,
    );
    final researchAvailable = technologyViewModel.technologies.any(
      (card) => card.canSelect,
    );
    final coachmarkSelectionKind = _coachmarkSelectionKind(
      selection,
      activePlayerId,
    );
    final coachmarkContext = FirstTurnCoachmarkContext(
      selectionKind: coachmarkSelectionKind,
      hasOwnedCity: _hasOwnedCity(gameState, activePlayerId),
      hasCityNeedingProduction: _hasCityNeedingProduction(
        gameState,
        activePlayerId,
      ),
      researchAvailable: researchAvailable,
    );
    final combatPreview = HudCombatPreviewFactory.from(
      gameState: gameState,
      mapData: session.mapData,
      turn: gameSave.turn,
      technologyRuleset: technologyRuleset,
    );
    final pendingAction = gameState?.pendingAction;
    final bannerCombatPreview =
        pendingAction is PendingAttackTargeting &&
            pendingAction.hasDefenderTarget
        ? combatPreview
        : null;
    final selectedUnit = gameState?.selectedUnit;
    final selectedUnitCanAct =
        selectedUnit != null &&
        gameState?.canControlUnit(selectedUnit) == true &&
        !playerActionState.actionsLocked;
    final resolvedModeBannerSpec = HudModeBannerSpec.resolve(
      l10n: l10n,
      pendingAction: gameState?.pendingAction,
      cityFoundingDraft: cityFoundingDraft,
      moveTargetingActive: moveModeActive,
      combatPreview: bannerCombatPreview,
      selectedUnit: selectedUnitCanAct ? selectedUnit : null,
      workerActionAvailable:
          selectedUnitCanAct &&
          _canPromptWorkerAction(selectedUnit, selectedInfoModel),
      workerActionBlockedReason: selectedUnitCanAct
          ? _workerActionBlockedReason(
              unit: selectedUnit,
              gameState: gameState,
              mapData: session.mapData,
              selectedInfoModel: selectedInfoModel,
              l10n: l10n,
            )
          : null,
      scoutAutoExploreAvailable:
          selectedUnitCanAct && _canPromptScoutAutoExplore(selectedUnit),
      canStartCityFounding:
          selectedUnitCanAct &&
          selectedUnit.type == GameUnitType.settler &&
          canStartCityFounding,
      cityFoundingBlockedReason: selectedUnitCanAct
          ? _cityFoundingBlockedReason(
              gameState: gameState,
              mapTiles: session.mapData,
              l10n: l10n,
            )
          : null,
      cityExpansionHexSelected: _cityExpansionHexSelected(gameState),
      selectedUnitMoveActionEnabled:
          selectedUnitCanAct && _canStartMoveTargeting(selectedUnit),
      selectedUnitMoveActionDisabledReason: _moveTargetingBlockedReason(
        selectedUnit,
        l10n,
      ),
    );
    final modeBannerPopupId =
        resolvedModeBannerSpec == null || !resolvedModeBannerSpec.minimizable
        ? null
        : HudMinimizedPopupIds.modeBanner(
            gameSave.id,
            resolvedModeBannerSpec.id,
          );
    final modeBannerSpec =
        modeBannerPopupId != null && minimizedPopups.hasEntry(modeBannerPopupId)
        ? null
        : resolvedModeBannerSpec;
    final largePanelOpen =
        modes.technology ||
        modes.empire ||
        modes.activityLog ||
        cityProductionContext.city != null;
    final coachmarksHaveOwnedSelection =
        coachmarkSelectionKind != FirstTurnCoachmarkSelectionKind.none;
    final coachmarksAllowModeBanner =
        resolvedModeBannerSpec == null ||
        (moveModeActive &&
            cityFoundingDraft == null &&
            gameState?.pendingAction == null);
    final coachmarksActive =
        gameSave.turn == 1 &&
        gameState != null &&
        activePlayerId.isNotEmpty &&
        playerControl.canAct &&
        coachmarksHaveOwnedSelection;
    final coachmarksEnabled =
        coachmarksActive &&
        playerActionState.canShowGlobalActions &&
        layoutMetrics.showTopResources &&
        modes == const HudPanelModes() &&
        openResourceBreakdown == null &&
        visibleOpenSelectionDetailChipId == null &&
        !inspectingMap &&
        coachmarksAllowModeBanner;

    return HudOverlayFrame(
      activePlayerCanAct: playerControl.canAct,
      moveModeActive: moveModeActive,
      cityFoundingDraft: cityFoundingDraft,
      modes: modes,
      activePlayerName: activePlayerName,
      activePlayerColor: activePlayerColor,
      readyToEndTurn: readyToEndTurn,
      playerActionState: playerActionState,
      resourceSummary: resourceSummary,
      activeTechnologySummary: activeTechnologySummary,
      remainingActionCount: remainingActionCount,
      currentActionIndex: currentActionIndex,
      turnActionOptions: turnActionOptions,
      activityLogEntries: activityLogEntries,
      layoutMetrics: layoutMetrics,
      canStartCityFounding: canStartCityFounding,
      cityProductionContext: cityProductionContext,
      objectiveSummary: objectiveSummary,
      turnHintLabel: turnHintLabel,
      nextActionObjectiveAdvice: nextActionObjectiveAdvice,
      selectedInfoModel: selectedInfoModel,
      mapInspection: mapInspection,
      inspectingMap: inspectingMap,
      selectionInfoModel: selectionInfoModel,
      visibleOpenSelectionDetailChipId: visibleOpenSelectionDetailChipId,
      selectionDetailSync: selectionDetailSync,
      researchAvailable: researchAvailable,
      resolvedModeBannerSpec: resolvedModeBannerSpec,
      modeBannerPopupId: modeBannerPopupId,
      modeBannerSpec: modeBannerSpec,
      combatPreview: combatPreview,
      largePanelOpen: largePanelOpen,
      coachmarksActive: coachmarksActive,
      coachmarksEnabled: coachmarksEnabled,
      coachmarkContext: coachmarkContext,
    );
  }
}
