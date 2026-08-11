import 'dart:math' as math;

import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider.dart';
import 'package:aonw/game/presentation/providers/hud/game_options_overlay_open_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_command_dispatcher_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_gamepad_focus_controller_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_minimized_popups_provider.dart';
import 'package:aonw/game/presentation/providers/player/player_control_provider.dart';
import 'package:aonw/game/presentation/providers/ruleset/ruleset_providers.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/technology_panel_view_model.dart';
import 'package:aonw/game/presentation/widgets/hud/gamepad/hud_gamepad_focus_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/global_hud_actions.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/game_objectives_overlay.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/hud_objective_button_signal.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/hud_objective_summary.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/hud_score_pressure_context.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_active_technology_summary.dart';
import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_targets.dart';
import 'package:aonw/game/presentation/widgets/options/game_help_panel.dart';
import 'package:aonw/game/presentation/widgets/options/game_options_layout.dart';
import 'package:aonw/game/presentation/widgets/options/game_options_panel.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_options_panel.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'game_options_overlay_contract.dart';
part 'game_options_overlay_side_menu.dart';
part 'game_options_overlay_state_transitions.dart';
part 'game_options_overlay_visuals.dart';

class _GameOptionsOverlayState extends ConsumerState<GameOptionsOverlay> {
  late final HudGamepadFocusTargetRegistry _gamepadFocusRegistry;
  bool _optionsOpen = false;
  bool _helpOpen = false;
  bool _menuCollapsed = false;

  @override
  void initState() {
    super.initState();
    _gamepadFocusRegistry = ref.read(
      hudGamepadFocusTargetRegistryProvider.notifier,
    );
  }

