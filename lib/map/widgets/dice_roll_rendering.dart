part of 'dice_roll_test_overlay.dart';

class _PositionedDie extends StatelessWidget {
  final _DiceFrame frame;
  final _DiePose die;
  final double size;

  const _PositionedDie({
    required this.frame,
    required this.die,
    required this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: die.center.dx - size / 2,
      top: die.center.dy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: die.angle,
          child: Transform.scale(
            scale: die.scale,
            child: CustomPaint(
              painter: _DiceSpritePainter(frame: frame, opacity: die.opacity),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiceSpritePainter extends CustomPainter {
  final _DiceFrame frame;
  final double opacity;

  const _DiceSpritePainter({required this.frame, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha((88 * opacity).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.76),
        width: size.width * 0.62,
        height: size.height * 0.18,
      ),
      shadowPaint,
    );

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true
      ..color = Colors.white.withAlpha((255 * opacity).round());
    canvas.drawImageRect(frame.image, frame.source, Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_DiceSpritePainter oldDelegate) {
    return oldDelegate.frame != frame || oldDelegate.opacity != opacity;
  }
}
