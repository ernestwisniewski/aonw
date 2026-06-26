import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/turn_reducer.dart';
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
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

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
    required GameState? gameState,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
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
      mapData: session.mapData,
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
      mapData: session.mapData,
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
              mapData: session.mapData,
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

  static Player? _activePlayer(GameSave gameSave, String activePlayerId) {
    for (final player in gameSave.players) {
      if (player.id == activePlayerId) return player;
    }
    return null;
  }

  static bool _cityExpansionHexSelected(GameState? gameState) {
    final pendingAction = gameState?.pendingAction;
    if (pendingAction is! PendingCityExpansionSelection) return false;
    return gameState?.cities.any(
          (city) =>
              city.id == pendingAction.cityId &&
              city.preferredExpansionHex != null,
        ) ??
        false;
  }

  static FirstTurnCoachmarkSelectionKind _coachmarkSelectionKind(
    GameSelection? selection,
    String activePlayerId,
  ) {
    final city = selection?.city;
    if (city != null && city.ownerPlayerId == activePlayerId) {
      return FirstTurnCoachmarkSelectionKind.city;
    }
    final unit = selection?.unit;
    if (unit == null || unit.ownerPlayerId != activePlayerId) {
      return FirstTurnCoachmarkSelectionKind.none;
    }
    return switch (unit.type) {
      GameUnitType.settler => FirstTurnCoachmarkSelectionKind.settler,
      GameUnitType.worker => FirstTurnCoachmarkSelectionKind.worker,
      _ => FirstTurnCoachmarkSelectionKind.unit,
    };
  }

  static bool _hasOwnedCity(GameState? gameState, String activePlayerId) {
    return gameState?.cities.any(
          (city) => city.ownerPlayerId == activePlayerId,
        ) ??
        false;
  }

  static bool _hasCityNeedingProduction(
    GameState? gameState,
    String activePlayerId,
  ) {
    return gameState?.cities.any(
          (city) =>
              city.ownerPlayerId == activePlayerId &&
              city.productionQueue == null,
        ) ??
        false;
  }

  static bool _canPromptWorkerAction(
    GameUnit? unit,
    SelectionViewModel? selectedInfoModel,
  ) {
    if (unit == null) return false;
    if (unit.type != GameUnitType.worker) return false;
    if (!_canUseUnitTurnAction(unit) || unit.queuedPath != null) return false;
    return selectedInfoModel?.workerAction?.canStartSelection == true;
  }

  static String? _workerActionBlockedReason({
    required GameUnit? unit,
    required GameState? gameState,
    required MapData mapData,
    required SelectionViewModel? selectedInfoModel,
    required AppLocalizations l10n,
  }) {
    if (unit == null || unit.type != GameUnitType.worker) return null;
    if (unit.isWorking) return null;
    final workerAction = selectedInfoModel?.workerAction;
    if (workerAction == null || workerAction.canStartSelection) return null;
    return _workerTileBlockedReason(
          unit: unit,
          gameState: gameState,
          mapData: mapData,
          l10n: l10n,
        ) ??
        workerAction.buildBlockedReason;
  }

  static String? _workerTileBlockedReason({
    required GameUnit unit,
    required GameState? gameState,
    required MapData mapData,
    required AppLocalizations l10n,
  }) {
    final hex = CityHex(col: unit.col, row: unit.row);
    if (mapData.tileAt(unit.col, unit.row) == null) {
      return l10n.selectionActionNoWorkerTile;
    }
    if (gameState?.cities.any((city) => city.center == hex) == true) {
      return l10n.selectionActionCannotImproveCityCenter;
    }
    if (gameState?.fieldImprovements.any(
          (improvement) => improvement.occupies(unit.col, unit.row),
        ) ==
        true) {
      return l10n.selectionActionTileAlreadyImproved;
    }
    final controlledByOwnCity =
        gameState?.cities.any(
          (city) =>
              city.ownerPlayerId == unit.ownerPlayerId &&
              city.controlsHex(hex) &&
              city.center != hex,
        ) ??
        false;
    if (!controlledByOwnCity) {
      return l10n.selectionActionTileMustBelongToCity;
    }
    return null;
  }

  static bool _canPromptScoutAutoExplore(GameUnit? unit) {
    return unit != null &&
        unit.type == GameUnitType.scout &&
        !unit.isAutoExploring &&
        _canUseUnitTurnAction(unit) &&
        unit.queuedPath == null;
  }

  static bool _canUseUnitTurnAction(GameUnit unit) {
    return unit.movementPoints > 0 && !unit.isWorking && !unit.isFortified;
  }

  static String? _cityFoundingBlockedReason({
    required GameState? gameState,
    required MapData mapData,
    required AppLocalizations l10n,
  }) {
    final unit = gameState?.selectedUnit;
    if (unit == null || unit.type != GameUnitType.settler || unit.isWorking) {
      return null;
    }
    final failure = CityFoundingRules.startFailure(
      unit: unit,
      centerTile: mapData.tileAt(unit.col, unit.row),
      cities: gameState?.cities ?? const [],
    );
    return _cityFoundingFailureReason(failure, l10n);
  }

  static String? _cityFoundingFailureReason(
    CityFoundingFailure? failure,
    AppLocalizations l10n,
  ) {
    return switch (failure) {
      null => null,
      CityFoundingFailure.noCommander =>
        l10n.selectionActionFoundCityNoCommander,
      CityFoundingFailure.noSettlers => l10n.selectionActionFoundCityNoSettlers,
      CityFoundingFailure.invalidCenter =>
        l10n.selectionActionFoundCityInvalidCenter,
      CityFoundingFailure.cityAlreadyExists =>
        l10n.selectionActionFoundCityCityAlreadyExists,
      CityFoundingFailure.centerOccupied =>
        l10n.selectionActionFoundCityCenterOccupied,
      CityFoundingFailure.tooCloseToCity =>
        l10n.selectionActionFoundCityTooCloseToCity,
      CityFoundingFailure.invalidControlledHexes =>
        l10n.selectionActionFoundCityInvalidControlledHexes,
    };
  }

  static bool _canStartMoveTargeting(GameUnit? unit) {
    return unit != null &&
        !unit.isMerchant &&
        _canUseUnitTurnAction(unit) &&
        unit.queuedPath == null;
  }

  static String? _moveTargetingBlockedReason(
    GameUnit? unit,
    AppLocalizations l10n,
  ) {
    if (unit == null) return null;
    if (unit.queuedPath != null) {
      return l10n.selectionActionCancelCurrentMoveFirst;
    }
    if (unit.isWorking) return l10n.selectionActionUnitWorking;
    if (unit.isFortified) {
      return UnitFortificationRules.canHeal(unit)
          ? l10n.selectionActionUnitHealing
          : l10n.selectionActionUnitFortified;
    }
    if (unit.movementPoints <= 0) return l10n.selectionActionNoMovement;
    return null;
  }
}
