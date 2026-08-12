import 'dart:async';

import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_active_production_banner.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/city/city_empty_production_state.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_change_modals.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_details_panels.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_dialog_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_gamepad_navigation.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_header.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list.dart';
import 'package:aonw/game/presentation/widgets/city/wonder_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_type_icon.dart';
import 'package:aonw/game/presentation/widgets/unit/unit_details_panel.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'city_production_panel_details.dart';
part 'city_production_panel_view.dart';
part 'city_production_request_flow.dart';

class CityProductionDialog extends StatelessWidget {
  final GameCity city;
  final CityRuleset cityRuleset;
  final ResearchState research;
  final TechnologyRuleset technologyRuleset;
  final WonderRegistry wonderRegistry;
  final WonderRuleset wonderRuleset;
  final WorldMap? mapData;
  final List<GameCity> cities;
  final List<GameUnit> units;
  final List<WorldArtifact> artifacts;
  final List<FieldImprovement> fieldImprovements;
  final Iterable<ResourceTradeAgreement> resourceTradeAgreements;
  final StrategicResourceAccounts strategicResources;
  final StrategicResourceEconomyProfile strategicResourceEconomy;
  final int productionPerTurn;
  final int? currentTurn;
  final PaceBalance paceBalance;
  final int playerGold;
  final ValueChanged<CityBuildingType> onBuild;
  final Future<void> Function(CityBuildingType)? onBuildRequested;
  final ValueChanged<WonderType>? onBuildWonder;
  final Future<void> Function(WonderType)? onBuildWonderRequested;
  final ValueChanged<GameUnitType> onProduceUnit;
  final Future<void> Function(GameUnitType, int?)? onProduceUnitRequested;
  final ValueChanged<CityProjectType>? onStartProject;
  final Future<void> Function(CityProjectType)? onStartProjectRequested;
  final ValueChanged<CitySpecializationType>? onSetSpecialization;
  final VoidCallback? onRushProduction;
  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;

  const CityProductionDialog({
    required this.city,
    required this.cityRuleset,
    required this.research,
    required this.technologyRuleset,
    this.wonderRegistry = WonderRegistry.empty,
    this.wonderRuleset = WonderRuleset.standard,
    this.mapData,
    this.cities = const [],
    this.units = const [],
    this.artifacts = const [],
    this.fieldImprovements = const [],
    this.resourceTradeAgreements = const [],
    this.strategicResources = StrategicResourceAccounts.empty,
    this.strategicResourceEconomy =
        StrategicResourceEconomyProfile.legacyPresenceV0,
    required this.productionPerTurn,
    this.currentTurn,
    this.paceBalance = PaceBalance.unlimited,
    this.playerGold = 0,
    required this.onBuild,
    this.onBuildRequested,
    this.onBuildWonder,
    this.onBuildWonderRequested,
    required this.onProduceUnit,
    this.onProduceUnitRequested,
    this.onStartProject,
    this.onStartProjectRequested,
    this.onSetSpecialization,
    this.onRushProduction,
    this.gamepadInputListenable,
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
      wonderRegistry: wonderRegistry,
      wonderRuleset: wonderRuleset,
      mapData: mapData,
      cities: cities,
      units: units,
      artifacts: artifacts,
      fieldImprovements: fieldImprovements,
      resourceTradeAgreements: resourceTradeAgreements,
      strategicResources: strategicResources,
      strategicResourceEconomy: strategicResourceEconomy,
      productionPerTurn: productionPerTurn,
      currentTurn: currentTurn,
      paceBalance: paceBalance,
      playerGold: playerGold,
      maxHeight: size.height * 0.82,
      onBuild: onBuild,
      onBuildRequested: onBuildRequested,
      onBuildWonder: onBuildWonder,
      onBuildWonderRequested: onBuildWonderRequested,
      onProduceUnit: onProduceUnit,
      onProduceUnitRequested: onProduceUnitRequested,
      onStartProject: onStartProject,
      onStartProjectRequested: onStartProjectRequested,
      onSetSpecialization: onSetSpecialization,
      onRushProduction: onRushProduction,
      gamepadInputListenable: gamepadInputListenable,
      onClose: () => Navigator.of(context).maybePop(),
    );
  }
}

class CityProductionPanel extends StatefulWidget {
  final GameCity city;
  final CityRuleset cityRuleset;
  final ResearchState research;
  final TechnologyRuleset technologyRuleset;
  final WonderRegistry wonderRegistry;
  final WonderRuleset wonderRuleset;
  final WorldMap? mapData;
  final List<GameCity> cities;
  final List<GameUnit> units;
  final List<WorldArtifact> artifacts;
  final List<FieldImprovement> fieldImprovements;
  final Iterable<ResourceTradeAgreement> resourceTradeAgreements;
  final StrategicResourceAccounts strategicResources;
  final StrategicResourceEconomyProfile strategicResourceEconomy;
  final int productionPerTurn;
  final int? currentTurn;
  final PaceBalance paceBalance;
  final int playerGold;
  final double? maxHeight;
  final ValueChanged<CityBuildingType> onBuild;
  final Future<void> Function(CityBuildingType)? onBuildRequested;
  final ValueChanged<WonderType>? onBuildWonder;
  final Future<void> Function(WonderType)? onBuildWonderRequested;
  final ValueChanged<GameUnitType> onProduceUnit;
  final Future<void> Function(GameUnitType, int?)? onProduceUnitRequested;
  final ValueChanged<CityProjectType>? onStartProject;
  final Future<void> Function(CityProjectType)? onStartProjectRequested;
  final ValueChanged<CitySpecializationType>? onSetSpecialization;
  final VoidCallback? onRushProduction;
  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;
  final VoidCallback onClose;

