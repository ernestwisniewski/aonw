import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_dialog_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:flutter/foundation.dart';

final class CityProductionGamepadChoice {
  const CityProductionGamepadChoice({
    required this.key,
    required this.canConfirm,
    required this.onConfirm,
    this.onDetails,
  });

  final String key;
  final bool canConfirm;
  final VoidCallback onConfirm;
  final VoidCallback? onDetails;
}

abstract final class CityProductionGamepadNavigation {
  static List<CityProductionGamepadChoice> choicesFor({
    required CityProductionDialogViewModel viewModel,
    required CityBuildingSortMode buildingSortMode,
    required ValueChanged<CityBuildingType> onBuild,
    required ValueChanged<WonderType>? onBuildWonder,
    required ValueChanged<GameUnitType> onProduceUnit,
    required ValueChanged<CityProductionItem> onBuildingDetails,
    required ValueChanged<CityProductionItem> onUnitDetails,
    required ValueChanged<CityProjectType>? onStartProject,
    required ValueChanged<CitySpecializationType>? onSetSpecialization,
  }) {
    return [
      for (final item in CityProductionList.sortedBuildings(
        viewModel.buildings,
        buildingSortMode,
      ))
        CityProductionGamepadChoice(
          key: cityProductionItemKey(item),
          canConfirm: !item.active,
          onConfirm: () => onBuild(item.buildingType!),
          onDetails: () => onBuildingDetails(item),
        ),
      for (final item in viewModel.units)
        CityProductionGamepadChoice(
          key: cityProductionItemKey(item),
          canConfirm: !item.active && !item.locked,
          onConfirm: () => onProduceUnit(item.unitType!),
          onDetails: () => onUnitDetails(item),
        ),
      for (final item in viewModel.wonders)
        if (!item.locked || item.active)
          CityProductionGamepadChoice(
            key: cityProductionItemKey(item),
            canConfirm: !item.active && !item.locked && onBuildWonder != null,
            onConfirm: () => onBuildWonder!(item.wonderType!),
          ),
      for (final item in viewModel.specializations)
        CityProductionGamepadChoice(
          key: citySpecializationItemKey(item),
          canConfirm:
              !item.active && !item.locked && onSetSpecialization != null,
          onConfirm: () => onSetSpecialization!(item.type),
        ),
      for (final item in viewModel.projects)
        CityProductionGamepadChoice(
          key: cityProductionItemKey(item),
          canConfirm: !item.active && onStartProject != null,
          onConfirm: () => onStartProject!(item.projectType!),
        ),
    ];
  }

  static String? selectedKeyFor(
    List<CityProductionGamepadChoice> choices,
    String? selectedKey,
  ) {
    return GamepadListCursor.selectedKeyFor(
      choices,
      selectedKey,
      keyOf: (choice) => choice.key,
      prefer: (choice) => choice.canConfirm,
    );
  }

  static String? nextKey({
    required List<CityProductionGamepadChoice> choices,
    required String? selectedKey,
    required GamepadMapDirection direction,
  }) {
    return GamepadListCursor.nextKey(
      items: choices,
      selectedKey: selectedKey,
      direction: direction,
      keyOf: (choice) => choice.key,
      prefer: (choice) => choice.canConfirm,
    );
  }

  static CityProductionGamepadChoice? selectedChoice(
    List<CityProductionGamepadChoice> choices,
    String? selectedKey,
  ) {
    return GamepadListCursor.selectedItemFor(
      choices,
      selectedKey,
      keyOf: (choice) => choice.key,
      prefer: (choice) => choice.canConfirm,
    );
  }
}
