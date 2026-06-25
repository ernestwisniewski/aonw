import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:test/test.dart';

void main() {
  group('MatchRules', () {
    test(
      'standard preset is unlimited with conquest and domination enabled',
      () {
        const rules = MatchRules.standard;

        expect(rules.gameLength, GameLengthConfig.unlimited);
        expect(rules.victory.conquestEnabled, isTrue);
        expect(rules.victory.dominationEnabled, isTrue);
        expect(rules.victory.dominationControlPercent, 60);
        expect(rules.victory.dominationHoldTurns, 5);
        expect(rules.victory.scoreFallbackEnabled, isFalse);
        expect(rules.victory.turnLimit, isNull);
        expect(rules.victory.hardTimeLimitMinutes, isNull);
        expect(rules.balance, isEmpty);
      },
    );

    test('target duration presets derive turn cap and victory pace', () {
      final rules = MatchRules.forGameLength(GameLengthConfig.standard60);

      expect(rules.gameLength.targetMinutes, 60);
      expect(rules.gameLength.turnLimit, 120);
      expect(rules.gameLength.paceProfile, PaceProfile.standard60);
      expect(rules.gameLength.scoreFallbackEnabled, isTrue);
      expect(rules.victory.dominationControlPercent, 45);
      expect(rules.victory.dominationHoldTurns, 10);
      expect(rules.victory.scoreFallbackEnabled, isTrue);
      expect(rules.victory.turnLimit, 120);
    });

    test('pace profiles scale domination thresholds and hold windows', () {
      final standard = MatchRules.forGameLength(
        GameLengthConfig.standard60,
      ).victory;
      final normal = MatchRules.forGameLength(
        GameLengthConfig.normal90,
      ).victory;
      final long = MatchRules.forGameLength(GameLengthConfig.long120).victory;
      final unlimited = MatchRules.standard.victory;

      expect(standard.dominationControlPercent, 45);
      expect(standard.dominationHoldTurns, 10);
      expect(normal.dominationControlPercent, 47);
      expect(normal.dominationHoldTurns, 12);
      expect(normal.scoreFallbackEnabled, isTrue);
      expect(normal.turnLimit, 180);
      expect(long.dominationControlPercent, 50);
      expect(long.dominationHoldTurns, 14);
      expect(unlimited.dominationControlPercent, 60);
      expect(unlimited.dominationHoldTurns, 5);
    });

    test('pace balance maps profiles to shared cost scalers', () {
      expect(PaceBalance.unlimited.researchCost(20), 20);
      expect(PaceBalance.unlimited.unitProductionCost(20), 26);
      expect(PaceBalance.unlimited.buildingProductionCost(20), 29);
      expect(PaceBalance.unlimited.growthCost(31), 36);
      expect(PaceBalance.unlimited.improvementTurns(2), 3);
      expect(PaceBalance.standard60.researchCost(20), 16);
      expect(PaceBalance.standard60.unitProductionCost(12), 10);
      expect(PaceBalance.standard60.buildingProductionCost(8), 7);
      expect(PaceBalance.standard60.growthCost(31), 27);
      expect(PaceBalance.standard60.objectiveTarget(28), 24);
      expect(PaceBalance.normal90.researchCost(20), 19);
      expect(PaceBalance.normal90.unitProductionCost(20), 18);
      expect(PaceBalance.normal90.buildingProductionCost(20), 19);
      expect(PaceBalance.normal90.growthCost(31), 29);
      expect(PaceBalance.normal90.objectiveTarget(28), 26);
      expect(PaceBalance.long120.researchCost(20), 22);
      expect(PaceBalance.long120.buildingProductionCost(20), 20);
      expect(PaceBalance.long120.objectiveTarget(28), 28);
    });

    test('target duration only accepts supported presets', () {
      expect(GameLengthConfig.targetDuration(60), GameLengthConfig.standard60);
      expect(GameLengthConfig.targetDuration(90), GameLengthConfig.normal90);
      expect(GameLengthConfig.targetDuration(120), GameLengthConfig.long120);
      expect(() => GameLengthConfig.targetDuration(45), throwsArgumentError);
    });

    test('target durations estimate turns from multiplayer cadence', () {
      expect(GameLengthConfig.estimatedMultiplayerTurnSeconds, 30);
      expect(GameLengthConfig.turnLimitForTargetMinutes(60), 120);
      expect(GameLengthConfig.turnLimitForTargetMinutes(90), 180);
      expect(GameLengthConfig.turnLimitForTargetMinutes(120), 240);
      expect(
        GameLengthConfig.turnLimitForTargetMinutes(
          60,
          estimatedTurnSeconds: 20,
        ),
        180,
      );
      expect(GameLengthConfig.normal90.turnLimit, 180);
      expect(GameLengthConfig.long120.turnLimit, 240);
    });

    test('serializes and deserializes clean ruleset JSON', () {
      for (final gameLength in [
        GameLengthConfig.standard60,
        GameLengthConfig.normal90,
        GameLengthConfig.long120,
        GameLengthConfig.unlimited,
      ]) {
        final rules = MatchRules.forGameLength(gameLength);

        final restored = MatchRules.fromJson(rules.toJson());

        expect(restored, rules);
        expect(restored.toJson(), rules.toJson());
      }
    });

    test('rejects malformed ruleset payloads', () {
      expect(
        () => GameLengthConfig.fromJson(const {'kind': 'unlimited'}),
        throwsFormatException,
      );
    });
  });
}
