import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/widgets/hud/action_deck/hud_action_deck.dart';
import 'package:aonw/game/presentation/widgets/hud/city/hud_city_production_context.dart';
import 'package:aonw/game/presentation/widgets/hud/layout/hud_layout_metrics.dart';
import 'package:aonw/game/presentation/widgets/hud/overlay/hud_overlay_panels.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_activity_log_entries.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_modes.dart';
import 'package:aonw/game/presentation/widgets/hud/turn/hud_player_action_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameHudOverlayPanelsHost extends ConsumerWidget {
  const GameHudOverlayPanelsHost({
    required this.session,
    required this.gameSave,
    super.key,
  });

  final GameSession session;
  final GameSave gameSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerControl = PlayerControlCoordinator.normalize(
      current: ref.watch(gamePlayerControlControllerProvider),
      save: gameSave,
    );
    final activePlayerId = playerControl.activePlayerId;
    final gameState = ref.watch(gameStateProvider(session.saveId)).value;
    final modes = normalizeHudPanelModes(
      current: ref.watch(hudPanelControllerProvider),
      gameState: gameState,
    );
    final cityRuleset = ref.watch(cityRulesetProvider);
    final technologyRuleset = ref.watch(technologyRulesetProvider);
    final technologyViewModel = ref.watch(
      technologyPanelViewModelProvider(session.saveId, activePlayerId),
    );
    final activityLogEntries = HudActivityLogEntries.visibleTo(
      entries: ref.watch(gameActivityLogProvider),
      activePlayerId: activePlayerId,
    );
    final cityProductionContext = HudCityProductionContext.from(
      modes: modes,
      selection: gameState?.selection,
    );
    final playerActionState = HudPlayerActionState.from(
      gameState: gameState,
      gameSave: gameSave,
      activePlayerId: activePlayerId,
      activePlayerCanAct: playerControl.canAct,
    );
    final layoutMetrics = HudLayoutMetrics.fromSize(
      size: MediaQuery.sizeOf(context),
      canShowGlobalActions: playerActionState.canShowGlobalActions,
      showTopResources: playerActionState.showTopResources,
    );
    final largePanelOpen =
        modes.technology ||
        modes.empire ||
        modes.activityLog ||
        cityProductionContext.city != null;
    final panelPadding = EdgeInsets.fromLTRB(
      12,
      layoutMetrics.panelTopPadding,
      layoutMetrics.panelRightPadding,
      largePanelOpen && layoutMetrics.portraitPhone
          ? HudActionDeck.collapsedHeight + 12
          : layoutMetrics.panelBottomPadding,
    );

    return HudOverlayPanels(
      panelPadding: panelPadding,
      technologyActive: modes.technology,
      empireActive: modes.empire,
      activityLogActive: modes.activityLog,
      cityProductionCity: cityProductionContext.city,
      gameState: gameState,
      activePlayerId: activePlayerId,
      technologyViewModel: technologyViewModel,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      mapData: session.mapData,
      cityProductionPerTurn: cityProductionContext.productionPerTurn,
      activityLogEntries: activityLogEntries,
      gameSave: gameSave,
    );
  }
}
