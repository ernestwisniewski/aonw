import 'package:aonw_core/domain.dart';

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

void requireAcceptedProductionQueue({
  required String fixtureId,
  required GameCommand command,
  required PersistentGameState after,
  required List<GameEvent> events,
}) {
  final (cityId, target, failure) = switch (command) {
    StartBuildingCommand(:final cityId, :final buildingType) => (
      cityId,
      BuildingProductionTarget(buildingType),
      'must commit the reviewed building queue',
    ),
    StartUnitProductionCommand(:final cityId, :final unitType) => (
      cityId,
      UnitProductionTarget(unitType),
      'must commit the reviewed unit queue without events',
    ),
    _ => throw StateError('Expected a production command.'),
  };
  if (after.cities.byId(cityId)?.productionQueue?.target != target ||
      command is StartUnitProductionCommand && events.isNotEmpty) {
    throw FormatException('$fixtureId $failure.');
  }
}

String? validateAcceptedDetachment({
  required DetachTroopCommand command,
  required PersistentGameState before,
  required PersistentGameState after,
  required String actorPlayerId,
  required List<GameEvent> events,
}) {
  final sourceBefore = before.units.byId(command.unitId);
  final sourceAfter = after.units.byId(command.unitId);
  final previousUnitIds = before.units.map((unit) => unit.id).toSet();
  final addedUnits = after.units
      .where((unit) => !previousUnitIds.contains(unit.id))
      .toList(growable: false);
  if (sourceBefore == null || sourceAfter == null || addedUnits.length != 1) {
    return 'must retain the source and add exactly one detached unit';
  }

  final expectedState = before.copyWith(
    units: after.units,
    fogOfWar: after.fogOfWar,
    runtimeState: before.runtimeState.copyWith(
      diplomacy: after.runtimeState.diplomacy,
    ),
  );
  if ((sourceAfter, after.units.length, after, events.isEmpty) !=
      (
        sourceBefore.detachTroop(command.troopType),
        before.units.length + 1,
        expectedState,
        true,
      )) {
    return 'must change only units, fog, and discovered diplomacy';
  }

  final detached = addedUnits.single;
  final destination = detached.coordinate;
  final expectedDetached = GameUnit(
    id: '${sourceBefore.id}_${command.troopType.name}_1',
    ownerPlayerId: actorPlayerId,
    type: command.troopType.detachedUnitType,
    name: command.troopType.detachedUnitNameToken,
    col: detached.col,
    row: detached.row,
    movementPoints: UnitMovementBalance.maxMovementPointsForType(
      command.troopType.detachedUnitType,
    ),
  );
  final initiallyVisible = before.fogOfWar.isVisible(
    actorPlayerId,
    destination,
  );
  final adjacent = HexGridTopology.areNeighbors(
    col: sourceBefore.col,
    row: sourceBefore.row,
    targetCol: detached.col,
    targetRow: detached.row,
  );
  if ((detached, initiallyVisible, adjacent) !=
      (expectedDetached, true, true)) {
    return 'must create the reviewed troop on a visible adjacent hex';
  }

  final visibleBefore = before.fogOfWar
      .fogForPlayer(actorPlayerId)
      .visibleHexes;
  final visibleAfter = after.fogOfWar.fogForPlayer(actorPlayerId).visibleHexes;
  final newlyVisible = visibleAfter.difference(visibleBefore);
  if ((!visibleAfter.containsAll(visibleBefore), newlyVisible.length) !=
      (false, 1)) {
    return 'must preserve visibility and reveal exactly one new hex';
  }

  return _validateDiscoveredContact(
    actorPlayerId: actorPlayerId,
    before: before,
    after: after,
    newlyVisible: newlyVisible,
  );
}

String? _validateDiscoveredContact({
  required String actorPlayerId,
  required PersistentGameState before,
  required PersistentGameState after,
  required Set<HexCoordinate> newlyVisible,
}) {
  final contactedPlayers = <String>{
    for (final unit in after.units)
      if (unit.ownerPlayerId != actorPlayerId &&
          newlyVisible.contains(unit.coordinate))
        unit.ownerPlayerId,
    for (final city in after.cities)
      if (city.ownerPlayerId != actorPlayerId &&
          newlyVisible.contains(city.center.toCoordinate()))
        city.ownerPlayerId,
  }..removeWhere((playerId) => playerId.isEmpty);
  final expectedDiplomacy = DiplomaticContact.mergeDiscoveredContacts(
    diplomacy: before.runtimeState.diplomacy,
    fogOfWar: after.fogOfWar,
    units: after.units,
    cities: after.cities,
    playerIds: before.knownPlayerIds,
  );
  if ((contactedPlayers.length, after.runtimeState.diplomacy) !=
      (1, expectedDiplomacy)) {
    return 'must discover exactly one opponent and merge diplomatic contact';
  }
  final contactedPlayerId = contactedPlayers.single;
  if (before.runtimeState.diplomacy.hasContact(
        actorPlayerId,
        contactedPlayerId,
      ) ||
      !after.runtimeState.diplomacy.hasContact(
        actorPlayerId,
        contactedPlayerId,
      )) {
    return 'must add the newly visible opponent contact';
  }
  return null;
}
