part of 'lobby_screen.dart';

class _QueueCountdownClock extends StatelessWidget {
  final String label;
  final int? secondsRemaining;

  const _QueueCountdownClock({
    required this.label,
    required this.secondsRemaining,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final seconds = secondsRemaining;
    final compact = MediaQuery.sizeOf(context).width < 390;
    final clockSize = compact ? 58.0 : 68.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GameUiTheme.surfaceDeep.withAlpha(238),
            GameUiTheme.cardAccent.withAlpha(200),
          ],
        ),
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.gold.withAlpha(190)),
        boxShadow: [
          BoxShadow(
            color: GameUiTheme.goldDark.withAlpha(72),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 10 : 12,
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: clockSize,
              child: CustomPaint(
                painter: _QueueCountdownClockPainter(secondsRemaining: seconds),
              ),
            ),
            SizedBox(width: compact ? 12 : 16),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.bodyStrong.copyWith(
                    color: GameUiTheme.goldLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueCountdownClockPainter extends CustomPainter {
  final int? secondsRemaining;

  const _QueueCountdownClockPainter({required this.secondsRemaining});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 1;
    final facePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          GameUiTheme.cardAccent.withAlpha(230),
          GameUiTheme.bg.withAlpha(238),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = GameUiTheme.goldLight.withAlpha(215);
    final innerRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = GameUiTheme.copper.withAlpha(180);

    canvas
      ..drawCircle(center, radius, facePaint)
      ..drawCircle(center, radius, rimPaint)
      ..drawCircle(center, radius * 0.82, innerRimPaint);

    final tickPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..color = GameUiTheme.gold.withAlpha(210);
    for (var index = 0; index < 12; index++) {
      final isQuarter = index % 3 == 0;
      final angle = -math.pi / 2 + index * math.pi / 6;
      final outer = Offset(
        center.dx + math.cos(angle) * radius * 0.72,
        center.dy + math.sin(angle) * radius * 0.72,
      );
      final inner = Offset(
        center.dx + math.cos(angle) * radius * (isQuarter ? 0.52 : 0.60),
        center.dy + math.sin(angle) * radius * (isQuarter ? 0.52 : 0.60),
      );
      tickPaint.strokeWidth = isQuarter ? 2 : 1;
      canvas.drawLine(inner, outer, tickPaint);
    }

    final seconds = secondsRemaining;
    final secondProgress = seconds == null
        ? 0.0
        : seconds == 0
        ? 0.0
        : (Duration.secondsPerMinute - (seconds % Duration.secondsPerMinute)) /
              Duration.secondsPerMinute;
    final secondAngle = -math.pi / 2 + secondProgress * math.pi * 2;
    const hourAngle = -math.pi / 2 + math.pi * 1.65;

    final hourPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = GameUiTheme.goldLight;
    final secondPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2
      ..color = GameUiTheme.copper;
    canvas
      ..drawLine(
        center,
        Offset(
          center.dx + math.cos(hourAngle) * radius * 0.34,
          center.dy + math.sin(hourAngle) * radius * 0.34,
        ),
        hourPaint,
      )
      ..drawLine(
        center,
        Offset(
          center.dx + math.cos(secondAngle) * radius * 0.60,
          center.dy + math.sin(secondAngle) * radius * 0.60,
        ),
        secondPaint,
      )
      ..drawCircle(center, radius * 0.07, Paint()..color = GameUiTheme.gold);
  }

  @override
  bool shouldRepaint(covariant _QueueCountdownClockPainter oldDelegate) {
    return oldDelegate.secondsRemaining != secondsRemaining;
  }
}
