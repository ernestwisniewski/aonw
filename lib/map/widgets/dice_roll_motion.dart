part of 'dice_roll_test_overlay.dart';

class _DieThrow {
  final int value;
  final Offset start;
  final Offset control;
  final Offset end;
  final double initialAngle;
  final double spinTurns;
  final int frameOffset;
  final double bouncePhase;
  final bool idle;

  const _DieThrow({
    required this.value,
    required this.start,
    required this.control,
    required this.end,
    required this.initialAngle,
    required this.spinTurns,
    required this.frameOffset,
    required this.bouncePhase,
    this.idle = false,
  });

  factory _DieThrow.idle({
    required int value,
    required Offset center,
    required double angle,
  }) {
    return _DieThrow(
      value: value,
      start: center,
      control: center,
      end: center,
      initialAngle: angle,
      spinTurns: 0,
      frameOffset: value - 1,
      bouncePhase: 0,
      idle: true,
    );
  }

  _DiePose at(double rawProgress) {
    if (idle) return settled();
    final progress = Curves.easeOutCubic.transform(rawProgress);
    final center = _quadratic(start, control, end, progress);
    final bounce =
        math.sin((rawProgress * math.pi * 4.4) + bouncePhase) *
        (1 - rawProgress) *
        18;
    final pop = math.sin(rawProgress * math.pi) * 0.22;

    return _DiePose(
      center: center + Offset(0, -bounce),
      angle: initialAngle + spinTurns * math.pi * 2 * progress,
      scale: 1 + pop,
      opacity: 1,
    );
  }

  _DiePose settled() {
    return _DiePose(center: end, angle: initialAngle, scale: 1, opacity: 1);
  }

  static Offset _quadratic(Offset a, Offset b, Offset c, double t) {
    final oneMinus = 1 - t;
    return a * oneMinus * oneMinus + b * 2 * oneMinus * t + c * t * t;
  }
}

class _DiePose {
  final Offset center;
  final double angle;
  final double scale;
  final double opacity;

  const _DiePose({
    required this.center,
    required this.angle,
    required this.scale,
    required this.opacity,
  });

  _DiePose shifted(Offset offset) {
    return _DiePose(
      center: center + offset,
      angle: angle,
      scale: scale,
      opacity: opacity,
    );
  }
}
