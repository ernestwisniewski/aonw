import 'dart:async';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_active_production_banner.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/city/city_empty_production_state.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_details_panels.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_dialog_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_header.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_type_icon.dart';
import 'package:aonw/game/presentation/widgets/unit/unit_details_panel.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class CityProductionDialog extends StatelessWidget {
  final GameCity city;
  final CityRuleset cityRuleset;
  final ResearchState research;
  final TechnologyRuleset technologyRuleset;
  final MapData? mapData;
  final List<GameCity> cities;
  final List<GameUnit> units;
  final List<WorldArtifact> artifacts;
  final List<FieldImprovement> fieldImprovements;
  final Iterable<ResourceTradeAgreement> resourceTradeAgreements;
  final int productionPerTurn;
  final int? currentTurn;
  final PaceBalance paceBalance;
  final int playerGold;
  final ValueChanged<CityBuildingType> onBuild;
  final ValueChanged<GameUnitType> onProduceUnit;
  final ValueChanged<CityProjectType>? onStartProject;
  final ValueChanged<CitySpecializationType>? onSetSpecialization;
  final VoidCallback? onRushProduction;

  const CityProductionDialog({
    required this.city,
    required this.cityRuleset,
    required this.research,
    required this.technologyRuleset,
    this.mapData,
    this.cities = const [],
    this.units = const [],
    this.artifacts = const [],
    this.fieldImprovements = const [],
    this.resourceTradeAgreements = const [],
    required this.productionPerTurn,
    this.currentTurn,
    this.paceBalance = PaceBalance.unlimited,
    this.playerGold = 0,
    required this.onBuild,
    required this.onProduceUnit,
    this.onStartProject,
    this.onSetSpecialization,
    this.onRushProduction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return CityProductionPanel(
      city: city,
      cityRuleset: cityRuleset,
      research: research,
      technologyRuleset: technologyRuleset,
      mapData: mapData,
      cities: cities,
      units: units,
      artifacts: artifacts,
      fieldImprovements: fieldImprovements,
      resourceTradeAgreements: resourceTradeAgreements,
      productionPerTurn: productionPerTurn,
      currentTurn: currentTurn,
      paceBalance: paceBalance,
      playerGold: playerGold,
      maxHeight: size.height * 0.82,
      onBuild: onBuild,
      onProduceUnit: onProduceUnit,
      onStartProject: onStartProject,
      onSetSpecialization: onSetSpecialization,
      onRushProduction: onRushProduction,
      onClose: () => Navigator.of(context).maybePop(),
    );
  }
}

class CityProductionPanel extends StatefulWidget {
  final GameCity city;
  final CityRuleset cityRuleset;
  final ResearchState research;
  final TechnologyRuleset technologyRuleset;
  final MapData? mapData;
  final List<GameCity> cities;
  final List<GameUnit> units;
  final List<WorldArtifact> artifacts;
  final List<FieldImprovement> fieldImprovements;
  final Iterable<ResourceTradeAgreement> resourceTradeAgreements;
  final int productionPerTurn;
  final int? currentTurn;
  final PaceBalance paceBalance;
  final int playerGold;
  final double? maxHeight;
  final ValueChanged<CityBuildingType> onBuild;
  final ValueChanged<GameUnitType> onProduceUnit;
  final ValueChanged<CityProjectType>? onStartProject;
  final ValueChanged<CitySpecializationType>? onSetSpecialization;
  final VoidCallback? onRushProduction;
  final VoidCallback onClose;

  const CityProductionPanel({
    required this.city,
    required this.cityRuleset,
    required this.research,
    required this.technologyRuleset,
    this.mapData,
    this.cities = const [],
    this.units = const [],
    this.artifacts = const [],
    this.fieldImprovements = const [],
    this.resourceTradeAgreements = const [],
    required this.productionPerTurn,
    this.currentTurn,
    this.paceBalance = PaceBalance.unlimited,
    this.playerGold = 0,
    this.maxHeight,
    required this.onBuild,
    required this.onProduceUnit,
    this.onStartProject,
    this.onSetSpecialization,
    this.onRushProduction,
    required this.onClose,
    super.key,
  });

  @override
  State<CityProductionPanel> createState() => _CityProductionPanelState();
}

class _CityProductionPanelState extends State<CityProductionPanel> {
  CityBuildingType? _detailsBuildingType;
  GameUnitType? _detailsUnitType;
  CityBuildingSortMode _buildingSortMode = CityBuildingSortMode.recommended;

