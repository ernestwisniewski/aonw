part of 'reducer_parity_movement_characterization.dart';

const _movementIdentityStateFixtureIds = <String>{
  'movement-characterization-hidden-target-no-op-accepted',
  'movement-characterization-hidden-intermediate-no-op-accepted',
  'movement-characterization-hidden-city-no-op-accepted',
  'movement-characterization-unit-missing-rejected',
  'movement-characterization-unit-working-rejected',
  'movement-characterization-merchant-rejected',
  'movement-characterization-current-tile-rejected',
  'movement-characterization-foreign-city-rejected',
  'movement-characterization-visible-occupied-rejected',
  'movement-characterization-path-not-found-rejected',
  'movement-characterization-capacity-rejected',
  'movement-characterization-invalid-origin-rejected',
  'movement-characterization-far-hidden-rejected',
  'movement-characterization-no-fog-occupied-rejected',
};

DomainState _movementExpectedState(String fixtureId, DomainState input) {
  if (_movementIdentityStateFixtureIds.contains(fixtureId)) return input;
  return switch (fixtureId) {
    'movement-characterization-fortified-move-accepted' =>
      _movementStateWithUnit(
        input,
        _inputMovementUnit(input)
            .copyWith(
              col: 1,
              row: 0,
              movementPoints:
                  UnitMovementBalance.maxMovementPointsForType(
                    _inputMovementUnit(input).type,
                  ) -
                  1,
              posture: UnitPosture.active,
            )
            .copyWithQueuedPath(null),
      ),
    'movement-characterization-partial-queued-accepted' =>
      _movementStateWithUnit(
        input,
        _inputMovementUnit(input)
            .copyWith(
              col: 2,
              row: 0,
              movementPoints: 0,
              posture: UnitPosture.active,
            )
            .copyWithQueuedPath(_movementPathToFour),
      ),
    'movement-characterization-zero-movement-queued-accepted' =>
      _movementStateWithUnit(
        input,
        _inputMovementUnit(input)
            .copyWith(posture: UnitPosture.active)
            .copyWithQueuedPath(_movementPathToTwo),
      ),
    'movement-characterization-contact-discovery-accepted' =>
      _contactDiscoveryExpectedState(input),
    _ => throw StateError('Unknown movement oracle id: $fixtureId.'),
  };
}

List<GameEvent> _movementExpectedEvents(String fixtureId) {
  if (fixtureId == 'movement-characterization-zero-movement-queued-accepted' ||
      _movementIdentityStateFixtureIds.contains(fixtureId)) {
    return const [];
  }
  return switch (fixtureId) {
    'movement-characterization-fortified-move-accepted' => const [
      UnitMovedEvent(
        unitId: _movementUnitId,
        fromCol: 0,
        fromRow: 0,
        toCol: 1,
        toRow: 0,
      ),
    ],
    'movement-characterization-partial-queued-accepted' => const [
      UnitMovedEvent(
        unitId: _movementUnitId,
        fromCol: 0,
        fromRow: 0,
        toCol: 2,
        toRow: 0,
      ),
    ],
    'movement-characterization-contact-discovery-accepted' => const [
      UnitMovedEvent(
        unitId: _movementUnitId,
        fromCol: 0,
        fromRow: 0,
        toCol: 1,
        toRow: 0,
      ),
    ],
    _ => throw StateError('Unknown movement event oracle id: $fixtureId.'),
  };
}

DomainState _contactDiscoveryExpectedState(DomainState input) {
  final moved = _inputMovementUnit(input)
      .copyWith(col: 1, row: 0, movementPoints: 4, posture: UnitPosture.active)
      .copyWithQueuedPath(null);
  final fog = FogOfWarState(
    players: {
      _movementActorId: PlayerFogOfWar(
        playerId: _movementActorId,
        discoveredHexes: {
          const HexCoordinate(col: 0, row: 0),
          const HexCoordinate(col: 1, row: 0),
          const HexCoordinate(col: 2, row: 0),
          const HexCoordinate(col: 3, row: 0),
        },
        visibleHexes: {
          const HexCoordinate(col: 0, row: 0),
          const HexCoordinate(col: 1, row: 0),
          const HexCoordinate(col: 2, row: 0),
          const HexCoordinate(col: 3, row: 0),
        },
      ),
    },
  );
  final diplomacy = DiplomacyState(contactKeys: const {'player_1|player_2'});
  return _movementStateWithUnit(
    input,
    moved,
  ).copyWith(fogOfWar: fog, diplomacy: diplomacy);
}

DomainState _movementStateWithUnit(DomainState state, GameUnit replacement) {
  return state.copyWith(
    units: [
      for (final unit in state.units)
        if (unit.id == replacement.id) replacement else unit,
    ],
  );
}

GameUnit _inputMovementUnit(DomainState state) {
  return state.units.singleWhere((unit) => unit.id == _movementUnitId);
}

final _movementPathToTwo = QueuedMovePath(
  targetCol: 2,
  targetRow: 0,
  steps: const [
    UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
    UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
    UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
  ],
);

final _movementPathToFour = QueuedMovePath(
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
