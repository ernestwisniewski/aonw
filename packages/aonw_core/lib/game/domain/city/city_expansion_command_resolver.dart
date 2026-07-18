import 'package:aonw_core/game/domain/city/city_expansion_selector.dart';
import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/technology_effect_summary.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_rulesets.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Persistence-neutral result of selecting a preferred city expansion hex.
///
/// Rejections and accepted semantic no-ops preserve [cities] identity. A
/// changed collection is owned by the result and cannot be mutated.
final class CityExpansionCommandResult {
  const CityExpansionCommandResult._accepted({required this.cities})
    : accepted = true,
      reason = null;

  const CityExpansionCommandResult._rejected({
    required this.cities,
    required this.reason,
  }) : accepted = false;

  final bool accepted;
  final String? reason;
  final List<GameCity> cities;
}

/// Applies city-expansion selection rules without a state container.
abstract final class CityExpansionCommandResolver {
  static CityExpansionCommandResult selectExpansionHex({
    required List<GameCity> cities,
    required ResearchState research,
    required SelectCityExpansionHexCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    final cityIndex = _cityIndexById(cities, command.cityId);
    if (cityIndex == null) return _reject(cities, 'city_not_found');

    final city = cities[cityIndex];
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject(cities, 'city_not_controlled');
    }

    final target = CityHex(col: command.col, row: command.row);
    if (!_isCandidate(
      city: city,
      target: target,
      cities: cities,
      research: research,
      mapTiles: mapTiles,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    )) {
      return _reject(cities, 'city_expansion_hex_unavailable');
    }
    if (city.preferredExpansionHex == target) {
      return CityExpansionCommandResult._accepted(cities: cities);
    }

    return CityExpansionCommandResult._accepted(
      cities: List<GameCity>.unmodifiable([
        for (var index = 0; index < cities.length; index++)
          if (index == cityIndex)
            city.copyWith(preferredExpansionHex: target)
          else
            cities[index],
      ]),
    );
  }

  static bool _isCandidate({
    required GameCity city,
    required CityHex target,
    required List<GameCity> cities,
    required ResearchState research,
    required MapTileLookup mapTiles,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: city.ownerPlayerId,
      research: research,
      ruleset: technologyRuleset,
    );
    final candidates = CityExpansionSelector.candidatesFor(
      city: city,
      mapTiles: mapTiles,
      cities: cities,
      allowCoast: true,
      allowOcean: true,
      ruleset: cityRuleset,
      technologyEffects: technologyEffects,
    );
    return candidates.any((candidate) => candidate.hex == target);
  }

  static int? _cityIndexById(List<GameCity> cities, String cityId) {
    for (var index = 0; index < cities.length; index++) {
      if (cities[index].id == cityId) return index;
    }
    return null;
  }

  static CityExpansionCommandResult _reject(
    List<GameCity> cities,
    String reason,
  ) {
    return CityExpansionCommandResult._rejected(cities: cities, reason: reason);
  }
}
