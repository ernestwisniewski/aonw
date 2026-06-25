import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter/material.dart';

class SelectionYieldItem {
  final GameIconData icon;
  final String label;
  final int value;
  final Color color;

  const SelectionYieldItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  static List<SelectionYieldItem> fromYield(
    TileYield yield, {
    String foodLabel = '',
    String productionLabel = '',
    String goldLabel = '',
    String defenseLabel = '',
  }) {
    return [
      SelectionYieldItem(
        icon: GameIcons.food,
        label: foodLabel,
        value: yield.food,
        color: const Color(0xFF87c96a),
      ),
      SelectionYieldItem(
        icon: GameIcons.production,
        label: productionLabel,
        value: yield.production,
        color: const Color(0xFFc9a95f),
      ),
      SelectionYieldItem(
        icon: GameIcons.gold,
        label: goldLabel,
        value: yield.gold,
        color: const Color(0xFFe0c35c),
      ),
      SelectionYieldItem(
        icon: GameIcons.defense,
        label: defenseLabel,
        value: yield.defense,
        color: const Color(0xFF8da8e8),
      ),
    ];
  }
}
