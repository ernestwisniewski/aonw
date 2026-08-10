import 'dart:math' as math;

import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/hud_canvas_shapes.dart';
import 'package:flutter/material.dart';

class GameLoadingMapBackdropPainter extends CustomPainter {
  const GameLoadingMapBackdropPainter({required this.compact});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    _paintHexMap(canvas, size);
    _paintRoute(canvas, size);
    _paintHorizons(canvas, size);
  }

  void _paintHexMap(Canvas canvas, Size size) {
    final cell = compact ? 44.0 : 58.0;
    final hexHeight = cell * 0.86;
    final rows = (size.height / hexHeight).ceil() + 3;
    final cols = (size.width / cell).ceil() + 3;
    final paints = _mapPaints();
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final center = Offset(
          -cell * 0.65 + col * cell + (row.isOdd ? cell * 0.5 : 0),
          -hexHeight + row * hexHeight,
        );
        final value = (col * 11 + row * 7 + (col - row).abs() * 3) % 17;
        final path = HudCanvasShapes.hexOutlinePath(center, cell * 0.48);
        canvas
          ..drawPath(path, _fillFor(value, paints))
          ..drawPath(path, paints.stroke);
      }
    }
  }

  void _paintRoute(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = GameUiTheme.copper.withAlpha(72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1.1 : 1.35
      ..strokeCap = StrokeCap.round;
    final route = Path()
      ..moveTo(size.width * 0.08, size.height * 0.72)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.55,
        size.width * 0.38,
        size.height * 0.82,
        size.width * 0.55,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.39,
        size.width * 0.84,
        size.height * 0.47,
        size.width * 0.94,
        size.height * 0.25,
      );
    canvas.drawPath(route, routePaint);
  }

  void _paintHorizons(Canvas canvas, Size size) {
    final horizonPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          GameUiTheme.gold.withAlpha(0),
          GameUiTheme.gold.withAlpha(64),
          GameUiTheme.gold.withAlpha(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1));
    canvas
      ..drawRect(
        Rect.fromLTWH(0, size.height * 0.18, size.width, 1),
        horizonPaint,
      )
      ..drawRect(
        Rect.fromLTWH(0, size.height * 0.82, size.width, 1),
        horizonPaint,
      );
  }

  @override
  bool shouldRepaint(covariant GameLoadingMapBackdropPainter oldDelegate) {
    return oldDelegate.compact != compact;
  }
}

_MapPaints _mapPaints() {
  return (
    water: Paint()
      ..color = GameUiTheme.info.withAlpha(22)
      ..style = PaintingStyle.fill,
    land: Paint()
      ..color = GameUiTheme.successDim.withAlpha(34)
      ..style = PaintingStyle.fill,
    coast: Paint()
      ..color = GameUiTheme.gold.withAlpha(28)
      ..style = PaintingStyle.fill,
    stroke: Paint()
      ..color = GameUiTheme.goldDark.withAlpha(58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8,
  );
}

Paint _fillFor(int value, _MapPaints paints) {
  if (value < 5) return paints.water;
  if (value < 11) return paints.land;
  return paints.coast;
}

typedef _MapPaints = ({Paint water, Paint land, Paint coast, Paint stroke});

class GameLoadingPanelTexturePainter extends CustomPainter {
  const GameLoadingPanelTexturePainter({required this.compact});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = GameUiTheme.goldDark.withAlpha(compact ? 22 : 26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    final step = compact ? 22.0 : 26.0;
    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        linePaint,
      );
    }
    final topPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          GameUiTheme.gold.withAlpha(36),
          Colors.transparent,
          GameUiTheme.copperDeep.withAlpha(24),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, topPaint);
  }

  @override
  bool shouldRepaint(covariant GameLoadingPanelTexturePainter oldDelegate) {
    return oldDelegate.compact != compact;
  }
}

class GameLoadingCompassPainter extends CustomPainter {
  const GameLoadingCompassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    _paintCompassRings(canvas, center, radius);
    _paintCompassRose(canvas, center, radius);
    _paintCardinalDiamonds(canvas, center, radius);
  }

  void _paintCompassRings(Canvas canvas, Offset center, double radius) {
    final glowPaint = Paint()
      ..color = GameUiTheme.copper.withAlpha(72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08;
    final ringPaint = Paint()
      ..color = GameUiTheme.gold.withAlpha(185)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.025;
    final finePaint = Paint()
      ..color = GameUiTheme.goldLight.withAlpha(160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.014;
    final fillPaint = Paint()
      ..color = GameUiTheme.bg.withAlpha(142)
      ..style = PaintingStyle.fill;
    canvas
      ..drawCircle(center, radius * 0.43, fillPaint)
      ..drawCircle(center, radius * 0.44, glowPaint)
      ..drawCircle(center, radius * 0.44, ringPaint)
      ..drawCircle(center, radius * 0.32, finePaint);
  }

  void _paintCompassRose(Canvas canvas, Offset center, double radius) {
    final rosePaint = Paint()
      ..color = GameUiTheme.gold.withAlpha(135)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.018
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 8; index++) {
      final angle = -math.pi / 2 + index * math.pi / 4;
      final start = _radialPoint(center, angle, radius * 0.18);
      final length = radius * (index.isEven ? 0.64 : 0.52);
      canvas.drawLine(start, _radialPoint(center, angle, length), rosePaint);
    }
  }

  void _paintCardinalDiamonds(Canvas canvas, Offset center, double radius) {
    final diamondPaint = Paint()
      ..color = GameUiTheme.goldLight.withAlpha(175)
      ..style = PaintingStyle.fill;
    for (final angle in [0.0, math.pi / 2, math.pi, math.pi * 1.5]) {
      final point = _radialPoint(center, angle, radius * 0.72);
      canvas.drawPath(_diamond(point, radius * 0.035), diamondPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GameLoadingCompassPainter oldDelegate) => false;
}

Offset _radialPoint(Offset center, double angle, double radius) {
  return Offset(
    center.dx + math.cos(angle) * radius,
    center.dy + math.sin(angle) * radius,
  );
}

Path _diamond(Offset center, double radius) {
  return Path()
    ..moveTo(center.dx, center.dy - radius)
    ..lineTo(center.dx + radius, center.dy)
    ..lineTo(center.dx, center.dy + radius)
    ..lineTo(center.dx - radius, center.dy)
    ..close();
}
