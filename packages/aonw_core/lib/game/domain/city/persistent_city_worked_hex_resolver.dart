import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state.dart';

class PersistentCityWorkedHexResult {
  const PersistentCityWorkedHexResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final String? reason;
}

class PersistentCityWorkedHexResolver {
  const PersistentCityWorkedHexResolver();

  PersistentCityWorkedHexResult toggleWorkedHex({
    required PersistentGameState state,
    required ToggleWorkedHexCommand command,
    required String actorPlayerId,
    CityRuleset cityRuleset = CityRulesets.standard,
  }) {
    final cityIndex = _cityIndexById(state.cities, command.cityId);
    if (cityIndex == null) return _reject(state, 'city_not_found');

    final city = state.cities[cityIndex];
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'city_not_controlled');
    }

    final target = CityHex(col: command.col, row: command.row);
    if (target == city.center || !city.controlledHexes.contains(target)) {
      return _reject(state, 'worked_hex_unavailable');
    }

    final manualHexes = _normalizedWorkedHexes(city, cityRuleset);
    late final List<CityHex> updatedWorkedHexes;
    if (manualHexes.contains(target)) {
      updatedWorkedHexes = [
        for (final hex in manualHexes)
          if (hex != target) hex,
      ];
    } else {
      final limit = cityRuleset.progression.workedHexLimitForPopulation(
        city.population,
      );
      if (manualHexes.length >= limit) {
        return _reject(state, 'worked_hex_limit_reached');
      }
      updatedWorkedHexes = [...manualHexes, target];
    }

    final updatedCity = city.copyWith(workedHexes: updatedWorkedHexes);
    return PersistentCityWorkedHexResult(
      accepted: true,
      state: state.copyWith(
        cities: _replaceCityAt(state.cities, cityIndex, updatedCity),
      ),
    );
  }

  PersistentCityWorkedHexResult _reject(
    PersistentGameState state,
    String reason,
  ) {
    return PersistentCityWorkedHexResult(
      accepted: false,
      state: state,
      reason: reason,
    );
  }

  static List<CityHex> _normalizedWorkedHexes(
    GameCity city,
    CityRuleset cityRuleset,
  ) {
    final limit = cityRuleset.progression.workedHexLimitForPopulation(
      city.population,
    );
    if (limit <= 0) return const [];

    final normalized = <CityHex>[];
    final seen = <CityHex>{};
    for (final hex in city.workedHexes) {
      if (normalized.length >= limit) break;
      if (hex == city.center) continue;
      if (!city.controlledHexes.contains(hex)) continue;
      if (!seen.add(hex)) continue;
      normalized.add(hex);
    }
    return normalized;
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
