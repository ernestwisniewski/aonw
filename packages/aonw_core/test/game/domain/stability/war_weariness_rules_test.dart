import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';
import 'package:aonw_core/game/domain/stability/war_weariness_rules.dart';
import 'package:test/test.dart';

void main() {
  const ruleset = StabilityRuleset.standard;

  test('one free attack per turn does not add weariness', () {
    final next = WarWearinessRules.next(
      current: 0,
      atWar: true,
      attacksThisTurn: 1,
      citiesLost: 0,
      signedPeace: false,
      ruleset: ruleset,
    );
    expect(next, 0);
  });

  test('attacks beyond the free one add weariness', () {
    final next = WarWearinessRules.next(
      current: 0,
      atWar: true,
      attacksThisTurn: 3,
      citiesLost: 0,
      signedPeace: false,
      ruleset: ruleset,
    );
    expect(next, 2);
  });

  test('losing a city adds two', () {
    final next = WarWearinessRules.next(
      current: 0,
      atWar: true,
      attacksThisTurn: 0,
      citiesLost: 1,
      signedPeace: false,
      ruleset: ruleset,
    );
    expect(next, 2);
  });

  test('decays by one during peace', () {
    final next = WarWearinessRules.next(
      current: 3,
      atWar: false,
      attacksThisTurn: 0,
      citiesLost: 0,
      signedPeace: false,
      ruleset: ruleset,
    );
    expect(next, 2);
  });

  test('decays faster after a treaty', () {
    final next = WarWearinessRules.next(
      current: 3,
      atWar: false,
      attacksThisTurn: 0,
      citiesLost: 0,
      signedPeace: true,
      ruleset: ruleset,
    );
    expect(next, 1);
  });

  test('never goes below zero', () {
    final next = WarWearinessRules.next(
      current: 0,
      atWar: false,
      attacksThisTurn: 0,
      citiesLost: 0,
      signedPeace: false,
      ruleset: ruleset,
    );
    expect(next, 0);
  });

  test('is capped', () {
    final next = WarWearinessRules.next(
      current: 8,
      atWar: true,
      attacksThisTurn: 10,
      citiesLost: 5,
      signedPeace: false,
      ruleset: ruleset,
    );
    expect(next, ruleset.warWearinessCap);
  });
}
