import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

final class HudStrategicResourceRow {
  const HudStrategicResourceRow({
    required this.resource,
    this.stockpiled = true,
    this.controlledDeposits = 0,
    required this.available,
    required this.allocated,
    required this.domesticProduction,
    required this.imports,
    required this.exports,
    required this.sourceCount,
    required this.shortage,
  });

  final ResourceType resource;
  final bool stockpiled;
  final int controlledDeposits;
  final int available;
  final int allocated;
  final int domesticProduction;
  final int imports;
  final int exports;
  final int sourceCount;
  final bool shortage;

  int get storedTotal => available + allocated;
  int get netPerTurn => domesticProduction + imports - exports;
}

final class HudStrategicResourceAllocation {
  const HudStrategicResourceAllocation({
    required this.city,
    required this.bundle,
  });

  final GameCity city;
  final StrategicResourceBundle bundle;
}

final class HudStrategicResourceSource {
  const HudStrategicResourceSource({
    required this.city,
    required this.hex,
    required this.resource,
    this.improvement,
    this.amountPerTurn,
  });

  final GameCity city;
  final CityHex hex;
  final ResourceType resource;
  final FieldImprovementType? improvement;
  final int? amountPerTurn;
}

/// One player-scoped read model shared by the top strip and resource popup.
///
/// It derives presentation values only; extraction, allocation, and transfer
/// rules remain authoritative in `aonw_core`.
final class HudStrategicResourceSummary {
  const HudStrategicResourceSummary({
    required this.enabled,
    required this.rows,
    required this.allocations,
    required this.sources,
  });

  static const empty = HudStrategicResourceSummary(
    enabled: false,
    rows: [],
    allocations: [],
    sources: [],
  );

  final bool enabled;
  final List<HudStrategicResourceRow> rows;
  final List<HudStrategicResourceAllocation> allocations;
  final List<HudStrategicResourceSource> sources;

  int get availableTypeCount => rows.where((row) => row.available > 0).length;

  int get shortageTypeCount => rows.where((row) => row.shortage).length;

  int get storedTotal => rows.fold(0, (sum, row) => sum + row.storedTotal);

  factory HudStrategicResourceSummary.fromGameState({
    required GameClientState state,
    required String playerId,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
  }) {
    if (playerId.isEmpty) return empty;

    final production = StrategicResourceProductionRules.forPlayer(
      playerId: playerId,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      mapTiles: mapData,
      research: state.research,
    );
    final network = EmpireResourceNetworkRules.forPlayer(
      playerId: playerId,
      cities: state.cities,
      mapTiles: mapData,
      research: state.research,
      ruleset: cityRuleset,
      resourceTradeAgreements: state.resourceTradeAgreements,
    );
    final allocations = _strategicAllocations(state.cities, playerId);
    final allocated = _allocatedBundle(allocations);
    final missingResources = _missingUnlockedResources(
      state: state,
      playerId: playerId,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    );
    return HudStrategicResourceSummary(
      enabled: true,
      rows: _strategicRows(
        state: state,
        playerId: playerId,
        allocated: allocated,
        production: production,
        network: network,
        missingResources: missingResources,
      ),
      allocations: List.unmodifiable(allocations),
      sources: List.unmodifiable(
        _strategicSources(
          state: state,
          inventory: network.visibleInventory,
          production: production,
        ),
      ),
    );
  }
}

List<HudStrategicResourceAllocation> _strategicAllocations(
  Iterable<GameCity> cities,
  String playerId,
) => [
  for (final city in cities)
    if (city.ownerPlayerId == playerId &&
        city.productionQueue != null &&
        !city.productionQueue!.resourceAllocation.isEmpty)
      HudStrategicResourceAllocation(
        city: city,
        bundle: city.productionQueue!.resourceAllocation,
      ),
];

StrategicResourceBundle _allocatedBundle(
  Iterable<HudStrategicResourceAllocation> allocations,
) => StrategicResourceBundle({
  for (final resource in ResourceCatalog.stockpiledResources)
    resource: allocations.fold(
      0,
      (sum, allocation) => sum + allocation.bundle.amountFor(resource),
    ),
});

