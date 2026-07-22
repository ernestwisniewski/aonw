part of '../persistent_move_unit_resolver_characterization_test.dart';

void _registerMoveRejectionCharacterizationTests() {
  group('move rejection precedence and identity', () {
    _registerMoveUnitGuardRejections();
    _registerMoveTargetGuardRejections();
    _registerMovePathGuardRejections();
  });
}

void _registerMoveUnitGuardRejections() {
  test('unit_not_found wins over every unit and map validation', () {
    final state = _moveState(
      units: [
        _moveUnit(
          id: 'other',
          ownerPlayerId: _moveOpponentId,
          type: GameUnitType.merchant,
          col: 99,
          excavatingArtifactId: 'artifact_1',
        ),
      ],
    );

    final result = _resolveMove(
      state,
      const MoveUnitCommand('missing', 99, 99),
      _movementMap(cols: 2),
    );

    _expectRejectedMove(result, state, 'unit_not_found');
  });

  test('unit_not_controlled wins over work, type, and bounds', () {
    final state = _moveState(
      units: [
        _moveUnit(
          ownerPlayerId: _moveOpponentId,
          type: GameUnitType.merchant,
          col: 99,
          excavatingArtifactId: 'artifact_1',
        ),
      ],
    );

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 99, 99),
      _movementMap(cols: 2),
    );

    _expectRejectedMove(result, state, 'unit_not_controlled');
  });

  test('unit_unavailable wins over merchant and bounds', () {
    final state = _moveState(
      units: [
        _moveUnit(
          type: GameUnitType.merchant,
          col: 99,
          excavatingArtifactId: 'artifact_1',
        ),
      ],
    );

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 99, 99),
      _movementMap(cols: 2),
    );

    _expectRejectedMove(result, state, 'unit_unavailable');
  });

  test('unit_uses_trade_routes wins over unit and target bounds', () {
    final state = _moveState(
      units: [_moveUnit(type: GameUnitType.merchant, col: 99)],
    );

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 99, 99),
      _movementMap(cols: 2),
    );

    _expectRejectedMove(result, state, 'unit_uses_trade_routes');
  });

  test('unit_out_of_bounds wins over target bounds', () {
    final state = _moveState(units: [_moveUnit(col: 99)]);

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 99, 99),
      _movementMap(cols: 2),
    );

    _expectRejectedMove(result, state, 'unit_out_of_bounds');
  });
}

void _registerMoveTargetGuardRejections() {
  test('move_target_out_of_bounds wins over city and occupancy', () {
    final state = _moveState(
      units: [
        _moveUnit(),
        _moveUnit(
          id: 'off_map_blocker',
          ownerPlayerId: _moveOpponentId,
          col: 99,
          row: 99,
        ),
      ],
      cities: const [
        GameCity(
          id: 'off_map_city',
          ownerPlayerId: _moveOpponentId,
          name: 'Off-map city',
          center: CityHex(col: 99, row: 99),
        ),
      ],
    );

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 99, 99),
      _movementMap(cols: 2),
    );

    _expectRejectedMove(result, state, 'move_target_out_of_bounds');
  });

  test('move_target_is_current_tile wins over city and occupancy', () {
    final state = _moveState(
      units: [
        _moveUnit(),
        _moveUnit(id: 'same_tile_blocker', ownerPlayerId: _moveOpponentId),
      ],
      cities: const [
        GameCity(
          id: 'same_tile_city',
          ownerPlayerId: _moveOpponentId,
          name: 'Same tile city',
          center: CityHex(col: 0, row: 0),
        ),
      ],
    );

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 0, 0),
      _movementMap(cols: 2),
    );

    _expectRejectedMove(result, state, 'move_target_is_current_tile');
  });

  test('foreign city wins over occupancy and terrain failures', () {
    final state = _moveState(
      units: [
        _moveUnit(),
        _moveUnit(id: 'city_blocker', ownerPlayerId: _moveOpponentId, col: 1),
      ],
      cities: const [
        GameCity(
          id: 'foreign_city',
          ownerPlayerId: _moveOpponentId,
          name: 'Foreign city',
          center: CityHex(col: 1, row: 0),
        ),
      ],
    );
    final map = _movementMap(
      cols: 2,
      terrainOverrides: const {
        (col: 1, row: 0): [TerrainType.mountain],
      },
    );

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 1, 0),
      map,
    );

    _expectRejectedMove(result, state, 'move_target_is_foreign_city_center');
  });
}

void _registerMovePathGuardRejections() {
  test('move_target_occupied wins over its blocked terrain', () {
    final state = _moveState(
      units: [
        _moveUnit(),
        _moveUnit(id: 'target_blocker', ownerPlayerId: _moveOpponentId, col: 1),
      ],
    );
    final map = _movementMap(
      cols: 2,
      terrainOverrides: const {
        (col: 1, row: 0): [TerrainType.mountain],
      },
    );

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 1, 0),
      map,
    );

    _expectRejectedMove(result, state, 'move_target_occupied');
  });

  test('move_path_not_found characterizes an impassable target', () {
    final state = _moveState(units: [_moveUnit()]);
    final map = _movementMap(
      cols: 2,
      terrainOverrides: const {
        (col: 1, row: 0): [TerrainType.mountain],
      },
    );

    final result = _resolveMove(
      state,
      const MoveUnitCommand(_moverId, 1, 0),
      map,
    );

    _expectRejectedMove(result, state, 'move_path_not_found');
  });

  test('capacity is the final rejection after a path is found', () {
    final state = _moveState(units: [_moveUnit(type: GameUnitType.warrior)]);
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

    _expectRejectedMove(result, state, 'unit_movement_capacity_insufficient');
  });
}
