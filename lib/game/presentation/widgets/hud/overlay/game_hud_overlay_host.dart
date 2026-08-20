import 'dart:async';

import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/providers/hud/game_options_overlay_open_provider.dart';
import 'package:aonw/game/presentation/widgets/activity_log/activity_log_dialog.dart';
import 'package:aonw/game/presentation/widgets/hud/gamepad/hud_gamepad_focus_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/gamepad/hud_gamepad_focus_ring.dart';
import 'package:aonw/game/presentation/widgets/hud/global_hud_actions.dart';
import 'package:aonw/game/presentation/widgets/hud/map/hud_map_inspection_menu.dart';
import 'package:aonw/game/presentation/widgets/hud/mode_banner/hud_mode_banner.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/hud_overlay_frame.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/hud_overlay_host_actions.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/hud_overlay_stack_slots.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_breakdown_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_economy_forecast.dart';
import 'package:aonw/game/presentation/widgets/hud/selection/hud_selection_actions.dart';
import 'package:aonw/game/presentation/widgets/hud/turn/hud_auto_turn_hint.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';
import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/selection_info/selection_info.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'game_hud_overlay_host_contract.dart';
part 'game_hud_overlay_host_gamepad_focus.dart';
part 'game_hud_overlay_host_helpers.dart';

class _GameHudOverlayHostState extends ConsumerState<GameHudOverlayHost> {
  final HudResourceEconomyForecastCache _resourceEconomyForecastCache =
      HudResourceEconomyForecastCache();
  late final HudGamepadFocusTargetRegistry _gamepadFocusRegistry;
  HudMinimizedPopupEntry? _restoredModeBannerEntry;
  bool _autoTurnHintRestored = false;
  @override
  void initState() {
    super.initState();
    _gamepadFocusRegistry = ref.read(
      hudGamepadFocusTargetRegistryProvider.notifier,
    );
  }

  void _setRestoredModeBannerEntry(HudMinimizedPopupEntry? entry) {
    if (mounted) setState(() => _restoredModeBannerEntry = entry);
  }

  void _setAutoTurnHintRestored(bool restored) {
    if (mounted) setState(() => _autoTurnHintRestored = restored);
  }

