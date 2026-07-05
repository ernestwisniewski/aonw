import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_dialog_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_list.dart';
import 'package:aonw_core/game/domain/unit.dart';
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
    if (selectedKey != null &&
        choices.any((choice) => choice.key == selectedKey)) {
      return selectedKey;
    }
    for (final choice in choices) {
      if (choice.canConfirm) return choice.key;
    }
    return choices.isEmpty ? null : choices.first.key;
  }

  static String? nextKey({
    required List<CityProductionGamepadChoice> choices,
    required String? selectedKey,
    required GamepadMapDirection direction,
  }) {
    if (choices.isEmpty) return null;
    final step = switch (direction) {
      GamepadMapDirection.up || GamepadMapDirection.left => -1,
      GamepadMapDirection.down || GamepadMapDirection.right => 1,
    };
    final effectiveKey = selectedKeyFor(choices, selectedKey);
    final selectedIndex = choices.indexWhere(
      (choice) => choice.key == effectiveKey,
    );
    final currentIndex = selectedIndex < 0 ? 0 : selectedIndex;
    final nextIndex = (currentIndex + step) % choices.length;
    return choices[nextIndex].key;
  }

  static CityProductionGamepadChoice? selectedChoice(
    List<CityProductionGamepadChoice> choices,
    String? selectedKey,
  ) {
    final effectiveKey = selectedKeyFor(choices, selectedKey);
    if (effectiveKey == null) return null;
    for (final choice in choices) {
      if (choice.key == effectiveKey) return choice;
    }
    return null;
  }
}
