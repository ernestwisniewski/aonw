part of 'replay_service_test.dart';

void _registerCombatReplayTest() {
  test('replays combat through the canonical game engine', () async {
    final attacker = GameUnit.produced(
      id: 'attacker',
      ownerPlayerId: 'p1',
      type: GameUnitType.warrior,
      col: 0,
      row: 0,
    );
    final defender = GameUnit.produced(
      id: 'defender',
      ownerPlayerId: 'p2',
      type: GameUnitType.settler,
      col: 1,
      row: 0,
    );
    final service = _service(
      replayStore: _MemoryReplayStore({
        'save_1': _snapshot(
          units: [attacker, defender],
          fogOfWar: _combatFog,
          players: const [
            Player(id: 'p1', name: 'Alice', colorValue: 0xFF4A7FC4),
            Player(id: 'p2', name: 'Bob', colorValue: 0xFFB45309),
          ],
        ),
      }),
      eventLog: _MemoryEventLog([
        RecordedDomainCommand(
          offset: 1,
          timestamp: DateTime.utc(2026, 4, 24, 12, 1),
          turn: 1,
          actorPlayerId: 'p1',
          commandTick: 9,
          command: const AttackHexCommand('attacker', 1, 0),
        ),
      ]),
      mapData: _map(cols: 2, rows: 1),
    );

    final timeline = await service.buildTimeline('save_1');

    final step = timeline.steps.single;
    expect(
      step.previousState.unitById('attacker')?.movementPoints,
      attacker.movementPoints,
    );
    expect(step.state.unitById('attacker')?.movementPoints, 0);
    expect(step.snapshot.domain.units, step.state.units);
    expect(step.offset, 1);
    expect(step.turn, 1);
    expect(step.combatAnimations, const [
      CombatAnimationFact(
        eventIndex: 1,
        attackerUnitId: 'attacker',
        defenderId: 'defender',
        attackerFromCol: 0,
        attackerFromRow: 0,
        attackerToCol: 1,
        attackerToRow: 0,
      ),
    ]);
  });
}

final _combatFog = FogOfWarState(
  players: {
    'p1': PlayerFogOfWar(
      playerId: 'p1',
      visibleHexes: {
        const HexCoordinate(col: 0, row: 0),
        const HexCoordinate(col: 1, row: 0),
      },
    ),
    'p2': PlayerFogOfWar(
      playerId: 'p2',
      visibleHexes: {
        const HexCoordinate(col: 0, row: 0),
        const HexCoordinate(col: 1, row: 0),
      },
    ),
  },
);
