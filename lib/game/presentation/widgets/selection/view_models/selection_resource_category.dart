import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter/material.dart';

enum SelectionResourceCategory { bonus, luxury, strategic }

abstract final class SelectionResourceCategoryResolver {
  static SelectionResourceCategory forResource(ResourceType resource) {
    return switch (ResourceCatalog.definitionFor(resource).category) {
      ResourceCategory.bonus => SelectionResourceCategory.bonus,
      ResourceCategory.luxury => SelectionResourceCategory.luxury,
      ResourceCategory.strategic => SelectionResourceCategory.strategic,
    };
  }
}

extension SelectionResourceCategoryStyle on SelectionResourceCategory {
  Color get color => switch (this) {
    SelectionResourceCategory.bonus => const Color(0xFF87c96a),
    SelectionResourceCategory.luxury => const Color(0xFFe0c35c),
    SelectionResourceCategory.strategic => const Color(0xFF8da8e8),
  };
}
