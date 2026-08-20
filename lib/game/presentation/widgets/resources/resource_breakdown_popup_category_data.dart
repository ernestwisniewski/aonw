import 'dart:math' as math;

import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_strategic_resource_summary.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

enum ResourcePopupCategory { bonus, luxury, strategic }

final class ResourcePopupCategoryData {
  const ResourcePopupCategoryData({
    required this.category,
    required this.title,
    required this.rows,
  });

  final ResourcePopupCategory category;
  final String title;
  final List<ResourcePopupRowData> rows;
}

final class ResourcePopupRowData {
  const ResourcePopupRowData({
    required this.label,
    required this.value,
    this.positive = false,
    this.negative = false,
    this.muted = false,
    this.groupLabel,
    this.targetCity,
  });

  final String label;
  final String value;
  final bool positive;
  final bool negative;
  final bool muted;
  final String? groupLabel;
  final GameCity? targetCity;
}

/// Builds the three player-facing resource groups used by the compact HUD
/// popup. Domain calculations stay authoritative elsewhere; this class only
/// filters and arranges already-computed presentation values.
final class ResourcePopupCategoryDataBuilder {
  const ResourcePopupCategoryDataBuilder({
    required this.resources,
    required this.network,
    required this.strategic,
    required this.cities,
    required this.l10n,
  });

  final CityResourceInventory resources;
  final EmpireResourceNetwork network;
  final HudStrategicResourceSummary strategic;
  final List<GameCity> cities;
  final AppLocalizations l10n;

  List<ResourcePopupCategoryData> build() => [
    _inventoryCategory(
      ResourcePopupCategory.bonus,
      ResourceCategory.bonus,
      l10n.resourceValueCategoryBonus,
    ),
    _inventoryCategory(
      ResourcePopupCategory.luxury,
      ResourceCategory.luxury,
      l10n.resourceValueCategoryLuxury,
    ),
    _strategicCategory(),
  ];
}

extension _ResourcePopupInventoryCategoryBuilder
    on ResourcePopupCategoryDataBuilder {
  ResourcePopupCategoryData _inventoryCategory(
    ResourcePopupCategory popupCategory,
    ResourceCategory domainCategory,
    String title,
  ) {
    final rows = <ResourcePopupRowData>[];
    for (final resource in ResourceCatalog.resourcesForCategory(
      domainCategory,
    )) {
      final count = math.max(
        resources.countFor(resource),
        network.visibleCountFor(resource),
      );
      if (count <= 0) continue;
      rows.add(
        ResourcePopupRowData(
          label: _resourceName(resource),
          value: 'x$count',
          positive: true,
        ),
      );
    }
    for (final entry in network.hiddenCountsByType.entries) {
      if (entry.value <= 0 ||
          ResourceCatalog.definitionFor(entry.key).category != domainCategory) {
        continue;
      }
      rows.add(
        ResourcePopupRowData(
          label: _resourceName(entry.key),
          value: '?x${entry.value}',
        ),
      );
    }
    _appendGroup(
      rows,
      _categorySourceRows(domainCategory),
      l10n.resourceBreakdownSourcesSection,
    );
    return ResourcePopupCategoryData(
      category: popupCategory,
      title: title,
      rows: _rowsOrNone(rows),
    );
  }

  List<ResourcePopupRowData> _categorySourceRows(ResourceCategory category) {
    final rows = <ResourcePopupRowData>[];
    final seen = <String>{};
    for (final source in [
      ...resources.sources,
      ...network.visibleInventory.sources,
    ]) {
      if (ResourceCatalog.definitionFor(source.resource).category != category ||
          !seen.add(_sourceKey(source))) {
        continue;
      }
      rows.add(
        ResourcePopupRowData(
          label: _sourceLocation(source),
          value: _resourceName(source.resource),
          positive: true,
          targetCity: _cityFor(source.cityId),
        ),
      );
    }
    for (final source in network.hiddenSources) {
      if (ResourceCatalog.definitionFor(source.resource).category != category ||
          !seen.add(_sourceKey(source))) {
        continue;
      }
      rows.add(
        ResourcePopupRowData(
          label: _sourceLocation(source),
          value: '? ${_resourceName(source.resource)}',
          targetCity: _cityFor(source.cityId),
        ),
      );
    }
    return rows;
  }
}

