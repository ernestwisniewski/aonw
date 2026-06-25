part of 'end_turn_button.dart';

class EndTurnPulsingBorderPainter extends CustomPainter {
  final double progress;
  final BorderRadius borderRadius;
  final Color color;
  final double emphasis;

  const EndTurnPulsingBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.color,
    this.emphasis = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = Curves.easeInOut.transform(progress);
    final clampedEmphasis = emphasis.clamp(1.0, 1.6);
    final rect = borderRadius.toRRect(
      (Offset.zero & size).deflate(1.2 + pulse * 0.2),
    );

    final glowPaint = Paint()
      ..color = color.withAlpha(
        ((42 + pulse * 74) * clampedEmphasis).round().clamp(0, 255),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 + pulse * 2.6 + (clampedEmphasis - 1) * 1.8
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        3 + (clampedEmphasis - 1) * 2.2,
      );

    final paint = Paint()
      ..color = Color.lerp(color, Colors.white, 0.16)!.withAlpha(
        ((188 + pulse * 56) * (1 + (clampedEmphasis - 1) * 0.22)).round().clamp(
          0,
          255,
        ),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7 + pulse * 1.0 + (clampedEmphasis - 1) * 0.8
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawRRect(rect, glowPaint)
      ..drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(EndTurnPulsingBorderPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.borderRadius != borderRadius ||
      old.emphasis != emphasis;
}

class _StaticBorderPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Color color;

  const _StaticBorderPainter({required this.borderRadius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = borderRadius.toRRect((Offset.zero & size).deflate(1.2));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(_StaticBorderPainter old) =>
      old.color != color || old.borderRadius != borderRadius;
}
