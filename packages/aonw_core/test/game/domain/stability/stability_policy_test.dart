import 'package:aonw_core/game/domain/stability/stability_band.dart';
import 'package:aonw_core/game/domain/stability/stability_modifier.dart';
import 'package:aonw_core/game/domain/stability/stability_policy.dart';
import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';
import 'package:test/test.dart';

void main() {
  const ruleset = StabilityRuleset.standard;

  group('bandFor', () {
    test('content at or above content threshold', () {
      expect(
        StabilityPolicy.bandFor(4, ruleset: ruleset),
        StabilityBand.content,
      );
      expect(
        StabilityPolicy.bandFor(10, ruleset: ruleset),
        StabilityBand.content,
      );
    });

    test('stable between zero and content threshold', () {
      expect(
        StabilityPolicy.bandFor(0, ruleset: ruleset),
        StabilityBand.stable,
      );
      expect(
        StabilityPolicy.bandFor(3, ruleset: ruleset),
        StabilityBand.stable,
      );
    });

    test('strained just below zero', () {
      expect(
        StabilityPolicy.bandFor(-1, ruleset: ruleset),
        StabilityBand.strained,
      );
      expect(
        StabilityPolicy.bandFor(-3, ruleset: ruleset),
        StabilityBand.strained,
      );
    });

    test('unrest at or below unrest threshold', () {
      expect(
        StabilityPolicy.bandFor(-4, ruleset: ruleset),
        StabilityBand.unrest,
      );
      expect(
        StabilityPolicy.bandFor(-9, ruleset: ruleset),
        StabilityBand.unrest,
      );
    });

    test('leader standing is pushed toward unrest', () {
      expect(
        StabilityPolicy.bandFor(3, relativeStanding: 1.0, ruleset: ruleset),
        StabilityBand.stable,
      );
      expect(
        StabilityPolicy.bandFor(0, relativeStanding: 1.0, ruleset: ruleset),
        StabilityBand.strained,
      );
    });

    test('underdog standing gets a catch-up shift up', () {
      expect(
        StabilityPolicy.bandFor(-1, relativeStanding: -1.0, ruleset: ruleset),
        StabilityBand.stable,
      );
    });
  });

  group('modifierFor', () {
    test('stable is neutral', () {
      expect(
        StabilityPolicy.modifierFor(StabilityBand.stable),
        StabilityModifier.stable,
      );
    });

    test('unrest cuts yields and halts growth', () {
      final modifier = StabilityPolicy.modifierFor(StabilityBand.unrest);
      expect(modifier.productionMultiplier, 0.75);
      expect(modifier.goldMultiplier, 0.75);
      expect(modifier.haltsGrowth, isTrue);
    });

    test('content grants a food bonus and does not halt growth', () {
      final modifier = StabilityPolicy.modifierFor(StabilityBand.content);
      expect(modifier.foodBonus, 1);
      expect(modifier.haltsGrowth, isFalse);
    });
  });
}
