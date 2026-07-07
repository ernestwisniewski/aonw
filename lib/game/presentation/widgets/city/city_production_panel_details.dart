part of 'city_production_dialog.dart';

extension _CityProductionPanelDetails on _CityProductionPanelState {
  void _showBuildingDetails(CityProductionItem item) {
    final buildingType = item.buildingType;
    if (buildingType == null) return;
    if (_opensDetailsAsModal(context)) {
      _showBuildingDetailsModal(item);
      return;
    }
    _setDetailsState(() {
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
      wonderRegistry: widget.wonderRegistry,
      wonderRuleset: widget.wonderRuleset,
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

  void _closeBuildingDetails() {
    _setDetailsState(() => _detailsBuildingType = null);
  }

  void _showUnitDetails(CityProductionItem item) {
    final unitType = item.unitType;
    if (unitType == null) return;
    if (_opensDetailsAsModal(context)) {
      _showUnitDetailsModal(item);
      return;
    }
    _setDetailsState(() {
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
    _setDetailsState(() => _detailsUnitType = null);
  }
}
