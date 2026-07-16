part of 'reducer_parity_accepted_semantics.dart';

void requireAcceptedUnitAction({
  required String fixtureId,
  required GameCommand command,
  required PersistentGameState before,
  required PersistentGameState after,
  required List<GameEvent> events,
}) {
  if (command is AssignMerchantTradeRouteCommand ||
      command is MoveMerchantToCityCommand) {
    requireAcceptedMerchantRouting(
      fixtureId: fixtureId,
      command: command,
      before: before,
      after: after,
      events: events,
    );
    return;
  }
  final failure = switch (command) {
    final AutoExploreUnitCommand command => validateAcceptedAutoExplore(
      command: command,
      before: before,
      after: after,
      events: events,
    ),
    final MoveUnitCommand command => validateAcceptedMovement(
      command: command,
      after: after,
      events: events,
    ),
    _ => throw StateError('Expected a unit movement command.'),
  };
  if (failure != null) throw FormatException('$fixtureId $failure.');
}

String? validateAcceptedAutoExplore({
  required AutoExploreUnitCommand command,
  required PersistentGameState before,
  required PersistentGameState after,
  required List<GameEvent> events,
}) {
  final unitBefore = before.units.byId(command.unitId);
  final unitAfter = after.units.byId(command.unitId);
  final movements = events.whereType<UnitMovedEvent>().toList(growable: false);
  if (unitBefore == null ||
      unitAfter == null ||
      unitAfter.posture != UnitPosture.autoExploring ||
      unitAfter.coordinate == unitBefore.coordinate ||
      unitAfter.movementPoints >= unitBefore.movementPoints ||
      movements.length != 1) {
    return 'must move the reviewed scout and retain auto-explore posture';
  }
  final movement = movements.single;
  if ((movement.unitId, movement.fromCol, movement.fromRow) !=
          (unitBefore.id, unitBefore.col, unitBefore.row) ||
      (movement.toCol, movement.toRow) != (unitAfter.col, unitAfter.row)) {
    return 'must commit one movement event matching the explored scout';
  }
  return null;
}

String? validateAcceptedMovement({
  required MoveUnitCommand command,
  required PersistentGameState after,
  required List<GameEvent> events,
}) {
  final unit = after.units.byId(command.unitId);
  final movedCount = events.whereType<UnitMovedEvent>().length;
  if ((unit?.col, unit?.row, movedCount) !=
      (command.targetCol, command.targetRow, 1)) {
    return 'must commit the reviewed movement and event';
  }
  return null;
}

void requireAcceptedMerchantRouting({
  required String fixtureId,
  required GameCommand command,
  required PersistentGameState before,
  required PersistentGameState after,
  required List<GameEvent> events,
}) {
  final (unitId, destinationCityId) = switch (command) {
    AssignMerchantTradeRouteCommand(:final unitId, :final destinationCityId) =>
      (unitId, destinationCityId),
    MoveMerchantToCityCommand(:final unitId, :final destinationCityId) => (
      unitId,
      destinationCityId,
    ),
    _ => throw StateError('Expected a merchant routing command.'),
  };
  final beforeMerchant = before.units.byId(unitId);
  final afterMerchant = after.units.byId(unitId);
  final destination = before.cities.byId(destinationCityId);
  if ((
        beforeMerchant == null,
        afterMerchant == null,
        destination == null,
        events.isEmpty,
        after,
      ) !=
      (false, false, false, true, before.copyWith(units: after.units))) {
    throw FormatException(
      '$fixtureId must change only units and emit no events.',
    );
  }

  switch (command) {
    case AssignMerchantTradeRouteCommand():
      _requireAcceptedAssignedMerchantRoute(
        fixtureId: fixtureId,
        before: before,
        beforeMerchant: beforeMerchant!,
        afterMerchant: afterMerchant!,
        destination: destination!,
      );
    case MoveMerchantToCityCommand():
      _requireAcceptedMerchantCityPath(
        fixtureId: fixtureId,
        beforeMerchant: beforeMerchant!,
        afterMerchant: afterMerchant!,
        destination: destination!,
      );
    default:
      throw StateError('Expected a merchant routing command.');
  }
}

void _requireAcceptedAssignedMerchantRoute({
  required String fixtureId,
  required PersistentGameState before,
  required GameUnit beforeMerchant,
  required GameUnit afterMerchant,
  required GameCity destination,
}) {
  final route = afterMerchant.merchantTradeRoute;
  final origin = before.cities.cityAt(beforeMerchant.col, beforeMerchant.row);
  if ((
        afterMerchant.queuedPath,
        route?.originCityId,
        route?.destinationCityId,
        _firstStepCoord(route?.steps),
        _lastStepCoord(route?.steps),
      ) !=
      (
        null,
        origin?.id,
        destination.id,
        beforeMerchant.coordinate.toRecord(),
        destination.center.coordinate.toRecord(),
      )) {
    throw FormatException(
      '$fixtureId must commit the reviewed round-trip trade route.',
    );
  }
}

void _requireAcceptedMerchantCityPath({
  required String fixtureId,
  required GameUnit beforeMerchant,
  required GameUnit afterMerchant,
  required GameCity destination,
}) {
  final path = afterMerchant.queuedPath;
  if ((
        afterMerchant.merchantTradeRoute,
        path?.targetCol,
        path?.targetRow,
        _firstStepCoord(path?.steps),
        _lastStepCoord(path?.steps),
      ) !=
      (
        null,
        destination.center.col,
        destination.center.row,
        beforeMerchant.coordinate.toRecord(),
        destination.center.coordinate.toRecord(),
      )) {
    throw FormatException(
      '$fixtureId must commit the reviewed queued city path.',
    );
  }
}

({int col, int row})? _firstStepCoord(List<UnitMovementStep>? steps) {
  if (steps == null || steps.isEmpty) return null;
  return steps.first.coord;
}

({int col, int row})? _lastStepCoord(List<UnitMovementStep>? steps) {
  if (steps == null || steps.isEmpty) return null;
  return steps.last.coord;
}
