import 'package:aonw/game/presentation/widgets/selection/density.dart';
import 'package:aonw/game/presentation/widgets/selection/selection_label_chip.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:flutter/material.dart';

class SelectionDetailsChips extends StatelessWidget {
  const SelectionDetailsChips({
    required this.items,
    required this.density,
    super.key,
  });

  final List<SelectionInfoItem> items;
  final SelectionDensity density;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final item in items)
          SelectionLabelChip(item: item, density: density),
      ],
    );
  }
}
