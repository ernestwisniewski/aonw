part of 'dice_roll_test_overlay.dart';

class _PositionedDie extends StatelessWidget {
  final ui.Image spriteSheet;
  final _DiePose die;
  final double size;
  final int frameIndex;

  const _PositionedDie({
    required this.spriteSheet,
    required this.die,
    required this.size,
    required this.frameIndex,
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
              painter: _DiceSpritePainter(
                spriteSheet: spriteSheet,
                frameIndex: frameIndex,
                opacity: die.opacity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiceSpritePainter extends CustomPainter {
  static const _columns = 6;

  final ui.Image spriteSheet;
  final int frameIndex;
  final double opacity;

  const _DiceSpritePainter({
    required this.spriteSheet,
    required this.frameIndex,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = spriteSheet.width / _columns;
    final frameHeight = frameWidth;
    final column = frameIndex % _columns;
    final row = frameIndex ~/ _columns;
    final source = Rect.fromLTWH(
      column * frameWidth,
      row * frameHeight,
      frameWidth,
      frameHeight,
    );

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
    canvas.drawImageRect(spriteSheet, source, Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_DiceSpritePainter oldDelegate) {
    return oldDelegate.spriteSheet != spriteSheet ||
        oldDelegate.frameIndex != frameIndex ||
        oldDelegate.opacity != opacity;
  }
}
