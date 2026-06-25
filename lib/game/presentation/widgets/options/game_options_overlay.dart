import 'dart:math' as math;

import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game_options_overlay_open_provider.dart';
import 'package:aonw/game/presentation/providers/game_state_provider.dart';
import 'package:aonw/game/presentation/providers/hud_command_dispatcher_provider.dart';
import 'package:aonw/game/presentation/providers/hud_minimized_popups_provider.dart';
import 'package:aonw/game/presentation/providers/player_control_provider.dart';
import 'package:aonw/game/presentation/providers/ruleset_providers.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/technology_panel_view_model.dart';
import 'package:aonw/game/presentation/widgets/hud/game_objectives_overlay.dart';
import 'package:aonw/game/presentation/widgets/hud/global_hud_actions.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_active_technology_summary.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_objective_button_signal.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_objective_summary.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_panel_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_score_pressure_context.dart';
import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_targets.dart';
import 'package:aonw/game/presentation/widgets/options/game_help_panel.dart';
import 'package:aonw/game/presentation/widgets/options/game_options_layout.dart';
import 'package:aonw/game/presentation/widgets/options/game_options_panel.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_options_panel.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameOptionsOverlay extends ConsumerStatefulWidget {
  final GameSession session;
  final GameSave? gameSave;
  final bool allowGraphicMode;
  final ValueChanged<MapViewMode> onViewModeChanged;
  final HexDisplaySettings displaySettings;
  final VoidCallback onToggleTerrain;
  final VoidCallback onToggleResources;
  final VoidCallback onToggleHeightBadge;
  final VoidCallback onToggleCitySites;
  final VoidCallback onToggleCityGrowth;
  final VoidCallback onToggleHexBorders;
  final VoidCallback onToggleHeightWalls;
  final ValueChanged<Color>? onHexBorderColorChanged;
  final ValueChanged<Color>? onWallTintColorChanged;
  final VoidCallback? onResetHexBorderColor;
  final VoidCallback? onResetWallTintColor;
  final bool showDiceRollTest;
  final VoidCallback? onToggleDiceRollTest;
  final VoidCallback? onResignMatch;
  final bool resigning;
  final Widget? closedContent;
  final ValueChanged<bool>? onOverlayPanelActiveChanged;

  const GameOptionsOverlay({
    required this.session,
    this.gameSave,
    required this.allowGraphicMode,
    required this.onViewModeChanged,
    required this.displaySettings,
    required this.onToggleTerrain,
    required this.onToggleResources,
    required this.onToggleHeightBadge,
    required this.onToggleCitySites,
    required this.onToggleCityGrowth,
    required this.onToggleHexBorders,
    required this.onToggleHeightWalls,
    this.onHexBorderColorChanged,
    this.onWallTintColorChanged,
    this.onResetHexBorderColor,
    this.onResetWallTintColor,
    this.showDiceRollTest = false,
    this.onToggleDiceRollTest,
    this.onResignMatch,
    this.resigning = false,
    this.closedContent,
    this.onOverlayPanelActiveChanged,
    super.key,
  });

  @override
  ConsumerState<GameOptionsOverlay> createState() => _GameOptionsOverlayState();
}

class _GameOptionsOverlayState extends ConsumerState<GameOptionsOverlay> {
  bool _optionsOpen = false;
  bool _helpOpen = false;
  bool _menuCollapsed = false;

  bool get _overlayPanelActive =>
      !_menuCollapsed && (_optionsOpen || _helpOpen);

  void _toggleOptions(String activePlayerId, GameState? gameState) {
    final opening = !_optionsOpen;
    if (opening) {
      _closeHudSidePanels(activePlayerId: activePlayerId, gameState: gameState);
    }
    setState(() {
      _optionsOpen = opening;
      if (_optionsOpen) _helpOpen = false;
    });
    _publishOverlayPanelActive();
  }

  void _toggleHelpPanel(String activePlayerId, GameState? gameState) {
    final opening = !_helpOpen;
    if (opening) {
      _closeHudSidePanels(activePlayerId: activePlayerId, gameState: gameState);
    }
    setState(() {
      _helpOpen = opening;
      if (_helpOpen) _optionsOpen = false;
    });
    _publishOverlayPanelActive();
  }

  void _closeOptions() {
    if (!_optionsOpen && !_helpOpen) return;
    setState(() {
      _optionsOpen = false;
      _helpOpen = false;
    });
    _publishOverlayPanelActive();
  }

