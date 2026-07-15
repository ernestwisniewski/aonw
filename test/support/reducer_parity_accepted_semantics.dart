import 'package:aonw_core/domain.dart';

void requireAcceptedRichTurnFinalization(
  String fixtureId,
  PersistentGameState before,
  PersistentGameState after,
  List<GameEvent> events,
) {
  if (fixtureId != 'turn-rich-map-finalization-accepted') return;
  final hold = after
      .runtimeState
      .mapObjectiveHoldStatesByObjectiveId['strategic_pass_1'];
  final objectiveEvents = events.whereType<MapObjectiveSecuredEvent>().toList();
  final objective = objectiveEvents.singleOrNull;
  if ((
        hold?.playerId,
        hold?.holdTurns,
        objective?.playerId,
        objective?.objectiveId,
        objective?.goldPerTurn,
        (after.playerGold['player_1'] ?? 0) -
            (before.playerGold['player_1'] ?? 0),
      ) !=
      ('player_1', 2, 'player_1', 'strategic_pass_1', 4, 4)) {
    throw FormatException(
      '$fixtureId must secure the reviewed objective and its gold reward.',
    );
  }

  final research = after.research.forPlayer('player_1');
  final discoveries = events
      .whereType<StrategicResourceDiscoveredEvent>()
      .toList();
  final discovery = discoveries.singleOrNull;
  if ((
        !research.hasUnlocked(TechnologyId.animalHusbandry),
        research.activeTechnologyId,
        discovery?.resourceType,
        discovery?.controlledCount,
      ) !=
      (false, null, ResourceType.horses, 1)) {
    throw FormatException(
      '$fixtureId must finish research and reveal the controlled horses.',
    );
  }

  final improvements = after.fieldImprovements
      .where((value) => value.builtByCityId == 'city_1')
      .toList();
  final improvement = improvements.singleOrNull;
  if ((
        before.units.byId('worker_1')?.workerJob?.remainingTurns,
        after.units.byId('worker_1'),
        improvement?.hex,
        improvement?.type,
      ) !=
      (1, null, const CityHex(col: 0, row: 1), FieldImprovementType.farm)) {
    throw FormatException(
      '$fixtureId must complete the reviewed worker improvement.',
    );
  }

  final foodBefore = before.cities.byId('city_1')?.storedFood;
  final foodAfter = after.cities.byId('city_1')?.storedFood;
  if (foodBefore == null || foodAfter == null || foodAfter <= foodBefore) {
    throw FormatException('$fixtureId must advance the reviewed city economy.');
  }
}

void requireAcceptedTurnSubmission({
  required String fixtureId,
  required SubmitTurnCommand command,
  required int inputTurn,
  required Iterable<String> playerIds,
  required Object? expectedTurn,
  required Map<String, dynamic> expectedPlayerStates,
  required PersistentGameState before,
  required PersistentGameState after,
  required DateTime now,
  required List<GameEvent> events,
}) {
  if (expectedTurn == inputTurn) {
    if (!after.runtimeState.hasSubmitted(command.playerId) ||
        expectedPlayerStates[command.playerId] != 'finished' ||
        events.isNotEmpty) {
      throw FormatException(
        '$fixtureId must commit the reviewed waiting submission.',
      );
    }
    return;
  }

  final expectedPlayerIds = playerIds.toList()..sort();
  final allSubmitted = events.whereType<AllPlayersSubmittedEvent>().toList();
  final turnEndedIds = events
      .whereType<TurnEndedEvent>()
      .map((event) => event.playerId)
      .toList();
  if (expectedTurn != inputTurn + 1 ||
      after.runtimeState.submittedPlayerIds.isNotEmpty ||
      after.runtimeState.turnStartedAt != now ||
      expectedPlayerStates.values.any((value) => value != 'active') ||
      allSubmitted.length != 1 ||
      !_sameOrderedValues(allSubmitted.single.playerIds, expectedPlayerIds) ||
      !_sameOrderedValues(turnEndedIds, expectedPlayerIds)) {
    throw FormatException(
      '$fixtureId must commit the reviewed simultaneous turn.',
    );
  }
  requireAcceptedRichTurnFinalization(fixtureId, before, after, events);
}

bool _sameOrderedValues<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

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

void requireAcceptedCombat(
  String fixtureId,
  String attackerUnitId,
  PersistentGameState after,
  List<GameEvent> events,
) {
  final attacker = after.units.byId(attackerUnitId);
  if ((
        attacker?.movementPoints,
        events.whereType<UnitAttackedEvent>().length,
        events.whereType<CombatResolvedEvent>().length,
      ) !=
      (0, 1, 1)) {
    throw FormatException(
      '$fixtureId must commit deterministic instant combat.',
    );
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
