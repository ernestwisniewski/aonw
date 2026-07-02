import 'package:aonw_core/game/domain/stability/stability_band.dart';
import 'package:aonw_core/game/domain/stability/stability_modifier.dart';
import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';

abstract final class StabilityPolicy {
  static double normalizeRelativeStanding(double relativeStanding) {
    if (relativeStanding.isNaN) return 0.0;
    return relativeStanding.clamp(-1.0, 1.0).toDouble();
  }

  /// Relative standing in [-1, 1] derived from a player's map control share.
  /// A player at their fair share (100% / players) is neutral (0); a runaway
  /// leader trends toward +1 (harder to stay content) and a trailing player
  /// toward -1 (a catch-up shift up).
  static double relativeStandingFor({
    required double controlPercent,
    required int playerCount,
  }) {
    final count = playerCount <= 0 ? 1 : playerCount;
    final fairShare = 100.0 / count;
    return normalizeRelativeStanding((controlPercent - fairShare) / fairShare);
  }

  static int effectiveNet(
    int net, {
    required double relativeStanding,
    required StabilityRuleset ruleset,
  }) {
    final normalizedStanding = normalizeRelativeStanding(relativeStanding);
    final shift = (normalizedStanding * ruleset.relativeStandingOffset).round();
    return net - shift;
  }

  static StabilityBand bandFor(
    int net, {
    double relativeStanding = 0.0,
    StabilityRuleset ruleset = StabilityRuleset.standard,
  }) {
    final effective = effectiveNet(
      net,
      relativeStanding: relativeStanding,
      ruleset: ruleset,
    );
    if (effective >= ruleset.contentThreshold) return StabilityBand.content;
    if (effective <= ruleset.unrestThreshold) return StabilityBand.unrest;
    if (effective < 0) return StabilityBand.strained;
    return StabilityBand.stable;
  }

  static StabilityModifier modifierFor(StabilityBand band) {
    return switch (band) {
      StabilityBand.content => const StabilityModifier(
        productionMultiplier: 1.0,
        goldMultiplier: 1.0,
        foodBonus: 1,
        haltsGrowth: false,
      ),
      StabilityBand.stable => StabilityModifier.stable,
      StabilityBand.strained => const StabilityModifier(
        productionMultiplier: 1.0,
        goldMultiplier: 0.9,
        foodBonus: 0,
        haltsGrowth: true,
      ),
      StabilityBand.unrest => const StabilityModifier(
        productionMultiplier: 0.75,
        goldMultiplier: 0.75,
        foodBonus: 0,
        haltsGrowth: true,
      ),
    };
  }
}
