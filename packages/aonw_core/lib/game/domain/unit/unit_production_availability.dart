import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city/city_production_queue.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_unit_production_rules.dart';
import 'package:aonw_core/game/domain/city/city_unit_supply_rules.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_unlock_query.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_production_requirement_rules.dart';
import 'package:aonw_core/game/domain/unit/unit_strategic_resource_availability.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

sealed class UnitProductionBlocker {
  const UnitProductionBlocker();

  String get rejectionCode;
}

final class UnitTechnologyBlocker extends UnitProductionBlocker {
  const UnitTechnologyBlocker();

  @override
  String get rejectionCode => 'unit_production_not_available';
}

final class UnitPresenceResourceBlocker extends UnitProductionBlocker {
  const UnitPresenceResourceBlocker(this.resources);

  final Set<ResourceType> resources;

  @override
  String get rejectionCode => 'unit_production_requires_resource';
}

final class UnitStrategicResourceBlocker extends UnitProductionBlocker {
  const UnitStrategicResourceBlocker(this.availability);

  final UnitStrategicResourceAvailability availability;

  @override
  String get rejectionCode => 'unit_production_missing_strategic_resource';
}

final class UnitCoastBlocker extends UnitProductionBlocker {
  const UnitCoastBlocker();

  @override
  String get rejectionCode => 'unit_production_requires_coast';
}

final class UnitSupplyBlocker extends UnitProductionBlocker {
  const UnitSupplyBlocker();

  @override
  String get rejectionCode => 'unit_supply_limit_reached';
}

typedef UnitProductionAvailabilityQuery = ({
  String playerId,
  GameCity city,
  GameUnitType unitType,
  Iterable<GameCity> cities,
  Iterable<GameUnit> units,
  Iterable<WorldArtifact> artifacts,
  Iterable<FieldImprovement> fieldImprovements,
  ResearchState research,
  Iterable<ResourceTradeAgreement> resourceTradeAgreements,
  MapReadView mapView,
  CityRuleset cityRuleset,
  TechnologyRuleset technologyRuleset,
  StrategicResourceAccounts strategicResources,
  int? preferredResourceOptionIndex,
});

final class UnitProductionAvailability {
  const UnitProductionAvailability({
    required this.blockers,
    required this.strategic,
  });

  final List<UnitProductionBlocker> blockers;
  final UnitStrategicResourceAvailability? strategic;

  bool get isAvailable => blockers.isEmpty;

  UnitProductionBlocker? get primaryBlocker => blockers.firstOrNull;

  String? get rejectionCode => primaryBlocker?.rejectionCode;

  StrategicResourceBundle get selectedAllocation =>
      strategic?.selectedAllocation ?? StrategicResourceBundle.empty;

  static UnitProductionAvailability evaluate(
    UnitProductionAvailabilityQuery query,
  ) {
    final technologyAvailable = _technologyAvailable(query);
    final missingPresence = _missingPresenceResources(query);
    final strategic = _strategicAvailability(query);
    final coastAvailable = CityUnitProductionRules.canProduceInCity(
      city: query.city,
      unitType: query.unitType,
      mapTiles: query.mapView.mapTiles,
    );
    final supplyAvailable = _supplyAvailable(query);
    return UnitProductionAvailability(
      blockers: List.unmodifiable([
        if (!technologyAvailable) const UnitTechnologyBlocker(),
        if (missingPresence.isNotEmpty)
          UnitPresenceResourceBlocker(Set.unmodifiable(missingPresence)),
        if (!strategic.isAvailable) UnitStrategicResourceBlocker(strategic),
        if (!coastAvailable) const UnitCoastBlocker(),
        if (!supplyAvailable) const UnitSupplyBlocker(),
      ]),
      strategic: strategic,
    );
  }

  /// Fast boolean query for planners that do not render blocker details.
  static bool canProduce(UnitProductionAvailabilityQuery query) {
    if (!_technologyAvailable(query)) return false;
    if (_missingPresenceResources(query).isNotEmpty) return false;
    if (!_strategicAvailability(query).isAvailable) return false;
    if (!CityUnitProductionRules.canProduceInCity(
      city: query.city,
      unitType: query.unitType,
      mapTiles: query.mapView.mapTiles,
    )) {
      return false;
    }
    return _supplyAvailable(query);
  }
}

bool _technologyAvailable(UnitProductionAvailabilityQuery query) =>
    CityProductionRules.canProduceUnit(
      query.unitType,
      ruleset: query.cityRuleset,
      technologyUnlocked: TechnologyUnlockQuery.hasUnitUnlocked(
        playerId: query.playerId,
        unitType: query.unitType,
        research: query.research,
        ruleset: query.technologyRuleset,
      ),
    );

Set<ResourceType> _missingPresenceResources(
  UnitProductionAvailabilityQuery query,
) => UnitProductionRequirementRules.missingResourceChoices(
  playerId: query.playerId,
  unitType: query.unitType,
  cities: query.cities,
  mapTiles: query.mapView.mapTiles,
  ruleset: query.cityRuleset,
  research: query.research,
  resourceTradeAgreements: query.resourceTradeAgreements,
);

UnitStrategicResourceAvailability _strategicAvailability(
  UnitProductionAvailabilityQuery query,
) => UnitStrategicResourceAvailability.forUnit(
  playerId: query.playerId,
  unitType: query.unitType,
  definition: query.cityRuleset.unitDefinitionFor(query.unitType),
  accounts: query.strategicResources,
  replacingCity: query.city,
  preferredOptionIndex: query.preferredResourceOptionIndex,
);

bool _supplyAvailable(UnitProductionAvailabilityQuery query) =>
    CityUnitSupplyRules.canQueueUnit(
      playerId: query.playerId,
      unitType: query.unitType,
      cities: query.cities,
      units: query.units,
      artifacts: query.artifacts,
      fieldImprovements: query.fieldImprovements,
      mapView: query.mapView,
      cityRuleset: query.cityRuleset,
      research: query.research,
      technologyRuleset: query.technologyRuleset,
      replacingCityId: query.city.id,
    );
