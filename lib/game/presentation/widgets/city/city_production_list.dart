import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_sorting.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_header.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list_sections.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list_tile.dart';
import 'package:aonw/game/presentation/widgets/city/city_specialization_list_tile.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

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
    required this.onBuild,
    required this.onProduceUnit,
    required this.onStartProject,
    required this.onSetSpecialization,
    this.buildingSortMode = CityBuildingSortMode.recommended,
    this.onBuildingSortModeChanged,
    this.compact = false,
    super.key,
  });

  final List<CityProductionItem> buildings;
  final List<CityProductionItem> futureBuildings;
  final List<CityProductionItem> units;
  final List<CityProductionItem> projects;
  final List<CitySpecializationItem> specializations;
  final ValueChanged<CityProductionItem> onBuildingDetails;
  final ValueChanged<CityProductionItem> onUnitDetails;
  final ValueChanged<CityBuildingType> onBuild;
  final ValueChanged<GameUnitType> onProduceUnit;
  final ValueChanged<CityProjectType>? onStartProject;
  final ValueChanged<CitySpecializationType>? onSetSpecialization;
  final CityBuildingSortMode buildingSortMode;
  final ValueChanged<CityBuildingSortMode>? onBuildingSortModeChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sortedBuildings = _sortBuildings(buildings, buildingSortMode);
    final sortedFutureBuildings = _sortBuildings(
      futureBuildings,
      buildingSortMode,
    );
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
        children.add(
          ProductionListTile(
            item: item,
            compact: compact,
            onDetails: null,
            onTap: item.active || onStartProject == null
                ? null
                : () => onStartProject!(item.projectType!),
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
        children.add(
          ProductionListTile(
            item: item,
            compact: compact,
            onDetails: () => onBuildingDetails(item),
            onTap: item.active ? null : () => onBuild(item.buildingType!),
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
        children.add(
          ProductionListTile(
            item: item,
            compact: compact,
            onDetails: () => onUnitDetails(item),
            onTap: item.active || item.locked
                ? null
                : () => onProduceUnit(item.unitType!),
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
        children.add(
          SpecializationListTile(
            item: item,
            compact: compact,
            onTap: item.active || item.locked || onSetSpecialization == null
                ? null
                : () => onSetSpecialization!(item.type),
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
}

class BuildingSectionHeader extends StatelessWidget {
  const BuildingSectionHeader({
    required this.label,
    required this.value,
    required this.compact,
    required this.onChanged,
    super.key,
  });

  final String label;
  final CityBuildingSortMode value;
  final bool compact;
  final ValueChanged<CityBuildingSortMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final sortChanged = onChanged;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              GameText.uppercase(label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.toolbarLabel.copyWith(color: GameUiTheme.gold),
            ),
          ),
          if (sortChanged != null) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: BuildingSortSelect(
                  value: value,
                  compact: compact,
                  onChanged: sortChanged,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BuildingSortSelect extends StatelessWidget {
  const BuildingSortSelect({
    required this.value,
    required this.compact,
    required this.onChanged,
    super.key,
  });

  final CityBuildingSortMode value;
  final bool compact;
  final ValueChanged<CityBuildingSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 190 : 230),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x33131313),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0x44EBD9B0)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: compact ? 8 : 10,
              right: compact ? 4 : 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.cityProductionSortLabel,
                  style: GameUiTheme.toolbarLabel.copyWith(
                    color: GameUiTheme.textSecondary,
                    fontSize: compact ? 9.5 : 10.5,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CityBuildingSortMode>(
                      key: const Key('cityProductionList.buildingSort'),
                      value: value,
                      isDense: true,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(7),
                      dropdownColor: GameUiTheme.bg,
                      iconEnabledColor: GameUiTheme.gold,
                      style: GameUiTheme.bodySmall.copyWith(
                        color: GameUiTheme.goldLight,
                        fontWeight: FontWeight.w800,
                      ),
                      items: [
                        for (final mode in CityBuildingSortMode.values)
                          DropdownMenuItem(
                            value: mode,
                            child: Text(
                              mode.label(l10n),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) onChanged(mode);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
