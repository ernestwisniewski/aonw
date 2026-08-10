import 'package:aonw/editor/widgets/editor_action_button.dart';
import 'package:aonw/editor/widgets/editor_toolbar_row.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class EditorHeightToolbarSection extends StatelessWidget {
  final int selectedHeight;
  final bool showHeightBadge;
  final VoidCallback onToggleHeightBadge;
  final ValueChanged<int> onHeightChanged;

  const EditorHeightToolbarSection({
    required this.selectedHeight,
    required this.showHeightBadge,
    required this.onToggleHeightBadge,
    required this.onHeightChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return EditorToolbarRow(
      label: 'HEIGHT',
      icon: Icons.terrain,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _HeightBadgeToggle(
              active: showHeightBadge,
              onTap: onToggleHeightBadge,
            ),
            const SizedBox(width: 6),
            EditorActionButton(
              '-',
              selectedHeight > 0
                  ? () => onHeightChanged(selectedHeight - 1)
                  : null,
            ),
            Container(
              width: 32,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GameUiTheme.chipSurface,
                borderRadius: GameUiTheme.chipBorderRadius,
              ),
              child: Text(
                '$selectedHeight',
                style: const TextStyle(
                  color: GameUiTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            EditorActionButton(
              '+',
              selectedHeight < 5
                  ? () => onHeightChanged(selectedHeight + 1)
                  : null,
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(6, (height) {
                  final active = height == selectedHeight;
                  return Container(
                    width: 10,
                    height: 10 + height * 3.0,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: active
                          ? GameUiTheme.accent
                          : GameUiTheme.chipSurfaceDim,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeightBadgeToggle extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _HeightBadgeToggle({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Show height on map',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active
                ? GameUiTheme.accent.withAlpha(60)
                : GameUiTheme.chipSurface,
            borderRadius: GameUiTheme.chipBorderRadius,
            border: Border.all(
              color: active ? GameUiTheme.accent : GameUiTheme.border,
            ),
          ),
          child: Icon(
            Icons.format_list_numbered,
            size: 14,
            color: active ? GameUiTheme.accent : GameUiTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
