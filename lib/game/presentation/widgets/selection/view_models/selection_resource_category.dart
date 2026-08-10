import 'package:aonw/game/domain/hex_assessment.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter/material.dart';

enum SelectionResourceCategory { bonus, luxury, strategic }

abstract final class SelectionResourceCategoryResolver {
  static SelectionResourceCategory forResource(ResourceType resource) {
    if (HexResourceGroups.strategic.contains(resource)) {
      return SelectionResourceCategory.strategic;
    }
    if (_luxuryResources.contains(resource)) {
      return SelectionResourceCategory.luxury;
    }
    return SelectionResourceCategory.bonus;
  }

  static const _luxuryResources = {
    ResourceType.gold,
    ResourceType.silver,
    ResourceType.gems,
    ResourceType.silk,
    ResourceType.spices,
    ResourceType.cotton,
    ResourceType.grapes,
    ResourceType.ivory,
    ResourceType.pearls,
    ResourceType.coffee,
    ResourceType.cocoa,
    ResourceType.tobacco,
    ResourceType.sugar,
  };
}

extension SelectionResourceCategoryStyle on SelectionResourceCategory {
  Color get color => switch (this) {
    SelectionResourceCategory.bonus => const Color(0xFF87c96a),
    SelectionResourceCategory.luxury => const Color(0xFFe0c35c),
    SelectionResourceCategory.strategic => const Color(0xFF8da8e8),
  };
}
