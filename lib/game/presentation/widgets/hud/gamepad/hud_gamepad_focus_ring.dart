import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_focus_ring.dart';
import 'package:flutter/material.dart';

class HudGamepadFocusRing extends StatelessWidget {
  const HudGamepadFocusRing({
    required this.focused,
    required this.child,
    this.borderRadius,
    super.key,
  });

  final bool focused;
  final Widget child;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return GameUiFocusRing(
      focused: focused,
      borderRadius: borderRadius ?? GameUiTheme.chipBorderRadius,
      child: child,
    );
  }
}