  void _collapseMenu(String activePlayerId, GameState? gameState) {
    _closeHudSidePanels(activePlayerId: activePlayerId, gameState: gameState);
    setState(() {
      _menuCollapsed = true;
      _optionsOpen = false;
      _helpOpen = false;
    });
    _publishOverlayPanelActive();
  }

  void _expandMenu() {
    setState(() => _menuCollapsed = false);
    _publishOverlayPanelActive();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _publishOverlayPanelActive() {
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
      );
      empireAction = GameUiSideMenuButton(
        buttonKey: const Key('globalHud.action.empire'),
        iconBuilder: (color) =>
            GameIcon(GameIcons.cityFilled, size: 18, color: color),
        open: modes.empire,
        tooltip: modes.empire ? l10n.globalHudCloseEmpire : l10n.commonEmpire,
        onPressed: () => _toggleEmpirePanel(activePlayerId, gameState),
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
      );
    }
    final minimizedPopups = minimizedState.entriesForSave(helpSaveId);
    final helpEntries = _helpEntries(
      l10n: l10n,
      saveId: helpSaveId,
      minimizedPopups: minimizedPopups,
    );
    final helpOpen = !_menuCollapsed && _helpOpen && helpEntries.isNotEmpty;
    if (_helpOpen && helpEntries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_helpOpen) return;
        setState(() => _helpOpen = false);
        _publishOverlayPanelActive();
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
                      followUnitMovementCameraEnabled:
                          gameplaySettings.followUnitMovementCamera,
                      onFollowUnitMovementCameraChanged: ref
                          .read(gameplaySettingsProvider.notifier)
                          .setFollowUnitMovementCamera,
                      followEnemyUnitCameraEnabled:
                          gameplaySettings.followEnemyUnitCamera,
                      onFollowEnemyUnitCameraChanged: ref
                          .read(gameplaySettingsProvider.notifier)
                          .setFollowEnemyUnitCamera,
                      cinematicCameraEnabled:
                          gameplaySettings.cinematicCameraEnabled,
                      onCinematicCameraChanged: ref
                          .read(gameplaySettingsProvider.notifier)
                          .setCinematicCameraEnabled,
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

  void _activateHelpEntry(HudMinimizedPopupEntry entry) {
    setState(() => _helpOpen = false);
    _publishOverlayPanelActive();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(hudMinimizedPopupsProvider.notifier).requestRestoreEntry(entry);
    });
  }

  List<HudMinimizedPopupEntry> _helpEntries({
    required AppLocalizations l10n,
    required String saveId,
    required List<HudMinimizedPopupEntry> minimizedPopups,
  }) {
    if (saveId.isEmpty) return minimizedPopups;
    final byId = <String, HudMinimizedPopupEntry>{
      HudMinimizedPopupIds.firstTurnTutorial(saveId): HudMinimizedPopupEntry(
        id: HudMinimizedPopupIds.firstTurnTutorial(saveId),
        kind: HudMinimizedPopupKind.firstTurnCoachmarks,
        title: l10n.firstTurnTutorialPopupTitle,
        subtitle: l10n.firstTurnTutorialPopupSubtitle,
      ),
      HudMinimizedPopupIds.autoTurnHint(saveId): HudMinimizedPopupEntry(
        id: HudMinimizedPopupIds.autoTurnHint(saveId),
        kind: HudMinimizedPopupKind.autoTurnHint,
        title: l10n.autoTurnHintTitle,
        subtitle: l10n.autoTurnHintMinimizedSubtitle,
      ),
    };
    for (final entry in minimizedPopups) {
      byId[entry.id] = entry;
    }
    return byId.values.toList(growable: false);
  }

  void _toggleObjectivesPanel(String activePlayerId, GameState? gameState) {
    _closeOptions();
    ref
        .read(hudCommandDispatcherProvider)
        .toggleObjectivesPanel(
          activePlayerId: activePlayerId,
          state: gameState,
        );
  }

  void _toggleActivityLogPanel(String activePlayerId, GameState? gameState) {
    _closeOptions();
    ref
        .read(hudCommandDispatcherProvider)
        .toggleActivityLogPanel(
          activePlayerId: activePlayerId,
          state: gameState,
        );
  }

  void _toggleTechnologyPanel(String activePlayerId, GameState? gameState) {
    _closeOptions();
    ref
        .read(hudCommandDispatcherProvider)
        .toggleTechnologyPanel(
          activePlayerId: activePlayerId,
          state: gameState,
        );
  }

  void _toggleEmpirePanel(String activePlayerId, GameState? gameState) {
    _closeOptions();
    ref
        .read(hudCommandDispatcherProvider)
        .toggleEmpirePanel(activePlayerId: activePlayerId, state: gameState);
  }

  void _closeHudSidePanels({
    required String activePlayerId,
    required GameState? gameState,
  }) {
    final dispatcher = ref.read(hudCommandDispatcherProvider)
      ..closeObjectivesPanel()
      ..closeEmpirePanel()
      ..closeActivityLogPanel();
    if (activePlayerId.isNotEmpty) {
      dispatcher.closeTechnologyPanel(
        activePlayerId: activePlayerId,
        state: gameState,
      );
    }
  }
}

