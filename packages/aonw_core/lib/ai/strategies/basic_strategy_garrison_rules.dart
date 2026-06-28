import 'dart:math' as math;

import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/defensive_stance.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class BasicStrategyGarrisonRules {
  const BasicStrategyGarrisonRules();

  List<BasicStrategyGarrisonNeed> cityNeeds(GameView view, AiContext context) {
    final defenses = context.strategicPlan?.defenses ?? const {};
    return [
      for (final city in view.ownCities)
        BasicStrategyGarrisonNeed(
          city: city,
          defense: defenses[city.id],
          requiredCount: requiredGarrisonCount(
            defenses[city.id],
            context.strategicPlan?.mode,
          ),
        ),
    ]..sort(compareNeeds);
  }

  int requiredGarrisonCount(
    StrategicDefenseAssignment? defense,
    StrategicMode? mode,
  ) {
    final threatLevel = defense?.threatLevel ?? 0;
    final threatNeed =
        threatLevel >= 24 ||
            (mode == StrategicMode.military && threatLevel >= 18)
        ? 2
        : 1;
    final assignedNeed = defense?.assignedUnitIds.length ?? 0;
    return math.max(threatNeed, assignedNeed);
  }

  bool canServeAsDefender(GameUnit unit, CombatRuleset ruleset) {
    if (unit.isWorker ||
        unit.type == GameUnitType.settler ||
        unit.hasSettlers ||
        unit.isWorking ||
        unit.queuedPath != null) {
      return false;
    }
    final stats = UnitCombatStats.derive(unit, ruleset: ruleset);
    return stats.attack > 0 || stats.defense > 0;
  }

  int compareNeeds(BasicStrategyGarrisonNeed a, BasicStrategyGarrisonNeed b) {
    final threatCompare = b.threatLevel.compareTo(a.threatLevel);
    if (threatCompare != 0) return threatCompare;
    final requiredCompare = b.requiredCount.compareTo(a.requiredCount);
    if (requiredCompare != 0) return requiredCompare;
    return a.city.id.compareTo(b.city.id);
  }
}

final class BasicStrategyGarrisonNeed {
  const BasicStrategyGarrisonNeed({
    required this.city,
    required this.defense,
    required this.requiredCount,
  });

  final GameCity city;
  final StrategicDefenseAssignment? defense;
  final int requiredCount;

  int get threatLevel => defense?.threatLevel ?? 0;

  Set<String> get preferredUnitIds =>
      defense == null ? const <String>{} : defense!.assignedUnitIds.toSet();
}