extension _ResourcePopupStrategicCategoryBuilder
    on ResourcePopupCategoryDataBuilder {
  ResourcePopupCategoryData _strategicCategory() {
    final rows = _strategicInventoryRows();
    _appendGroup(
      rows,
      _strategicSourceRows(),
      l10n.resourceBreakdownSourcesSection,
    );
    _appendGroup(
      rows,
      _strategicAllocationRows(),
      l10n.resourceBreakdownAllocations,
    );
    _appendGroup(rows, _strategicGateRows(), l10n.unitsSection);
    return ResourcePopupCategoryData(
      category: ResourcePopupCategory.strategic,
      title: l10n.diplomacyStrategicResourcesTitle,
      rows: _rowsOrNone(rows),
    );
  }

  List<ResourcePopupRowData> _strategicInventoryRows() {
    final summaryByResource = {
      for (final row in strategic.rows) row.resource: row,
    };
    final rows = <ResourcePopupRowData>[];
    for (final resource in ResourceCatalog.strategicResources) {
      rows.addAll(_strategicRowsFor(resource, summaryByResource[resource]));
    }
    for (final entry in network.hiddenCountsByType.entries) {
      if (entry.value <= 0 || !ResourceCatalog.isStrategic(entry.key)) continue;
      rows.add(
        ResourcePopupRowData(
          label: _resourceName(entry.key),
          value: '?x${entry.value}',
        ),
      );
    }
    return rows;
  }

  List<ResourcePopupRowData> _strategicRowsFor(
    ResourceType resource,
    HudStrategicResourceRow? summary,
  ) {
    final controlled = math.max(
      summary?.controlledDeposits ?? 0,
      math.max(
        resources.countFor(resource),
        network.visibleInventory.countFor(resource),
      ),
    );
    final available = math.max(
      summary?.available ?? 0,
      math.max(resources.countFor(resource), network.visibleCountFor(resource)),
    );
    final stored = summary?.storedTotal ?? 0;
    final hasFlow =
        summary != null &&
        [
          summary.domesticProduction,
          summary.imports,
          summary.exports,
        ].any((value) => value > 0);
    final hasValue = [
      available,
      stored,
      controlled,
      summary?.allocated ?? 0,
    ].any((value) => value > 0);
    if (!hasValue && !hasFlow) return const [];

    final name = _resourceName(resource);
    final stockpiled =
        summary?.stockpiled ?? ResourceCatalog.isStockpiled(resource);
    final rows = stockpiled
        ? _stockpiledRows(name, stored, controlled, summary?.shortage ?? false)
        : <ResourcePopupRowData>[
            if (available > 0)
              ResourcePopupRowData(
                label: name,
                value: 'x$available',
                positive: true,
                negative: summary?.shortage ?? false,
              ),
          ];
    if (summary != null && summary.netPerTurn != 0) {
      rows.add(
        ResourcePopupRowData(
          label: '$name · ${l10n.resourceBreakdownNetPerTurn}',
          value: _signed(summary.netPerTurn),
          positive: summary.netPerTurn > 0,
          negative: summary.netPerTurn < 0,
        ),
      );
    }
    return rows;
  }

  List<ResourcePopupRowData> _stockpiledRows(
    String resourceName,
    int stored,
    int controlled,
    bool shortage,
  ) => [
    if (stored > 0)
      ResourcePopupRowData(
        label: '$resourceName · ${l10n.resourceBreakdownStored}',
        value: '$stored',
        positive: true,
        negative: shortage,
      ),
    if (controlled > 0)
      ResourcePopupRowData(
        label: '$resourceName · ${l10n.resourceBreakdownControlledDeposits}',
        value: 'x$controlled',
        positive: true,
      ),
  ];

  List<ResourcePopupRowData> _strategicSourceRows() {
    final rows = <ResourcePopupRowData>[];
    final represented = <String>{};
    for (final source in strategic.sources) {
      represented.add(_strategicSourceKey(source));
      if ((source.amountPerTurn ?? 1) <= 0) continue;
      rows.add(
        ResourcePopupRowData(
          label: _strategicSourceLabel(source),
          value: source.amountPerTurn == null
              ? ''
              : _signed(source.amountPerTurn!),
          positive: (source.amountPerTurn ?? 0) > 0,
          targetCity: source.city,
        ),
      );
    }

    final seen = <String>{...represented};
    for (final source in [
      ...resources.sources,
      ...network.visibleInventory.sources,
    ]) {
      if (!ResourceCatalog.isStrategic(source.resource) ||
          !seen.add(_sourceKey(source))) {
        continue;
      }
      rows.add(
        ResourcePopupRowData(
          label: _sourceLocation(source),
          value: _resourceName(source.resource),
          positive: true,
          targetCity: _cityFor(source.cityId),
        ),
      );
    }
    for (final source in network.hiddenSources) {
      if (!ResourceCatalog.isStrategic(source.resource) ||
          !seen.add(_sourceKey(source))) {
        continue;
      }
      rows.add(
        ResourcePopupRowData(
          label: _sourceLocation(source),
          value: '? ${_resourceName(source.resource)}',
          targetCity: _cityFor(source.cityId),
        ),
      );
    }
    return rows;
  }

  List<ResourcePopupRowData> _strategicAllocationRows() => [
    for (final allocation in strategic.allocations)
      if (!allocation.bundle.isEmpty)
        ResourcePopupRowData(
          label: _allocationLabel(allocation),
          value: allocation.bundle.amounts.entries
              .map((entry) => '${entry.value} ${_resourceName(entry.key)}')
              .join(' · '),
          targetCity: allocation.city,
        ),
  ];

  List<ResourcePopupRowData> _strategicGateRows() => [
    for (final gate in network.unitGates)
      if (gate.satisfied || gate.blockedByHiddenResource)
        ResourcePopupRowData(
          label: GameDisplayNames.unitType(l10n, gate.unitType),
          value: _gateValue(gate),
          positive: gate.satisfied,
        ),
  ];
}