  @override
  void didUpdateWidget(covariant CityProductionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city.id != widget.city.id) {
      _detailsBuildingType = null;
      _detailsUnitType = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 480;
    final viewModel = _viewModelFor(l10n);
    final detailsBuildingItem = viewModel.itemForBuilding(_detailsBuildingType);
    final detailsUnitItem = viewModel.itemForUnit(_detailsUnitType);
    final activeItem = viewModel.activeItem;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 760,
        maxHeight: widget.maxHeight ?? MediaQuery.sizeOf(context).height * 0.82,
      ),
      child: GameModalScaffold(
        surfaceKey: const Key('cityProductionPanel.surface'),
        size: GameModalSize.wide,
        showCornerDiamonds: false,
        contentPadding: EdgeInsets.zero,
        centerInAvailableSpace: false,
        scrollable: false,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CityProductionHeader(
              cityName: viewModel.cityName,
              title: l10n.productionTitle,
              productionPerTurnLabel: l10n.productionPerTurn(
                viewModel.productionPerTurn,
              ),
              playerGold: widget.playerGold,
              closeTooltip: l10n.closeAction,
              onClose: widget.onClose,
              compact: compact,
            ),
            if (activeItem != null)
              CityActiveProductionBanner(
                title: activeItem.title,
                continuous: activeItem.continuous,
                turnsRemaining: activeItem.turnsRemaining,
                eta: activeItem.effectiveEta,
                totalCost: activeItem.totalCost,
                investedProduction: activeItem.investedProduction,
                progress: activeItem.progress,
                metaLabels: activeItem.metaLabels,
                canBeRushed: activeItem.canBeRushed,
                rushGoldCost: activeItem.rushGoldCost,
                playerGold: widget.playerGold,
                onRushProduction: widget.onRushProduction,
              ),
            Flexible(
              child: viewModel.hasItems
                  ? Stack(
                      children: [
                        Positioned.fill(
                          child: CityProductionList(
                            buildings: viewModel.buildings,
                            futureBuildings: viewModel.futureBuildings,
                            units: viewModel.units,
                            projects: viewModel.projects,
                            specializations: viewModel.specializations,
                            buildingSortMode: _buildingSortMode,
                            onBuildingSortModeChanged: _setBuildingSortMode,
                            onBuildingDetails: _showBuildingDetails,
                            onUnitDetails: _showUnitDetails,
                            onBuild: widget.onBuild,
                            onProduceUnit: widget.onProduceUnit,
                            onStartProject: widget.onStartProject,
                            onSetSpecialization: widget.onSetSpecialization,
                            compact: compact,
                          ),
                        ),
                        if (detailsBuildingItem != null)
                          Positioned.fill(
                            child: CityProductionBuildingDetailsLayer(
                              item: detailsBuildingItem,
                              l10n: l10n,
                              definition: widget.cityRuleset
                                  .buildingDefinitionFor(
                                    detailsBuildingItem.buildingType!,
                                  ),
                              unlockingTechnology:
                                  TechnologyUnlockQuery.unlockingTechnologyForBuilding(
                                    buildingType:
                                        detailsBuildingItem.buildingType!,
                                    ruleset: widget.technologyRuleset,
                                  ),
                              currentCityYield: viewModel.currentCityYield,
                              currentCityScience: viewModel.currentCityScience,
                              compact: compact,
                              onClose: _closeBuildingDetails,
                            ),
                          ),
                        if (detailsUnitItem != null)
                          Positioned.fill(
                            child: CityProductionUnitDetailsLayer(
                              item: detailsUnitItem,
                              l10n: l10n,
                              definition: widget.cityRuleset.unitDefinitionFor(
                                detailsUnitItem.unitType!,
                              ),
                              unlockingTechnology:
                                  TechnologyUnlockQuery.unlockingTechnologyForUnit(
                                    unitType: detailsUnitItem.unitType!,
                                    ruleset: widget.technologyRuleset,
                                  ),
                              compact: compact,
                              onClose: _closeUnitDetails,
                            ),
                          ),
                      ],
                    )
                  : const CityEmptyProductionState(),
            ),
          ],
        ),
      ),
    );
  }

  void _showBuildingDetails(CityProductionItem item) {
    final buildingType = item.buildingType;
    if (buildingType == null) return;
    if (_opensDetailsAsModal(context)) {
      _showBuildingDetailsModal(item);
      return;
    }
    setState(() {
      _detailsBuildingType = buildingType;
      _detailsUnitType = null;
    });
  }

  bool _opensDetailsAsModal(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.portrait;
  }

  void _showBuildingDetailsModal(CityProductionItem item) {
    final buildingType = item.buildingType;
    if (buildingType == null) return;
    final l10n = AppLocalizations.of(context);
    final viewModel = _viewModelFor(l10n);
    final definition = widget.cityRuleset.buildingDefinitionFor(buildingType);

    unawaited(
      showGameModal<void>(
        context: context,
        builder: (dialogContext) => CityBuildingDetailsDialog(
          buildingType: buildingType,
          definition: definition,
          unlockingTechnology:
              TechnologyUnlockQuery.unlockingTechnologyForBuilding(
                buildingType: buildingType,
                ruleset: widget.technologyRuleset,
              ),
          l10n: l10n,
          title: item.title,
          emoji: item.emoji,
          statusLabel: _buildingStateLabel(l10n, item),
          costLabel: l10n.cityProductionCostShort(definition.productionCost),
          progressLabel: _buildingProgressLabel(l10n, item),
          paceLabel: l10n.cityProductionPaceShort(item.productionPerTurn),
          yieldImpactMode: item.buildingState == CityBuildingCardState.built
              ? CityBuildingYieldImpactMode.active
              : CityBuildingYieldImpactMode.planned,
          currentCityYield: viewModel.currentCityYield,
          currentCityScience: viewModel.currentCityScience,
          onClose: () => Navigator.of(dialogContext).maybePop(),
        ),
      ),
    );
  }

  CityProductionDialogViewModel _viewModelFor(AppLocalizations l10n) {
    return CityProductionDialogViewModel.from(
      widget.city,
      l10n: l10n,
      cityRuleset: widget.cityRuleset,
      research: widget.research,
      technologyRuleset: widget.technologyRuleset,
      mapData: widget.mapData,
      cities: widget.cities,
      units: widget.units,
      artifacts: widget.artifacts,
      fieldImprovements: widget.fieldImprovements,
      resourceTradeAgreements: widget.resourceTradeAgreements,
      productionPerTurn: widget.productionPerTurn,
      currentTurn: widget.currentTurn,
      paceBalance: widget.paceBalance,
    );
  }

  String _buildingStateLabel(AppLocalizations l10n, CityProductionItem item) {
    return switch (item.buildingState) {
      CityBuildingCardState.built => l10n.cityProductionBuiltLabel,
      CityBuildingCardState.inProgress => l10n.productionInProgressLabel,
      CityBuildingCardState.locked => l10n.productionButtonLocked,
      CityBuildingCardState.available ||
      null => l10n.cityProductionAvailableLabel,
    };
  }

  String _buildingProgressLabel(
    AppLocalizations l10n,
    CityProductionItem item,
  ) {
    final eta = item.effectiveEta;
    final turns = eta.hasTurns ? ' • ${eta.detailLabel(l10n)}' : '';
    return '${item.investedProduction}/${item.totalCost}$turns';
  }

  void _setBuildingSortMode(CityBuildingSortMode mode) {
    setState(() => _buildingSortMode = mode);
  }

  void _closeBuildingDetails() {
    setState(() => _detailsBuildingType = null);
  }

  void _showUnitDetails(CityProductionItem item) {
    final unitType = item.unitType;
    if (unitType == null) return;
    if (_opensDetailsAsModal(context)) {
      _showUnitDetailsModal(item);
      return;
    }
    setState(() {
      _detailsBuildingType = null;
      _detailsUnitType = unitType;
    });
  }

  void _showUnitDetailsModal(CityProductionItem item) {
    final unitType = item.unitType;
    if (unitType == null) return;
    final l10n = AppLocalizations.of(context);
    final definition = widget.cityRuleset.unitDefinitionFor(unitType);

    unawaited(
      showGameModal<void>(
        context: context,
        builder: (dialogContext) => UnitDetailsPanel(
          unitType: unitType,
          unlockingTechnology: TechnologyUnlockQuery.unlockingTechnologyForUnit(
            unitType: unitType,
            ruleset: widget.technologyRuleset,
          ),
          l10n: l10n,
          title: item.title,
          icon: item.icon ?? gameIconForUnitType(unitType),
          statusLabel: item.active
              ? l10n.productionInProgressLabel
              : l10n.cityProductionAvailableUnitLabel,
          costLabel: l10n.cityProductionCostShort(definition.productionCost),
          progressLabel: _buildingProgressLabel(l10n, item),
          paceLabel: l10n.cityProductionPaceShort(item.productionPerTurn),
          maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.78,
          onClose: () => Navigator.of(dialogContext).maybePop(),
        ),
      ),
    );
  }

  void _closeUnitDetails() {
    setState(() => _detailsUnitType = null);
  }
}