  void _updateOverlayState(VoidCallback update) {
    setState(update);
    widget.onOverlayPanelActiveChanged?.call(_overlayPanelActive);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final minimizedState = ref.watch(hudMinimizedPopupsProvider);
    final autoActionFlowEnabled = ref.watch(hudAutoActionFlowProvider);
    final autoTurnFlowEnabled = ref.watch(hudAutoTurnFlowProvider);
    final gameplaySettings = ref.watch(gameplaySettingsProvider);
    final helpSaveId = widget.gameSave?.id ?? widget.session.saveId;
    final gameState = widget.session.saveId.isEmpty
        ? null
        : ref.watch(gameStateProvider(widget.session.saveId)).value;
    final modes = ref.watch(hudPanelControllerProvider);
    final playerControl = widget.gameSave == null
        ? null
        : PlayerControlCoordinator.normalize(
            current: ref.watch(gamePlayerControlControllerProvider),
            save: widget.gameSave!,
          );
    final activePlayerId =
        playerControl?.activePlayerId ?? gameState?.activePlayerId ?? '';
    final scorePressure = HudScorePressureContext.from(
      gameSave: widget.gameSave,
      gameState: gameState,
      mapData: widget.session.mapData,
    );
    final victory = widget.gameSave?.matchRules.victory;
    final objectiveSummary = HudObjectiveSummary.fromGameState(
      state: gameState,
      mapData: widget.session.mapData,
      activePlayerId: activePlayerId,
      modes: modes,
      cityProductionOpen: false,
      resourceBreakdownOpen: false,
      paceBalance:
          widget.gameSave?.matchRules.paceBalance ?? PaceBalance.unlimited,
      dominationRequiredHoldTurns: victory?.dominationEnabled == true
          ? victory!.dominationHoldTurns
          : 0,
      scoreByPlayerId: scorePressure.scoreByPlayerId,
      scoreAdviceByPlayerId: scorePressure.adviceByPlayerId,
      scoreBreakdownByPlayerId: scorePressure.breakdownByPlayerId,
      scoreRemainingTurns: scorePressure.remainingTurns,
    );
    final activityLogAvailable =
        widget.gameSave != null && activePlayerId.isNotEmpty;
    final cityRuleset = ref.watch(cityRulesetProvider);
    final technologyRuleset = ref.watch(technologyRulesetProvider);
    final technologyViewModel = TechnologyPanelViewModelFactory.create(
      state: gameState,
      playerId: activePlayerId,
      ruleset: technologyRuleset,
      cityRuleset: cityRuleset,
      mapData: widget.session.mapData,
      currentTurn: widget.gameSave?.turn,
      paceBalance:
          widget.gameSave?.matchRules.paceBalance ?? PaceBalance.unlimited,
    );
    final activeTechnologySummary = HudActiveTechnologySummary.fromViewModel(
      viewModel: technologyViewModel,
      l10n: l10n,
      currentTurn: widget.gameSave?.turn,
    );
    final activePlayerSubmitted =
        gameState?.hasSubmittedTurn(activePlayerId) ?? false;
    final activePlayerFinished =
        widget.gameSave?.playerStates[activePlayerId] ==
        PlayerTurnState.finished;
    final canShowGlobalActions =
        widget.gameSave != null &&
        activePlayerId.isNotEmpty &&
        !activePlayerSubmitted &&
        !activePlayerFinished;
    final objectiveButtonSignal = objectiveSummary.activeObjectives.isEmpty
        ? null
        : HudObjectiveButtonSignal.from(
            l10n: l10n,
            objectives: objectiveSummary.activeObjectives,
            open: modes.objectives,
          );
    final minimizedPopups = minimizedState.entriesForSave(helpSaveId);
    final helpEntries = _helpEntries(
      l10n: l10n,
      saveId: helpSaveId,
      minimizedPopups: minimizedPopups,
    );
    final sideMenuFocusTargets = _sideMenuFocusTargets(
      l10n: l10n,
      menuCollapsed: _menuCollapsed,
      helpAvailable: helpEntries.isNotEmpty,
      objectivesAvailable: objectiveButtonSignal != null,
      activityLogAvailable: activityLogAvailable,
      globalActionsAvailable: canShowGlobalActions,
      activePlayerId: activePlayerId,
      gameState: gameState,
    );
    _publishGamepadFocusTargets(sideMenuFocusTargets);
    final focusState = ref.watch(hudGamepadFocusControllerProvider);
    final focusedSideMenuTargetId =
        focusState.active &&
            sideMenuFocusTargets.any(
              (target) => target.id == focusState.targetId,
            )
        ? focusState.targetId
        : null;
    Widget? researchAction;
    Widget? empireAction;
    if (canShowGlobalActions) {
      researchAction = GameUiSideMenuButton(
        key: FirstTurnCoachmarkTargets.research,
        buttonKey: const Key('globalHud.action.research'),
        iconBuilder: (color) =>
            GameIcon(GameIcons.science, size: 18, color: color),
        open: modes.technology,
        tooltip: researchGlobalHudActionTooltip(
          l10n: l10n,
          technologyActive: modes.technology,
          activeTechnologyName: activeTechnologySummary.name,
          activeTechnologyTurnsRemaining:
              activeTechnologySummary.turnsRemaining,
          activeTechnologyCompletionTurn:
              activeTechnologySummary.completionTurn,
          researchAvailable: technologyViewModel.technologies.any(
            (card) => card.canSelect,
          ),
        ),
        onPressed: () => _toggleTechnologyPanel(activePlayerId, gameState),
        gamepadFocused: _sideMenuFocused(focusedSideMenuTargetId, 'research'),
      );
      empireAction = GameUiSideMenuButton(
        buttonKey: const Key('globalHud.action.empire'),
        iconBuilder: (color) =>
            GameIcon(GameIcons.cityFilled, size: 18, color: color),
        open: modes.empire,
        tooltip: modes.empire ? l10n.globalHudCloseEmpire : l10n.commonEmpire,
        onPressed: () => _toggleEmpirePanel(activePlayerId, gameState),
        gamepadFocused: _sideMenuFocused(focusedSideMenuTargetId, 'empire'),
      );
    }
    Widget? objectiveAction;
    if (objectiveButtonSignal != null) {
      objectiveAction = GameUiSideMenuButton(
        buttonKey: const Key('globalHud.action.objectives'),
        iconBuilder: (color) =>
            GameIcon(GameIcons.checkCircle, size: 18, color: color),
        open: modes.objectives,
        badgeLabel: objectiveButtonSignal.badgeLabel,
        badgeTone: objectiveButtonSignal.badgeTone,
        tooltip: objectiveButtonSignal.tooltip,
        onPressed: () => _toggleObjectivesPanel(activePlayerId, gameState),
        gamepadFocused: _sideMenuFocused(focusedSideMenuTargetId, 'objectives'),
      );
    }
    Widget? activityLogAction;
    if (activityLogAvailable) {
      activityLogAction = GameUiSideMenuButton(
        buttonKey: const Key('globalHud.action.activityLog'),
        iconBuilder: (color) =>
            GameIcon(GameIcons.activityLog, size: 18, color: color),
        open: modes.activityLog,
        tooltip: modes.activityLog
            ? l10n.globalHudCloseActivityLog
            : l10n.activityLogTitle,
        onPressed: () => _toggleActivityLogPanel(activePlayerId, gameState),
        gamepadFocused: _sideMenuFocused(
          focusedSideMenuTargetId,
          'activityLog',
        ),
      );
    }
    final helpOpen = !_menuCollapsed && _helpOpen && helpEntries.isNotEmpty;
    if (_helpOpen && helpEntries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_helpOpen) return;
        _updateOverlayState(() => _helpOpen = false);
      });
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = GameOptionsOverlayLayout.resolve(
          size: constraints.biggest,
          safePadding: MediaQuery.paddingOf(context),
          hasResignAction: widget.onResignMatch != null,
          sideActionCount: 0,
        );
        final objectivesOpen =
            !_menuCollapsed &&
            !_optionsOpen &&
            !helpOpen &&
            objectiveSummary.showOverlay;
        return Stack(
          fit: StackFit.expand,
          children: [
            GameOptionsOverlayOpenPublisher(
              saveId: helpSaveId,
              active: _optionsOpen || helpOpen || objectivesOpen,
            ),
            if (_optionsOpen || helpOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _closeOptions,
                ),
              ),
            if (_menuCollapsed)
              Positioned(
                left: layout.buttonLeft,
                top: layout.buttonTop,
                child: KeyedSubtree(
                  key: FirstTurnCoachmarkTargets.sideMenu,
                  child: GameUiSideMenuButton(
                    buttonKey: const Key('gameOptions.menuExpandButton'),
                    open: false,
                    tooltip: l10n.optionsOpenMenuTooltip,
                    iconBuilder: (color) =>
                        Icon(Icons.menu_open, size: 20, color: color),
                    onPressed: _expandMenu,
                    gamepadFocused: _sideMenuFocused(
                      focusedSideMenuTargetId,
                      'menu',
                    ),
                  ),
                ),
              )
            else
              Positioned(
                left: layout.buttonLeft,
                top: layout.buttonTop,
                child: _GameOptionsSideMenuRail(
                  key: FirstTurnCoachmarkTargets.sideMenu,
                  children: [
                    GameUiSideMenuButton(
                      buttonKey: const Key('gameOptions.optionsButton'),
                      open: _optionsOpen,
                      tooltip: l10n.optionsTooltipWithCollapseHint(
                        l10n.optionsTooltip,
                      ),
                      iconBuilder: (color) =>
                          _MapOptionsGlyph(color: color, active: _optionsOpen),
                      onPressed: () =>
                          _toggleOptions(activePlayerId, gameState),
                      onLongPress: () =>
                          _collapseMenu(activePlayerId, gameState),
                      gamepadFocused: _sideMenuFocused(
                        focusedSideMenuTargetId,
                        'options',
                      ),
                    ),
                    const _GameOptionsSideMenuSeparator(),
                    if (helpEntries.isNotEmpty)
                      HelpPopupsButton(
                        open: helpOpen,
                        count: minimizedPopups.length,
                        attentionSequence:
                            minimizedState.attentionRequest?.sequence ?? 0,
                        onPressed: () =>
                            _toggleHelpPanel(activePlayerId, gameState),
                        gamepadFocused: _sideMenuFocused(
                          focusedSideMenuTargetId,
                          'help',
                        ),
                      ),
                    ?objectiveAction,
                    const _GameOptionsSideMenuSeparator(),
                    ?activityLogAction,
                    ?researchAction,
                    ?empireAction,
                  ],
                ),
              ),
            if (!_menuCollapsed && _optionsOpen)
              Positioned(
                left: layout.panelLeft,
                top: layout.panelTop,
                child: ConstrainedBox(
                  key: const Key('gameOptions.panelViewport'),
                  constraints: BoxConstraints(
                    maxWidth: layout.panelWidth,
                    maxHeight: layout.panelMaxHeight,
                  ),
                  child: SingleChildScrollView(
                    primary: false,
                    child: GameOptionsPanel(
                      width: layout.panelWidth,
                      session: widget.session,
                      allowGraphicMode: widget.allowGraphicMode,
                      onViewModeChanged: widget.onViewModeChanged,
                      displaySettings: widget.displaySettings,
                      onToggleTerrain: widget.onToggleTerrain,
                      onToggleResources: widget.onToggleResources,
                      onToggleHeightBadge: widget.onToggleHeightBadge,
                      onToggleCitySites: widget.onToggleCitySites,
                      onToggleCityGrowth: widget.onToggleCityGrowth,
                      onToggleHexBorders: widget.onToggleHexBorders,
                      onToggleHeightWalls: widget.onToggleHeightWalls,
                      autoActionFlowEnabled: autoActionFlowEnabled,
                      onAutoActionFlowChanged: ref
                          .read(hudAutoActionFlowProvider.notifier)
                          .setEnabled,
                      autoTurnFlowEnabled: autoTurnFlowEnabled,
                      onAutoTurnFlowChanged: ref
                          .read(hudAutoTurnFlowProvider.notifier)
                          .setEnabled,
                      camera: GameOptionsCameraBindings(
                        settings: gameplaySettings,
                        controller: ref.read(gameplaySettingsProvider.notifier),
                      ),
                      onHexBorderColorChanged: widget.onHexBorderColorChanged,
                      onWallTintColorChanged: widget.onWallTintColorChanged,
                      onResetHexBorderColor: widget.onResetHexBorderColor,
                      onResetWallTintColor: widget.onResetWallTintColor,
                      showDiceRollTest: widget.showDiceRollTest,
                      onToggleDiceRollTest: widget.onToggleDiceRollTest,
                      onResignMatch: widget.onResignMatch,
                      resigning: widget.resigning,
                    ),
                  ),
                ),
              ),
            if (objectivesOpen)
              Positioned(
                left: layout.panelLeft,
                top: layout.panelTop,
                child: ConstrainedBox(
                  key: const Key('gameOptions.objectivesPanelViewport'),
                  constraints: BoxConstraints(
                    maxWidth: layout.sidePanelWidth,
                    maxHeight: layout.panelMaxHeight,
                  ),
                  child: SingleChildScrollView(
                    primary: false,
                    child: GameObjectivesOverlay(
                      objectives: objectiveSummary.activeObjectives,
                      scoreBreakdown: objectiveSummary.scoreBreakdown,
                      maxWidth: layout.sidePanelWidth,
                    ),
                  ),
                ),
              ),
            if (helpOpen)
              Positioned(
                left: layout.panelLeft,
                top: layout.panelTop,
                child: ConstrainedBox(
                  key: const Key('gameOptions.helpPanelViewport'),
                  constraints: BoxConstraints(
                    maxWidth: layout.sidePanelWidth,
                    maxHeight: layout.panelMaxHeight,
                  ),
                  child: SingleChildScrollView(
                    primary: false,
                    child: HelpPopupsPanel(
                      width: layout.sidePanelWidth,
                      entries: helpEntries,
                      onActivate: _activateHelpEntry,
                    ),
                  ),
                ),
              ),
            if (!_optionsOpen && !helpOpen && widget.closedContent != null)
              Positioned(
                top: layout.closedContentTop,
                right: layout.closedContentRight,
                child: ConstrainedBox(
                  key: const Key('gameOptions.closedContentViewport'),
                  constraints: BoxConstraints(
                    maxWidth: layout.closedContentMaxWidth,
                    maxHeight: layout.closedContentMaxHeight,
                  ),
                  child: SingleChildScrollView(
                    primary: false,
                    child: widget.closedContent!,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
