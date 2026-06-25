import 'package:aonw/game/presentation/widgets/bottom_toolbar/hex_presentation/hex_tag_view_model.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_yield_breakdown_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_improvement_item.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_item.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_resource_value_card.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_yield_item.dart';
import 'package:aonw_core/game/domain/unit.dart';

sealed class SelectionDetailViewModel {
  final String chipId;
  final String title;
  final String contentKey;

  const SelectionDetailViewModel({
    required this.chipId,
    required this.title,
    required this.contentKey,
  });
}

class SelectionDescriptionDetail extends SelectionDetailViewModel {
  final String heading;
  final String subtitle;
  final String body;
  final List<SelectionInfoItem> items;
  final List<SelectionYieldItem> yields;
  final String? yieldTitle;
  final String? yieldTooltip;
  final List<HexTagViewModel> tags;
  final CityYieldBreakdownViewModel? cityYieldBreakdown;
  final SelectionAssetIconViewModel? assetIcon;

  const SelectionDescriptionDetail({
    required super.chipId,
    required super.contentKey,
    required super.title,
    required this.heading,
    required this.subtitle,
    this.body = '',
    required this.items,
    required this.yields,
    this.yieldTitle,
    this.yieldTooltip,
    required this.tags,
    this.cityYieldBreakdown,
    this.assetIcon,
  });
}

class SelectionTerrainDetail extends SelectionDetailViewModel {
  final List<String> terrainLabels;
  final List<HexTagViewModel> tags;

  const SelectionTerrainDetail({
    required super.chipId,
    required super.title,
    required super.contentKey,
    required this.terrainLabels,
    required this.tags,
  });
}

class SelectionResourcesDetail extends SelectionDetailViewModel {
  final List<String> resourceLabels;
  final List<SelectionInfoItem> resourceItems;
  final List<SelectionResourceValueCard> valueCards;

  const SelectionResourcesDetail({
    required super.chipId,
    required super.contentKey,
    required super.title,
    required this.resourceLabels,
    required this.resourceItems,
    this.valueCards = const [],
  });
}

class SelectionImprovementsDetail extends SelectionDetailViewModel {
  final List<SelectionImprovementItem> improvements;

  const SelectionImprovementsDetail({
    required super.chipId,
    required super.title,
    required super.contentKey,
    required this.improvements,
  });
}

class SelectionBuildingsDetail extends SelectionDetailViewModel {
  final List<String> buildings;
  final List<SelectionCityBuildingItem> buildingItems;

  const SelectionBuildingsDetail({
    required super.chipId,
    required super.title,
    required super.contentKey,
    required this.buildings,
    this.buildingItems = const [],
  });

  List<SelectionCityBuildingItem> get displayItems {
    if (buildingItems.isNotEmpty) return buildingItems;
    return [
      for (final building in buildings)
        SelectionCityBuildingItem(label: building),
    ];
  }
}

class SelectionArmyDetail extends SelectionDetailViewModel {
  final List<ArmyTroop> troops;

  const SelectionArmyDetail({
    required super.chipId,
    required super.title,
    required super.contentKey,
    required this.troops,
  });
}

class WorkerActionSelectionDetail extends SelectionDetailViewModel {
  const WorkerActionSelectionDetail({
    required super.chipId,
    required super.title,
    required super.contentKey,
    required this.workerAction,
  });

  final WorkerActionPanelViewModel workerAction;
}
