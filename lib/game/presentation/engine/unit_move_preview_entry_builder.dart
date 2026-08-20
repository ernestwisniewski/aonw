import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_move_preview_layer.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/transport.dart';
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
        availableMovementUnits: unit.movementUnits,
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
      availableMovementUnits: unit.movementUnits,
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

  static int maxMovementUnits(GameUnit unit) {
    return UnitMovementBalance.maxMovementUnitsFor(
      type: unit.type,
      carriedArtifactId: unit.carriedArtifactId,
    );
  }

  static Set<int> roadSegmentIndicesFor({
    required GameClientState state,
    required GameUnitType? unitType,
    required List<UnitMovementStep> steps,
  }) {
    if (unitType?.movementDomain != UnitMovementDomain.land ||
        steps.length < 2) {
      return const {};
    }

    final knownNetwork = TransportNetworkVisibilityRules.knownFor(
      network: state.transportNetwork,
      playerId: state.activePlayerId,
      ownCityIds: [
        for (final city in state.cities)
          if (city.ownerPlayerId == state.activePlayerId) city.id,
      ],
      visibility: state.activePlayerVisibility,
    );
    final roadNetwork = TransportNetworkIndex(knownNetwork);
    final cityCenters = <HexCoordinate>{
      for (final city in state.citiesKnownToActivePlayer)
        city.center.toCoordinate(),
    };
    return Set.unmodifiable({
      for (var index = 1; index < steps.length; index++)
        if (roadNetwork.hasOperationalRoadEdge(
          fromCol: steps[index - 1].col,
          fromRow: steps[index - 1].row,
          toCol: steps[index].col,
          toRow: steps[index].row,
          cityCenters: cityCenters,
        ))
          index,
    });
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
  }) {
    final selected = state.selectedUnitId == unit.id;
    return UnitMovePreviewLayerEntry(
      id: id,
      preview: plan,
      displaySteps: displaySteps,
      travelledUpToIndex: travelled,
      roadSegmentIndices: roadSegmentIndicesFor(
        state: state,
        unitType: unit.type,
        steps: displaySteps,
      ),
      unitType: unit.type,
      maxMovementPointsPerTurn: maxMovementUnits(unit),
      dimmed: dimmed,
      subdued: !selected,
      showCostLabel: showCostLabel,
      showTargetOutline: selected,
    );
  }
}
