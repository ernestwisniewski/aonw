import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_move_preview.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_move_preview_layer.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class UnitMovePreviewEntryBuilder {
  static UnitMovePreviewLayerEntry? queuedPath({
    required GameClientState state,
    required GameUnit unit,
    required bool dimmed,
  }) {
    if (!state.canControlUnit(unit)) return null;
    final tradeRoute = unit.merchantTradeRoute;
    if (tradeRoute != null && tradeRoute.steps.length >= 2) {
      final travelled = _travelledIndex(tradeRoute.steps, unit);
      if (travelled < 0) return null;
      final plan = UnitMovementPlan(
        unitId: unit.id,
        targetCol: tradeRoute.targetCol,
        targetRow: tradeRoute.targetRow,
        totalCost: tradeRoute.steps.last.cumulativeCost,
        availableMovementPoints: unit.movementPoints,
        steps: tradeRoute.steps,
      ).remainingFromStepIndex(travelled);
      return _entry(
        id: 'trade:${unit.id}',
        state: state,
        unit: unit,
        plan: plan,
        displaySteps: tradeRoute.steps,
        travelled: travelled,
        dimmed: dimmed,
        routeKind: UnitMovePreviewRouteKind.trade,
        showCostLabel: false,
      );
    }

    final queued = unit.queuedPath;
    if (queued == null || queued.steps.length < 2) return null;
    final travelled = _travelledIndex(queued.steps, unit);
    if (travelled < 0) return null;
    final plan = UnitMovementPlan(
      unitId: unit.id,
      targetCol: queued.targetCol,
      targetRow: queued.targetRow,
      totalCost: queued.steps.last.cumulativeCost,
      availableMovementPoints: unit.movementPoints,
      canSpendTurnEnteringFirstStep: unit.movementPoints > 0,
      steps: queued.steps,
    ).remainingFromStepIndex(travelled);
    return _entry(
      id: 'queued:${unit.id}',
      state: state,
      unit: unit,
      plan: plan,
      displaySteps: queued.steps,
      travelled: travelled,
      dimmed: dimmed,
      showCostLabel: state.selectedUnitId == unit.id,
    );
  }

  static int maxMovementPoints(GameUnit unit) {
    return UnitMovementBalance.maxMovementPointsFor(
      type: unit.type,
      carriedArtifactId: unit.carriedArtifactId,
    );
  }

  static int _travelledIndex(List<UnitMovementStep> steps, GameUnit unit) {
    return steps.indexWhere(
      (step) => step.col == unit.col && step.row == unit.row,
    );
  }

  static UnitMovePreviewLayerEntry _entry({
    required String id,
    required GameClientState state,
    required GameUnit unit,
    required UnitMovementPlan plan,
    required List<UnitMovementStep> displaySteps,
    required int travelled,
    required bool dimmed,
    required bool showCostLabel,
    UnitMovePreviewRouteKind routeKind = UnitMovePreviewRouteKind.movement,
  }) {
    final selected = state.selectedUnitId == unit.id;
    return UnitMovePreviewLayerEntry(
      id: id,
      preview: plan,
      displaySteps: displaySteps,
      travelledUpToIndex: travelled,
      unitType: unit.type,
      maxMovementPointsPerTurn: maxMovementPoints(unit),
      routeKind: routeKind,
      dimmed: dimmed,
      subdued: !selected,
      showCostLabel: showCostLabel,
      showConfirmedTarget: selected,
    );
  }
}
