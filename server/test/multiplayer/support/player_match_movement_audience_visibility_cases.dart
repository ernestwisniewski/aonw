part of '../player_match_movement_audience_test.dart';

void _registerMovementAudienceVisibilityTests() {
  test('does not assemble exact paths across fog snapshots', () {
    final canonical = _annotate(
      executions: _orderedExecutions(),
      previous: _state(
        a: (col: 0, row: 0),
        b: (col: 0, row: 1),
        observerVisible: _hexes(const [(col: 0, row: 0), (col: 1, row: 0)]),
      ),
      next: _state(
        a: (col: 3, row: 0),
        b: (col: 1, row: 1),
        observerVisible: _hexes(const [(col: 2, row: 0), (col: 3, row: 0)]),
      ),
    );

    expect(_projectSnapshots(canonical, _observer), isEmpty);
    expect(_projectSnapshots(canonical, _playerA), [
      'unit-a:0,0->1,0;audience=public',
      'unit-a:1,0->2,0|3,0;audience=public',
    ]);
  });

  test('projects a coarse event without exposing a partial exact path', () {
    const origin = HexCoordinate(col: 0, row: 0);
    const destination = HexCoordinate(col: 3, row: 0);
    final previous = _state(
      a: (col: 0, row: 0),
      b: (col: 0, row: 1),
      observerVisible: {origin},
    );
    final next = _state(
      a: (col: 3, row: 0),
      b: (col: 1, row: 1),
      observerVisible: {destination},
    );
    final executions = _annotate(
      executions: _orderedExecutions(),
      previous: previous,
      next: next,
    );
    final events = PlayerMatchEventAudience.annotateForStorage(
      events: const [
        UnitMovedEvent(
          unitId: 'unit-a',
          fromCol: 0,
          fromRow: 0,
          toCol: 3,
          toRow: 0,
        ),
      ],
      participantPlayerIds: const [_playerA, _playerB, _observer],
      previous: GameEventOwnershipIndex.from(previous.units, previous.cities),
      next: GameEventOwnershipIndex.from(next.units, next.cities),
      previousFog: previous.fogOfWar,
      nextFog: next.fogOfWar,
    );
    final canonical = _event(events: events, movementExecutions: executions);
    const projector = PlayerMatchViewProjector();

    final observer = projector.eventFor(canonical, _recipient);
    expect(observer.events, hasLength(1));
    expect(observer.movementExecutions.isEmpty, isTrue);

    final owner = projector.eventFor(
      canonical,
      const MatchRecipient(userIdentifier: 'owner-user', playerId: _playerA),
    );
    expect(owner.events, hasLength(1));
    expect(owner.movementExecutions.values, hasLength(2));
  });
}
