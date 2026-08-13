part of 'city_production_dialog.dart';

mixin _CityProductionRequestFlow on State<CityProductionPanel> {
  bool _gamepadSelectionVisible = false;
  bool _productionSelectionPending = false;
  CityBuildingSortMode _buildingSortMode = CityBuildingSortMode.recommended;

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
      strategicResources: widget.strategicResources,
      productionPerTurn: widget.productionPerTurn,
      currentTurn: widget.currentTurn,
      paceBalance: widget.paceBalance,
    );
  }

  void _setBuildingSortMode(CityBuildingSortMode mode) {
    setState(() => _buildingSortMode = mode);
  }

  void _showGamepadSelection() {
    if (_gamepadSelectionVisible) return;
    setState(() => _gamepadSelectionVisible = true);
  }

  Future<void> _requestBuilding(CityBuildingType type) =>
      _requestProductionChange(
        target: BuildingProductionTarget(type),
        allocation: StrategicResourceBundle.empty,
        dispatch: () async {
          final request = widget.onBuildRequested;
          if (request != null) {
            await request(type);
          } else {
            widget.onBuild(type);
          }
        },
      );

  Future<void> _requestWonder(WonderType type) => _requestProductionChange(
    target: WonderProductionTarget(type),
    allocation: StrategicResourceBundle.empty,
    dispatch: () async {
      final request = widget.onBuildWonderRequested;
      if (request != null) {
        await request(type);
      } else {
        widget.onBuildWonder?.call(type);
      }
    },
  );

  Future<void> _requestProject(CityProjectType type) =>
      _requestProductionChange(
        target: ProjectProductionTarget(type),
        allocation: StrategicResourceBundle.empty,
        dispatch: () async {
          final request = widget.onStartProjectRequested;
          if (request != null) {
            await request(type);
          } else {
            widget.onStartProject?.call(type);
          }
        },
      );

  Future<void> _requestUnit(GameUnitType type) async {
    if (_productionSelectionPending) return;
    final item = _viewModelFor(AppLocalizations.of(context)).itemForUnit(type);
    final strategic = item?.unitAvailability?.strategic;
    var optionIndex = strategic?.selectedOptionIndex;
    if (strategic != null && strategic.options.length > 1) {
      optionIndex = await showCityProductionResourceOptionModal(
        context: context,
        availability: strategic,
      );
      if (optionIndex == null || !mounted) return;
    }
    final allocation = optionIndex == null || strategic == null
        ? strategic?.selectedAllocation ?? StrategicResourceBundle.empty
        : strategic.options[optionIndex];
    await _requestProductionChange(
      target: UnitProductionTarget(type),
      allocation: allocation,
      dispatch: () async {
        final request = widget.onProduceUnitRequested;
        if (request != null) {
          await request(type, optionIndex);
        } else {
          widget.onProduceUnit(type);
        }
      },
    );
  }

  Future<void> _requestProductionChange({
    required CityProductionTarget target,
    required StrategicResourceBundle allocation,
    required Future<void> Function() dispatch,
  }) async {
    if (_productionSelectionPending) return;
    final queue = widget.city.productionQueue;
    if (queue?.target == target) return;
    final mustConfirm =
        queue != null &&
        (queue.investedProduction > 0 || !queue.resourceAllocation.isEmpty);
    if (mustConfirm &&
        !await showCityProductionChangeConfirmationModal(
          context: context,
          stockpile: widget.strategicResources.forPlayer(
            widget.city.ownerPlayerId,
          ),
          currentAllocation: queue.resourceAllocation,
          nextAllocation: allocation,
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => _productionSelectionPending = true);
    try {
      await dispatch();
    } finally {
      if (mounted) setState(() => _productionSelectionPending = false);
    }
  }
}
