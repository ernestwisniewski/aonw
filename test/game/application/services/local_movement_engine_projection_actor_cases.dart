part of 'local_movement_engine_projection_test.dart';

void _registerLocalMovementActorCases() {
  test('AI movement preserves unrelated human interaction', () {
    final humanUnit = _unit(id: 'human', col: 0);
    final aiUnit = GameUnit(
      id: 'ai_mover',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'AI mover',
      col: 2,
      row: 0,
      movementPoints: 3,
    );
    const pending = PendingAttackTargeting(
      ownerPlayerId: _playerId,
      attackerUnitId: 'human',
    );
    final state = GameClientState(
      activePlayerId: _playerId,
      activePlayerCanAct: true,
      units: [humanUnit, aiUnit],
      interaction: InteractionState(
        selection: GameSelection.unit(humanUnit),
        pendingAction: pending,
        moveCommandActive: true,
      ),
    );

    final result = _resolver(_map(cols: 4)).resolve(
      baseSnapshot: _snapshot(state),
      currentState: state,
      command: const MoveUnitCommand('ai_mover', 3, 0),
      savedAt: DateTime.utc(2026, 7, 29, 21, 30),
      context: const GameCommandContext(
        actorPlayerId: 'player_2',
        ignoreFogOfWar: true,
      ),
    );

    expect(result.state.unitById('ai_mover')?.col, 3);
    expect(result.state.selectedUnitId, 'human');
    expect(result.state.pendingAction, same(pending));
    expect(result.state.moveCommandActive, isTrue);
  });

  test('AI detachment does not auto-select its commander', () {
    final humanUnit = _unit(id: 'human', col: 0, row: 0);
    final aiCommander = GameUnit(
      id: 'ai_commander',
      ownerPlayerId: 'player_2',
      type: GameUnitType.commander,
      name: 'AI commander',
      col: 2,
      row: 1,
      movementPoints: 3,
      army: const [ArmyTroop(type: TroopType.warrior, count: 1)],
    );
    const pending = PendingAttackTargeting(
      ownerPlayerId: _playerId,
      attackerUnitId: 'human',
    );
    final state = GameClientState(
      activePlayerId: _playerId,
      activePlayerCanAct: true,
      units: [humanUnit, aiCommander],
      interaction: InteractionState(
        selection: GameSelection.unit(humanUnit),
        pendingAction: pending,
        moveCommandActive: true,
      ),
    );

    final result = _resolver(_map(cols: 4, rows: 3)).resolve(
      baseSnapshot: _snapshot(state),
      currentState: state,
      command: const DetachTroopCommand('ai_commander', TroopType.warrior),
      savedAt: DateTime.utc(2026, 7, 29, 21, 45),
      context: const GameCommandContext(
        actorPlayerId: 'player_2',
        ignoreFogOfWar: true,
      ),
    );

    expect(result.state.units, hasLength(3));
    expect(result.state.selectedUnitId, 'human');
    expect(result.state.pendingAction, same(pending));
    expect(result.state.moveCommandActive, isTrue);
  });
}
