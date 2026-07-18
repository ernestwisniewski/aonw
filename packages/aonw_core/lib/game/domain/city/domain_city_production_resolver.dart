import 'package:aonw_core/game/domain/city/city_production_command_resolver.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';

final class DomainCityProductionResult {
  const DomainCityProductionResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final String? reason;
}

/// Canonical-state adapter for the state-neutral city-production resolver.
final class DomainCityProductionResolver {
  const DomainCityProductionResolver();

  DomainCityProductionResult startCityProject({
    required DomainState state,
    required StartCityProjectCommand command,
    required String actorPlayerId,
    CityRuleset cityRuleset = CityRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final result = CityProductionCommandResolver.startCityProject(
      cities: state.cities,
      command: command,
      actorPlayerId: actorPlayerId,
      cityRuleset: cityRuleset,
      paceBalance: paceBalance,
    );
    if (!result.accepted) {
      return DomainCityProductionResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return DomainCityProductionResult(
      accepted: true,
      state: identical(result.cities, state.cities)
          ? state
          : state.copyWith(cities: result.cities),
    );
  }
}
