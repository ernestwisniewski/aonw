import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/command.dart';

/// Persistence-neutral result of toggling one manually worked city hex.
final class ToggleWorkedHexResult {
  ToggleWorkedHexResult._accepted({required Iterable<GameCity> cities})
    : accepted = true,
      reason = null,
      cities = List<GameCity>.unmodifiable(
        cities.map((city) => city.immutableSnapshot()),
      );

  const ToggleWorkedHexResult._rejected({
    required this.cities,
    required this.reason,
  }) : accepted = false;

  final bool accepted;
  final String? reason;
  final List<GameCity> cities;
}

/// Applies the worked-hex rules without depending on a state representation.
abstract final class ToggleWorkedHexResolver {
  static ToggleWorkedHexResult toggleWorkedHex({
    required List<GameCity> cities,
    required ToggleWorkedHexCommand command,
    required String actorPlayerId,
    CityRuleset cityRuleset = CityRulesets.standard,
  }) {
    final cityIndex = _cityIndexById(cities, command.cityId);
    if (cityIndex == null) return _reject(cities, 'city_not_found');

    final city = cities[cityIndex];
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject(cities, 'city_not_controlled');
    }

    final target = CityHex(col: command.col, row: command.row);
    if (target == city.center || !city.controlledHexes.contains(target)) {
      return _reject(cities, 'worked_hex_unavailable');
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
        return _reject(cities, 'worked_hex_limit_reached');
      }
      updatedWorkedHexes = [...manualHexes, target];
    }

    final updatedCities = List<GameCity>.of(cities);
    updatedCities[cityIndex] = city.copyWith(workedHexes: updatedWorkedHexes);
    return ToggleWorkedHexResult._accepted(cities: updatedCities);
  }

  static ToggleWorkedHexResult _reject(List<GameCity> cities, String reason) {
    return ToggleWorkedHexResult._rejected(cities: cities, reason: reason);
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
}