class _MapOptionsGlyph extends StatelessWidget {
  const _MapOptionsGlyph({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: const Key('gameOptions.optionsModeGlyph'),
      dimension: 25,
      child: CustomPaint(
        painter: _AntiqueGearsPainter(color: color, active: active),
      ),
    );
  }
}

class _AntiqueGearsPainter extends CustomPainter {
  const _AntiqueGearsPainter({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = (active ? GameUiTheme.goldLight : GameUiTheme.copper).withAlpha(
        active ? 82 : 42,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final bodyPaint = Paint()
      ..color = GameUiTheme.bg.withAlpha(active ? 132 : 168)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color.withAlpha(active ? 255 : 230)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final accentPaint = Paint()
      ..color = (active ? GameUiTheme.goldLight : GameUiTheme.copper).withAlpha(
        active ? 245 : 210,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round;

    _drawGear(
      canvas,
      center: Offset(size.width * 0.43, size.height * 0.42),
      toothRadius: size.width * 0.35,
      rootRadius: size.width * 0.28,
      hubRadius: size.width * 0.095,
      teeth: 10,
      rotation: -math.pi / 14,
      fill: bodyPaint,
      stroke: strokePaint,
      glow: glowPaint,
      spoke: accentPaint,
    );
    _drawGear(
      canvas,
      center: Offset(size.width * 0.68, size.height * 0.67),
      toothRadius: size.width * 0.23,
      rootRadius: size.width * 0.18,
      hubRadius: size.width * 0.065,
      teeth: 8,
      rotation: math.pi / 9,
      fill: bodyPaint,
      stroke: accentPaint,
      glow: null,
      spoke: strokePaint,
    );
  }

  void _drawGear(
    Canvas canvas, {
    required Offset center,
    required double toothRadius,
    required double rootRadius,
    required double hubRadius,
    required int teeth,
    required double rotation,
    required Paint fill,
    required Paint stroke,
    required Paint? glow,
    required Paint spoke,
  }) {
    final gear = _gearPath(
      center: center,
      toothRadius: toothRadius,
      rootRadius: rootRadius,
      teeth: teeth,
      rotation: rotation,
    );
    if (glow != null) canvas.drawPath(gear, glow);
    canvas
      ..drawPath(gear, fill)
      ..drawPath(gear, stroke);

    final spokeCount = teeth <= 8 ? 4 : 5;
    for (var i = 0; i < spokeCount; i++) {
      final angle = rotation + (math.pi * 2 * i / spokeCount);
      final end = Offset(
        center.dx + math.cos(angle) * (rootRadius - hubRadius * 0.55),
        center.dy + math.sin(angle) * (rootRadius - hubRadius * 0.55),
      );
      canvas.drawLine(center, end, spoke);
    }
    canvas
      ..drawCircle(center, hubRadius * 1.55, fill)
      ..drawCircle(center, hubRadius * 1.55, stroke)
      ..drawCircle(center, hubRadius * 0.48, spoke);
  }

  Path _gearPath({
    required Offset center,
    required double toothRadius,
    required double rootRadius,
    required int teeth,
    required double rotation,
  }) {
    final path = Path();
    final points = teeth * 2;
    for (var i = 0; i < points; i++) {
      final angle = rotation + (math.pi * 2 * i / points);
      final radius = i.isEven ? toothRadius : rootRadius;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _AntiqueGearsPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.active != active;
  }
}

class _GameOptionsSideMenuRail extends StatelessWidget {
  const _GameOptionsSideMenuRail({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(height: 4),
          children[index],
        ],
      ],
    );
  }
}

class _GameOptionsSideMenuSeparator extends StatelessWidget {
  const _GameOptionsSideMenuSeparator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: GameUiSideMenuButton.extent,
      height: 10,
      child: Center(
        child: Container(
          width: 22,
          height: 1,
          color: GameUiTheme.gold.withAlpha(92),
        ),
      ),
    );
  }
}
