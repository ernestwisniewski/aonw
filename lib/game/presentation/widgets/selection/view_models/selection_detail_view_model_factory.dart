import 'package:aonw/game/presentation/widgets/selection/view_models/selection_detail_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_chip_id.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_chips_factory.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_item.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_view_model.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';

abstract final class SelectionDetailViewModelFactory {
  static SelectionDetailViewModel? detailFor(
    String chipId,
    SelectionViewModel model,
    AppLocalizations l10n,
  ) {
    if (!SelectionInfoChipsFactory.supportsChip(model, chipId)) return null;
    final improvementDescription =
        chipId == SelectionInfoChipId.description &&
        model.selectionKey.startsWith('improvement:');
    final cityDescription =
        chipId == SelectionInfoChipId.description &&
        model.selectionKey.startsWith('city:');
    final unitDescription =
        chipId == SelectionInfoChipId.description &&
        model.selectionKey.startsWith('unit:');
    final assetFocusedDescription = improvementDescription || cityDescription;

    return switch (chipId) {
      SelectionInfoChipId.description => SelectionDescriptionDetail(
        chipId: chipId,
        contentKey: '${model.selectionKey}:$chipId',
        title: assetFocusedDescription ? model.title : l10n.commonDescription,
        heading: assetFocusedDescription ? '' : model.title,
        subtitle: assetFocusedDescription ? '' : model.subtitle,
        body: model.description,
        items: _descriptionItemsFor(
          model,
          improvementDescription: improvementDescription,
          cityDescription: cityDescription,
          unitDescription: unitDescription,
        ),
        yields: improvementDescription
            ? model.yields
                  .where((item) => item.value > 0)
                  .toList(growable: false)
            : model.yields,
        yieldTitle: model.yieldTitle,
        yieldTooltip: model.yieldTooltip,
        tags: improvementDescription ? const [] : model.tags,
        cityYieldBreakdown: model.cityYieldBreakdown,
        assetIcon: model.assetIcon,
      ),
      SelectionInfoChipId.terrain => SelectionTerrainDetail(
        chipId: chipId,
        title: l10n.commonTerrain,
        contentKey: '${model.selectionKey}:$chipId',
        terrainLabels: _partsFrom(
          _itemByLabel(model, SelectionInfoItemSemanticId.terrain)?.value,
          noneLabel: l10n.commonNoneLower,
        ),
        tags: model.tags,
      ),
      SelectionInfoChipId.resources => SelectionResourcesDetail(
        chipId: chipId,
        contentKey: '${model.selectionKey}:$chipId',
        title: l10n.commonResources,
        resourceLabels: _partsFrom(
          _itemByLabel(model, SelectionInfoItemSemanticId.resources)?.value,
          noneLabel: l10n.commonNoneLower,
        ),
        resourceItems: [
          for (final item in model.items)
            if (_matchesItem(item, SelectionInfoItemSemanticId.resources)) item,
        ],
        valueCards: model.resourceValueCards,
      ),
      SelectionInfoChipId.improvements => SelectionImprovementsDetail(
        chipId: chipId,
        title: l10n.commonImprovements,
        contentKey: '${model.selectionKey}:$chipId',
        improvements: model.improvements,
      ),
      SelectionInfoChipId.buildings => SelectionBuildingsDetail(
        chipId: chipId,
        title: l10n.commonBuildings,
        contentKey: '${model.selectionKey}:$chipId',
        buildings: model.cityBuildings,
        buildingItems: model.cityBuildingItems,
      ),
      SelectionInfoChipId.army => SelectionArmyDetail(
        chipId: chipId,
        title: l10n.selectionActionArmy,
        contentKey: '${model.selectionKey}:$chipId',
        troops: model.armyTroops,
      ),
      _ => null,
    };
  }

  static SelectionInfoItem? _itemByLabel(
    SelectionViewModel model,
    String label,
  ) {
    for (final item in model.items) {
      if (_matchesItem(item, label)) return item;
    }
    return null;
  }

  static List<SelectionInfoItem> _descriptionItemsFor(
    SelectionViewModel model, {
    required bool improvementDescription,
    required bool cityDescription,
    required bool unitDescription,
  }) {
    if (improvementDescription) return const [];
    if (cityDescription && model.descriptionItems.isNotEmpty) {
      return model.descriptionItems;
    }
    if (unitDescription) return model.descriptionItems;
    return model.items;
  }

  static bool _matchesItem(SelectionInfoItem item, String label) {
    return item.label == label || item.semanticId == label;
  }

  static List<String> _partsFrom(String? value, {required String noneLabel}) {
    if (value == null || value.isEmpty) return const [];
    final normalized = value.toLowerCase();
    if (normalized == noneLabel.toLowerCase()) return const [];
    return [
      for (final part in value.split(' + '))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }
}
