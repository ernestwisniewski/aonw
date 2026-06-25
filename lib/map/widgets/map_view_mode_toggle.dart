import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class MapViewModeToggle extends StatelessWidget {
  final MapViewMode value;
  final ValueChanged<MapViewMode> onChanged;
  final bool allowGraphicMode;

  const MapViewModeToggle({
    required this.value,
    required this.onChanged,
    required this.allowGraphicMode,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Tooltip(
      message: allowGraphicMode
          ? l10n.mapViewModeTooltip
          : l10n.mapViewGraphicUnavailableTooltip,
      child: SegmentedButton<MapViewMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: MapViewMode.graphic,
            enabled: allowGraphicMode,
            label: Text(GameText.actionLabel(l10n.mapViewModeGraphic)),
          ),
          ButtonSegment(
            value: MapViewMode.tile,
            label: Text(GameText.actionLabel(l10n.mapViewModeTiles)),
          ),
        ],
        selected: {value},
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          minimumSize: WidgetStateProperty.all(const Size(0, 30)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 10),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return GameUiTheme.textTertiary;
            }
            if (states.contains(WidgetState.selected)) {
              return GameUiTheme.bg;
            }
            return GameUiTheme.textSecondary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GameUiTheme.textPrimary;
            }
            return Colors.transparent;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.disabled)
                ? GameUiTheme.textTertiary
                : GameUiTheme.textSecondary;
            return BorderSide(color: color);
          }),
          textStyle: WidgetStateProperty.all(GameUiTheme.labelSmall),
        ),
        onSelectionChanged: (selection) {
          final selected = selection.first;
          if (selected == value) return;
          onChanged(selected);
        },
      ),
    );
  }
}
