part of '../persistent_auto_explore_characterization_test.dart';

void _expectRejectedAutoExplore(
  PersistentUnitActionResult result,
  PersistentGameState input, {
  required String reason,
}) {
  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(result.events, isEmpty);
  expect(result.state, same(input));
  expect(result.state.units, same(input.units));
  expect(result.state.fogOfWar, same(input.fogOfWar));
  expect(result.state.runtimeState, same(input.runtimeState));
  _expectAutoExploreSentinelsShared(input, result.state);
  _expectAutoExploreStateIsImmutable(result.state);
}

void _expectImmediateAutoExplore(
  PersistentUnitActionResult result,
  PersistentGameState input,
) {
  final before = input.units.first;
  final moved = before
      .copyWith(
        col: 1,
        row: 0,
        movementPoints: 2,
        posture: UnitPosture.autoExploring,
      )
      .copyWithQueuedPath(null);
  final expectedFog = _expectedAutoExploreFog(cols: 2);
  final expected = input.copyWith(
    units: _replaceCharacterizedUnit(input.units, moved),
    fogOfWar: expectedFog,
  );

  expect(result.accepted, isTrue);
  expect(result.reason, isNull);
  expect(result.state, expected);
  expect(result.state, isNot(same(input)));
  expect(result.state.units.first, moved);
  expect(result.state.units.first.queuedPath, isNull);
  expect(result.state.fogOfWar, expectedFog);
  _expectAutoExploreMoveEvent(result, fromCol: 0, toCol: 1);
  _expectChangedAutoExploreSharing(input, result.state);
}

void _expectPartialAutoExplore(
  PersistentUnitActionResult result,
  PersistentGameState input,
) {
  final expectedPath = QueuedMovePath(
    targetCol: 4,
    targetRow: 0,
    steps: const [
      UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
      UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
      UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 3),
      UnitMovementStep(col: 4, row: 0, enterCost: 1, cumulativeCost: 4),
    ],
  );
  final moved = input.units.first
      .copyWith(
        col: 1,
        row: 0,
        movementPoints: 0,
        posture: UnitPosture.autoExploring,
      )
      .copyWithQueuedPath(expectedPath);
  final expectedFog = _expectedAutoExploreFog(cols: 4);
  final expected = input.copyWith(
    units: _replaceCharacterizedUnit(input.units, moved),
    fogOfWar: expectedFog,
  );

  expect(result.accepted, isTrue);
  expect(result.reason, isNull);
  expect(result.state, expected);
  expect(result.state.units.first, moved);
  expect(result.state.units.first.queuedPath, expectedPath);
  expect(result.state.fogOfWar, expectedFog);
  _expectAutoExploreMoveEvent(result, fromCol: 0, toCol: 1);
  _expectChangedAutoExploreSharing(
    input,
    result.state,
    expectFogChanged: false,
  );
}

void _expectHiddenAcceptedNoOp(
  PersistentUnitActionResult result,
  PersistentGameState input,
) {
  final exploring = input.units.first
      .copyWith(posture: UnitPosture.autoExploring)
      .copyWithQueuedPath(null);
  final expected = input.copyWith(
    units: _replaceCharacterizedUnit(input.units, exploring),
  );

  expect(result.accepted, isTrue);
  expect(result.reason, isNull);
  expect(result.events, isEmpty);
  expect(result.state, expected);
  expect(result.state, isNot(same(input)));
  expect(result.state.units.first, exploring);
  expect(result.state.units.first.coordinate, input.units.first.coordinate);
  expect(
    result.state.units.first.movementPoints,
    input.units.first.movementPoints,
  );
  expect(result.state.fogOfWar, same(input.fogOfWar));
  expect(result.state.runtimeState, same(input.runtimeState));
  _expectAutoExploreSentinelsShared(input, result.state);
  _expectAutoExploreStateIsImmutable(result.state);
}

List<GameUnit> _replaceCharacterizedUnit(
  List<GameUnit> units,
  GameUnit replacement,
) {
  return [
    for (final unit in units)
      if (unit.id == replacement.id) replacement else unit,
  ];
}

FogOfWarState _expectedAutoExploreFog({required int cols}) {
  final visible = {
    for (var col = 0; col < cols; col++) HexCoordinate(col: col, row: 0),
  };
  return FogOfWarState(
    players: {
      _autoExploreActorId: PlayerFogOfWar(
        playerId: _autoExploreActorId,
        discoveredHexes: visible,
        visibleHexes: visible,
      ),
      _autoExploreSentinelId: _autoExploreSentinelFog,
    },
  );
}

void _expectAutoExploreMoveEvent(
  PersistentUnitActionResult result, {
  required int fromCol,
  required int toCol,
}) {
  expect(result.events, hasLength(1));
  final event = result.events.single;
  expect(event, isA<UnitMovedEvent>());
  final moved = event as UnitMovedEvent;
  expect(moved.unitId, _autoExploreUnitId);
  expect((moved.fromCol, moved.fromRow), (fromCol, 0));
  expect((moved.toCol, moved.toRow), (toCol, 0));
}

