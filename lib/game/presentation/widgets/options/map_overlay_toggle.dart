import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

enum MapOverlayOption { hexes, height }

class MapOverlayToggle extends StatelessWidget {
  const MapOverlayToggle({
    required this.hexesVisible,
    required this.heightVisible,
    required this.onToggleHexes,
    required this.onToggleHeight,
    super.key,
  });

  final bool hexesVisible;
  final bool heightVisible;
  final VoidCallback onToggleHexes;
  final VoidCallback onToggleHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = <MapOverlayOption>{
      if (hexesVisible) MapOverlayOption.hexes,
      if (heightVisible) MapOverlayOption.height,
    };

    return Tooltip(
      message: '${l10n.gameOptionShowHexes} / ${l10n.gameOptionShowHeight}',
      child: SegmentedButton<MapOverlayOption>(
        key: const Key('gameOptions.mapOverlayToggle'),
        multiSelectionEnabled: true,
        emptySelectionAllowed: true,
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: MapOverlayOption.hexes,
            label: Text(GameText.actionLabel(l10n.gameOptionShowHexes)),
          ),
          ButtonSegment(
            value: MapOverlayOption.height,
            label: Text(GameText.actionLabel(l10n.gameOptionShowHeight)),
          ),
        ],
        selected: selected,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          minimumSize: WidgetStateProperty.all(const Size(0, 30)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 10),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return GameUiTheme.bg;
            return GameUiTheme.textSecondary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GameUiTheme.textPrimary;
            }
            return Colors.transparent;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.selected)
                ? GameUiTheme.textPrimary
                : GameUiTheme.textSecondary;
            return BorderSide(color: color);
          }),
          textStyle: WidgetStateProperty.all(GameUiTheme.labelSmall),
        ),
        onSelectionChanged: (next) {
          if (next.contains(MapOverlayOption.hexes) != hexesVisible) {
            onToggleHexes();
          }
          if (next.contains(MapOverlayOption.height) != heightVisible) {
            onToggleHeight();
          }
        },
      ),
    );
  }
}
