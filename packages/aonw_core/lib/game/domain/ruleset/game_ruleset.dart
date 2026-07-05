import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

class GameRuleset {
  final CityRuleset city;
  final CombatRuleset combat;
  final TechnologyRuleset technology;
  final PaceBalance paceBalance;
  final StabilityRuleset stability;

  const GameRuleset({
    required this.city,
    this.combat = CombatRuleset.standard,
    required this.technology,
    this.paceBalance = PaceBalance.unlimited,
    this.stability = StabilityRuleset.standard,
  });

  factory GameRuleset.standard() => _standard;

  static const GameRuleset defaults = GameRuleset(
    city: CityRulesets.standard,
    combat: CombatRuleset.standard,
    technology: TechnologyRulesets.standard,
    stability: StabilityRuleset.standard,
  );

  static final GameRuleset _standard = defaults.copyWith(
    city: CityRulesets.fromUnitSpecs(UnitSpecResolver.standard),
  );

  GameRuleset copyWith({
    CityRuleset? city,
    CombatRuleset? combat,
    TechnologyRuleset? technology,
    PaceBalance? paceBalance,
    StabilityRuleset? stability,
  }) {
    return GameRuleset(
      city: city ?? this.city,
      combat: combat ?? this.combat,
      technology: technology ?? this.technology,
      paceBalance: paceBalance ?? this.paceBalance,
      stability: stability ?? this.stability,
    );
  }
}
