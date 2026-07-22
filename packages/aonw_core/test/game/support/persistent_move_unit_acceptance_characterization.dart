part of '../persistent_move_unit_resolver_characterization_test.dart';

void _registerMoveAcceptanceCharacterizationTests() {
  group('accepted move state transitions', () {
    _registerImmediateAndPartialMoveTests();
    _registerQueuedAndHiddenMoveTests();
    _registerExceptionalAcceptedMoveTests();
  });
}

void _registerImmediateAndPartialMoveTests() {
  test('immediate movement updates exact slices and emits one event', () {
    final state = _moveState(units: [_moveUnit()]);

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 1, 0),
      _movementMap(cols: 3),
    );

    expect(result.accepted, isTrue);
    expect(result.reason, isNull);
    expect(result.state.units.first, _moveUnit(col: 1, movementPoints: 4));
    expect(
      result.state.fogOfWar,
      _expectedActorFog(const [
        (col: 0, row: 0),
        (col: 1, row: 0),
        (col: 2, row: 0),
      ]),
    );
    _expectMoveEvent(result, fromCol: 0, toCol: 1);
    _expectMovedStateSharing(state, result, diplomacyChanged: false);
  });

  test('partial movement queues the complete remaining intent', () {
    final state = _moveState(units: [_moveUnit(movementPoints: 2)]);

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 4, 0),
      _movementMap(cols: 5),
    );

    final moved = result.state.units.first;
    expect(result.accepted, isTrue);
    expect(result.reason, isNull);
    expect(moved.col, 2);
    expect(moved.row, 0);
    expect(moved.movementPoints, 0);
    expect(moved.posture, UnitPosture.active);
    expect(
      moved.queuedPath,
      QueuedMovePath(
        targetCol: 4,
        targetRow: 0,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
          UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 3),
          UnitMovementStep(col: 4, row: 0, enterCost: 1, cumulativeCost: 4),
        ],
      ),
    );
    expect(
      result.state.fogOfWar,
      _expectedActorFog(const [
        (col: 0, row: 0),
        (col: 1, row: 0),
        (col: 2, row: 0),
        (col: 3, row: 0),
        (col: 4, row: 0),
      ]),
    );
    _expectMoveEvent(result, fromCol: 0, toCol: 2);
    _expectMovedStateSharing(state, result, diplomacyChanged: false);
  });
}

