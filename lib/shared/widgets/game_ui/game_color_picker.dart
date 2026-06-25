import 'dart:async';

import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:flutter/material.dart';

class GameColorPickerButton extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onPicked;
  final VoidCallback? onDefault;

  const GameColorPickerButton({
    required this.label,
    required this.color,
    required this.onPicked,
    this.onDefault,
    super.key,
  });

  void _show(BuildContext context) {
    unawaited(
      showGameModal<void>(
        context: context,
        builder: (_) => _ColorPickerDialog(
          label: label,
          initial: color,
          onPicked: onPicked,
          onDefault: onDefault,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.colorPickerChangeTooltip(label),
      child: GestureDetector(
        onTap: () => _show(context),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: GameUiTheme.chipSurface,
            borderRadius: GameUiTheme.chipBorderRadius,
            border: Border.all(color: GameUiTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ColorSwatch(color: color, size: 14),
              const SizedBox(width: 5),
              Text(label, style: GameUiTheme.chipLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final double size;

  const _ColorSwatch({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    final isTransparent = (color.a * 255.0).round() == 0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isTransparent ? null : color,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: Colors.white38),
      ),
      child: isTransparent
          ? Icon(Icons.block, size: size * 0.7, color: Colors.white38)
          : null,
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final String label;
  final Color initial;
  final ValueChanged<Color> onPicked;
  final VoidCallback? onDefault;

  const _ColorPickerDialog({
    required this.label,
    required this.initial,
    required this.onPicked,
    this.onDefault,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  static const List<Color> _palette = [
    Colors.black,
    Colors.white,
    Color(0xFF7a9fc4),
    Color(0xFFf5c842),
    Color(0xFFe05050),
    Color(0xFF50e080),
    Color(0xFFc850e0),
    Color(0xFF50c8e0),
    Color(0xFFe08050),
    Color(0xFF8d6e63),
    Color(0xFF546e7a),
    Color(0xFF1a237e),
  ];

  late Color _baseColor;
  late double _opacity;

  @override
  void initState() {
    super.initState();
    final color = widget.initial;
    _opacity = (color.a * 255.0).round().clamp(0, 255) / 255.0;
    _baseColor = color.withAlpha(255);
  }

  Color get _current => _baseColor.withAlpha((_opacity * 255).round());

  void _selectBase(Color color) {
    setState(() => _baseColor = color.withAlpha(255));
    widget.onPicked(_current);
  }

  void _setOpacity(double value) {
    setState(() => _opacity = value);
    widget.onPicked(_current);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GameModalScaffold(
      size: GameModalSize.compact,
      header: GameModalHeader(
        title: widget.label.toUpperCase(),
        onClose: () => Navigator.of(context).pop(),
      ),
      content: SizedBox(
        width: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _ColorSwatch(color: _current, size: 20),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _palette.map((color) {
                final selected = color.withAlpha(255) == _baseColor;
                final hex = color.toARGB32().toRadixString(16).toUpperCase();
                return Tooltip(
                  message: selected
                      ? l10n.colorPickerColorSelected(hex)
                      : l10n.colorPickerSelectColor(hex),
                  child: GestureDetector(
                    onTap: () => _selectBase(color),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: selected ? GameUiTheme.accent : Colors.white24,
                          width: selected ? 2 : 1,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('OPACITY', style: GameUiTheme.toolbarLabel),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: GameUiTheme.accent,
                      inactiveTrackColor: GameUiTheme.chipSurfaceDim,
                      thumbColor: GameUiTheme.accent,
                      overlayColor: GameUiTheme.accent.withAlpha(40),
                    ),
                    child: Slider(value: _opacity, onChanged: _setOpacity),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${(_opacity * 100).round()}%',
                    style: const TextStyle(
                      color: GameUiTheme.textSecondary,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.onDefault case final onDefault?) ...[
                  EpicButton.outlined(
                    label: l10n.commonDefault,
                    onPressed: () {
                      onDefault();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
                EpicButton.primary(
                  label: l10n.commonDone,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
