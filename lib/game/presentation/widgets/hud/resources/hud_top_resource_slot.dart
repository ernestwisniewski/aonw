import 'dart:async';

import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/hud_command_dispatcher_provider.dart';
import 'package:aonw/game/presentation/widgets/activity_log/activity_log_dialog.dart';
import 'package:aonw/game/presentation/widgets/hud/outcome/hud_victory_status_summary.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_activity_log_entries.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_active_technology_summary.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_breakdown_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_summary.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_overlay.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HudTopResourceSlot extends ConsumerWidget {
  const HudTopResourceSlot({
    required this.show,
    required this.resourceSummary,
    required this.gameState,
    required this.activeTechnologySummary,
    required this.playerName,
    required this.playerColor,
    required this.turnNumber,
    required this.gameSave,
    required this.mapData,
    required this.activePlayerId,
    required this.l10n,
    super.key,
  });

  final bool show;
  final HudResourceSummary resourceSummary;
  final GameState? gameState;
  final HudActiveTechnologySummary activeTechnologySummary;
  final String? playerName;
  final Color? playerColor;
  final int turnNumber;
  final GameSave gameSave;
  final MapData mapData;
  final String? activePlayerId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();

    final openBreakdown = ref.watch(hudResourceBreakdownControllerProvider);
    final dispatcher = ref.read(hudCommandDispatcherProvider);
    final activityLogEntries = HudActivityLogEntries.visibleTo(
      entries: ref.watch(gameActivityLogProvider),
      activePlayerId: activePlayerId ?? '',
    );
    final victoryStatus = HudVictoryStatusSummary.from(
      gameSave: gameSave,
      gameState: gameState,
      l10n: l10n,
      mapData: mapData,
      activePlayerId: activePlayerId,
    );

    return Positioned.fill(
      child: TopResourceOverlay(
        gold: resourceSummary.gold,
        goldPerTurn: resourceSummary.goldPerTurn,
        goldIncome: resourceSummary.goldIncome,
        unitUpkeep: resourceSummary.unitUpkeep,
        sciencePerTurn: resourceSummary.sciencePerTurn,
        resourceInventory: resourceSummary.resourceInventory,
        resourceNetwork: resourceSummary.resourceNetwork,
        openBreakdown: openBreakdown,
        goldBreakdown: resourceSummary.goldBreakdown,
        scienceBreakdown: resourceSummary.scienceBreakdown,
        cities: gameState?.cities ?? const [],
        activeTechnologyName: activeTechnologySummary.name,
        activeTechnologyTurnsRemaining: activeTechnologySummary.turnsRemaining,
        activeTechnologyCompletionTurn: activeTechnologySummary.completionTurn,
        victoryStatus: victoryStatus,
        playerName: playerName,
        playerColor: playerColor,
        turnNumber: turnNumber,
        l10n: l10n,
        onTurnPressed: () {
          dispatcher.closeResourceBreakdown();
          unawaited(
            showTurnTimelinePopup(
              context,
              entries: activityLogEntries,
              gameSave: gameSave,
              currentState: gameState,
              activePlayerId: activePlayerId,
            ),
          );
        },
        onGoldPressed: () =>
            dispatcher.toggleResourceBreakdown(ResourceBreakdownType.gold),
        onSciencePressed: () =>
            dispatcher.toggleResourceBreakdown(ResourceBreakdownType.science),
        onResourcesPressed: () =>
            dispatcher.toggleResourceBreakdown(ResourceBreakdownType.resources),
        onVictoryPressed: dispatcher.toggleVictoryBreakdown,
        onCloseBreakdown: dispatcher.closeResourceBreakdown,
      ),
    );
  }
}
