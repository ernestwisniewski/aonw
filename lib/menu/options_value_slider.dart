import 'package:aonw/menu/menu_gamepad_input.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class OptionsValueSlider extends StatelessWidget {
  const OptionsValueSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions = 20,
    this.step = 0.05,
    this.valueLabelBuilder,
    super.key,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final double step;
  final String Function(double value)? valueLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(min, max).toDouble();
    final valueLabel =
        valueLabelBuilder?.call(clampedValue) ??
        '${(clampedValue * 100).round()}%';
    return Padding(
      padding: const EdgeInsets.fromLTRB(46, 0, 2, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _labelRow(valueLabel),
          _slider(context, clampedValue, valueLabel),
        ],
      ),
    );
  }

  Widget _labelRow(String valueLabel) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.toolbarLabel.copyWith(
              color: GameUiTheme.textSecondary,
            ),
          ),
        ),
        Text(
          valueLabel,
          style: GameUiTheme.toolbarLabel.copyWith(color: GameUiTheme.gold),
        ),
      ],
    );
  }

  Widget _slider(BuildContext context, double clampedValue, String valueLabel) {
    return Actions(
      actions: {
        MenuGamepadAdjustIntent: CallbackAction<MenuGamepadAdjustIntent>(
          onInvoke: (intent) {
            onChanged(_adjustedValue(clampedValue, intent.delta));
            return Object();
          },
        ),
      },
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: GameUiTheme.gold,
          inactiveTrackColor: GameUiTheme.gold.withAlpha(48),
          thumbColor: GameUiTheme.goldLight,
          overlayColor: GameUiTheme.gold.withAlpha(38),
          valueIndicatorColor: GameUiTheme.surface,
          valueIndicatorTextStyle: GameUiTheme.toolbarLabel.copyWith(
            color: GameUiTheme.goldLight,
          ),
        ),
        child: Slider(
          value: clampedValue,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ),
    );
  }

  double _adjustedValue(double clampedValue, int delta) {
    return (clampedValue + delta * step).clamp(min, max).toDouble();
  }
}
