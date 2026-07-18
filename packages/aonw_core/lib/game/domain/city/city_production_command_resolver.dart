import 'package:aonw_core/game/domain/city/city_production_queue.dart';
import 'package:aonw_core/game/domain/city/city_production_target.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_specialization.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/technology_id.dart';

/// Persistence-neutral result of applying a city-production command.
///
/// Rejections and accepted semantic no-ops preserve [cities] identity. A
/// changed collection is owned by the result and cannot be mutated.
final class CityProductionCommandResult {
  const CityProductionCommandResult._accepted({required this.cities})
    : accepted = true,
      reason = null;

  const CityProductionCommandResult._rejected({
    required this.cities,
    required this.reason,
  }) : accepted = false;

  final bool accepted;
  final String? reason;
  final List<GameCity> cities;
}

/// Applies authoritative city-production rules without a state container.
abstract final class CityProductionCommandResolver {
  static CityProductionCommandResult startCityProject({
    required List<GameCity> cities,
    required StartCityProjectCommand command,
    required String actorPlayerId,
    required CityRuleset cityRuleset,
    required PaceBalance paceBalance,
  }) {
    final cityIndex = _cityIndexById(cities, command.cityId);
    if (cityIndex == null) return _reject(cities, 'city_not_found');

    final city = cities[cityIndex];
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject(cities, 'city_not_controlled');
    }

    final target = ProjectProductionTarget(command.projectType);
    if (city.productionQueue?.target == target) {
      return CityProductionCommandResult._accepted(cities: cities);
    }

    return CityProductionCommandResult._accepted(
      cities: List<GameCity>.unmodifiable([
        for (var index = 0; index < cities.length; index++)
          if (index == cityIndex)
            _queueProject(city, target, cityRuleset, paceBalance)
          else
            cities[index],
      ]),
    );
  }

  static CityProductionCommandResult setCitySpecialization({
    required List<GameCity> cities,
    required ResearchState research,
    required SetCitySpecializationCommand command,
    required String actorPlayerId,
  }) {
    final cityIndex = _cityIndexById(cities, command.cityId);
    if (cityIndex == null) return _reject(cities, 'city_not_found');

    final city = cities[cityIndex];
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject(cities, 'city_not_controlled');
    }
    if (!research
        .forPlayer(city.ownerPlayerId)
        .hasUnlocked(TechnologyId.specialization)) {
      return _reject(cities, 'city_specialization_locked');
    }
    if (city.specialization == command.specialization) {
      return _reject(cities, 'city_specialization_unchanged');
    }
    if (!CitySpecializationRules.hasRequiredBuilding(
      city.buildings,
      command.specialization,
    )) {
      return _reject(cities, 'city_specialization_missing_building');
    }

    return CityProductionCommandResult._accepted(
      cities: List<GameCity>.unmodifiable([
        for (var index = 0; index < cities.length; index++)
          if (index == cityIndex)
            city.copyWith(specialization: command.specialization)
          else
            cities[index],
      ]),
    );
  }

  static GameCity _queueProject(
    GameCity city,
    ProjectProductionTarget target,
    CityRuleset cityRuleset,
    PaceBalance paceBalance,
  ) {
    final activeInvestment = city.productionQueue?.investedProduction;
    final rolloverInvestment = activeInvestment == null
        ? CityProductionRules.rolloverInvestment(
            storedOverflow: city.productionOverflow,
            productionCost: CityProductionRules.targetCost(
              target,
              ruleset: cityRuleset,
              paceBalance: paceBalance,
            ),
          )
        : 0;
    return city.copyWith(
      productionQueue: CityProductionQueue.target(
        target: target,
        investedProduction: activeInvestment ?? rolloverInvestment,
      ),
      productionOverflow: activeInvestment == null
          ? 0
          : city.productionOverflow,
    );
  }

  static int? _cityIndexById(List<GameCity> cities, String cityId) {
    for (var index = 0; index < cities.length; index++) {
      if (cities[index].id == cityId) return index;
    }
    return null;
  }

  static CityProductionCommandResult _reject(
    List<GameCity> cities,
    String reason,
  ) {
    return CityProductionCommandResult._rejected(
      cities: cities,
      reason: reason,
    );
  }
}
