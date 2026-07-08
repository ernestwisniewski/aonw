import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_sort_controls.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_sorting.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_header.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list_sections.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list_tile.dart';
import 'package:aonw/game/presentation/widgets/city/city_specialization_list_tile.dart';
import 'package:aonw/game/presentation/widgets/shared/selected_panel_item_revealer.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:flutter/material.dart';

export 'package:aonw/game/presentation/widgets/city/city_building_sort_controls.dart'
    show BuildingSectionHeader, BuildingSortSelect;
export 'package:aonw/game/presentation/widgets/city/city_building_sorting.dart'
    show CityBuildingSortMode;

class CityProductionList extends StatelessWidget {
  const CityProductionList({
    required this.buildings,
    required this.futureBuildings,
    required this.units,
    required this.projects,
    required this.specializations,
    required this.onBuildingDetails,
    required this.onUnitDetails,
    required this.onWonderDetails,
    required this.onBuild,
    required this.onProduceUnit,
    required this.onStartProject,
    required this.onSetSpecialization,
    this.wonders = const [],
    this.onBuildWonder,
    this.buildingSortMode = CityBuildingSortMode.recommended,
    this.onBuildingSortModeChanged,
    this.selectedItemKey,
    this.compact = false,
    super.key,
  });

  final List<CityProductionItem> buildings;
  final List<CityProductionItem> futureBuildings;
  final List<CityProductionItem> wonders;
  final List<CityProductionItem> units;
  final List<CityProductionItem> projects;
  final List<CitySpecializationItem> specializations;
  final ValueChanged<CityProductionItem> onBuildingDetails;
  final ValueChanged<CityProductionItem> onUnitDetails;
  final ValueChanged<CityProductionItem> onWonderDetails;
  final ValueChanged<CityBuildingType> onBuild;
  final ValueChanged<WonderType>? onBuildWonder;
  final ValueChanged<GameUnitType> onProduceUnit;
  final ValueChanged<CityProjectType>? onStartProject;
  final ValueChanged<CitySpecializationType>? onSetSpecialization;
  final CityBuildingSortMode buildingSortMode;
  final ValueChanged<CityBuildingSortMode>? onBuildingSortModeChanged;
  final String? selectedItemKey;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sortedBuildings = _sortBuildings(buildings, buildingSortMode);
    final sortedFutureBuildings = _sortBuildings(
      futureBuildings,
      buildingSortMode,
    );
    final visibleWonders = [
      for (final item in wonders)
        if (!item.locked || item.active) item,
    ];
    final unavailableWonders = [
      for (final item in wonders)
        if (item.locked && !item.active) item,
    ];
    final hasBuildingRows =
        sortedBuildings.isNotEmpty || sortedFutureBuildings.isNotEmpty;
    final children = <Widget>[];

    void addMajorGap() {
      if (children.isNotEmpty) children.add(SizedBox(height: compact ? 8 : 10));
    }

    void addProjectSection() {
      children.add(
        CityProductionSectionTitle(l10n.cityProductionProjectsSection),
      );
      for (final item in projects) {
        final itemKey = cityProductionItemKey(item);
        children.add(
          SelectedPanelItemRevealer(
            selected: selectedItemKey == itemKey,
            alignment: 0.18,
            child: ProductionListTile(
              key: ValueKey(itemKey),
              item: item,
              compact: compact,
              selected: selectedItemKey == itemKey,
              onDetails: null,
              onTap: item.active || onStartProject == null
                  ? null
                  : () => onStartProject!(item.projectType!),
            ),
          ),
        );
      }
    }

    void addWonderRows(List<CityProductionItem> items) {
      for (final item in items) {
        final itemKey = cityProductionItemKey(item);
        children.add(
          SelectedPanelItemRevealer(
            selected: selectedItemKey == itemKey,
            alignment: 0.18,
            child: ProductionListTile(
              key: ValueKey(itemKey),
              item: item,
              compact: compact,
              selected: selectedItemKey == itemKey,
              onDetails: () => onWonderDetails(item),
              onTap: item.active || item.locked || onBuildWonder == null
                  ? null
                  : () => onBuildWonder!(item.wonderType!),
            ),
          ),
        );
      }
    }

    if (sortedBuildings.isNotEmpty) {
      addMajorGap();
      children.add(
        BuildingSectionHeader(
          label: l10n.buildingsSection,
          value: buildingSortMode,
          compact: compact,
          onChanged: onBuildingSortModeChanged,
        ),
      );
      for (final item in sortedBuildings) {
        final itemKey = cityProductionItemKey(item);
        children.add(
          SelectedPanelItemRevealer(
            selected: selectedItemKey == itemKey,
            alignment: 0.18,
            child: ProductionListTile(
              key: ValueKey(itemKey),
              item: item,
              compact: compact,
              selected: selectedItemKey == itemKey,
              onDetails: () => onBuildingDetails(item),
              onTap: item.active ? null : () => onBuild(item.buildingType!),
            ),
          ),
        );
      }
    } else if (hasBuildingRows && onBuildingSortModeChanged != null) {
      addMajorGap();
      children
        ..add(
          BuildingSortSelect(
            value: buildingSortMode,
            compact: compact,
            onChanged: onBuildingSortModeChanged!,
          ),
        )
        ..add(SizedBox(height: compact ? 6 : 8));
    }