void _registerQueuedAndHiddenMoveTests() {
  test('zero movement points queue an immutable path without moving', () {
    final state = _moveState(units: [_moveUnit(movementPoints: 0)]);

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 2, 0),
      _movementMap(cols: 3),
    );

    final queued = result.state.units.first;
    expect(result.accepted, isTrue);
    expect(result.reason, isNull);
    expect(result.events, isEmpty);
    expect(queued.col, 0);
    expect(queued.row, 0);
    expect(queued.movementPoints, 0);
    expect(queued.posture, UnitPosture.active);
    expect(queued.queuedPath?.targetCol, 2);
    expect(queued.queuedPath?.targetRow, 0);
    expect(queued.queuedPath?.steps, const [
      UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
      UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
    ]);
    expect(
      () => queued.queuedPath!.steps.add(
        const UnitMovementStep(col: 9, row: 9, enterCost: 1, cumulativeCost: 3),
      ),
      throwsUnsupportedError,
    );
    expect(result.state, isNot(same(state)));
    expect(result.state.units, isNot(same(state.units)));
    expect(result.state.units.first, isNot(same(state.units.first)));
    expect(result.state.units.last, same(state.units.last));
    expect(result.state.fogOfWar, same(state.fogOfWar));
    expect(result.state.runtimeState, same(state.runtimeState));
    _expectOuterMovementSentinelsShared(state, result.state);
    _expectRuntimeMovementSentinelsShared(state, result.state);
    _expectMovementStateIsImmutable(result.state);
    expect(state.units.first.queuedPath, isNull);
  });

  test('occupied target uses the exact approach plan and queues remainder', () {
    final state = _moveState(
      units: [
        _moveUnit(movementPoints: 2),
        _moveUnit(id: 'friendly_blocker', col: 4),
      ],
    );

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 4, 0),
      _movementMap(cols: 5),
    );

    expect(result.accepted, isTrue);
    expect(result.reason, isNull);
    expect(
      result.state.units.first,
      _moveUnit(
        col: 2,
        movementPoints: 0,
        queuedPath: QueuedMovePath(
          targetCol: 3,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
            UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
            UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 3),
          ],
        ),
      ),
    );
    expect(
      result.state.fogOfWar,
      _expectedActorFog(const [
        (col: 0, row: 0),
        (col: 1, row: 0),
        (col: 2, row: 0),
        (col: 3, row: 0),
        (col: 4, row: 0),
      ]),
    );
    _expectMoveEvent(result, fromCol: 0, toCol: 2);
    _expectMovedStateSharing(state, result, diplomacyChanged: false);
  });

  test('hidden occupied target is an accepted identity no-op', () {
    final state = _moveState(
      units: [
        _moveUnit(),
        _moveUnit(id: 'hidden_target', ownerPlayerId: _moveOpponentId, col: 1),
      ],
      fogOfWar: _actorFog(visible: {const HexCoordinate(col: 0, row: 0)}),
    );

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 1, 0),
      _movementMap(cols: 2),
    );

    _expectAcceptedNoOp(result, state);
  });

  test('hidden intermediate blocker is an accepted identity no-op', () {
    final state = _moveState(
      units: [
        _moveUnit(),
        _moveUnit(
          id: 'hidden_intermediate',
          ownerPlayerId: _moveOpponentId,
          col: 1,
        ),
      ],
      fogOfWar: _actorFog(
        visible: {
          const HexCoordinate(col: 0, row: 0),
          const HexCoordinate(col: 2, row: 0),
        },
      ),
    );

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 2, 0),
      _movementMap(cols: 3),
    );

    _expectAcceptedNoOp(result, state);
  });
}

void _registerExceptionalAcceptedMoveTests() {
  test('artifact carrier spends its turn entering its rough city', () {
    final state = _moveState(
      units: [
        _moveUnit(type: GameUnitType.scout, carriedArtifactId: 'artifact_1'),
      ],
      cities: const [
        GameCity(
          id: 'own_city',
          ownerPlayerId: _moveActorId,
          name: 'Own city',
          center: CityHex(col: 1, row: 0),
        ),
      ],
    );
    final map = _movementMap(
      cols: 2,
      terrainOverrides: const {
        (col: 1, row: 0): [
          TerrainType.snow,
          TerrainType.forest,
          TerrainType.hills,
        ],
      },
    );

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 1, 0),
      map,
    );

    expect(result.accepted, isTrue);
    expect(result.reason, isNull);
    expect(
      result.state.units.first,
      _moveUnit(
        type: GameUnitType.scout,
        col: 1,
        movementPoints: 0,
        carriedArtifactId: 'artifact_1',
      ),
    );
    expect(
      result.state.fogOfWar,
      _expectedActorFog(const [(col: 0, row: 0), (col: 1, row: 0)]),
    );
    _expectMoveEvent(result, fromCol: 0, toCol: 1);
    _expectMovedStateSharing(state, result, diplomacyChanged: false);
  });

  test('movement reveals an opponent and persists diplomatic contact', () {
    final state = _moveState(
      units: [
        _moveUnit(),
        _moveUnit(
          id: 'revealed_opponent',
          ownerPlayerId: _moveOpponentId,
          col: 3,
        ),
      ],
    );

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 1, 0),
      _movementMap(cols: 4),
    );

    expect(result.accepted, isTrue);
    expect(result.reason, isNull);
    expect(
      result.state.fogOfWar,
      _expectedActorFog(const [
        (col: 0, row: 0),
        (col: 1, row: 0),
        (col: 2, row: 0),
        (col: 3, row: 0),
      ]),
    );
    expect(
      result.state.runtimeState.diplomacy,
      DiplomacyState(
        contactKeys: const {'player_1|player_2', 'player_1|sentinel'},
        relations: _sentinelDiplomacy.relations,
      ),
    );
    _expectMoveEvent(result, fromCol: 0, toCol: 1);
    _expectMovedStateSharing(state, result, diplomacyChanged: true);
  });
}
