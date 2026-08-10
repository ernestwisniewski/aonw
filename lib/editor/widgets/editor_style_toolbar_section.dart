import 'package:aonw/editor/widgets/editor_action_button.dart';
import 'package:aonw/editor/widgets/editor_color_picker.dart';
import 'package:aonw/editor/widgets/editor_toolbar_row.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class EditorStyleToolbarSection extends StatelessWidget {
  final HexDisplaySettings displaySettings;
  final double defaultZoom;
  final ValueChanged<Color> onHexBorderColorChanged;
  final ValueChanged<Color> onSelectedHexColorChanged;
  final ValueChanged<Color> onWallTintColorChanged;
  final ValueChanged<double> onDefaultZoomChanged;

  const EditorStyleToolbarSection({
    required this.displaySettings,
    required this.defaultZoom,
    required this.onHexBorderColorChanged,
    required this.onSelectedHexColorChanged,
    required this.onWallTintColorChanged,
    required this.onDefaultZoomChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return EditorToolbarRow(
      label: 'STYLE',
      icon: Icons.palette,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EditorColorPickerButton(
              label: 'Border',
              color: displaySettings.hexBorderColor,
              onPicked: onHexBorderColorChanged,
            ),
            const SizedBox(width: 6),
            EditorColorPickerButton(
              label: 'Select',
              color: displaySettings.selectedHexColor,
              onPicked: onSelectedHexColorChanged,
            ),
            const SizedBox(width: 6),
            EditorColorPickerButton(
              label: 'Wall',
              color: displaySettings.wallTintColor,
              onPicked: onWallTintColorChanged,
            ),
            const SizedBox(width: 12),
            _DefaultZoomControl(
              zoom: defaultZoom,
              onChanged: onDefaultZoomChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultZoomControl extends StatelessWidget {
  final double zoom;
  final ValueChanged<double> onChanged;

  const _DefaultZoomControl({required this.zoom, required this.onChanged});

  static const double _step = 0.25;
  static const double _min = 0.25;
  static const double _max = 4.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('ZOOM', style: GameUiTheme.chipLabel),
        const SizedBox(width: 4),
        EditorActionButton(
          '−',
          zoom > _min
              ? () => onChanged((zoom - _step).clamp(_min, _max))
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            '${zoom.toStringAsFixed(zoom.truncateToDouble() == zoom ? 0 : 2)}×',
            style: const TextStyle(
              color: GameUiTheme.textPrimary,
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        EditorActionButton(
          '+',
          zoom < _max
              ? () => onChanged((zoom + _step).clamp(_min, _max))
              : null,
        ),
      ],
    );
  }
}
