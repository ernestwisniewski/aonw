part of 'city_production_dialog.dart';

typedef _CityProductionPanelViewData = ({
  AppLocalizations l10n,
  bool compact,
  CityProductionDialogViewModel viewModel,
  CityBuildingSortMode buildingSortMode,
  String? selectedItemKey,
  List<CityProductionGamepadChoice> gamepadChoices,
  CityProductionItem? detailsBuildingItem,
  CityProductionItem? detailsUnitItem,
  CityProductionItem? detailsWonderItem,
});

typedef _CityProductionPanelActions = ({
  ValueChanged<CityBuildingSortMode> onBuildingSortModeChanged,
  ValueChanged<CityProductionItem> onBuildingDetails,
  ValueChanged<CityProductionItem> onUnitDetails,
  ValueChanged<CityProductionItem> onWonderDetails,
  VoidCallback onCloseBuildingDetails,
  VoidCallback onCloseUnitDetails,
  VoidCallback onCloseWonderDetails,
});

class _CityProductionPanelView extends StatelessWidget {
  const _CityProductionPanelView({
    required this.panel,
    required this.data,
    required this.actions,
  });

  final CityProductionPanel panel;
  final _CityProductionPanelViewData data;
  final _CityProductionPanelActions actions;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 760,
        maxHeight: panel.maxHeight ?? MediaQuery.sizeOf(context).height * 0.82,
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
            _CityProductionPanelHeader(panel: panel, data: data),
            if (data.viewModel.activeItem case final activeItem?)
              _CityProductionActiveItem(
                item: activeItem,
                playerGold: panel.playerGold,
                onRushProduction: panel.onRushProduction,
              ),
            Flexible(
              child: data.viewModel.hasItems
                  ? _CityProductionChoicesView(
                      panel: panel,
                      data: data,
                      actions: actions,
                    )
                  : const CityEmptyProductionState(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityProductionPanelHeader extends StatelessWidget {
  const _CityProductionPanelHeader({required this.panel, required this.data});

  final CityProductionPanel panel;
  final _CityProductionPanelViewData data;

  @override
  Widget build(BuildContext context) {
    return CityProductionHeader(
      cityName: data.viewModel.cityName,
      title: data.l10n.productionTitle,
      productionPerTurnLabel: data.l10n.productionPerTurn(
        data.viewModel.productionPerTurn,
      ),
      playerGold: panel.playerGold,
      closeTooltip: data.l10n.closeAction,
      onClose: panel.onClose,
      compact: data.compact,
      strategicResourceSummaryLabel:
          data.viewModel.strategicResourceSummaryLabel,
    );
  }
}

class _CityProductionActiveItem extends StatelessWidget {
  const _CityProductionActiveItem({
    required this.item,
    required this.playerGold,
    required this.onRushProduction,
  });

  final CityProductionItem item;
  final int playerGold;
  final VoidCallback? onRushProduction;

  @override
  Widget build(BuildContext context) {
    return CityActiveProductionBanner(
      title: item.title,
      continuous: item.continuous,
      turnsRemaining: item.turnsRemaining,
      eta: item.effectiveEta,
      totalCost: item.totalCost,
      investedProduction: item.investedProduction,
      progress: item.progress,
      metaLabels: item.metaLabels,
      strategicResourceLabel: item.strategicResourceLabel,
      canBeRushed: item.canBeRushed,
      rushGoldCost: item.rushGoldCost,
      playerGold: playerGold,
      onRushProduction: onRushProduction,
    );
  }
}

class _CityProductionChoicesView extends StatelessWidget {
  const _CityProductionChoicesView({
    required this.panel,
    required this.data,
    required this.actions,
  });

  final CityProductionPanel panel;
  final _CityProductionPanelViewData data;
  final _CityProductionPanelActions actions;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: _productionList()),
        if (data.detailsBuildingItem case final item?)
          Positioned.fill(child: _buildingDetails(item)),
        if (data.detailsUnitItem case final item?)
          Positioned.fill(child: _unitDetails(item)),
        if (data.detailsWonderItem case final item?)
          Positioned.fill(child: _wonderDetails(item)),
      ],
    );
  }

  Widget _productionList() {
    final viewModel = data.viewModel;
    return CityProductionList(
      buildings: viewModel.buildings,
      futureBuildings: viewModel.futureBuildings,
      wonders: viewModel.wonders,
      units: viewModel.units,
      projects: viewModel.projects,
      specializations: viewModel.specializations,
      buildingSortMode: data.buildingSortMode,
      onBuildingSortModeChanged: actions.onBuildingSortModeChanged,
      selectedItemKey: data.selectedItemKey,
      onBuildingDetails: actions.onBuildingDetails,
      onUnitDetails: actions.onUnitDetails,
      onWonderDetails: actions.onWonderDetails,
      onBuild: panel.onBuild,
      onBuildWonder: panel.onBuildWonder,
      onProduceUnit: panel.onProduceUnit,
      onStartProject: panel.onStartProject,
      onSetSpecialization: panel.onSetSpecialization,
      compact: data.compact,
    );
  }

  Widget _buildingDetails(CityProductionItem item) {
    final buildingType = item.buildingType!;
    return CityProductionBuildingDetailsLayer(
      item: item,
      l10n: data.l10n,
      definition: panel.cityRuleset.buildingDefinitionFor(buildingType),
      unlockingTechnology: TechnologyUnlockQuery.unlockingTechnologyForBuilding(
        buildingType: buildingType,
        ruleset: panel.technologyRuleset,
      ),
      currentCityYield: data.viewModel.currentCityYield,
      currentCityScience: data.viewModel.currentCityScience,
      compact: data.compact,
      onClose: actions.onCloseBuildingDetails,
    );
  }

  Widget _unitDetails(CityProductionItem item) {
    final unitType = item.unitType!;
    return CityProductionUnitDetailsLayer(
      item: item,
      l10n: data.l10n,
      definition: panel.cityRuleset.unitDefinitionFor(unitType),
      unlockingTechnology: TechnologyUnlockQuery.unlockingTechnologyForUnit(
        unitType: unitType,
        ruleset: panel.technologyRuleset,
      ),
      compact: data.compact,
      onClose: actions.onCloseUnitDetails,
    );
  }

  Widget _wonderDetails(CityProductionItem item) {
    final wonderType = item.wonderType!;
    return CityProductionWonderDetailsLayer(
      item: item,
      l10n: data.l10n,
      definition: panel.wonderRuleset.definitionFor(wonderType),
      unlockingTechnology: TechnologyUnlockQuery.unlockingTechnologyForWonder(
        wonderType: wonderType,
        ruleset: panel.technologyRuleset,
      ),
      compact: data.compact,
      onClose: actions.onCloseWonderDetails,
    );
  }
}
