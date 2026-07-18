import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/toggle_worked_hex_resolver.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';

final class DomainCityWorkedHexResult {
  const DomainCityWorkedHexResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final String? reason;
}

/// Canonical-state adapter for the persistence-neutral worked-hex resolver.
final class DomainCityWorkedHexResolver {
  const DomainCityWorkedHexResolver();

  DomainCityWorkedHexResult toggleWorkedHex({
    required DomainState state,
    required ToggleWorkedHexCommand command,
    required String actorPlayerId,
    CityRuleset cityRuleset = CityRulesets.standard,
  }) {
    final result = ToggleWorkedHexResolver.toggleWorkedHex(
      cities: state.cities,
      command: command,
      actorPlayerId: actorPlayerId,
      cityRuleset: cityRuleset,
    );
    if (!result.accepted) {
      return DomainCityWorkedHexResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return DomainCityWorkedHexResult(
      accepted: true,
      state: state.copyWith(cities: result.cities),
    );
  }
}
