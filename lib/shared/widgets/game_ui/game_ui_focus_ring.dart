import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class GameUiFocusRing extends StatelessWidget {
  const GameUiFocusRing({
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
    if (!focused) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: SurfaceElevation.flat.fill(
                  background: Colors.transparent,
                  alpha: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: borderRadius ?? GameUiTheme.borderRadius,
                  side: BorderSide(
                    color: SurfaceElevation.flat.strokeColor(
                      color: GameUiTheme.info,
                      alpha: 255,
                    ),
                    width: 2.2,
                  ),
                ),
                shadows: SurfaceElevation.flat.shadows(
                  color: GameUiTheme.info,
                  alpha: 110,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