    if (sortedFutureBuildings.isNotEmpty) {
      if (sortedBuildings.isNotEmpty) {
        children.add(SizedBox(height: compact ? 6 : 8));
      } else if (!hasBuildingRows || onBuildingSortModeChanged == null) {
        addMajorGap();
      }
      children.add(
        FutureBuildingsSection(
          items: sortedFutureBuildings,
          title: l10n.futureBuildingsSection(sortedFutureBuildings.length),
          subtitle: l10n.futureBuildingsSubtitle,
          compact: compact,
          onDetails: onBuildingDetails,
        ),
      );
    }

    if (units.isNotEmpty) {
      addMajorGap();
      children.add(CityProductionSectionTitle(l10n.unitsSection));
      for (final item in units) {
        final itemKey = cityProductionItemKey(item);
        children.add(
          SelectedPanelItemRevealer(
            selected: selectedItemKey == itemKey,
            alignment: 0.18,
            child: ProductionListTile(
              key: ValueKey(itemKey),
              item: item,
              compact: compact,
              selected: selectedItemKey == itemKey,
              onDetails: () => onUnitDetails(item),
              onTap: item.active || item.locked
                  ? null
                  : () => onProduceUnit(item.unitType!),
            ),
          ),
        );
      }
    }

    if (visibleWonders.isNotEmpty || unavailableWonders.isNotEmpty) {
      addMajorGap();
      if (visibleWonders.isNotEmpty) {
        children.add(
          CityProductionSectionTitle(l10n.cityProductionWondersSection),
        );
        addWonderRows(visibleWonders);
        if (unavailableWonders.isNotEmpty) {
          children.add(SizedBox(height: compact ? 6 : 8));
        }
      }
      if (unavailableWonders.isNotEmpty) {
        children.add(
          FutureBuildingsSection(
            items: unavailableWonders,
            title: l10n.futureWondersSection(unavailableWonders.length),
            subtitle: l10n.futureWondersSubtitle,
            compact: compact,
            onDetails: onWonderDetails,
          ),
        );
      }
    }

    if (specializations.isNotEmpty) {
      addMajorGap();
      children.add(
        CityProductionSectionTitle(l10n.cityProductionSpecializationSection),
      );
      for (final item in specializations) {
        final itemKey = citySpecializationItemKey(item);
        children.add(
          SelectedPanelItemRevealer(
            selected: selectedItemKey == itemKey,
            alignment: 0.18,
            child: SpecializationListTile(
              key: ValueKey(itemKey),
              item: item,
              compact: compact,
              selected: selectedItemKey == itemKey,
              onTap: item.active || item.locked || onSetSpecialization == null
                  ? null
                  : () => onSetSpecialization!(item.type),
            ),
          ),
        );
      }
    }

    if (projects.isNotEmpty) {
      addMajorGap();
      addProjectSection();
    }

    return ListView(
      padding: compact
          ? const EdgeInsets.fromLTRB(10, 8, 10, 10)
          : const EdgeInsets.fromLTRB(14, 12, 14, 14),
      children: children,
    );
  }

  static List<CityProductionItem> _sortBuildings(
    List<CityProductionItem> items,
    CityBuildingSortMode mode,
  ) {
    return CityBuildingSorter.sort(
      items,
      mode,
      (item) => CityBuildingSortProfile(
        title: item.title,
        productionCost: item.totalCost,
        investedProduction: item.investedProduction,
        productionPerTurn: item.productionPerTurn,
        turnsRemaining: item.turnsRemaining,
        metrics: item.buildingSortMetrics,
      ),
    );
  }

  static List<CityProductionItem> sortedBuildings(
    List<CityProductionItem> items,
    CityBuildingSortMode mode,
  ) => _sortBuildings(items, mode);
}

String cityProductionItemKey(CityProductionItem item) {
  final buildingType = item.buildingType;
  if (buildingType != null) return 'building:${buildingType.name}';
  final unitType = item.unitType;
  if (unitType != null) return 'unit:${unitType.name}';
  final projectType = item.projectType;
  if (projectType != null) return 'project:${projectType.name}';
  final wonderType = item.wonderType;
  if (wonderType != null) return 'wonder:${wonderType.name}';
  return 'item:${item.title}';
}

String citySpecializationItemKey(CitySpecializationItem item) =>
    'specialization:${item.type.name}';
