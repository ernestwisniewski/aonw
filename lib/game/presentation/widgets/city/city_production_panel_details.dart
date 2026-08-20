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
      _detailsWonderType = null;
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
      _detailsWonderType = null;
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
          statusLabel: item.active
              ? l10n.productionInProgressLabel
              : item.locked
              ? l10n.productionButtonLocked
              : l10n.cityProductionAvailableUnitLabel,
          costLabel: l10n.cityProductionCostShort(definition.productionCost),
          progressLabel: _buildingProgressLabel(l10n, item),
          paceLabel: l10n.cityProductionPaceShort(item.productionPerTurn),
          additionalRequirementLines: item.unitRequirementLines,
          maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.78,
          onClose: () => Navigator.of(dialogContext).maybePop(),
        ),
      ),
    );
  }

  void _closeUnitDetails() {
    _setDetailsState(() => _detailsUnitType = null);
  }

  void _showWonderDetails(CityProductionItem item) {
    final wonderType = item.wonderType;
    if (wonderType == null) return;
    if (_opensDetailsAsModal(context)) {
      _showWonderDetailsModal(item);
      return;
    }
    _setDetailsState(() {
      _detailsBuildingType = null;
      _detailsUnitType = null;
      _detailsWonderType = wonderType;
    });
  }

  void _showWonderDetailsModal(CityProductionItem item) {
    final wonderType = item.wonderType;
    if (wonderType == null) return;
    final l10n = AppLocalizations.of(context);
    final definition = widget.wonderRuleset.definitionFor(wonderType);

    unawaited(
      showGameModal<void>(
        context: context,
        builder: (dialogContext) => WonderDetailsDialog(
          wonderType: wonderType,
          definition: definition,
          unlockingTechnology:
              TechnologyUnlockQuery.unlockingTechnologyForWonder(
                wonderType: wonderType,
                ruleset: widget.technologyRuleset,
              ),
          l10n: l10n,
          title: item.title,
          statusLabel: item.active
              ? l10n.productionInProgressLabel
              : item.locked
              ? l10n.productionButtonLocked
              : l10n.cityProductionAvailableLabel,
          costLabel: l10n.cityProductionCostShort(definition.productionCost),
          progressLabel: _buildingProgressLabel(l10n, item),
          paceLabel: l10n.cityProductionPaceShort(item.productionPerTurn),
          onClose: () => Navigator.of(dialogContext).maybePop(),
        ),
      ),
    );
  }

  void _closeWonderDetails() {
    _setDetailsState(() => _detailsWonderType = null);
  }
}
