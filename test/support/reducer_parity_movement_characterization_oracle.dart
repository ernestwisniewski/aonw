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
  'movement-characterization-terrain-ocean-land-rejected',
  'movement-characterization-terrain-lake-land-rejected',
  'movement-characterization-terrain-mountain-rejected',
};

const _movementSimpleAcceptedCosts = <String, int>{
  'movement-characterization-fortified-move-accepted': 2,
  'movement-characterization-terrain-plains-accepted': 2,
  'movement-characterization-terrain-desert-accepted': 4,
  'movement-characterization-terrain-tundra-accepted': 4,
  'movement-characterization-terrain-snow-accepted': 6,
  'movement-characterization-terrain-wetlands-accepted': 4,
  'movement-characterization-terrain-forest-accepted': 4,
  'movement-characterization-terrain-jungle-accepted': 4,
  'movement-characterization-terrain-hills-accepted': 4,
  'movement-characterization-terrain-river-accepted': 2,
  'movement-characterization-terrain-coast-land-accepted': 2,
  'movement-characterization-terrain-ocean-naval-accepted': 2,
  'movement-characterization-road-half-point-accepted': 1,
  'movement-characterization-artifact-capacity-accepted': 10,
};

DomainState _movementExpectedState(String fixtureId, DomainState input) {
  if (_movementIdentityStateFixtureIds.contains(fixtureId)) return input;
  if (_movementSimpleAcceptedCosts[fixtureId] case final cost?) {
    final unit = _inputMovementUnit(input);
    final available =
        fixtureId == 'movement-characterization-fortified-move-accepted'
        ? 10
        : unit.movementUnits;
    final remaining = cost >= available ? 0 : available - cost;
    return _movementStateWithUnit(
      input,
      unit
          .copyWith(
            col: 1,
            row: 0,
            movementUnits: remaining,
            posture: UnitPosture.active,
          )
          .copyWithQueuedPath(null),
    );
  }
  return switch (fixtureId) {
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
    'movement-characterization-rough-prefix-exhausted-accepted' =>
      _movementStateWithUnit(
        input,
        _inputMovementUnit(input)
            .copyWith(
              col: 2,
              row: 0,
              movementPoints: 0,
              posture: UnitPosture.active,
            )
            .copyWithQueuedPath(_movementRoughPathToThree),
      ).copyWith(
        fogOfWar: _movementFog(
          discovered: {
            const HexCoordinate(col: 0, row: 0),
            const HexCoordinate(col: 1, row: 0),
            const HexCoordinate(col: 2, row: 0),
            const HexCoordinate(col: 3, row: 0),
          },
          visible: {
            const HexCoordinate(col: 1, row: 0),
            const HexCoordinate(col: 2, row: 0),
            const HexCoordinate(col: 3, row: 0),
          },
        ),
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
  if (_movementSimpleAcceptedCosts.containsKey(fixtureId)) {
    return const [
      UnitMovedEvent(
        unitId: _movementUnitId,
        fromCol: 0,
        fromRow: 0,
        toCol: 1,
        toRow: 0,
      ),
    ];
  }
  return switch (fixtureId) {
    'movement-characterization-partial-queued-accepted' => const [
      UnitMovedEvent(
        unitId: _movementUnitId,
        fromCol: 0,
        fromRow: 0,
        toCol: 2,
        toRow: 0,
      ),
    ],
    'movement-characterization-rough-prefix-exhausted-accepted' => const [
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

List<Map<String, dynamic>> _movementExpectedExecutions(String fixtureId) {
  if (fixtureId == 'movement-characterization-zero-movement-queued-accepted' ||
      _movementIdentityStateFixtureIds.contains(fixtureId)) {
    return const [];
  }
  if (_movementSimpleAcceptedCosts[fixtureId] case final cost?) {
    return [
      _movementExecution([(col: 1, row: 0, cost: cost)]),
    ];
  }
  return switch (fixtureId) {
    'movement-characterization-partial-queued-accepted' => [
      _movementExecution(const [
        (col: 1, row: 0, cost: 2),
        (col: 2, row: 0, cost: 2),
      ]),
    ],
    'movement-characterization-rough-prefix-exhausted-accepted' => [
      _movementExecution(const [
        (col: 1, row: 0, cost: 4),
        (col: 2, row: 0, cost: 4),
      ]),
    ],
    'movement-characterization-contact-discovery-accepted' => [
      _movementExecution(const [(col: 1, row: 0, cost: 2)]),
    ],
    _ => throw StateError('Unknown movement execution oracle id: $fixtureId.'),
  };
}

Map<String, dynamic> _movementExecution(
  List<({int col, int row, int cost})> route,
) {
  var cumulativeCost = 0;
  return {
    'unitId': _movementUnitId,
    'fromCol': 0,
    'fromRow': 0,
    'steps': [
      for (final step in route)
        {
          'col': step.col,
          'row': step.row,
          'enterCost': step.cost,
          'cumulativeCost': cumulativeCost += step.cost,
        },
    ],
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
    UnitMovementStep(col: 1, row: 0, enterCost: 2, cumulativeCost: 2),
    UnitMovementStep(col: 2, row: 0, enterCost: 2, cumulativeCost: 4),
  ],
);

final _movementPathToFour = QueuedMovePath(
  targetCol: 4,
  targetRow: 0,
  steps: const [
    UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
    UnitMovementStep(col: 1, row: 0, enterCost: 2, cumulativeCost: 2),
    UnitMovementStep(col: 2, row: 0, enterCost: 2, cumulativeCost: 4),
    UnitMovementStep(col: 3, row: 0, enterCost: 2, cumulativeCost: 6),
    UnitMovementStep(col: 4, row: 0, enterCost: 2, cumulativeCost: 8),
  ],
);

final _movementRoughPathToThree = QueuedMovePath(
  targetCol: 3,
  targetRow: 0,
  steps: const [
    UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
    UnitMovementStep(col: 1, row: 0, enterCost: 4, cumulativeCost: 4),
    UnitMovementStep(col: 2, row: 0, enterCost: 4, cumulativeCost: 8),
    UnitMovementStep(col: 3, row: 0, enterCost: 2, cumulativeCost: 10),
  ],
);
