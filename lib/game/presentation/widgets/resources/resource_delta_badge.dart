import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

const List<Shadow> topResourceNumberShadows = [
  Shadow(color: Color(0x80000000), blurRadius: 1, offset: Offset(0, 1)),
];

class ResourceDelta {
  const ResourceDelta(this.value);

  final int value;

  bool get isPositive => value > 0;

  bool get isNegative => value < 0;

  String get label {
    if (isPositive) return '▲ +$value';
    if (isNegative) return '▼ $value';
    return '0';
  }

  Color get color {
    if (isPositive) return GameUiTheme.success;
    if (isNegative) return GameUiTheme.danger;
    return GameUiTheme.textSecondary;
  }
}

class ResourceDeltaBadge extends StatelessWidget {
  const ResourceDeltaBadge(this.delta, {required this.active, super.key});

  final ResourceDelta delta;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Text(
      delta.label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: GameHudTheme.buttonTopLabel.copyWith(
        color: active ? GameUiTheme.bg : delta.color,
        fontSize: 10.5,
        fontFeatures: GameUiTheme.tabularFigures,
        shadows: topResourceNumberShadows,
      ),
    );
  }
}
