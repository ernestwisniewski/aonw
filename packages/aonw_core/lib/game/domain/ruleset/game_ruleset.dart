import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/wonder.dart';

class GameRuleset {
  final CityRuleset city;
  final CombatRuleset combat;
  final TechnologyRuleset technology;
  final PaceBalance paceBalance;
  final StabilityRuleset stability;
  final WonderRuleset wonders;

  const GameRuleset({
    required this.city,
    this.combat = CombatRuleset.standard,
    required this.technology,
    this.paceBalance = PaceBalance.unlimited,
    this.stability = StabilityRuleset.standard,
    this.wonders = WonderRuleset.standard,
  });

  factory GameRuleset.standard() => defaults;

  static const GameRuleset defaults = GameRuleset(
    city: CityRulesets.standard,
    combat: CombatRuleset.standard,
    technology: TechnologyRulesets.standard,
    stability: StabilityRuleset.standard,
    wonders: WonderRuleset.standard,
  );

  GameRuleset copyWith({
    CityRuleset? city,
    CombatRuleset? combat,
    TechnologyRuleset? technology,
    PaceBalance? paceBalance,
    StabilityRuleset? stability,
    WonderRuleset? wonders,
  }) {
    return GameRuleset(
      city: city ?? this.city,
      combat: combat ?? this.combat,
      technology: technology ?? this.technology,
      paceBalance: paceBalance ?? this.paceBalance,
      stability: stability ?? this.stability,
      wonders: wonders ?? this.wonders,
    );
  }
}