  @override
  void didUpdateWidget(covariant GameHudOverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameSave.id == widget.gameSave.id) return;
    _restoredModeBannerEntry = null;
    _autoTurnHintRestored = false;
    _resourceEconomyForecastCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    final playerControl = PlayerControlCoordinator.normalize(
      current: ref.watch(gamePlayerControlControllerProvider),
      save: widget.gameSave,
    );
    final gameStateProviderValue = gameStateProvider(widget.session.saveId);
    final actions = _actions;
    ref
      ..listen<AsyncValue<GameClientState>>(gameStateProviderValue, (_, next) {
        if (!mounted) return;
        _syncModesWithState(next.value);
      })
      ..listen<int>(gameActivityLogPanelRequestProvider, (previous, next) {
        if (!mounted || previous == next) return;
        actions.openActivityLogPanel();
      });
    final dispatcher = ref.read(hudCommandDispatcherProvider);
    final gameState = ref.watch(gameStateProviderValue).value;
    final activePlayerId = playerControl.activePlayerId;
    final minimizedPopups = ref.watch(hudMinimizedPopupsProvider);
    final autoTurnFlowEnabled = ref.watch(hudAutoTurnFlowProvider);
    final optionsOverlayOpen =
        widget.optionsOverlayOpenOverride ||
        ref.watch(gameOptionsOverlayOpenProvider(widget.gameSave.id));
    final cityRuleset = ref.watch(cityRulesetProvider);
    final technologyRuleset = ref.watch(technologyRulesetProvider);
    final stabilityRuleset = ref.watch(stabilityRulesetProvider);
    final openResourceBreakdown = ref.watch(
      hudResourceBreakdownControllerProvider,
    );
    final openSelectionDetailChipId = ref.watch(
      openSelectionDetailControllerProvider,
    );
    final l10n = AppLocalizations.of(context);
    final frame = HudOverlayFrame.from(
      viewportSize: MediaQuery.sizeOf(context),
      session: widget.session,
      gameSave: widget.gameSave,
      playerControl: playerControl,
      gameState: gameState,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityRuleset: stabilityRuleset,
      economyForecastCache: _resourceEconomyForecastCache,
      panelModes: ref.watch(hudPanelControllerProvider),
      openResourceBreakdown: openResourceBreakdown,
      technologyViewModel: ref.watch(
        technologyPanelViewModelProvider(widget.session.saveId, activePlayerId),
      ),
      activityLog: ref.watch(gameActivityLogProvider),
      l10n: l10n,
      mapInspection: ref.watch(mapInspectionControllerProvider),
      openSelectionDetailChipId: openSelectionDetailChipId,
      minimizedPopups: minimizedPopups,
    );
    if (frame.selectionDetailSync.closeUnsupportedDetail) {
      _closeSelectionDetailAfterBuild();
    }
    final activityLogAvailable = activePlayerId.isNotEmpty && gameState != null;
    final deckGlobalActions = _deckGlobalActions(
      l10n: l10n,
      frame: frame,
      activityLogAvailable: activityLogAvailable,
    );
    final toggleVisibleSelectionDetail = _selectionDetailToggler(
      frame.inspectingMap,
    );
    final selectionActionChips = buildHudSelectionActionChips(
      gameState: gameState,
      mapData: widget.session.mapData,
      activePlayerId: activePlayerId,
      actionsLocked: frame.playerActionState.actionsLocked,
      moveModeActive: frame.moveModeActive,
      armyDetailActive: openSelectionDetailChipId == SelectionInfoChipId.army,
      workerAction: frame.selectedInfoModel?.workerAction,
      cityBuildingsModeActive: frame.modes.cityBuildings,
      cityDescriptionActive:
          openSelectionDetailChipId == SelectionInfoChipId.description,
      cityBuildingsDetailActive:
          openSelectionDetailChipId == SelectionInfoChipId.buildings,
      l10n: l10n,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      canStartCityFounding: frame.canStartCityFounding,
      cityFoundingActive: frame.cityFoundingDraft != null,
      onMoveSelectedUnit: dispatcher.moveSelectedUnit,
      onAutoExploreSelectedUnit: () =>
          dispatcher.autoExploreSelectedUnit(gameState),
      onAutomateSelectedWorker: () => dispatcher.automateWorker(gameState),
      onBuildRoad: () => dispatcher.buildRoad(gameState),
      onStartAttackTargeting: () => dispatcher.startAttackTargeting(gameState),
      onCancelAttackTargeting: () =>
          dispatcher.cancelAttackTargeting(gameState),
      onShowArmy: dispatcher.showArmySelectionDetail,
      onStartWorkerActionSelection: () =>
          dispatcher.startWorkerActionSelection(gameState),
      onCancelWorkerActionSelection: () =>
          dispatcher.cancelWorkerActionSelection(gameState),
      onCancelWorkerJob: () => dispatcher.cancelWorkerJob(gameState),
      onCancelWorkerAssignment: () => dispatcher.cancelAssignment(gameState),
      onStartMerchantTradeRouteSelection: () =>
          dispatcher.startMerchantTradeRouteSelection(gameState),
      onCancelMerchantTradeRouteSelection: () =>
          dispatcher.cancelMerchantTradeRouteSelection(gameState),
      onAssignMerchantTradeRoute: (cityId) =>
          dispatcher.assignMerchantTradeRoute(gameState, cityId),
      onStartMerchantMoveToCitySelection: () =>
          dispatcher.startMerchantMoveToCitySelection(gameState),
      onCancelMerchantMoveToCitySelection: () =>
          dispatcher.cancelMerchantMoveToCitySelection(gameState),
      onMoveMerchantToCity: (cityId) =>
          dispatcher.moveMerchantToCity(gameState, cityId),
      onStartArtifactExcavation: () =>
          dispatcher.startArtifactExcavation(gameState),
      onStoreArtifactInCity: () => dispatcher.storeArtifactInCity(gameState),
      onStartCityFounding: dispatcher.startCityFounding,
      onConfirmCityFounding: () => dispatcher.confirmCityFounding(gameState),
      onCancelCityFounding: dispatcher.cancelCityFounding,
      onSkipSelectedUnitTurn: () => dispatcher.skipSelectedUnitTurn(gameState),
      onFortifySelectedUnit: () => dispatcher.fortifySelectedUnit(gameState),
      onCancelSelectedUnitAction: () =>
          dispatcher.cancelSelectedUnitAction(gameState),
      onToggleCityDescription: () =>
          toggleVisibleSelectionDetail(SelectionInfoChipId.description),
      onToggleCityBuildingDetails: () =>
          toggleVisibleSelectionDetail(SelectionInfoChipId.buildings),
      onStartCityExpansionSelection: () =>
          dispatcher.startCityExpansionSelection(gameState),
      onCancelCityExpansionSelection: () =>
          dispatcher.cancelCityExpansionSelection(gameState),
      onToggleCityBuildings: actions.toggleCityBuildings,
    );
    final visibleSelectionActionChips = frame.inspectingMap
        ? const <Widget>[]
        : selectionActionChips;
    final closeVisibleSelectionDetail = frame.inspectingMap
        ? () => ref.read(mapInspectionControllerProvider.notifier).clear()
        : () => _closeSelectionDetail(openSelectionDetailChipId);
    final hudGamepadFocus = _resolveHudGamepadFocus(
      frame: frame,
      dispatcher: dispatcher,
      gameState: gameState,
      activePlayerId: activePlayerId,
      enabled: !optionsOverlayOpen && !frame.largePanelOpen,
      selectionActions: visibleSelectionActionChips,
    );
    _listenForMinimizedPopupRestoreRequests(
      modeBannerPopupId: frame.modeBannerPopupId,
      autoTurnHintPopupId: HudMinimizedPopupIds.autoTurnHint(
        widget.gameSave.id,
      ),
    );
    final autoTurnHintPopupId = HudMinimizedPopupIds.autoTurnHint(
      widget.gameSave.id,
    );
    _syncTransientModeHelp(frame);
    final effectiveModeBannerSpec = _restoredModeBannerSpec();
    final effectiveModeBannerPopupId = _restoredModeBannerEntry?.id;
    final autoTurnHintVisible =
        minimizedPopups.loaded &&
        !optionsOverlayOpen &&
        !frame.inspectingMap &&
        !frame.largePanelOpen &&
        _autoTurnHintRestored;
    return Stack(
      fit: StackFit.expand,
      children: [
        HudActionDeckSlot(
          animatingUnitIdsListenable: widget.animatingUnitIdsListenable,
          gameSave: widget.gameSave,
          activePlayerId: activePlayerId,
          activePlayerCanAct: frame.activePlayerCanAct,
          gameState: gameState,
          readyToEndTurn: frame.readyToEndTurn,
          remainingActionCount: frame.remainingActionCount,
          currentActionIndex: frame.currentActionIndex,
          turnActionOptions: frame.turnActionOptions,
          actionHintLabel: frame.turnHintLabel,
          nextActionObjectiveAdvice: frame.nextActionObjectiveAdvice,
          selection: frame.selectionInfoModel,
          openSelectionDetailChipId: frame.visibleOpenSelectionDetailChipId,
          selectionActions: hudGamepadFocus.selectionActions,
          cityFoundingDraft: frame.cityFoundingDraft,
          combatPreview: frame.combatPreview,
          cityRuleset: cityRuleset,
          technologyRuleset: technologyRuleset,
          useBottomGlobalActions: frame.layoutMetrics.useBottomGlobalActions,
          mainGlobalActions: deckGlobalActions,
          activityLogAvailable: activityLogAvailable,
          activityLogModeActive: frame.modes.activityLog,
          showSelectionInfo:
              !frame.largePanelOpen && !frame.mapInspection.anchored,
          panelOpen: frame.largePanelOpen,
          cityProductionPanelOpen: frame.cityProductionContext.city != null,
          onToggleSelectionDetail: toggleVisibleSelectionDetail,
          onCloseSelectionDetail: closeVisibleSelectionDetail,
        ),
        HudMapInspectionMenu(
          inspection: frame.mapInspection,
          selection: frame.selectionInfoModel,
          viewportSize: MediaQuery.sizeOf(context),
          activePlayerId: activePlayerId,
          research: gameState?.research ?? ResearchState.empty,
          technologyRuleset: technologyRuleset,
          onClose: () =>
              ref.read(mapInspectionControllerProvider.notifier).clear(),
        ),
        HudTopResourceSlot(
          show: frame.layoutMetrics.showTopResources,
          resourceSummary: frame.resourceSummary,
          gameState: gameState,
          activeTechnologySummary: frame.activeTechnologySummary,
          playerName: frame.activePlayerName,
          playerColor: frame.activePlayerColor,
          turnNumber: widget.gameSave.turn,
          gameSave: widget.gameSave,
          mapData: widget.session.mapData,
          activePlayerId: activePlayerId,
          l10n: AppLocalizations.of(context),
          gamepadFocusedTargetId: hudGamepadFocus.focusedTargetId,
          gamepadInputListenable: widget.gamepadInputListenable,
        ),
        HudModeBannerSlot(
          layoutMetrics: frame.layoutMetrics,
          spec: optionsOverlayOpen ? null : effectiveModeBannerSpec,
          popupId: effectiveModeBannerPopupId,
          onMinimize: _minimizeModeBanner,
        ),
        HudAutoTurnHintSlot(
          layoutMetrics: frame.layoutMetrics,
          visible: autoTurnHintVisible,
          enabled: autoTurnFlowEnabled,
          onMinimize: () => _minimizeAutoTurnHint(autoTurnHintPopupId),
        ),
        HudFirstTurnCoachmarksSlot(
          saveId: widget.gameSave.id,
          active: frame.coachmarksActive,
          enabled: frame.coachmarksEnabled,
          initialCameraFocusReadyListenable:
              widget.initialCameraFocusReadyListenable,
          hasSelectionActions: visibleSelectionActionChips.isNotEmpty,
          readyToEndTurn: frame.readyToEndTurn,
          coachmarkContext: frame.coachmarkContext,
          gamepadInputListenable: widget.gamepadInputListenable,
        ),
      ],
    );
  }

  void Function(String chipId) _selectionDetailToggler(bool inspectingMap) {
    if (inspectingMap) {
      return (chipId) => ref
          .read(mapInspectionControllerProvider.notifier)
          .toggleDetail(chipId);
    }
    return (chipId) =>
        ref.read(openSelectionDetailControllerProvider.notifier).toggle(chipId);
  }
}