Set<ResourceType> _missingUnlockedResources({
  required GameClientState state,
  required String playerId,
  required CityRuleset cityRuleset,
  required TechnologyRuleset technologyRuleset,
}) {
  final missing = <ResourceType>{};
  for (final unitType in GameUnitType.values) {
    if (!_unitIsUnlocked(state, playerId, unitType, technologyRuleset)) {
      continue;
    }
    final availability = UnitStrategicResourceAvailability.forUnit(
      playerId: playerId,
      unitType: unitType,
      definition: cityRuleset.unitDefinitionFor(unitType),
      accounts: state.strategicResources,
    );
    if (!availability.isAvailable) {
      missing.addAll(availability.missing.amounts.keys);
    }
  }
  return missing;
}

bool _unitIsUnlocked(
  GameClientState state,
  String playerId,
  GameUnitType unitType,
  TechnologyRuleset technologyRuleset,
) => TechnologyUnlockQuery.hasUnitUnlocked(
  playerId: playerId,
  unitType: unitType,
  research: state.research,
  ruleset: technologyRuleset,
);

List<HudStrategicResourceRow> _strategicRows({
  required GameClientState state,
  required String playerId,
  required StrategicResourceBundle allocated,
  required StrategicResourceProductionProjection production,
  required EmpireResourceNetwork network,
  required Set<ResourceType> missingResources,
}) {
  final stockpile = state.strategicResources.forPlayer(playerId);
  return List.unmodifiable([
    for (final resource in ResourceCatalog.strategicResources)
      HudStrategicResourceRow(
        resource: resource,
        stockpiled: ResourceCatalog.isStockpiled(resource),
        controlledDeposits: network.visibleInventory.countFor(resource),
        available: ResourceCatalog.isStockpiled(resource)
            ? stockpile.amountFor(resource)
            : network.visibleCountFor(resource),
        allocated: ResourceCatalog.isStockpiled(resource)
            ? allocated.amountFor(resource)
            : 0,
        domesticProduction: production.output.amountFor(resource),
        imports: _tradeCount(state, playerId, resource, imports: true),
        exports: _tradeCount(state, playerId, resource, imports: false),
        sourceCount: ResourceCatalog.isStockpiled(resource)
            ? production.sources
                  .where((source) => source.resource == resource)
                  .length
            : network.visibleInventory.countFor(resource),
        shortage: missingResources.contains(resource),
      ),
  ]);
}

List<HudStrategicResourceSource> _strategicSources({
  required GameClientState state,
  required CityResourceInventory inventory,
  required StrategicResourceProductionProjection production,
}) => [
  for (final source in inventory.sources)
    if (ResourceCatalog.isStrategic(source.resource))
      HudStrategicResourceSource(
        city: state.cities.firstWhere(
          (candidate) => candidate.id == source.cityId,
        ),
        hex: source.hex,
        resource: source.resource,
        improvement: _improvementAt(state, source.hex)?.type,
        amountPerTurn: _productionAt(production, source)?.amountPerTurn,
      ),
];

FieldImprovement? _improvementAt(GameClientState state, CityHex hex) {
  for (final improvement in state.fieldImprovements) {
    if (improvement.hex == hex) return improvement;
  }
  return null;
}

StrategicResourceProductionSource? _productionAt(
  StrategicResourceProductionProjection production,
  CityResourceSource source,
) {
  for (final candidate in production.sources) {
    if (candidate.cityId == source.cityId &&
        candidate.hex == source.hex &&
        candidate.resource == source.resource) {
      return candidate;
    }
  }
  return null;
}

int _tradeCount(
  GameClientState state,
  String playerId,
  ResourceType resource, {
  required bool imports,
}) => state.resourceTradeAgreements
    .where((agreement) {
      final participantId = imports
          ? agreement.importerPlayerId
          : agreement.exporterPlayerId;
      return agreement.isActive &&
          participantId == playerId &&
          agreement.resource == resource;
    })
    .fold(0, (sum, agreement) => sum + agreement.amountPerTurn);