void _expectChangedAutoExploreSharing(
  PersistentGameState input,
  PersistentGameState actual, {
  bool expectFogChanged = true,
}) {
  expect(actual.units, isNot(same(input.units)));
  expect(actual.units.first, isNot(same(input.units.first)));
  for (var index = 1; index < input.units.length; index++) {
    expect(actual.units[index], same(input.units[index]));
  }
  expect(
    actual.fogOfWar,
    expectFogChanged ? isNot(same(input.fogOfWar)) : same(input.fogOfWar),
  );
  expect(actual.runtimeState, same(input.runtimeState));
  expect(actual.runtimeState.diplomacy, same(input.runtimeState.diplomacy));
  _expectAutoExploreSentinelsShared(input, actual);
  _expectAutoExploreStateIsImmutable(actual);
}

void _expectAutoExploreSentinelsShared(
  PersistentGameState input,
  PersistentGameState actual,
) {
  expect(input.playerColors, isNotEmpty);
  expect(input.playerCountries, isNotEmpty);
  expect(input.playerGold, isNotEmpty);
  expect(input.playerWarWeariness, isNotEmpty);
  expect(input.playerStabilityNet, isNotEmpty);
  expect(input.cities, isNotEmpty);
  expect(input.artifacts, isNotEmpty);
  expect(input.fieldImprovements, isNotEmpty);
  expect(input.fogOfWar.players, isNotEmpty);
  expect(input.research.players, isNotEmpty);
  expect(input.wonderRegistry.completedBy, isNotEmpty);
  expect(actual.playerColors, same(input.playerColors));
  expect(actual.playerCountries, same(input.playerCountries));
  expect(actual.playerGold, same(input.playerGold));
  expect(actual.playerWarWeariness, same(input.playerWarWeariness));
  expect(actual.playerStabilityNet, same(input.playerStabilityNet));
  expect(actual.cities, same(input.cities));
  expect(actual.artifacts, same(input.artifacts));
  expect(actual.fieldImprovements, same(input.fieldImprovements));
  expect(
    actual.fogOfWar.players[_autoExploreSentinelId],
    same(input.fogOfWar.players[_autoExploreSentinelId]),
  );
  expect(actual.research, same(input.research));
  expect(actual.wonderRegistry, same(input.wonderRegistry));
  _expectAutoExploreRuntimeSentinelsShared(input, actual);
}

void _expectAutoExploreRuntimeSentinelsShared(
  PersistentGameState input,
  PersistentGameState actual,
) {
  final before = input.runtimeState;
  final after = actual.runtimeState;
  expect(before.cityFoundingDraft, isNotNull);
  expect(before.pendingAction, isNotNull);
  expect(before.submittedPlayerIds, isNotEmpty);
  expect(before.timeoutStreaksByPlayerId, isNotEmpty);
  expect(before.afkPlayerIds, isNotEmpty);
  expect(before.kickedPlayerIds, isNotEmpty);
  expect(before.intendedAttacks, isNotEmpty);
  expect(before.diplomacy.isNotEmpty, isTrue);
  expect(before.dominationHoldTurnsByPlayerId, isNotEmpty);
  expect(before.culturalVictoryHoldTurnsByPlayerId, isNotEmpty);
  expect(before.mapObjectiveHoldStatesByObjectiveId, isNotEmpty);
  expect(before.resourceTradeAgreements, isNotEmpty);
  expect(before.turnStartedAt, isNotNull);
  expect(after.cityFoundingDraft, same(before.cityFoundingDraft));
  expect(after.pendingAction, same(before.pendingAction));
  expect(after.submittedPlayerIds, same(before.submittedPlayerIds));
  expect(after.timeoutStreaksByPlayerId, same(before.timeoutStreaksByPlayerId));
  expect(after.afkPlayerIds, same(before.afkPlayerIds));
  expect(after.kickedPlayerIds, same(before.kickedPlayerIds));
  expect(after.intendedAttacks, same(before.intendedAttacks));
  expect(
    after.dominationHoldTurnsByPlayerId,
    same(before.dominationHoldTurnsByPlayerId),
  );
  expect(
    after.culturalVictoryHoldTurnsByPlayerId,
    same(before.culturalVictoryHoldTurnsByPlayerId),
  );
  expect(
    after.mapObjectiveHoldStatesByObjectiveId,
    same(before.mapObjectiveHoldStatesByObjectiveId),
  );
  expect(after.resourceTradeAgreements, same(before.resourceTradeAgreements));
  expect(after.turnStartedAt, before.turnStartedAt);
}

void _expectAutoExploreStateIsImmutable(PersistentGameState state) {
  expect(
    () => state.units.add(_autoExploreSentinelUnit),
    throwsUnsupportedError,
  );
  expect(
    () => state.cities.add(_autoExploreSentinelCity),
    throwsUnsupportedError,
  );
  expect(() => state.playerGold['mutation_probe'] = 1, throwsUnsupportedError);
  expect(
    () => state.runtimeState.submittedPlayerIds.add('mutation_probe'),
    throwsUnsupportedError,
  );
}
