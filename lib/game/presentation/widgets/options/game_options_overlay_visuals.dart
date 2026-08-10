part of 'game_options_overlay.dart';

class _MapOptionsGlyph extends StatelessWidget {
  const _MapOptionsGlyph({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: const Key('gameOptions.optionsModeGlyph'),
      dimension: 25,
      child: CustomPaint(
        painter: _AntiqueGearsPainter(color: color, active: active),
      ),
    );
  }
}

class _AntiqueGearsPainter extends CustomPainter {
  const _AntiqueGearsPainter({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = (active ? GameUiTheme.goldLight : GameUiTheme.copper).withAlpha(
        active ? 82 : 42,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final bodyPaint = Paint()
      ..color = GameUiTheme.bg.withAlpha(active ? 132 : 168)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color.withAlpha(active ? 255 : 230)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final accentPaint = Paint()
      ..color = (active ? GameUiTheme.goldLight : GameUiTheme.copper).withAlpha(
        active ? 245 : 210,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round;

    _drawGear(
      canvas,
      center: Offset(size.width * 0.43, size.height * 0.42),
      toothRadius: size.width * 0.35,
      rootRadius: size.width * 0.28,
      hubRadius: size.width * 0.095,
      teeth: 10,
      rotation: -math.pi / 14,
      fill: bodyPaint,
      stroke: strokePaint,
      glow: glowPaint,
      spoke: accentPaint,
    );
    _drawGear(
      canvas,
      center: Offset(size.width * 0.68, size.height * 0.67),
      toothRadius: size.width * 0.23,
      rootRadius: size.width * 0.18,
      hubRadius: size.width * 0.065,
      teeth: 8,
      rotation: math.pi / 9,
      fill: bodyPaint,
      stroke: accentPaint,
      glow: null,
      spoke: strokePaint,
    );
  }

  void _drawGear(
    Canvas canvas, {
    required Offset center,
    required double toothRadius,
    required double rootRadius,
    required double hubRadius,
    required int teeth,
    required double rotation,
    required Paint fill,
    required Paint stroke,
    required Paint? glow,
    required Paint spoke,
  }) {
    final gear = _gearPath(
      center: center,
      toothRadius: toothRadius,
      rootRadius: rootRadius,
      teeth: teeth,
      rotation: rotation,
    );
    if (glow != null) canvas.drawPath(gear, glow);
    canvas
      ..drawPath(gear, fill)
      ..drawPath(gear, stroke);

    final spokeCount = teeth <= 8 ? 4 : 5;
    for (var i = 0; i < spokeCount; i++) {
      final angle = rotation + (math.pi * 2 * i / spokeCount);
      final end = Offset(
        center.dx + math.cos(angle) * (rootRadius - hubRadius * 0.55),
        center.dy + math.sin(angle) * (rootRadius - hubRadius * 0.55),
      );
      canvas.drawLine(center, end, spoke);
    }
    canvas
      ..drawCircle(center, hubRadius * 1.55, fill)
      ..drawCircle(center, hubRadius * 1.55, stroke)
      ..drawCircle(center, hubRadius * 0.48, spoke);
  }

  Path _gearPath({
    required Offset center,
    required double toothRadius,
    required double rootRadius,
    required int teeth,
    required double rotation,
  }) {
    final path = Path();
    final points = teeth * 2;
    for (var i = 0; i < points; i++) {
      final angle = rotation + (math.pi * 2 * i / points);
      final radius = i.isEven ? toothRadius : rootRadius;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _AntiqueGearsPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.active != active;
  }
}

class _GameOptionsSideMenuRail extends StatelessWidget {
  const _GameOptionsSideMenuRail({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(height: 4),
          children[index],
        ],
      ],
    );
  }
}

class _GameOptionsSideMenuSeparator extends StatelessWidget {
  const _GameOptionsSideMenuSeparator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: GameUiSideMenuButton.extent,
      height: 10,
      child: Center(
        child: Container(
          width: 22,
          height: 1,
          color: GameUiTheme.gold.withAlpha(92),
        ),
      ),
    );
  }
}
