part of '../persistent_auto_explore_characterization_test.dart';

void _registerAutoExploreRejectionCharacterizationTests() {
  group('auto-explore rejection precedence and identity', () {
    test('unit_not_found wins over every unit and map condition', () {
      final state = _autoExploreState(
        units: [
          _autoExploreScout(
            id: 'other_unit',
            ownerPlayerId: _autoExploreOpponentId,
            type: GameUnitType.warrior,
            col: -1,
            movementPoints: 0,
            posture: UnitPosture.fortified,
            excavatingArtifactId: 'busy_artifact',
            queuedPath: _autoExploreQueuedPath(),
          ),
        ],
      );

      final result = _resolveAutoExplore(
        state,
        _autoExploreMap(cols: 1),
        unitId: 'missing_unit',
      );

      _expectRejectedAutoExplore(result, state, reason: 'unit_not_found');
    });

    test('unit_not_controlled wins over type, work, movement, and path', () {
      final state = _autoExploreState(
        units: [
          _autoExploreScout(
            ownerPlayerId: _autoExploreOpponentId,
            type: GameUnitType.warrior,
            movementPoints: 0,
            posture: UnitPosture.fortified,
            excavatingArtifactId: 'busy_artifact',
            queuedPath: _autoExploreQueuedPath(),
          ),
        ],
      );

      final result = _resolveAutoExplore(state, _autoExploreMap(cols: 1));

      _expectRejectedAutoExplore(result, state, reason: 'unit_not_controlled');
    });

    test('unit_not_scout wins over work, movement, and path', () {
      final state = _autoExploreState(
        units: [
          _autoExploreScout(
            type: GameUnitType.warrior,
            movementPoints: 0,
            posture: UnitPosture.fortified,
            excavatingArtifactId: 'busy_artifact',
            queuedPath: _autoExploreQueuedPath(),
          ),
        ],
      );

      final result = _resolveAutoExplore(state, _autoExploreMap(cols: 1));

      _expectRejectedAutoExplore(result, state, reason: 'unit_not_scout');
    });

    test('unit_busy wins over movement and queued path', () {
      final state = _autoExploreState(
        units: [
          _autoExploreScout(
            movementPoints: 0,
            posture: UnitPosture.fortified,
            excavatingArtifactId: 'busy_artifact',
            queuedPath: _autoExploreQueuedPath(),
          ),
        ],
      );

      final result = _resolveAutoExplore(state, _autoExploreMap(cols: 1));

      _expectRejectedAutoExplore(result, state, reason: 'unit_busy');
    });

    test('unit_exhausted wins over queued path', () {
      final state = _autoExploreState(
        units: [
          _autoExploreScout(
            movementPoints: 0,
            queuedPath: _autoExploreQueuedPath(),
          ),
        ],
      );

      final result = _resolveAutoExplore(state, _autoExploreMap(cols: 1));

      _expectRejectedAutoExplore(result, state, reason: 'unit_exhausted');
    });

    test('unit_has_path wins over planner target selection', () {
      final state = _autoExploreState(
        units: [
          _autoExploreScout(
            movementPoints: 1,
            queuedPath: _autoExploreQueuedPath(),
          ),
        ],
      );

      final result = _resolveAutoExplore(state, _autoExploreMap(cols: 1));

      _expectRejectedAutoExplore(result, state, reason: 'unit_has_path');
    });

    test('auto_explore_no_target is final after all unit guards pass', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final state = _autoExploreState(
        units: [_autoExploreScout(movementPoints: 1)],
        fogOfWar: _autoExploreActorFog(visible: {origin}, discovered: {origin}),
      );

      final result = _resolveAutoExplore(state, _autoExploreMap(cols: 1));

      _expectRejectedAutoExplore(
        result,
        state,
        reason: 'auto_explore_no_target',
      );
    });
  });

  group('auto-explore downstream movement rejections', () {
    test('invalid origin reaches the movement unit_out_of_bounds guard', () {
      final state = _autoExploreState(
        units: [_autoExploreScout(col: -1, movementPoints: 1)],
      );

      final result = _resolveAutoExplore(state, _autoExploreMap(cols: 3));

      _expectRejectedAutoExplore(result, state, reason: 'unit_out_of_bounds');
    });

    test('known foreign city prevents target selection', () {
      final known = {
        for (var col = 0; col <= 3; col++) HexCoordinate(col: col, row: 0),
      };
      final state = _autoExploreState(
        units: [_autoExploreScout(movementPoints: 1)],
        cities: const [
          GameCity(
            id: 'known_foreign_city',
            ownerPlayerId: _autoExploreOpponentId,
            name: 'Known foreign city',
            center: CityHex(col: 1, row: 0),
          ),
        ],
        fogOfWar: _autoExploreActorFog(visible: known, discovered: known),
      );

      final result = _resolveAutoExplore(state, _autoExploreMap(cols: 5));

      _expectRejectedAutoExplore(
        result,
        state,
        reason: 'auto_explore_no_target',
      );
    });

    test('an eventually untraversable tile preserves capacity rejection', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final state = _autoExploreState(
        units: [
          _autoExploreScout(
            movementPoints: 2,
            carriedArtifactId: 'carried_artifact',
          ),
        ],
        fogOfWar: _autoExploreActorFog(visible: {origin}, discovered: {origin}),
      );
      final map = _autoExploreMap(
        cols: 2,
        terrainOverrides: const {
          (col: 1, row: 0): [TerrainType.snow, TerrainType.hills],
        },
      );

      final result = _resolveAutoExplore(state, map);

      _expectRejectedAutoExplore(
        result,
        state,
        reason: 'unit_movement_capacity_insufficient',
      );
    });
  });
}
