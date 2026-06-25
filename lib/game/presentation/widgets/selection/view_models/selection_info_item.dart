import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:flutter/material.dart';

abstract final class SelectionInfoItemSemanticId {
  static const terrain = 'terrain';
  static const resources = 'resources';
  static const height = 'height';
}

class SelectionInfoItem {
  final GameIconData icon;
  final String label;
  final String value;
  final Color color;
  final bool showLabel;
  final String? semanticId;

  const SelectionInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.showLabel = true,
    this.semanticId,
  });
}
