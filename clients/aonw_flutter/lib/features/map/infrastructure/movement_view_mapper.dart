import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';
import '../read_model/player_map_view.dart';

final class MovementViewMapper {
  const MovementViewMapper();

  ReachableView reachable(
    AonwReachableResult wire, {
    required MapView map,
    required String expectedUnitId,
    required int expectedRevision,
  }) {
    _validateStamp(wire.stamp, map: map, expectedRevision: expectedRevision);
    if (wire.unitId != expectedUnitId) {
      throw const FormatException('Reachable result belongs to another unit.');
    }
    final coordinates = <MapHexCoordinate>{};
    final tiles = <ReachableTileView>[];
    MapHexCoordinate? previous;
    for (final tile in wire.tiles) {
      final coordinate = _coordinate(tile.coordinate);
      if (!map.contains(coordinate) || !coordinates.add(coordinate)) {
        throw const FormatException(
          'Reachable result has invalid tile coverage.',
        );
      }
      if (previous != null && _rowMajorCompare(previous, coordinate) >= 0) {
        throw const FormatException('Reachable result order is unstable.');
      }
      tiles.add(
        ReachableTileView(
          coordinate: coordinate,
          costUnits: tile.costUnits,
          exhaustsMovement: tile.exhaustsMovement,
        ),
      );
      previous = coordinate;
    }
    return ReachableView(
      stamp: _stamp(wire.stamp),
      unitId: wire.unitId,
      availableMovementUnits: wire.availableMovementUnits,
      tiles: tiles,
    );
  }

  RoutePlanView routePlan(
    AonwRoutePlanResult wire, {
    required MapView map,
    required VisibleUnitView unit,
    required MapHexCoordinate expectedTarget,
    required int expectedRevision,
  }) {
    _validateStamp(wire.stamp, map: map, expectedRevision: expectedRevision);
    final target = _coordinate(wire.target);
    final destination = _coordinate(wire.destination);
    _validateRouteIdentity(
      wire,
      map: map,
      unit: unit,
      target: target,
      destination: destination,
      expectedTarget: expectedTarget,
    );
    final steps = _routeSteps(wire.steps, map);
    _validateRouteEndpoints(
      steps,
      origin: unit.coordinate,
      destination: destination,
      totalCostUnits: wire.totalCostUnits,
    );
    return RoutePlanView(
      stamp: _stamp(wire.stamp),
      unitId: wire.unitId,
      target: target,
      destination: destination,
      totalCostUnits: wire.totalCostUnits,
      availableMovementUnits: wire.availableMovementUnits,
      remainingMovementUnits: wire.remainingMovementUnits,
      steps: steps,
    );
  }

  static List<MovementStepView> _routeSteps(
    List<AonwMovementStep> wire,
    MapView map,
  ) {
    final steps = <MovementStepView>[];
    var previousCost = -1;
    for (final step in wire) {
      final coordinate = _coordinate(step.coordinate);
      if (!map.contains(coordinate) ||
          step.cumulativeCostUnits < previousCost) {
        throw const FormatException('Route result contains invalid steps.');
      }
      steps.add(
        MovementStepView(
          coordinate: coordinate,
          enterCostUnits: step.enterCostUnits,
          cumulativeCostUnits: step.cumulativeCostUnits,
        ),
      );
      previousCost = step.cumulativeCostUnits;
    }
    return steps;
  }

  static void _validateRouteIdentity(
    AonwRoutePlanResult wire, {
    required MapView map,
    required VisibleUnitView unit,
    required MapHexCoordinate target,
    required MapHexCoordinate destination,
    required MapHexCoordinate expectedTarget,
  }) {
    if (wire.unitId != unit.id || target != expectedTarget) {
      throw const FormatException('Route result belongs to another request.');
    }
    if (!map.contains(target) || !map.contains(destination)) {
      throw const FormatException('Route result is outside the map.');
    }
  }

  static void _validateRouteEndpoints(
    List<MovementStepView> steps, {
    required MapHexCoordinate origin,
    required MapHexCoordinate destination,
    required int totalCostUnits,
  }) {
    if (steps.isEmpty ||
        steps.first.coordinate != origin ||
        steps.first.enterCostUnits != 0 ||
        steps.first.cumulativeCostUnits != 0 ||
        steps.last.coordinate != destination ||
        steps.last.cumulativeCostUnits != totalCostUnits) {
      throw const FormatException('Route result endpoints are inconsistent.');
    }
  }

  void validateCommand(
    AonwCommandResult wire, {
    required MapView map,
    required String expectedUnitId,
    required int expectedRevision,
  }) {
    final nextRevision = wire.accepted
        ? expectedRevision + 1
        : expectedRevision;
    _validateStamp(wire.stamp, map: map, expectedRevision: nextRevision);
    if (wire.accepted) {
      final evidence = wire.evidence;
      if (evidence != null &&
          (evidence is! AonwUnitMovementEvidence ||
              evidence.unitId != expectedUnitId)) {
        throw const FormatException(
          'Accepted move has inconsistent movement evidence.',
        );
      }
    } else if (wire.rejection == null || wire.rejection!.isEmpty) {
      throw const FormatException('Rejected move has no rejection code.');
    }
  }

  static MapHexCoordinate _coordinate(AonwCoordinate value) =>
      (col: value.col, row: value.row);

  static int _rowMajorCompare(MapHexCoordinate left, MapHexCoordinate right) {
    final row = left.row.compareTo(right.row);
    return row != 0 ? row : left.col.compareTo(right.col);
  }

  static void _validateStamp(
    AonwSessionStamp value, {
    required MapView map,
    required int expectedRevision,
  }) {
    final digest = RegExp(r'^[0-9a-f]{64}$');
    if (!digest.hasMatch(value.stateDigest) ||
        !digest.hasMatch(value.mapHash) ||
        !digest.hasMatch(value.rulesetHash) ||
        value.mapHash != map.contentHash ||
        value.revision != expectedRevision) {
      throw const FormatException('Session response identity is stale.');
    }
  }

  static SessionStampView _stamp(AonwSessionStamp value) => SessionStampView(
    behaviorVersion: value.behaviorVersion,
    revision: value.revision,
    stateDigest: value.stateDigest,
    mapHash: value.mapHash,
    rulesetHash: value.rulesetHash,
  );
}
