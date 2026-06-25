import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/resource_visibility_rules.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_production_requirement.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

class CityResourceSource {
  final String cityId;
  final CityHex hex;
  final ResourceType resource;

  const CityResourceSource({
    required this.cityId,
    required this.hex,
    required this.resource,
  });
}

class CityResourceInventory {
  final String playerId;
  final Map<ResourceType, int> countsByType;
  final List<CityResourceSource> sources;

  const CityResourceInventory({
    required this.playerId,
    required this.countsByType,
    required this.sources,
  });

  static const empty = CityResourceInventory(
    playerId: '',
    countsByType: {},
    sources: [],
  );

  int get totalCount {
    var total = 0;
    for (final count in countsByType.values) {
      total += count;
    }
    return total;
  }

  int get distinctTypeCount => countsByType.length;

  int countFor(ResourceType resource) => countsByType[resource] ?? 0;

  bool controls(ResourceType resource) => countFor(resource) > 0;

  bool controlsAny(Set<ResourceType> resources) {
    for (final resource in resources) {
      if (controls(resource)) return true;
    }
    return false;
  }
}

class EmpireResourceUnitGate {
  final GameUnitType unitType;
  final Set<ResourceType> resourceChoices;
  final Set<ResourceType> visibleControlledResources;
  final Set<ResourceType> hiddenControlledResources;

  const EmpireResourceUnitGate({
    required this.unitType,
    required this.resourceChoices,
    required this.visibleControlledResources,
    required this.hiddenControlledResources,
  });

  bool get satisfied => visibleControlledResources.isNotEmpty;

  bool get blockedByHiddenResource =>
      !satisfied && hiddenControlledResources.isNotEmpty;

  Set<ResourceType> get missingResources {
    if (satisfied || blockedByHiddenResource) return const {};
    return resourceChoices;
  }
}

class EmpireResourceNetwork {
  final String playerId;
  final CityResourceInventory visibleInventory;
  final Map<ResourceType, int> importedCountsByType;
  final Map<ResourceType, int> hiddenCountsByType;
  final List<CityResourceSource> hiddenSources;
  final List<EmpireResourceUnitGate> unitGates;

  const EmpireResourceNetwork({
    required this.playerId,
    required this.visibleInventory,
    this.importedCountsByType = const {},
    required this.hiddenCountsByType,
    required this.hiddenSources,
    required this.unitGates,
  });

  static const empty = EmpireResourceNetwork(
    playerId: '',
    visibleInventory: CityResourceInventory.empty,
    importedCountsByType: {},
    hiddenCountsByType: {},
    hiddenSources: [],
    unitGates: [],
  );

  int visibleCountFor(ResourceType resource) =>
      visibleInventory.countFor(resource) + importedCountFor(resource);

  int importedCountFor(ResourceType resource) =>
      importedCountsByType[resource] ?? 0;

  int hiddenCountFor(ResourceType resource) =>
      hiddenCountsByType[resource] ?? 0;

  bool controlsVisible(ResourceType resource) =>
      visibleInventory.controls(resource) || importedCountFor(resource) > 0;

  bool controlsHidden(ResourceType resource) => hiddenCountFor(resource) > 0;

  Iterable<EmpireResourceUnitGate> gatesUnlockedBy(
    ResourceType resource,
  ) sync* {
    for (final gate in unitGates) {
      if (gate.resourceChoices.contains(resource)) yield gate;
    }
  }
}

abstract final class CityResourceInventoryRules {
  static CityResourceInventory forPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required MapData mapData,
    ResearchState research = ResearchState.empty,
  }) {
    return _fromCities(
      playerId: playerId,
      cities: cities.where((city) => city.ownerPlayerId == playerId),
      mapData: mapData,
      research: research,
    );
  }

  static CityResourceInventory forCity(
    GameCity city,
    MapData mapData, {
    ResearchState research = ResearchState.empty,
  }) {
    return _fromCities(
      playerId: city.ownerPlayerId,
      cities: [city],
      mapData: mapData,
      research: research,
    );
  }

  static CityResourceInventory _fromCities({
    required String playerId,
    required Iterable<GameCity> cities,
    required MapData mapData,
    required ResearchState research,
  }) {
    if (playerId.isEmpty) return CityResourceInventory.empty;

    final counts = <ResourceType, int>{};
    final sources = <CityResourceSource>[];
    final visitedHexes = <String>{};

    for (final city in cities) {
      for (final hex in city.territoryHexes) {
        final tileKey = '${hex.col}:${hex.row}';
        if (!visitedHexes.add(tileKey)) continue;

        final tile = mapData.tileAt(hex.col, hex.row);
        if (tile == null || tile.resources.isEmpty) continue;

        for (final resource in ResourceVisibilityRules.visibleResources(
          resources: tile.resources,
          playerId: playerId,
          research: research,
        )) {
          counts[resource] = (counts[resource] ?? 0) + 1;
          sources.add(
            CityResourceSource(cityId: city.id, hex: hex, resource: resource),
          );
        }
      }
    }

    final sortedCounts = Map<ResourceType, int>.fromEntries(
      counts.entries.toList()..sort((a, b) => a.key.name.compareTo(b.key.name)),
    );
    return CityResourceInventory(
      playerId: playerId,
      countsByType: Map.unmodifiable(sortedCounts),
      sources: List.unmodifiable(_sortedSources(sources)),
    );
  }
}

