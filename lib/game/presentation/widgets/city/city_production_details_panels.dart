import 'dart:math' as math;

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/unit/unit_details_panel.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_layout.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class CityProductionBuildingDetailsLayer extends StatelessWidget {
  const CityProductionBuildingDetailsLayer({
    required this.item,
    required this.l10n,
    required this.definition,
    required this.unlockingTechnology,
    required this.currentCityYield,
    required this.currentCityScience,
    required this.compact,
    required this.onClose,
    super.key,
  });

  final CityProductionItem item;
  final AppLocalizations l10n;
  final CityBuildingDefinition definition;
  final TechnologyDefinition? unlockingTechnology;
  final TileYield? currentCityYield;
  final int currentCityScience;
  final bool compact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return _CityProductionInlineDetailsLayer(
      compact: compact,
      childBuilder: (maxWidth, maxHeight) {
        return CityProductionBuildingDetailsPanel(
          item: item,
          l10n: l10n,
          definition: definition,
          unlockingTechnology: unlockingTechnology,
          currentCityYield: currentCityYield,
          currentCityScience: currentCityScience,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          onClose: onClose,
        );
      },
    );
  }
}

class CityProductionUnitDetailsLayer extends StatelessWidget {
  const CityProductionUnitDetailsLayer({
    required this.item,
    required this.l10n,
    required this.definition,
    required this.unlockingTechnology,
    required this.compact,
    required this.onClose,
    super.key,
  });

  final CityProductionItem item;
  final AppLocalizations l10n;
  final UnitProductionDefinition definition;
  final TechnologyDefinition? unlockingTechnology;
  final bool compact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return _CityProductionInlineDetailsLayer(
      compact: compact,
      childBuilder: (maxWidth, maxHeight) {
        return CityProductionUnitDetailsPanel(
          item: item,
          l10n: l10n,
          definition: definition,
          unlockingTechnology: unlockingTechnology,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          onClose: onClose,
        );
      },
    );
  }
}

class _CityProductionInlineDetailsLayer extends StatelessWidget {
  const _CityProductionInlineDetailsLayer({
    required this.compact,
    required this.childBuilder,
  });

  final bool compact;
  final Widget Function(double maxWidth, double maxHeight) childBuilder;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('cityProductionPanel.detailsLayer'),
      color: SurfaceElevation.flat.fill(background: GameUiTheme.bg, alpha: 188),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = compact ? 8.0 : 14.0;
          final maxWidth = compact
              ? math.max(260.0, constraints.maxWidth - padding * 2)
              : 560.0;
          final maxHeight = GameModalLayout.inlineDetailsMaxHeight(
            availableHeight: constraints.maxHeight,
            padding: padding,
            compact: compact,
          );

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Align(
              alignment: Alignment.topCenter,
              child: childBuilder(maxWidth, maxHeight),
            ),
          );
        },
      ),
    );
  }
}

class CityProductionBuildingDetailsPanel extends StatelessWidget {
  const CityProductionBuildingDetailsPanel({
    required this.item,
    required this.l10n,
    required this.definition,
    required this.unlockingTechnology,
    this.maxWidth = 560,
    this.maxHeight,
    this.currentCityYield,
    this.currentCityScience = 0,
    required this.onClose,
    super.key,
  });

  final CityProductionItem item;
  final AppLocalizations l10n;
  final CityBuildingDefinition definition;
  final TechnologyDefinition? unlockingTechnology;
  final double maxWidth;
  final double? maxHeight;
  final TileYield? currentCityYield;
  final int currentCityScience;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final type = item.buildingType!;
    final eta = item.effectiveEta;
    final turns = eta.hasTurns ? ' • ${eta.detailLabel(l10n)}' : '';

    return CityBuildingDetailsPanel(
      buildingType: type,
      definition: definition,
      unlockingTechnology: unlockingTechnology,
      l10n: l10n,
      title: item.title,
      emoji: item.emoji,
      statusLabel: _stateLabel(l10n, item),
      costLabel: l10n.cityProductionCostShort(definition.productionCost),
      progressLabel: '${item.investedProduction}/${item.totalCost}$turns',
      paceLabel: l10n.cityProductionPaceShort(item.productionPerTurn),
      yieldImpactMode: item.buildingState == CityBuildingCardState.built
          ? CityBuildingYieldImpactMode.active
          : CityBuildingYieldImpactMode.planned,
      currentCityYield: currentCityYield,
      currentCityScience: currentCityScience,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      onClose: onClose,
    );
  }

  static String _stateLabel(AppLocalizations l10n, CityProductionItem item) {
    return switch (item.buildingState) {
      CityBuildingCardState.built => l10n.cityProductionBuiltLabel,
      CityBuildingCardState.inProgress => l10n.productionInProgressLabel,
      CityBuildingCardState.locked => l10n.productionButtonLocked,
      CityBuildingCardState.available ||
      null => l10n.cityProductionAvailableLabel,
    };
  }
}

class CityProductionUnitDetailsPanel extends StatelessWidget {
  const CityProductionUnitDetailsPanel({
    required this.item,
    required this.l10n,
    required this.definition,
    required this.unlockingTechnology,
    this.maxWidth = 560,
    this.maxHeight,
    required this.onClose,
    super.key,
  });

  final CityProductionItem item;
  final AppLocalizations l10n;
  final UnitProductionDefinition definition;
  final TechnologyDefinition? unlockingTechnology;
  final double maxWidth;
  final double? maxHeight;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final eta = item.effectiveEta;
    final turns = eta.hasTurns ? ' • ${eta.detailLabel(l10n)}' : '';

    return UnitDetailsPanel(
      unitType: item.unitType!,
      unlockingTechnology: unlockingTechnology,
      l10n: l10n,
      title: item.title,
      icon: item.icon ?? gameIconForUnitType(item.unitType!),
      statusLabel: item.active
          ? l10n.productionInProgressLabel
          : l10n.cityProductionAvailableUnitLabel,
      costLabel: l10n.cityProductionCostShort(definition.productionCost),
      progressLabel: '${item.investedProduction}/${item.totalCost}$turns',
      paceLabel: l10n.cityProductionPaceShort(item.productionPerTurn),
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      onClose: onClose,
    );
  }
}
