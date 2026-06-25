import 'package:aonw_core/game/domain/combat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CombatResolver', () {
    test('is deterministic for the same combatants and seed', () {
      final attacker = _combatant(
        id: 'attacker',
        stats: const CombatStats(attack: 6, defense: 2, hp: 10),
      );
      final defender = _combatant(
        id: 'defender',
        owner: 'player_2',
        stats: const CombatStats(attack: 4, defense: 2, hp: 10),
      );

      final first = CombatResolver.resolve(
        attacker: attacker,
        defender: defender,
        rng: CombatRng.fromTurn(
          turn: 3,
          attackerId: attacker.unitId,
          defenderId: defender.unitId,
        ),
      );
      final second = CombatResolver.resolve(
        attacker: attacker,
        defender: defender,
        rng: CombatRng.fromTurn(
          turn: 3,
          attackerId: attacker.unitId,
          defenderId: defender.unitId,
        ),
      );

      expect(first, second);
    });

    test('melee defender retaliates when it survives', () {
      final outcome = CombatResolver.resolve(
        attacker: _combatant(
          id: 'attacker',
          stats: const CombatStats(attack: 6, defense: 1, hp: 10, range: 1),
        ),
        defender: _combatant(
          id: 'defender',
          owner: 'player_2',
          stats: const CombatStats(attack: 5, defense: 1, hp: 10, range: 1),
        ),
        rng: CombatRng(99),
        ruleset: const CombatRuleset(varianceRange: 0),
      );

      expect(outcome.defenderHpAfter, 5);
      expect(outcome.attackerHpAfter, 6);
      expect(outcome.defenderKilled, isFalse);
      expect(outcome.steps.whereType<RetaliationStep>(), hasLength(1));
    });

    test('ranged attacker does not trigger retaliation', () {
      final outcome = CombatResolver.resolve(
        attacker: _combatant(
          id: 'archer',
          stats: const CombatStats(attack: 6, defense: 1, hp: 10, range: 2),
        ),
        defender: _combatant(
          id: 'defender',
          owner: 'player_2',
          stats: const CombatStats(attack: 5, defense: 1, hp: 10, range: 1),
        ),
        rng: CombatRng(99),
        ruleset: const CombatRuleset(varianceRange: 0),
      );

      expect(outcome.defenderHpAfter, 5);
      expect(outcome.attackerHpAfter, 10);
      expect(outcome.steps.whereType<RetaliationStep>(), isEmpty);
    });

    test('kills defender when damage reduces HP to zero or below', () {
      final outcome = CombatResolver.resolve(
        attacker: _combatant(
          id: 'attacker',
          stats: const CombatStats(attack: 12, defense: 1, hp: 10),
        ),
        defender: _combatant(
          id: 'defender',
          owner: 'player_2',
          stats: const CombatStats(attack: 5, defense: 1, hp: 5),
        ),
        rng: CombatRng(99),
        ruleset: const CombatRuleset(varianceRange: 0),
      );

      expect(outcome.defenderHpAfter, lessThanOrEqualTo(0));
      expect(outcome.defenderKilled, isTrue);
      expect(outcome.steps.whereType<RetaliationStep>(), isEmpty);
    });

    test('can flag low-health surviving defender retreat', () {
      final outcome = CombatResolver.resolve(
        attacker: _combatant(
          id: 'attacker',
          stats: const CombatStats(attack: 7, defense: 1, hp: 10),
        ),
        defender: _combatant(
          id: 'defender',
          owner: 'player_2',
          stats: const CombatStats(attack: 5, defense: 0, hp: 8, mobility: 1),
        ),
        rng: CombatRng(99),
        ruleset: const CombatRuleset(
          varianceRange: 0,
          retreatThresholdPercent: 25,
        ),
        defenderCanRetreat: true,
      );

      expect(outcome.defenderRetreated, isTrue);
      expect(outcome.defenderKilled, isFalse);
      expect(outcome.defenderHpAfter, 1);
      expect(outcome.steps.whereType<RetaliationStep>(), isEmpty);
    });

    test('does not retreat from lethal damage', () {
      final outcome = CombatResolver.resolve(
        attacker: _combatant(
          id: 'attacker',
          stats: const CombatStats(attack: 9, defense: 1, hp: 10),
        ),
        defender: _combatant(
          id: 'defender',
          owner: 'player_2',
          stats: const CombatStats(attack: 5, defense: 0, hp: 8, mobility: 1),
        ),
        rng: CombatRng(99),
        ruleset: const CombatRuleset(
          varianceRange: 0,
          retreatThresholdPercent: 25,
        ),
        defenderCanRetreat: true,
      );

      expect(outcome.defenderHpAfter, lessThanOrEqualTo(0));
      expect(outcome.defenderRetreated, isFalse);
      expect(outcome.defenderKilled, isTrue);
      expect(outcome.steps.whereType<RetaliationStep>(), isEmpty);
    });

    test('zero attack stat deals no damage', () {
      final outcome = CombatResolver.resolve(
        attacker: _combatant(
          id: 'settler',
          stats: const CombatStats(attack: 0, defense: 1, hp: 1),
        ),
        defender: _combatant(
          id: 'defender',
          owner: 'player_2',
          stats: const CombatStats(attack: 0, defense: 1, hp: 5),
        ),
        rng: CombatRng(99),
        ruleset: const CombatRuleset(varianceRange: 0),
      );

      expect(outcome.defenderHpAfter, 5);
      expect(outcome.steps.whereType<AttackStep>().single.damage, 0);
    });
  });
}

Combatant _combatant({
  required String id,
  String owner = 'player_1',
  required CombatStats stats,
}) {
  return Combatant(unitId: id, ownerPlayerId: owner, baseStats: stats);
}
