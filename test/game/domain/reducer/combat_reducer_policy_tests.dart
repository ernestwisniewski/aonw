part of 'combat_reducer_test.dart';

void _registerCombatPolicyTests() {
  test('hidden treaty target does not leak HUD feedback', () {
    final mapData = _map(3, 3);
    final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
    final defender = _unit(id: 'd', ownerPlayerId: 'p2', col: 1, row: 0);
    final state = GameState(
      activePlayerId: 'p1',
      units: [attacker, defender],
      diplomacy: DiplomacyState.empty.setStatus(
        'p1',
        'p2',
        DiplomaticRelationStatus.friendly,
      ),
      fogOfWar: _visible('p1', const [HexCoordinate(col: 0, row: 0)]),
    );

    final result = _reducer(
      mapData,
    ).reduce(state, const AttackHexCommand('a', 1, 0));

    expect(result.state, same(state));
    expect(result.events, isEmpty);
    expect(result.uiEffects, isEmpty);
  });

  test('disabled command context cannot attack or reveal treaty status', () {
    final mapData = _map(3, 3);
    final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
    final defender = _unit(id: 'd', ownerPlayerId: 'p2', col: 1, row: 0);
    final state = GameState(
      activePlayerId: 'p1',
      units: [attacker, defender],
      diplomacy: DiplomacyState.empty.setStatus(
        'p1',
        'p2',
        DiplomaticRelationStatus.friendly,
      ),
      fogOfWar: _visible('p1', const [
        HexCoordinate(col: 0, row: 0),
        HexCoordinate(col: 1, row: 0),
      ]),
    );

    final result = _reducer(mapData).reduce(
      state,
      const AttackHexCommand('a', 1, 0),
      context: const GameCommandContext(actorPlayerId: 'p1', canAct: false),
    );

    expect(result.state, same(state));
    expect(result.events, isEmpty);
    expect(result.uiEffects, isEmpty);
  });

  test('unrelated pending action blocks combat without clearing UI state', () {
    final mapData = _map(3, 3);
    final attacker = _unit(id: 'a', ownerPlayerId: 'p1', col: 0, row: 0);
    final defender = _unit(id: 'd', ownerPlayerId: 'p2', col: 1, row: 0);
    const pending = PendingResearchSelection(ownerPlayerId: 'p1');
    final state = GameState(
      activePlayerId: 'p1',
      units: [attacker, defender],
      fogOfWar: _visible('p1', const [
        HexCoordinate(col: 0, row: 0),
        HexCoordinate(col: 1, row: 0),
      ]),
      interaction: const GameInteractionState(pendingAction: pending),
    );

    final result = _reducer(
      mapData,
    ).reduce(state, const AttackHexCommand('a', 1, 0));

    expect(result.state, same(state));
    expect(result.state.pendingAction, same(pending));
    expect(result.events, isEmpty);
    expect(result.uiEffects, isEmpty);
  });
}
