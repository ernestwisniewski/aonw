import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city/city_building_requirement_rules.dart';
import 'package:aonw_core/game/domain/city/city_production_queue.dart';
import 'package:aonw_core/game/domain/city/city_production_target.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_specialization.dart';
import 'package:aonw_core/game/domain/city/city_unit_production_rules.dart';
import 'package:aonw_core/game/domain/city/city_unit_supply_rules.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/technology_id.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_unlock_query.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/unit_production_requirement_rules.dart';
import 'package:aonw_core/game/domain/wonder/wonder_availability_policy.dart';
import 'package:aonw_core/game/domain/wonder/wonder_registry.dart';
import 'package:aonw_core/game/domain/wonder/wonder_ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Persistence-neutral result of applying a city-production command.
///
/// Rejections preserve [cities] identity. A changed collection is owned by the
/// result and cannot be mutated.
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
  static CityProductionCommandResult startBuilding({
    required List<GameCity> cities,
    required ResearchState research,
    required StartBuildingCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
  }) {
    final cityIndex = _cityIndexById(cities, command.cityId);
    if (cityIndex == null) return _reject(cities, 'city_not_found');

    final city = cities[cityIndex];
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject(cities, 'city_not_controlled');
    }

    final technologyUnlocked = TechnologyUnlockQuery.hasBuildingUnlocked(
      playerId: city.ownerPlayerId,
      buildingType: command.buildingType,
      research: research,
      ruleset: technologyRuleset,
    );
    final requirementsMet = CityBuildingRequirementRules.meetsRequirements(
      city: city,
      buildingType: command.buildingType,
      mapTiles: mapTiles,
      ruleset: cityRuleset,
      research: research,
    );
    if (!CityProductionRules.canBuild(
      city.buildings,
      command.buildingType,
      ruleset: cityRuleset,
      technologyUnlocked: technologyUnlocked,
      requirementsMet: requirementsMet,
    )) {
      return _reject(cities, 'building_not_available');
    }

    final target = BuildingProductionTarget(command.buildingType);
    return CityProductionCommandResult._accepted(
      cities: List<GameCity>.unmodifiable([
        for (var index = 0; index < cities.length; index++)
          if (index == cityIndex)
            _queueProduction(
              city,
              target,
              productionCost: CityProductionRules.buildingProductionCost(
                command.buildingType,
                ruleset: cityRuleset,
                paceBalance: paceBalance,
              ),
            )
          else
            cities[index],
      ]),
    );
  }

  static CityProductionCommandResult startUnitProduction({
    required List<GameCity> cities,
    required List<GameUnit> units,
    required List<WorldArtifact> artifacts,
    required List<FieldImprovement> fieldImprovements,
    required ResearchState research,
    required List<ResourceTradeAgreement> resourceTradeAgreements,
    required MapReadView mapView,
    required StartUnitProductionCommand command,
    required String actorPlayerId,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
  }) {
    return _StartUnitProductionResolver(
      cities: cities,
      research: research,
      command: command,
      actorPlayerId: actorPlayerId,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
      resourceRequirementsAreMet: (city) =>
          UnitProductionRequirementRules.meetsRequirements(
            playerId: city.ownerPlayerId,
            unitType: command.unitType,
            cities: cities,
            mapTiles: mapView.mapTiles,
            ruleset: cityRuleset,
            research: research,
            resourceTradeAgreements: resourceTradeAgreements,
          ),
      coastRequirementIsMet: (city) => CityUnitProductionRules.canProduceInCity(
        city: city,
        unitType: command.unitType,
        mapTiles: mapView.mapTiles,
      ),
      supplyIsAvailable: (city) => CityUnitSupplyRules.canQueueUnit(
        playerId: city.ownerPlayerId,
        unitType: command.unitType,
        cities: cities,
        units: units,
        artifacts: artifacts,
        fieldImprovements: fieldImprovements,
        mapView: mapView,
        cityRuleset: cityRuleset,
        research: research,
        technologyRuleset: technologyRuleset,
        replacingCityId: city.id,
      ),
    ).resolve();
  }

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
            _queueProduction(
              city,
              target,
              productionCost: CityProductionRules.targetCost(
                target,
                ruleset: cityRuleset,
                paceBalance: paceBalance,
              ),
            )
          else
            cities[index],
      ]),
    );
  }

  static CityProductionCommandResult startWonder({
    required List<GameCity> cities,
    required ResearchState research,
    required WonderRegistry wonderRegistry,
    required StartWonderCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    required WonderRuleset wonderRuleset,
    required PaceBalance paceBalance,
  }) {
    final cityIndex = _cityIndexById(cities, command.cityId);
    if (cityIndex == null) return _reject(cities, 'city_not_found');

    final city = cities[cityIndex];
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject(cities, 'city_not_controlled');
    }

    final availability = WonderAvailabilityPolicy.availabilityFor(
      city: city,
      wonderType: command.wonderType,
      cities: cities,
      registry: wonderRegistry,
      research: research,
      mapTiles: mapTiles,
      ruleset: wonderRuleset,
    );
    if (!availability.isAvailable) {
      return _reject(cities, 'wonder_not_available');
    }

    final target = WonderProductionTarget(command.wonderType);
    return CityProductionCommandResult._accepted(
      cities: List<GameCity>.unmodifiable([
        for (var index = 0; index < cities.length; index++)
          if (index == cityIndex)
            _queueProduction(
              city,
              target,
              productionCost: CityProductionRules.wonderProductionCost(
                command.wonderType,
                ruleset: wonderRuleset,
                paceBalance: paceBalance,
              ),
            )
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

  static GameCity _queueProduction(
    GameCity city,
    CityProductionTarget target, {
    required int productionCost,
  }) {
    final activeInvestment = city.productionQueue?.investedProduction;
    final rolloverInvestment = activeInvestment == null
        ? CityProductionRules.rolloverInvestment(
            storedOverflow: city.productionOverflow,
            productionCost: productionCost,
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

final class _StartUnitProductionResolver {
  const _StartUnitProductionResolver({
    required this.cities,
    required this.research,
    required this.command,
    required this.actorPlayerId,
    required this.cityRuleset,
    required this.technologyRuleset,
    required this.paceBalance,
    required this.resourceRequirementsAreMet,
    required this.coastRequirementIsMet,
    required this.supplyIsAvailable,
  });

  final List<GameCity> cities;
  final ResearchState research;
  final StartUnitProductionCommand command;
  final String actorPlayerId;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final PaceBalance paceBalance;
  final bool Function(GameCity city) resourceRequirementsAreMet;
  final bool Function(GameCity city) coastRequirementIsMet;
  final bool Function(GameCity city) supplyIsAvailable;

  CityProductionCommandResult resolve() {
    final cityIndex = _cityIndexById(command.cityId);
    if (cityIndex == null) return _reject('city_not_found');

    final city = cities[cityIndex];
    if (city.ownerPlayerId != actorPlayerId) {
      return _reject('city_not_controlled');
    }
    final rejectionReason = _availabilityRejectionReason(city);
    if (rejectionReason != null) return _reject(rejectionReason);

    final target = UnitProductionTarget(command.unitType);
    final updatedCity = CityProductionCommandResolver._queueProduction(
      city,
      target,
      productionCost: CityProductionRules.unitProductionCost(
        command.unitType,
        ruleset: cityRuleset,
        paceBalance: paceBalance,
      ),
    );
    return CityProductionCommandResult._accepted(
      cities: List<GameCity>.unmodifiable([
        for (var index = 0; index < cities.length; index++)
          if (index == cityIndex) updatedCity else cities[index],
      ]),
    );
  }

  String? _availabilityRejectionReason(GameCity city) {
    if (!_technologyIsAvailable(city)) {
      return 'unit_production_not_available';
    }
    if (!resourceRequirementsAreMet(city)) {
      return 'unit_production_requires_resource';
    }
    if (!coastRequirementIsMet(city)) {
      return 'unit_production_requires_coast';
    }
    if (!supplyIsAvailable(city)) return 'unit_supply_limit_reached';
    return null;
  }

  bool _technologyIsAvailable(GameCity city) {
    final technologyUnlocked = TechnologyUnlockQuery.hasUnitUnlocked(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      research: research,
      ruleset: technologyRuleset,
    );
    return CityProductionRules.canProduceUnit(
      command.unitType,
      ruleset: cityRuleset,
      technologyUnlocked: technologyUnlocked,
    );
  }

  int? _cityIndexById(String cityId) {
    for (var index = 0; index < cities.length; index++) {
      if (cities[index].id == cityId) return index;
    }
    return null;
  }

  CityProductionCommandResult _reject(String reason) {
    return CityProductionCommandResult._rejected(
      cities: cities,
      reason: reason,
    );
  }
}
