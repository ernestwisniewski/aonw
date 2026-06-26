import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/hover_intent_marker.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart' show Color;

typedef PlayerColorResolver = int Function(String playerId);

final class GameHoverIntentResolver {
  final GameState state;
  final MapData mapData;
  final bool reduceMotion;
  final PlayerColorResolver colorForPlayer;
  UnitMovementPathfinder? _movementPathfinder;
  String? _movementPathfinderUnitId;

  GameHoverIntentResolver({
    required this.state,
    required this.mapData,
    required this.reduceMotion,
    required this.colorForPlayer,
  });

  bool isStale(HoverIntentKind? kind, {required bool longPressInspectActive}) {
    if (kind == null) return false;
    if (longPressInspectActive && kind == HoverIntentKind.inspect) {
      return false;
    }
    final expectedKind = switch (state.interactionMode) {
      GameInteractionMode.moveTargeting => HoverIntentKind.move,
      GameInteractionMode.attackTargeting => HoverIntentKind.attack,
      GameInteractionMode.cityFounding => HoverIntentKind.founding,
      GameInteractionMode.cityWorkedHexSelection => HoverIntentKind.workedHex,
      GameInteractionMode.cityExpansionSelection => HoverIntentKind.founding,
      GameInteractionMode.workerAction => HoverIntentKind.worker,
      GameInteractionMode.merchantTradeRouteSelection => HoverIntentKind.trade,
      GameInteractionMode.merchantMoveToCitySelection => HoverIntentKind.trade,
      GameInteractionMode.standard => null,
      _ => null,
    };
    return expectedKind == null || kind != expectedKind;
  }

  HoverIntentMarkerSpec? resolve(
    TileData tileData, {
    bool forceInspect = false,
  }) {
    final visibility = state.activePlayerVisibility;
    if (visibility.isEnabled && !visibility.canInspectTile(tileData)) {
      if (forceInspect || !_canShowHiddenMoveIntent()) return null;
    }

    final hex = CityHex(col: tileData.col, row: tileData.row);
    if (forceInspect) {
      return _hoverIntent(hex, HoverIntentKind.inspect, HudPalette.info);
    }

    return switch (state.interactionMode) {
      GameInteractionMode.moveTargeting => _moveHoverIntentForTile(
        tileData,
        hex,
      ),
      GameInteractionMode.attackTargeting => _hoverIntent(
        hex,
        HoverIntentKind.attack,
        HudPalette.danger,
      ),
      GameInteractionMode.cityFounding => _hoverIntent(
        hex,
        HoverIntentKind.founding,
        Color(
          colorForPlayer(
            state.cityFoundingDraft?.ownerPlayerId ?? state.activePlayerId,
          ),
        ),
      ),
      GameInteractionMode.cityWorkedHexSelection => _hoverIntent(
        hex,
        HoverIntentKind.workedHex,
        HudPalette.success,
      ),
      GameInteractionMode.cityExpansionSelection => _hoverIntent(
        hex,
        HoverIntentKind.founding,
        HudPalette.gold,
      ),
      GameInteractionMode.workerAction => _hoverIntent(
        hex,
        HoverIntentKind.worker,
        HudPalette.info,
      ),
      GameInteractionMode.merchantTradeRouteSelection => _hoverIntent(
        hex,
        HoverIntentKind.trade,
        HudPalette.gold,
      ),
      GameInteractionMode.merchantMoveToCitySelection => _hoverIntent(
        hex,
        HoverIntentKind.trade,
        HudPalette.gold,
      ),
      _ => null,
    };
  }

  bool _canShowHiddenMoveIntent() {
    if (state.interactionMode != GameInteractionMode.moveTargeting) {
      return false;
    }
    final unit = state.selectedUnit;
    return unit != null && state.canControlUnit(unit);
  }

  HoverIntentMarkerSpec _hoverIntent(
    CityHex hex,
    HoverIntentKind kind,
    Color color, {
    bool blocked = false,
  }) {
    return HoverIntentMarkerSpec(
      hex: hex,
      kind: kind,
      color: color,
      blocked: blocked,
      reduceMotion: reduceMotion,
    );
  }

  HoverIntentMarkerSpec _moveHoverIntentForTile(
    TileData tileData,
    CityHex hex,
  ) {
    final blocked = _moveTargetBlockedForTile(tileData);
    return _hoverIntent(
      hex,
      HoverIntentKind.move,
      blocked ? HudPalette.danger : HudPalette.gold,
      blocked: blocked,
    );
  }

  bool _moveTargetBlockedForTile(TileData tileData) {
    final unit = state.selectedUnit;
    if (unit == null || unit.occupies(tileData.col, tileData.row)) {
      return false;
    }
    if (UnitMovementCostRules.costToEnterTile(
      tileData,
      unitType: unit.type,
    ).blocked) {
      return true;
    }

    final pathfinder = _pathfinderFor(unit);
    final plan = pathfinder.plan(unit: unit, targetTile: tileData);
    if (plan == null) return true;
    return !UnitMovementFeasibility.canEventuallyTraverse(
      unit: unit,
      plan: plan,
      canEnterStepBeyondCapacity: (step) => _canCarryArtifactIntoTargetCity(
        unit: unit,
        targetTile: tileData,
        step: step,
      ),
    );
  }

  bool _canCarryArtifactIntoTargetCity({
    required GameUnit unit,
    required TileData targetTile,
    required UnitMovementStep step,
  }) {
    if (unit.carriedArtifactId == null) return false;
    if (step.col != targetTile.col || step.row != targetTile.row) {
      return false;
    }
    for (final city in state.cities) {
      if (!city.occupiesCenter(step.col, step.row)) continue;
      return city.ownerPlayerId == unit.ownerPlayerId;
    }
    return false;
  }

  UnitMovementPathfinder _pathfinderFor(GameUnit unit) {
    final cached = _movementPathfinder;
    if (cached != null && _movementPathfinderUnitId == unit.id) {
      return cached;
    }
    final pathfinder = UnitMovementPathfinder(
      mapData: mapData,
      units: state.units,
      canEnterTile: (tile) => UnitMovementVisibilityRules.canPlanThroughTile(
        unit: unit,
        tile: tile,
        visibility: state.activePlayerVisibility,
      ),
    );
    _movementPathfinder = pathfinder;
    _movementPathfinderUnitId = unit.id;
    return pathfinder;
  }
}
