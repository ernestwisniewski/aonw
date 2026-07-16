import 'package:aonw_core/game/domain/city/city_expansion_selector.dart';
import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

class PersistentCityExpansionResult {
  const PersistentCityExpansionResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final String? reason;
}

class PersistentCityExpansionResolver {
  const PersistentCityExpansionResolver();

  PersistentCityExpansionResult selectExpansionHex({
    required PersistentGameState state,
    required SelectCityExpansionHexCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    final cityIndex = _cityIndexById(state.cities, command.cityId);
    if (cityIndex == null) return _reject(state, 'city_not_found');

    final city = state.cities[cityIndex];
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'city_not_controlled');
    }

    final target = CityHex(col: command.col, row: command.row);
    if (!_isCandidate(
      city: city,
      target: target,
      state: state,
      mapTiles: mapTiles,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    )) {
      return _reject(state, 'city_expansion_hex_unavailable');
    }

    final updatedCity = city.copyWith(preferredExpansionHex: target);
    return PersistentCityExpansionResult(
      accepted: true,
      state: state.copyWith(
        cities: _replaceCityAt(state.cities, cityIndex, updatedCity),
      ),
    );
  }

  PersistentCityExpansionResult _reject(
    PersistentGameState state,
    String reason,
  ) {
    return PersistentCityExpansionResult(
      accepted: false,
      state: state,
      reason: reason,
    );
  }

  static bool _isCandidate({
    required GameCity city,
    required CityHex target,
    required PersistentGameState state,
    required MapTileLookup mapTiles,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: city.ownerPlayerId,
      research: state.research,
      ruleset: technologyRuleset,
    );
    final candidates = CityExpansionSelector.candidatesFor(
      city: city,
      mapTiles: mapTiles,
      cities: state.cities,
      allowCoast: true,
      allowOcean: true,
      ruleset: cityRuleset,
      technologyEffects: technologyEffects,
    );
    for (final candidate in candidates) {
      if (candidate.hex == target) return true;
    }
    return false;
  }

  static int? _cityIndexById(List<GameCity> cities, String cityId) {
    for (var i = 0; i < cities.length; i++) {
      if (cities[i].id == cityId) return i;
    }
    return null;
  }

  static List<GameCity> _replaceCityAt(
    List<GameCity> cities,
    int index,
    GameCity updated,
  ) {
    return [...cities]..[index] = updated;
  }
}
