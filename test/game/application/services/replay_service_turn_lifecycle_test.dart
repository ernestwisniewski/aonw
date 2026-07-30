part of 'replay_service_test.dart';

GameUnit _actionableUnit() => GameUnit.produced(
  id: 'warrior_p1',
  ownerPlayerId: 'p1',
  type: GameUnitType.warrior,
  col: 0,
  row: 0,
);

MerchantTradeRoute _merchantRoute({
  required String originCityId,
  required String destinationCityId,
  required int toCol,
}) {
  return MerchantTradeRoute(
    originCityId: originCityId,
    destinationCityId: destinationCityId,
    steps: [
      for (var col = 0; col <= toCol; col++)
        UnitMovementStep(
          col: col,
          row: 0,
          enterCost: col == 0 ? 0 : 1,
          cumulativeCost: col,
        ),
    ],
  );
}

void _registerReplayTurnLifecycleTests() {
  test('replays next-player turn start as part of sequential end', () async {
    final queuedUnit = _queuedReplayUnit(ownerPlayerId: 'p1');
    final service = _turnLifecycleReplayService(
      queuedUnit: queuedUnit,
      playerStates: const {
        'p2': PlayerTurnState.active,
        'p1': PlayerTurnState.active,
      },
      players: const [
        Player(id: 'p2', name: 'Bob', colorValue: 0xFFC45050),
        Player(id: 'p1', name: 'Alice', colorValue: 0xFF4A7FC4),
      ],
      command: const EndTurnCommand('p2'),
    );

    final step = (await service.buildTimeline('save_1')).steps.single;

    expect(step.offset, 1);
    expect(step.state.units.single.col, 1);
    expect(step.state.units.single.queuedPath, isNull);
    final effect = step.uiEffects.whereType<AnimateUnitMoveEffect>().single;
    expect(effect.unitId, queuedUnit.id);
    expect(effect.fromCol, 0);
    expect(effect.steps.single.col, 1);
  });

  test('replays sequential round wrap and first-player movement', () async {
    final service = _turnLifecycleReplayService(
      queuedUnit: _queuedReplayUnit(ownerPlayerId: 'p2'),
      playerStates: const {
        'p2': PlayerTurnState.finished,
        'p1': PlayerTurnState.active,
      },
      players: const [
        Player(id: 'p2', name: 'Bob', colorValue: 0xFFC45050),
        Player(id: 'p1', name: 'Alice', colorValue: 0xFF4A7FC4),
      ],
      command: const EndTurnCommand('p1'),
    );

    final step = (await service.buildTimeline('save_1')).steps.single;

    expect(step.turn, 1);
    expect(step.domain.turn, 2);
    expect(step.state.units.single.col, 1);
    expect(step.uiEffects.whereType<AnimateUnitMoveEffect>(), hasLength(1));
  });
}

ReplayService _turnLifecycleReplayService({
  required GameUnit queuedUnit,
  required Map<String, PlayerTurnState> playerStates,
  required List<Player> players,
  required EndTurnCommand command,
}) {
  return _service(
    replayStore: _MemoryReplayStore({
      'save_1': _snapshot(
        units: [queuedUnit],
        players: players,
        playerStates: playerStates,
      ),
    }),
    eventLog: _MemoryEventLog([
      LoggedCommand(
        offset: 1,
        timestamp: DateTime.utc(2026, 4, 24, 12, 1),
        turn: 1,
        command: command,
      ),
    ]),
    mapData: _map(cols: 2),
  );
}

GameUnit _queuedReplayUnit({required String ownerPlayerId}) => GameUnit(
  id: 'queued_unit',
  ownerPlayerId: ownerPlayerId,
  type: GameUnitType.warrior,
  name: GameUnitType.warrior.defaultNameToken,
  col: 0,
  row: 0,
  movementPoints: 0,
  queuedPath: QueuedMovePath(
    targetCol: 1,
    targetRow: 0,
    steps: const [
      UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
    ],
  ),
);
