part of 'game_icon.dart';

class GameIcon extends StatelessWidget {
  final GameIconData icon;
  final double size;
  final Color color;

  const GameIcon(
    this.icon, {
    required this.size,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GameIconPainter(icon: icon, color: color),
      ),
    );
  }
}

abstract final class GameIconRenderer {
  static void paintIcon(
    Canvas canvas,
    GameIconData icon, {
    required Offset topLeft,
    required double size,
    required Color color,
  }) {
    final scale = size / 24.0;
    final paint = icon.filled
        ? (Paint()
            ..color = color
            ..style = PaintingStyle.fill)
        : (Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = icon.strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);

    canvas
      ..save()
      ..translate(topLeft.dx, topLeft.dy)
      ..scale(scale, scale);
    for (final pathData in icon.paths) {
      canvas.drawPath(GameIconPathParser.parse(pathData), paint);
    }
    canvas.restore();
  }
}

class _GameIconPainter extends CustomPainter {
  final GameIconData icon;
  final Color color;

  const _GameIconPainter({required this.icon, required this.color});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    GameIconRenderer.paintIcon(
      canvas,
      icon,
      topLeft: Offset.zero,
      size: canvasSize.shortestSide,
      color: color,
    );
  }

  @override
  bool shouldRepaint(_GameIconPainter old) =>
      old.icon != icon || old.color != color;
}
