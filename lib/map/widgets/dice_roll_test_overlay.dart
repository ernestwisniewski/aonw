import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiceRollTestOverlay extends StatefulWidget {
  const DiceRollTestOverlay({this.spriteSheetFuture, super.key});

  static const assetPath = 'assets/sprites/dice.png';

  @visibleForTesting
  final Future<ui.Image>? spriteSheetFuture;

  @override
  State<DiceRollTestOverlay> createState() => _DiceRollTestOverlayState();
}

class _DiceRollTestOverlayState extends State<DiceRollTestOverlay>
    with SingleTickerProviderStateMixin {
  final _random = math.Random();
  late final AnimationController _controller;
  late final Future<ui.Image> _spriteSheetFuture;

  List<_DieThrow> _dice = const [];
  Offset _dragOffset = Offset.zero;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1380),
        )..addStatusListener((status) {
          if (status != AnimationStatus.completed || !mounted) return;
          setState(() {});
        });
    _spriteSheetFuture = widget.spriteSheetFuture ?? _loadSpriteSheet();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<ui.Image> _loadSpriteSheet() async {
    final bytes = await rootBundle.load(DiceRollTestOverlay.assetPath);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _roll(Size size, {Offset? dragVector, Offset? startCenter}) {
    if (size.width <= 0 || size.height <= 0) return;

    final diceSize = _diceSizeFor(size);
    final releaseStart = startCenter ?? _idleCenterFor(size) + _dragOffset;
    final throwVector = _throwVectorFor(size, dragVector);
    final distance = _randomRange(
      math.min(size.width, size.height) * 0.22,
      math.min(size.width, size.height) * 0.36,
    );
    final targetCenter = _clampCenter(
      releaseStart + throwVector * distance,
      size,
      diceSize,
    );

    setState(() {
      _dragging = false;
      _dragOffset = Offset.zero;
      _dice = List.generate(2, (index) {
        final sideOffset = Offset((index == 0 ? -0.46 : 0.46) * diceSize, 0);
        final start = _clampCenter(releaseStart + sideOffset, size, diceSize);
        final drift = Offset(
          _randomRange(-diceSize * 0.65, diceSize * 0.65),
          _randomRange(-diceSize * 0.25, diceSize * 0.45),
        );
        final end = _clampCenter(
          targetCenter + sideOffset * _randomRange(0.82, 1.18) + drift,
          size,
          diceSize,
        );
        final midpoint = Offset.lerp(start, end, 0.5)!;
        final lift = Offset(
          _randomRange(-diceSize * 0.85, diceSize * 0.85),
          -_randomRange(size.height * 0.16, size.height * 0.31),
        );

        return _DieThrow(
          value: _random.nextInt(6) + 1,
          start: start,
          control: _clampCenter(midpoint + lift, size, diceSize),
          end: end,
          initialAngle: _randomRange(-0.45, 0.45),
          spinTurns: (_random.nextBool() ? 1 : -1) * _randomRange(2.6, 4.3),
          frameOffset: _random.nextInt(24),
          bouncePhase: _randomRange(0.0, math.pi),
        );
      });
    });

    unawaited(_controller.forward(from: 0));
  }

  Offset _throwVectorFor(Size size, Offset? dragVector) {
    final fallback = Offset(
      _randomRange(-0.58, 0.58),
      -_randomRange(0.82, 1.12),
    );
    final vector = dragVector == null || dragVector.distance < 18
        ? fallback
        : dragVector;
    final normalized = vector / math.max(vector.distance, 1);
    final upwardBias = Offset(normalized.dx * 0.82, normalized.dy - 0.38);
    return upwardBias / math.max(upwardBias.distance, 1);
  }

  Offset _clampCenter(Offset center, Size size, double diceSize) {
    final half = diceSize / 2;
    return Offset(
      center.dx.clamp(half + 10, size.width - half - 10).toDouble(),
      center.dy.clamp(half + 10, size.height - half - 10).toDouble(),
    );
  }

  Offset _idleCenterFor(Size size) {
    return Offset(size.width * 0.5, size.height * 0.62);
  }

  double _diceSizeFor(Size size) {
    return (math.min(size.width, size.height) * 0.16).clamp(86.0, 138.0);
  }

  double _randomRange(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final diceSize = _diceSizeFor(size);
        final restingCenter = _restingCenterFor(size);
        final interactionCenter = restingCenter + _dragOffset;

        return FutureBuilder<ui.Image>(
          future: _spriteSheetFuture,
          builder: (context, snapshot) {
            final image = snapshot.data;
            if (image == null) return const SizedBox.expand();

            return Stack(
              key: const Key('diceRollTestOverlay'),
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final active = _controller.isAnimating || _dice.isNotEmpty;
                    final dice = active
                        ? _dice
                        : _idleDice(
                            center: interactionCenter,
                            diceSize: diceSize,
                            reduceMotion: reduceMotion,
                          );
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        for (var i = 0; i < dice.length; i++)
                          _PositionedDie(
                            key: Key('diceRollTestOverlay.die.$i'),
                            spriteSheet: image,
                            die: _poseFor(dice[i], reduceMotion: reduceMotion),
                            size: diceSize,
                            frameIndex: _frameIndexFor(
                              dice[i],
                              reduceMotion ? 1 : _controller.value,
                              animating: _controller.isAnimating,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                Positioned(
                  left: interactionCenter.dx - diceSize * 1.28,
                  top: interactionCenter.dy - diceSize * 0.76,
                  width: diceSize * 2.56,
                  height: diceSize * 1.52,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _roll(size, startCenter: interactionCenter),
                    onPanStart: (details) {
                      setState(() {
                        _dragging = true;
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _dragOffset += details.delta;
                      });
                    },
                    onPanEnd: (_) {
                      final vector = _dragOffset;
                      _roll(
                        size,
                        dragVector: vector,
                        startCenter: interactionCenter,
                      );
                    },
                    onPanCancel: () {
                      setState(() {
                        _dragging = false;
                        _dragOffset = Offset.zero;
                      });
                    },
                  ),
                ),
                if (_dragging)
                  Positioned(
                    left: interactionCenter.dx - 2,
                    top: interactionCenter.dy - 2,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(180),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const SizedBox.square(dimension: 4),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Offset _restingCenterFor(Size size) {
    if (_dice.isEmpty || _controller.isAnimating) {
      return _idleCenterFor(size);
    }
    final sum = _dice.fold<Offset>(
      Offset.zero,
      (previous, die) => previous + die.end,
    );
    return sum / _dice.length.toDouble();
  }

  _DiePose _poseFor(_DieThrow die, {required bool reduceMotion}) {
    final pose = reduceMotion ? die.settled() : die.at(_controller.value);
    if (!_dragging || _controller.isAnimating || _dice.isEmpty) return pose;
    return pose.shifted(_dragOffset);
  }

  List<_DieThrow> _idleDice({
    required Offset center,
    required double diceSize,
    required bool reduceMotion,
  }) {
    final bob = reduceMotion
        ? 0.0
        : math.sin(DateTime.now().millisecondsSinceEpoch / 340) * 2.0;
    return [
      _DieThrow.idle(
        value: 1,
        center: center + Offset(-diceSize * 0.48, bob),
        angle: -0.08,
      ),
      _DieThrow.idle(
        value: 6,
        center: center + Offset(diceSize * 0.48, -bob),
        angle: 0.1,
      ),
    ];
  }

  int _frameIndexFor(
    _DieThrow die,
    double progress, {
    required bool animating,
  }) {
    if (!animating || progress >= 0.86) {
      return 30 + die.value - 1;
    }
    return (die.frameOffset + (progress * 38).floor()) % 24;
  }
}

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