abstract final class EmpireResourceNetworkRules {
  static EmpireResourceNetwork forPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required MapData mapData,
    ResearchState research = ResearchState.empty,
    CityRuleset ruleset = CityRulesets.standard,
    Iterable<ResourceTradeAgreement> resourceTradeAgreements = const [],
  }) {
    if (playerId.isEmpty) return EmpireResourceNetwork.empty;

    final playerCities = [
      for (final city in cities)
        if (city.ownerPlayerId == playerId) city,
    ];
    final visibleInventory = CityResourceInventoryRules.forPlayer(
      playerId: playerId,
      cities: playerCities,
      mapData: mapData,
      research: research,
    );
    final hiddenSources = _hiddenSourcesFor(
      playerId: playerId,
      cities: playerCities,
      mapData: mapData,
      research: research,
    );
    final hiddenCounts = _countsFor(hiddenSources);
    final importedCounts = _importedCountsFor(
      playerId: playerId,
      resourceTradeAgreements: resourceTradeAgreements,
    );

    return EmpireResourceNetwork(
      playerId: playerId,
      visibleInventory: visibleInventory,
      importedCountsByType: importedCounts,
      hiddenCountsByType: hiddenCounts,
      hiddenSources: hiddenSources,
      unitGates: _unitGates(
        visibleInventory: visibleInventory,
        importedCountsByType: importedCounts,
        hiddenCountsByType: hiddenCounts,
        ruleset: ruleset,
      ),
    );
  }

  static List<CityResourceSource> _hiddenSourcesFor({
    required String playerId,
    required Iterable<GameCity> cities,
    required MapData mapData,
    required ResearchState research,
  }) {
    final sources = <CityResourceSource>[];
    final visitedHexes = <String>{};

    for (final city in cities) {
      for (final hex in city.territoryHexes) {
        final tileKey = '${hex.col}:${hex.row}';
        if (!visitedHexes.add(tileKey)) continue;

        final tile = mapData.tileAt(hex.col, hex.row);
        if (tile == null || tile.resources.isEmpty) continue;

        for (final resource in tile.resources) {
          if (ResourceVisibilityRules.isRevealed(
            resource: resource,
            playerId: playerId,
            research: research,
          )) {
            continue;
          }
          sources.add(
            CityResourceSource(cityId: city.id, hex: hex, resource: resource),
          );
        }
      }
    }

    return List.unmodifiable(_sortedSources(sources));
  }

  static Map<ResourceType, int> _countsFor(
    Iterable<CityResourceSource> sources,
  ) {
    final counts = <ResourceType, int>{};
    for (final source in sources) {
      counts[source.resource] = (counts[source.resource] ?? 0) + 1;
    }
    return Map.unmodifiable(
      Map<ResourceType, int>.fromEntries(
        counts.entries.toList()
          ..sort((a, b) => a.key.name.compareTo(b.key.name)),
      ),
    );
  }

  static List<EmpireResourceUnitGate> _unitGates({
    required CityResourceInventory visibleInventory,
    required Map<ResourceType, int> importedCountsByType,
    required Map<ResourceType, int> hiddenCountsByType,
    required CityRuleset ruleset,
  }) {
    final gates = <EmpireResourceUnitGate>[];
    final entries = ruleset.units.entries.toList()
      ..sort((a, b) => a.key.name.compareTo(b.key.name));

    for (final entry in entries) {
      for (final requirement in entry.value.requirements) {
        switch (requirement) {
          case UnitResourceRequirement(:final resources):
            gates.add(
              EmpireResourceUnitGate(
                unitType: entry.key,
                resourceChoices: Set.unmodifiable(resources),
                visibleControlledResources: Set.unmodifiable(
                  resources.where(
                    (resource) =>
                        visibleInventory.controls(resource) ||
                        (importedCountsByType[resource] ?? 0) > 0,
                  ),
                ),
                hiddenControlledResources: Set.unmodifiable(
                  resources.where(
                    (resource) => (hiddenCountsByType[resource] ?? 0) > 0,
                  ),
                ),
              ),
            );
        }
      }
    }

    return List.unmodifiable(gates);
  }

  static Map<ResourceType, int> _importedCountsFor({
    required String playerId,
    required Iterable<ResourceTradeAgreement> resourceTradeAgreements,
  }) {
    final counts = <ResourceType, int>{};
    for (final agreement in resourceTradeAgreements) {
      if (!agreement.importsFor(playerId)) continue;
      counts[agreement.resource] = (counts[agreement.resource] ?? 0) + 1;
    }
    return Map.unmodifiable(
      Map<ResourceType, int>.fromEntries(
        counts.entries.toList()
          ..sort((a, b) => a.key.name.compareTo(b.key.name)),
      ),
    );
  }
}

List<CityResourceSource> _sortedSources(List<CityResourceSource> sources) {
  return sources..sort((a, b) {
    final resource = a.resource.name.compareTo(b.resource.name);
    if (resource != 0) return resource;
    final city = a.cityId.compareTo(b.cityId);
    if (city != 0) return city;
    final col = a.hex.col.compareTo(b.hex.col);
    if (col != 0) return col;
    return a.hex.row.compareTo(b.hex.row);
  });
}
