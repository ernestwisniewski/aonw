part of 'hud_action_deck_test.dart';

void _registerHudActionDeckCombatForecastCases() {
  testWidgets('selected attack target opens combat confirmation popup', (
    tester,
  ) async {
    await _pumpDeck(
      tester,
      gameState: GameClientState(
        interaction: const InteractionState(
          pendingAction: PendingAttackTargeting(
            ownerPlayerId: 'player_1',
            attackerUnitId: 'attacker_1',
            defenderCol: 1,
            defenderRow: 0,
          ),
        ),
      ),
      combatPreview: const HudCombatPreview(
        attackerUnitId: 'attacker_1',
        defenderUnitId: 'defender_1',
        attackerUnitType: GameUnitType.warrior,
        defenderUnitType: GameUnitType.spearman,
        attackerName: 'Warrior',
        defenderName: 'Spearman',
        targetIsCity: false,
        attackerModifiers: [
          CounterModifier(
            label: 'counter.spearmanVsMounted.attack',
            target: CombatStatTarget.attack,
            delta: 2,
          ),
        ],
        attackerHpBefore: 10,
        defenderHpBefore: 10,
        attackerMaxHp: 10,
        defenderMaxHp: 10,
        attackerHpAfter: 8,
        defenderHpAfter: 6,
        attackerAttack: 6,
        attackerDefense: 3,
        defenderAttack: 4,
        defenderDefense: 2,
        defenderRange: 1,
        attackDamage: 4,
        retaliationDamage: 2,
        attackerKilled: false,
        defenderKilled: false,
        defenderRetreated: false,
        distance: 1,
        range: 1,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('hudCombatConfirm.surface')), findsOneWidget);
    expect(find.text('Confirm attack'), findsAtLeastNWidgets(1));
    expect(find.text('Poland: Warrior → Poland: Spearman'), findsOneWidget);
    expect(find.text('Why this forecast?'), findsOneWidget);
    expect(
      find.text(
        'Attack advantage: Poland has 6 attack against 2 defense; the target loses about 4 HP.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Helps the attack (Poland): spearmen against mounted units.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('hudCombatConfirm.forecast')), findsOneWidget);
    expect(find.byKey(const Key('hudCombatConfirm.outcome')), findsOneWidget);
    expect(find.text('Outcome: defender survives'), findsOneWidget);
    expect(
      find.byKey(const Key('hudCombatConfirm.attackerRing')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('hudCombatConfirm.defenderRing')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('hudCombatConfirm.attackerHpAfter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('hudCombatConfirm.defenderHpAfter')),
      findsOneWidget,
    );
    expect(find.text('8/10'), findsOneWidget);
    expect(find.text('6/10'), findsOneWidget);
    expect(find.byKey(const Key('hudCombatConfirm.cancel')), findsOneWidget);
    expect(find.byKey(const Key('hudCombatConfirm.confirm')), findsOneWidget);
  });

  testWidgets('combat modal makes a retreat outcome explicit', (tester) async {
    await _pumpDeck(
      tester,
      gameState: GameClientState(
        interaction: const InteractionState(
          pendingAction: PendingAttackTargeting(
            ownerPlayerId: 'player_1',
            attackerUnitId: 'attacker_1',
            defenderCol: 1,
            defenderRow: 0,
          ),
        ),
      ),
      combatPreview: const HudCombatPreview(
        attackerUnitId: 'attacker_1',
        defenderUnitId: 'defender_1',
        attackerName: 'Warrior',
        defenderName: 'Spearman',
        targetIsCity: false,
        attackerHpBefore: 10,
        defenderHpBefore: 3,
        attackerMaxHp: 10,
        defenderMaxHp: 10,
        attackerHpAfter: 8,
        defenderHpAfter: 1,
        attackerAttack: 6,
        attackerDefense: 3,
        defenderAttack: 4,
        defenderDefense: 2,
        defenderRange: 1,
        attackDamage: 2,
        retaliationDamage: 2,
        attackerKilled: false,
        defenderKilled: false,
        defenderRetreated: true,
        distance: 1,
        range: 1,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('hudCombatConfirm.outcome')), findsOneWidget);
    expect(find.text('Outcome: defender will retreat'), findsOneWidget);
    expect(find.textContaining('Target: HP 3->1/10'), findsOneWidget);
  });
}
