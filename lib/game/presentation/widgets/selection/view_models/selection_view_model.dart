import 'package:aonw/game/presentation/widgets/bottom_toolbar/hex_presentation/hex_tag_view_model.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_yield_breakdown_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_improvement_item.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_item.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_resource_value_card.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_yield_item.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class SelectionCityBuildingItem {
  final CityBuildingType? type;
  final String label;

  const SelectionCityBuildingItem({required this.label, this.type});
}

class SelectionAssetIconViewModel {
  final GameUnitType? unitType;
  final int? cityVisualLevel;
  final int? cityTechnologyProfileIndex;
  final FieldImprovementType? fieldImprovementType;
  final int? fieldImprovementEraColumn;

  const SelectionAssetIconViewModel.unit(this.unitType)
    : cityVisualLevel = null,
      cityTechnologyProfileIndex = null,
      fieldImprovementType = null,
      fieldImprovementEraColumn = null;

  const SelectionAssetIconViewModel.city({
    this.cityVisualLevel = 0,
    this.cityTechnologyProfileIndex = 0,
  }) : unitType = null,
       fieldImprovementType = null,
       fieldImprovementEraColumn = null;

  const SelectionAssetIconViewModel.fieldImprovement({
    required this.fieldImprovementType,
    this.fieldImprovementEraColumn = 0,
  }) : unitType = null,
       cityVisualLevel = null,
       cityTechnologyProfileIndex = null;

  bool get isUnit => unitType != null;
  bool get isCity => cityVisualLevel != null;
  bool get isFieldImprovement => fieldImprovementType != null;
}

class SelectionViewModel {
  final GameIconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final SelectionAssetIconViewModel? assetIcon;
  final List<SelectionInfoItem> items;
  final String description;
  final List<SelectionInfoItem> descriptionItems;
  final List<SelectionYieldItem> yields;
  final String? yieldTitle;
  final String? yieldTooltip;
  final List<HexTagViewModel> tags;
  final List<SelectionImprovementItem> improvements;
  final List<SelectionResourceValueCard> resourceValueCards;
  final List<String> cityBuildings;
  final List<SelectionCityBuildingItem> cityBuildingItems;
  final CityYieldBreakdownViewModel? cityYieldBreakdown;
  final bool supportsArmyDetail;
  final List<ArmyTroop> armyTroops;
  final WorkerActionPanelViewModel? workerAction;
  final String selectionKey;
  final bool preferImprovementsTab;

  const SelectionViewModel({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.assetIcon,
    required this.items,
    this.description = '',
    this.descriptionItems = const [],
    this.yields = const [],
    this.yieldTitle,
    this.yieldTooltip,
    this.tags = const [],
    this.improvements = const [],
    this.resourceValueCards = const [],
    this.cityBuildings = const [],
    this.cityBuildingItems = const [],
    this.cityYieldBreakdown,
    this.supportsArmyDetail = false,
    this.armyTroops = const [],
    this.workerAction,
    this.selectionKey = '',
    this.preferImprovementsTab = false,
  });

  const factory SelectionViewModel.empty() = EmptySelectionViewModel;
}

class EmptySelectionViewModel extends SelectionViewModel {
  const EmptySelectionViewModel()
    : super(
        icon: GameIcons.touch,
        color: GameUiTheme.accent,
        title: '',
        subtitle: '',
        selectionKey: 'empty',
        items: const [],
      );
}
