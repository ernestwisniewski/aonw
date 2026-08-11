import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/selection/hud_selection_action_spec.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/transport.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/widgets.dart';

final _roadBlockerReason =
    <RoadConstructionBlocker, String Function(AppLocalizations)>{
      RoadConstructionBlocker.workerBusy: (l10n) =>
          l10n.selectionActionUnitWorking,
      RoadConstructionBlocker.noMovementPoints: (l10n) =>
          l10n.selectionActionNoMovement,
      RoadConstructionBlocker.queuedPathActive: (l10n) =>
          l10n.selectionActionCancelCurrentMoveFirst,
      RoadConstructionBlocker.existingRoad: (l10n) =>
          l10n.selectionActionRoadAlreadyBuilt,
      RoadConstructionBlocker.enemyTerritory: (l10n) =>
          l10n.selectionActionRoadEnemyTerritory,
      RoadConstructionBlocker.impassableTerrain: (l10n) =>
          l10n.selectionActionRoadInvalidTerrain,
      RoadConstructionBlocker.cityCenter: (l10n) =>
          l10n.selectionActionRoadCityCenter,
    };

HudSelectionActionSpec workerRoadActionFor(
  GameUnit unit,
  GameClientState? gameState,
  WorldMap mapData,
  String? lockedReason,
  AppLocalizations l10n,
  VoidCallback onBuildRoad,
) {
  final legality = gameState == null
      ? const RoadConstructionLegality.blocked(
          RoadConstructionBlocker.missingTile,
        )
      : RoadConstructionRules.evaluate(
          unit: unit,
          cities: gameState.cities,
          network: gameState.transportNetwork,
          mapTiles: mapData,
        );
  final actionReason = legality.allowed
      ? null
      : _roadConstructionBlockedReason(l10n, legality.blocker);
  return HudSelectionActionSpec(
    icon: GameIcons.road,
    actionId: 'buildRoad',
    label: l10n.selectionActionBuildRoad,
    color: GameUiTheme.gold,
    active: false,
    enabled: legality.allowed && lockedReason == null,
    disabledReason: lockedReason ?? actionReason,
    onTap: onBuildRoad,
  );
}

String _roadConstructionBlockedReason(
  AppLocalizations l10n,
  RoadConstructionBlocker? blocker,
) {
  return _roadBlockerReason[blocker]?.call(l10n) ??
      l10n.selectionActionRoadUnavailable;
}