extension _ResourcePopupCategoryBuilderHelpers
    on ResourcePopupCategoryDataBuilder {
  void _appendGroup(
    List<ResourcePopupRowData> target,
    List<ResourcePopupRowData> group,
    String label,
  ) {
    for (var index = 0; index < group.length; index++) {
      final row = group[index];
      target.add(
        ResourcePopupRowData(
          label: row.label,
          value: row.value,
          positive: row.positive,
          negative: row.negative,
          muted: row.muted,
          groupLabel: index == 0 ? label : null,
          targetCity: row.targetCity,
        ),
      );
    }
  }

  List<ResourcePopupRowData> _rowsOrNone(List<ResourcePopupRowData> rows) =>
      rows.isEmpty
      ? [
          ResourcePopupRowData(
            label: l10n.commonNoneLower,
            value: '',
            muted: true,
          ),
        ]
      : rows;

  String _strategicSourceLabel(HudStrategicResourceSource source) {
    final labels = <String>[
      _resourceName(source.resource),
      if (source.improvement case final improvement?)
        GameDisplayNames.fieldImprovement(l10n, improvement),
      GameDisplayNames.city(l10n, source.city),
    ];
    return labels.join(' · ');
  }

  String _allocationLabel(HudStrategicResourceAllocation allocation) {
    final target = allocation.city.productionQueue?.target;
    final targetLabel = switch (target) {
      UnitProductionTarget(:final unitType) => GameDisplayNames.unitType(
        l10n,
        unitType,
      ),
      _ => '',
    };
    final cityLabel = GameDisplayNames.city(l10n, allocation.city);
    return targetLabel.isEmpty ? cityLabel : '$targetLabel · $cityLabel';
  }

  String _gateValue(EmpireResourceUnitGate gate) {
    final resourceTypes = gate.satisfied
        ? gate.visibleControlledResources
        : gate.hiddenControlledResources;
    final prefix = gate.satisfied ? '+ ' : '? ';
    final names = [
      for (final resource in resourceTypes) _resourceName(resource),
    ]..sort();
    return '$prefix${names.join(' / ')}';
  }

  String _sourceLocation(CityResourceSource source) {
    final city = _cityFor(source.cityId);
    return city == null ? source.cityId : GameDisplayNames.city(l10n, city);
  }

  GameCity? _cityFor(String cityId) {
    for (final city in cities) {
      if (city.id == cityId) return city;
    }
    return null;
  }

  String _resourceName(ResourceType resource) =>
      GameDisplayNames.resource(l10n, resource);

  String _sourceKey(CityResourceSource source) =>
      '${source.cityId}:${source.hex.col}:${source.hex.row}:${source.resource.name}';

  String _strategicSourceKey(HudStrategicResourceSource source) =>
      '${source.city.id}:${source.hex.col}:${source.hex.row}:${source.resource.name}';
}

String _signed(int value) => value > 0 ? '+$value' : '$value';
