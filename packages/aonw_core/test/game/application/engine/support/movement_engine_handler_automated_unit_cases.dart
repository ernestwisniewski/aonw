part of '../movement_engine_handler_test.dart';

void _registerMovementEngineHandlerAutomatedUnitCases() {
  test('auto explore updates scout posture through the same engine', () {
    final snapshot = _snapshot(
      units: [_unit(id: 'scout', type: GameUnitType.scout, movementPoints: 3)],
      fogOfWar: _fog(visibleCols: 1),
    );

    final result = _apply(
      snapshot,
      const AutoExploreUnitCommand('scout'),
      mapView: _map(cols: 4),
    );

    final accepted = _expectAccepted(result);
    final scout = accepted.snapshot.domain.units.single;
    expect(scout.posture, UnitPosture.autoExploring);
    expect(scourCoordinate(scout), isNot((0, 0)));
    expect(accepted.events, hasLength(1));
    expect(accepted.movementDelta.executions, hasLength(1));
  });

  test('worker automation applies the canonical worker domain result', () {
    final snapshot = _snapshot(
      units: [_unit(id: 'worker', type: GameUnitType.worker, col: 1)],
      cities: const [
        GameCity(
          id: 'city',
          ownerPlayerId: _playerId,
          name: 'City',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 1, row: 0)],
        ),
      ],
      research: ResearchState(
        players: {
          _playerId: PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.agriculture},
          ),
        },
      ),
    );

    final result = _apply(
      snapshot,
      const AutomateWorkerCommand('worker'),
      mapView: _map(cols: 2),
    );

    final accepted = _expectAccepted(result);
    final worker = accepted.snapshot.domain.units.single;
    expect(worker.workerJob, isNotNull);
    expect(worker.posture, UnitPosture.active);
    expect(worker.movementPoints, 0);
    expect(accepted.events, isEmpty);
    expect(accepted.movementDelta.executions, isEmpty);
  });
}
