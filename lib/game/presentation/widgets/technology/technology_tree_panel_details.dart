part of 'technology_tree_dialog.dart';

extension _TechnologyTreePanelDetails on _TechnologyTreePanelState {
  void _showTechnologyDetails(TechnologyCardViewModel card) {
    if (_opensDetailsAsModal(context)) {
      _showTechnologyDetailsModal(card);
      return;
    }
    _setDetailsState(() {
      _detailsTechnologyId = card.id;
      _detailsBuildingType = null;
      _detailsUnitType = null;
      _detailsWonderType = null;
    });
  }

  void _closeTechnologyDetails() {
    _setDetailsState(() => _detailsTechnologyId = null);
  }

  void _showBuildingDetails(CityBuildingType buildingType) {
    if (_opensDetailsAsModal(context)) {
      _showBuildingDetailsModal(buildingType);
      return;
    }
    _setDetailsState(() {
      _detailsTechnologyId = null;
      _detailsBuildingType = buildingType;
      _detailsUnitType = null;
      _detailsWonderType = null;
    });
  }

  void _showUnitDetails(GameUnitType unitType) {
    if (_opensDetailsAsModal(context)) {
      _showUnitDetailsModal(unitType);
      return;
    }
    _setDetailsState(() {
      _detailsTechnologyId = null;
      _detailsBuildingType = null;
      _detailsUnitType = unitType;
      _detailsWonderType = null;
    });
  }

  void _showWonderDetails(WonderType wonderType) {
    if (_opensDetailsAsModal(context)) {
      _showWonderDetailsModal(wonderType);
      return;
    }
    _setDetailsState(() {
      _detailsTechnologyId = null;
      _detailsBuildingType = null;
      _detailsUnitType = null;
      _detailsWonderType = wonderType;
    });
  }

  bool _opensDetailsAsModal(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.portrait;
  }

  void _showTechnologyDetailsModal(TechnologyCardViewModel card) {
    final l10n = AppLocalizations.of(context);
    _clearInlineDetails();
    unawaited(
      showGameModal<void>(
        context: context,
        builder: (dialogContext) => TechnologyDetailsDialog(
          card: card,
          l10n: l10n,
          cityRuleset: widget.cityRuleset,
          technologyRuleset: widget.technologyRuleset,
          onClose: () => Navigator.of(dialogContext).maybePop(),
        ),
      ),
    );
  }

  void _showBuildingDetailsModal(CityBuildingType buildingType) {
    final l10n = AppLocalizations.of(context);
    final definition = widget.cityRuleset.buildingDefinitionFor(buildingType);
    _clearInlineDetails();
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
          title: GameDisplayNames.cityBuilding(l10n, buildingType),
          statusLabel: l10n.technologyDetailsUnlockStatus,
          costLabel: l10n.cityProductionCostShort(definition.productionCost),
          onClose: () => Navigator.of(dialogContext).maybePop(),
        ),
      ),
    );
  }

  void _showUnitDetailsModal(GameUnitType unitType) {
    final l10n = AppLocalizations.of(context);
    final definition = _unitDefinitionFor(unitType);
    _clearInlineDetails();
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
          title: GameDisplayNames.unitType(l10n, unitType),
          statusLabel: l10n.technologyDetailsUnlockStatus,
          costLabel: definition == null
              ? null
              : l10n.cityProductionCostShort(definition.productionCost),
          maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.78,
          onClose: () => Navigator.of(dialogContext).maybePop(),
        ),
      ),
    );
  }

  void _showWonderDetailsModal(WonderType wonderType) {
    final l10n = AppLocalizations.of(context);
    final definition = WonderRuleset.standard.definitionFor(wonderType);
    _clearInlineDetails();
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
          title: WonderDisplayNames.wonder(l10n, wonderType),
          statusLabel: l10n.technologyDetailsUnlockStatus,
          costLabel: l10n.cityProductionCostShort(definition.productionCost),
          onClose: () => Navigator.of(dialogContext).maybePop(),
        ),
      ),
    );
  }

  void _clearInlineDetails() {
    if (_detailsTechnologyId == null &&
        _detailsBuildingType == null &&
        _detailsUnitType == null &&
        _detailsWonderType == null) {
      return;
    }
    _setDetailsState(() {
      _detailsTechnologyId = null;
      _detailsBuildingType = null;
      _detailsUnitType = null;
      _detailsWonderType = null;
    });
  }

  UnitProductionDefinition? _unitDefinitionFor(GameUnitType unitType) {
    try {
      return widget.cityRuleset.unitDefinitionFor(unitType);
    } on ArgumentError {
      return null;
    }
  }

  void _closeDetailsLayer() {
    _setDetailsState(() {
      _detailsBuildingType = null;
      _detailsUnitType = null;
      _detailsWonderType = null;
    });
  }

  TechnologyCardViewModel? _technologyCardFor(
    List<TechnologyCardViewModel> cards,
    TechnologyId? technologyId,
  ) {
    if (technologyId == null) return null;
    for (final card in cards) {
      if (card.id == technologyId) return card;
    }
    return null;
  }
}
