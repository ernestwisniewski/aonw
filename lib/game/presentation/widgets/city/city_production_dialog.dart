import 'dart:async';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_active_production_banner.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/city/city_empty_production_state.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_details_panels.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_dialog_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_gamepad_navigation.dart';
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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'city_production_panel_details.dart';

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
  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;

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
  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;
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
    this.gamepadInputListenable,
    required this.onClose,
    super.key,
  });

  @override
  State<CityProductionPanel> createState() => _CityProductionPanelState();
}

class _CityProductionPanelState extends State<CityProductionPanel> {
  CityBuildingType? _detailsBuildingType;
  GameUnitType? _detailsUnitType;
  String? _selectedItemKey;
  bool _gamepadSelectionVisible = false;
  CityBuildingSortMode _buildingSortMode = CityBuildingSortMode.recommended;

  void _setDetailsState(void Function() update) {
    setState(update);
  }

  @override
  void didUpdateWidget(covariant CityProductionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city.id != widget.city.id) {
      _detailsBuildingType = null;
      _detailsUnitType = null;
      _selectedItemKey = null;
      _gamepadSelectionVisible = false;
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
    final gamepadChoices = CityProductionGamepadNavigation.choicesFor(
      viewModel: viewModel,
      buildingSortMode: _buildingSortMode,
      onBuild: widget.onBuild,
      onProduceUnit: widget.onProduceUnit,
      onBuildingDetails: _showBuildingDetails,
      onUnitDetails: _showUnitDetails,
      onStartProject: widget.onStartProject,
      onSetSpecialization: widget.onSetSpecialization,
    );
    final selectedItemKey = CityProductionGamepadNavigation.selectedKeyFor(
      gamepadChoices,
      _selectedItemKey,
    );

    return GamepadPanelInputListener(
      input: widget.gamepadInputListenable,
      onNavigate: (direction) => _moveSelection(gamepadChoices, direction),
      onConfirm: () => _confirmSelected(gamepadChoices),
      onDetails: () => _showSelectedDetails(gamepadChoices),
      onCancel: _handleGamepadCancel,
      onInputActive: _showGamepadSelection,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight:
              widget.maxHeight ?? MediaQuery.sizeOf(context).height * 0.82,
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
                              selectedItemKey: _gamepadSelectionVisible
                                  ? selectedItemKey
                                  : null,
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
                                currentCityScience:
                                    viewModel.currentCityScience,
                                compact: compact,
                                onClose: _closeBuildingDetails,
                              ),
                            ),
                          if (detailsUnitItem != null)
                            Positioned.fill(
                              child: CityProductionUnitDetailsLayer(
                                item: detailsUnitItem,
                                l10n: l10n,
                                definition: widget.cityRuleset
                                    .unitDefinitionFor(
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
      ),
    );
  }

  void _setBuildingSortMode(CityBuildingSortMode mode) {
    setState(() => _buildingSortMode = mode);
  }

  void _showGamepadSelection() {
    if (_gamepadSelectionVisible) return;
    setState(() => _gamepadSelectionVisible = true);
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
    if (_detailsBuildingType == null && _detailsUnitType == null) return false;
    setState(() {
      _detailsBuildingType = null;
      _detailsUnitType = null;
    });
    return true;
  }
}