  const CityProductionPanel({
    required this.city,
    required this.cityRuleset,
    required this.research,
    required this.technologyRuleset,
    this.wonderRegistry = WonderRegistry.empty,
    this.wonderRuleset = WonderRuleset.standard,
    this.mapData,
    this.cities = const [],
    this.units = const [],
    this.artifacts = const [],
    this.fieldImprovements = const [],
    this.resourceTradeAgreements = const [],
    this.strategicResources = StrategicResourceAccounts.empty,
    this.strategicResourceEconomy =
        StrategicResourceEconomyProfile.legacyPresenceV0,
    required this.productionPerTurn,
    this.currentTurn,
    this.paceBalance = PaceBalance.unlimited,
    this.playerGold = 0,
    this.maxHeight,
    required this.onBuild,
    this.onBuildRequested,
    this.onBuildWonder,
    this.onBuildWonderRequested,
    required this.onProduceUnit,
    this.onProduceUnitRequested,
    this.onStartProject,
    this.onStartProjectRequested,
    this.onSetSpecialization,
    this.onRushProduction,
    this.gamepadInputListenable,
    required this.onClose,
    super.key,
  });

  @override
  State<CityProductionPanel> createState() => _CityProductionPanelState();
}

class _CityProductionPanelState extends State<CityProductionPanel>
    with _CityProductionRequestFlow {
  CityBuildingType? _detailsBuildingType;
  GameUnitType? _detailsUnitType;
  WonderType? _detailsWonderType;
  String? _selectedItemKey;

  void _setDetailsState(void Function() update) => setState(update);

  @override
  void didUpdateWidget(covariant CityProductionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city.id != widget.city.id) {
      _detailsBuildingType = null;
      _detailsUnitType = null;
      _detailsWonderType = null;
      _selectedItemKey = null;
      _gamepadSelectionVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewData = _viewDataFor(context);

    return GamepadPanelInputListener(
      input: widget.gamepadInputListenable,
      onNavigate: (direction) =>
          _moveSelection(viewData.gamepadChoices, direction),
      onConfirm: () => _confirmSelected(viewData.gamepadChoices),
      onDetails: () => _showSelectedDetails(viewData.gamepadChoices),
      onCancel: _handleGamepadCancel,
      onInputActive: _showGamepadSelection,
      child: _CityProductionPanelView(
        panel: widget,
        data: viewData,
        actions: (
          onBuildingSortModeChanged: _setBuildingSortMode,
          onBuildingDetails: _showBuildingDetails,
          onUnitDetails: _showUnitDetails,
          onWonderDetails: _showWonderDetails,
          onCloseBuildingDetails: _closeBuildingDetails,
          onCloseUnitDetails: _closeUnitDetails,
          onCloseWonderDetails: _closeWonderDetails,
          onBuild: _requestBuilding,
          onBuildWonder: _requestWonder,
          onProduceUnit: _requestUnit,
          onStartProject: _requestProject,
        ),
      ),
    );
  }

  _CityProductionPanelViewData _viewDataFor(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final viewModel = _viewModelFor(l10n);
    final gamepadChoices = CityProductionGamepadNavigation.choicesFor(
      viewModel: viewModel,
      buildingSortMode: _buildingSortMode,
      onBuild: _requestBuilding,
      onBuildWonder: widget.onBuildWonder == null ? null : _requestWonder,
      onProduceUnit: _requestUnit,
      onBuildingDetails: _showBuildingDetails,
      onUnitDetails: _showUnitDetails,
      onWonderDetails: _showWonderDetails,
      onStartProject: widget.onStartProject == null ? null : _requestProject,
      onSetSpecialization: widget.onSetSpecialization,
    );
    return (
      l10n: l10n,
      compact: MediaQuery.sizeOf(context).width < 480,
      viewModel: viewModel,
      buildingSortMode: _buildingSortMode,
      selectedItemKey: _gamepadSelectionVisible
          ? CityProductionGamepadNavigation.selectedKeyFor(
              gamepadChoices,
              _selectedItemKey,
            )
          : null,
      gamepadChoices: gamepadChoices,
      productionSelectionPending: _productionSelectionPending,
      detailsBuildingItem: viewModel.itemForBuilding(_detailsBuildingType),
      detailsUnitItem: viewModel.itemForUnit(_detailsUnitType),
      detailsWonderItem: viewModel.itemForWonder(_detailsWonderType),
    );
  }

  void _moveSelection(
    List<CityProductionGamepadChoice> choices,
    GamepadMapDirection direction,
  ) {
    final nextKey = CityProductionGamepadNavigation.nextKey(
      choices: choices,
      selectedKey: _selectedItemKey,
      direction: direction,
    );
    if (nextKey == null) return;
    setState(() => _selectedItemKey = nextKey);
  }

  void _confirmSelected(List<CityProductionGamepadChoice> choices) {
    final selected = CityProductionGamepadNavigation.selectedChoice(
      choices,
      _selectedItemKey,
    );
    if (selected == null || !selected.canConfirm) return;
    selected.onConfirm();
  }

  void _showSelectedDetails(List<CityProductionGamepadChoice> choices) {
    final selected = CityProductionGamepadNavigation.selectedChoice(
      choices,
      _selectedItemKey,
    );
    selected?.onDetails?.call();
  }

  void _handleGamepadCancel() {
    if (_closeInlineDetails()) return;
    widget.onClose();
  }

  bool _closeInlineDetails() {
    if (_detailsBuildingType == null &&
        _detailsUnitType == null &&
        _detailsWonderType == null) {
      return false;
    }
    setState(() {
      _detailsBuildingType = null;
      _detailsUnitType = null;
      _detailsWonderType = null;
    });
    return true;
  }
}
