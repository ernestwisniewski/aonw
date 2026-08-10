import 'dart:math' as math;

import 'package:aonw/menu/menu_animated_background.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/hud_canvas_shapes.dart';
import 'package:flutter/material.dart';

class MenuRouteBackdrop extends StatelessWidget {
  const MenuRouteBackdrop({
    required this.child,
    this.maxContentWidth = 1120,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  final Widget child;
  final double maxContentWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return MenuAnimatedBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _MenuRouteBackdropTint()),
          const Positioned.fill(
            child: CustomPaint(painter: _MenuRouteCartographyPainter()),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(constraints.maxWidth, maxContentWidth);
              return Align(
                alignment: alignment,
                child: SizedBox(
                  width: width,
                  height: constraints.maxHeight,
                  child: child,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MenuRouteBackdropTint extends StatelessWidget {
  const _MenuRouteBackdropTint();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GameUiTheme.bg.withAlpha(238),
            GameUiTheme.surfaceDeep.withAlpha(216),
            GameUiTheme.bg.withAlpha(178),
            GameUiTheme.bg.withAlpha(230),
          ],
          stops: const [0, 0.34, 0.67, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.72, -0.62),
            radius: 1.05,
            colors: [
              GameUiTheme.gold.withAlpha(52),
              Colors.transparent,
              GameUiTheme.bg.withAlpha(180),
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
      ),
    );
  }
}

class _MenuRouteCartographyPainter extends CustomPainter {
  const _MenuRouteCartographyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = GameUiTheme.goldDark.withAlpha(34);
    final coast = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = GameUiTheme.copper.withAlpha(56);
    final cell = size.shortestSide < 520 ? 46.0 : 58.0;
    final rowHeight = cell * 0.86;

    for (var y = -rowHeight; y < size.height + rowHeight; y += rowHeight) {
      final row = (y / rowHeight).round();
      for (var x = -cell; x < size.width + cell; x += cell) {
        final cx = x + (row.isOdd ? cell * 0.5 : 0);
        final cy = y;
        if ((row + (x / cell).round()) % 3 == 0) {
          canvas.drawPath(
            HudCanvasShapes.hexOutlinePath(Offset(cx, cy), cell * 0.47),
            stroke,
          );
        }
      }
    }

    final route = Path()
      ..moveTo(size.width * 0.08, size.height * 0.78)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.54,
        size.width * 0.42,
        size.height * 0.92,
        size.width * 0.58,
        size.height * 0.52,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.18,
        size.width * 0.86,
        size.height * 0.36,
        size.width * 0.96,
        size.height * 0.12,
      );
    canvas.drawPath(route, coast);

    final horizon = Paint()
      ..shader = LinearGradient(
        colors: [
          GameUiTheme.gold.withAlpha(0),
          GameUiTheme.gold.withAlpha(72),
          GameUiTheme.gold.withAlpha(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1));
    canvas
      ..drawRect(Rect.fromLTWH(0, size.height * 0.18, size.width, 1), horizon)
      ..drawRect(Rect.fromLTWH(0, size.height * 0.82, size.width, 1), horizon);
  }

  @override
  bool shouldRepaint(covariant _MenuRouteCartographyPainter oldDelegate) =>
      false;
}
