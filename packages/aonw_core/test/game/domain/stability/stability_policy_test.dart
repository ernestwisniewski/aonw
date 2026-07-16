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

  group('normalizeRelativeStanding', () {
    test('keeps in-range standing values', () {
      expect(StabilityPolicy.normalizeRelativeStanding(-0.25), -0.25);
      expect(StabilityPolicy.normalizeRelativeStanding(0.75), 0.75);
    });

    test('clamps out-of-range standing values', () {
      expect(StabilityPolicy.normalizeRelativeStanding(-3.0), -1.0);
      expect(StabilityPolicy.normalizeRelativeStanding(4.5), 1.0);
    });

    test('neutralizes a NaN standing', () {
      expect(StabilityPolicy.normalizeRelativeStanding(double.nan), 0.0);
    });
  });

  group('relativeStandingFor', () {
    test('is neutral at the fair share', () {
      expect(
        StabilityPolicy.relativeStandingFor(controlPercent: 25, playerCount: 4),
        closeTo(0.0, 0.0001),
      );
    });

    test('trends to a full leader well above the fair share', () {
      expect(
        StabilityPolicy.relativeStandingFor(controlPercent: 50, playerCount: 4),
        closeTo(1.0, 0.0001),
      );
    });

    test('trends to a full underdog at zero control and clamps', () {
      expect(
        StabilityPolicy.relativeStandingFor(controlPercent: 0, playerCount: 4),
        closeTo(-1.0, 0.0001),
      );
    });
  });

  group('effectiveNet', () {
    test('treats a NaN standing as neutral instead of crashing', () {
      expect(
        StabilityPolicy.effectiveNet(
          5,
          relativeStanding: double.nan,
          ruleset: ruleset,
        ),
        5,
      );
    });

    test('clamps a leader standing above 1.0', () {
      expect(
        StabilityPolicy.effectiveNet(
          8,
          relativeStanding: 3.0,
          ruleset: ruleset,
        ),
        StabilityPolicy.effectiveNet(
          8,
          relativeStanding: 1.0,
          ruleset: ruleset,
        ),
      );
      expect(
        StabilityPolicy.effectiveNet(
          8,
          relativeStanding: 3.0,
          ruleset: ruleset,
        ),
        5,
      );
    });

    test('clamps an underdog standing below -1.0', () {
      expect(
        StabilityPolicy.effectiveNet(
          0,
          relativeStanding: -3.0,
          ruleset: ruleset,
        ),
        3,
      );
    });

    test('out-of-range leader standing cannot flip content into unrest', () {
      expect(
        StabilityPolicy.bandFor(8, relativeStanding: 5.0, ruleset: ruleset),
        StabilityBand.content,
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

  group('modifierForNet', () {
    const contentModifier = StabilityModifier(
      productionMultiplier: 1.0,
      goldMultiplier: 1.0,
      foodBonus: 1,
      haltsGrowth: false,
    );
    const strainedModifier = StabilityModifier(
      productionMultiplier: 1.0,
      goldMultiplier: 0.9,
      foodBonus: 0,
      haltsGrowth: true,
    );
    const unrestModifier = StabilityModifier(
      productionMultiplier: 0.75,
      goldMultiplier: 0.75,
      foodBonus: 0,
      haltsGrowth: true,
    );

    test('maps the standard ruleset thresholds to their exact modifiers', () {
      final cases = <(int, StabilityModifier)>[
        (-5, unrestModifier),
        (-4, unrestModifier),
        (-3, strainedModifier),
        (-1, strainedModifier),
        (0, StabilityModifier.stable),
        (3, StabilityModifier.stable),
        (4, contentModifier),
        (5, contentModifier),
      ];

      for (final (net, expected) in cases) {
        expect(
          StabilityPolicy.modifierForNet(net, ruleset: ruleset),
          expected,
          reason: 'unexpected modifier for stability net $net',
        );
      }
    });

    test('uses custom thresholds instead of standard boundary values', () {
      final customRuleset = ruleset.copyWith(
        contentThreshold: 7,
        unrestThreshold: -2,
      );
      final cases = <(int, StabilityModifier)>[
        (-3, unrestModifier),
        (-2, unrestModifier),
        (-1, strainedModifier),
        (0, StabilityModifier.stable),
        (6, StabilityModifier.stable),
        (7, contentModifier),
        (8, contentModifier),
      ];

      for (final (net, expected) in cases) {
        expect(
          StabilityPolicy.modifierForNet(net, ruleset: customRuleset),
          expected,
          reason: 'unexpected modifier for custom stability net $net',
        );
      }
    });
  });
}
