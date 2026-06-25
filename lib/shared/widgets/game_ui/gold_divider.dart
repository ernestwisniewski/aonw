import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class GoldDivider extends StatelessWidget {
  const GoldDivider({
    super.key,
    this.width,
    this.height,
    this.axis = Axis.horizontal,
    this.alpha = 170,
  });

  final double? width;
  final double? height;
  final Axis axis;
  final int alpha;

  @override
  Widget build(BuildContext context) {
    final goldFade = SurfaceElevation.flat.fill(
      background: GameUiTheme.gold,
      alpha: alpha,
    );
    final diamond = Transform.rotate(
      angle: 0.785398,
      child: Container(
        key: const ValueKey('gold-divider-diamond'),
        width: 5,
        height: 5,
        color: GameUiTheme.gold,
      ),
    );

    if (axis == Axis.vertical) {
      return SizedBox(
        key: const ValueKey('gold-divider-root'),
        width: 9,
        height: height,
        child: Column(
          children: [
            Expanded(
              child: _Line(axis: axis, colors: [Colors.transparent, goldFade]),
            ),
            diamond,
            Expanded(
              child: _Line(axis: axis, colors: [goldFade, Colors.transparent]),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      key: const ValueKey('gold-divider-root'),
      width: width,
      height: 9,
      child: Row(
        children: [
          Expanded(
            child: _Line(axis: axis, colors: [Colors.transparent, goldFade]),
          ),
          diamond,
          Expanded(
            child: _Line(axis: axis, colors: [goldFade, Colors.transparent]),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.axis, required this.colors});

  final Axis axis;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: axis == Axis.vertical
              ? Alignment.topCenter
              : Alignment.centerLeft,
          end: axis == Axis.vertical
              ? Alignment.bottomCenter
              : Alignment.centerRight,
          colors: colors,
        ),
        shape: const RoundedRectangleBorder(),
      ),
      child: SizedBox(
        width: axis == Axis.vertical ? 1 : null,
        height: axis == Axis.horizontal ? 1 : null,
      ),
    );
  }
}
