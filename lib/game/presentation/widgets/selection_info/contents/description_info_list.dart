import 'dart:math';

import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class DescriptionInfoList extends StatelessWidget {
  const DescriptionInfoList({required this.items, super.key});

  final List<SelectionInfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (items.isEmpty) return const SizedBox.shrink();

        final maxWidth = constraints.maxWidth;
        if (maxWidth <= 0 || maxWidth.isInfinite) {
          return _buildStandardRows();
        }

        const spacing = 6.0;
        const minTileWidth = 150.0;
        final columns = max(
          1,
          min(4, (maxWidth + spacing) ~/ (minTileWidth + spacing)),
        );
        final tileWidth = (maxWidth - (columns - 1) * spacing) / columns;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in items)
                  SizedBox(
                    width: tileWidth,
                    child: _DescriptionInfoRow(item: item),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStandardRows() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(height: 6),
          _DescriptionInfoRow(item: items[index]),
        ],
      ],
    );
  }
}

class _DescriptionInfoRow extends StatelessWidget {
  const _DescriptionInfoRow({required this.item});

  final SelectionInfoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: ShapeDecoration(
        color: GameHudTheme.chipSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: GameHudTheme.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: GameIcon(item.icon, size: 16, color: item.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameHudTheme.selectionChip.copyWith(
                    color: GameUiTheme.goldLight,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GameHudTheme.selectionSubtitle.copyWith(
                    color: GameHudTheme.textSecondary,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
