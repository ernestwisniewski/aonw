import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw/shared/assets/sprite_frames.dart';
import 'package:flutter/material.dart';

part 'dice_roll_motion.dart';
part 'dice_roll_rendering.dart';

class DiceRollTestOverlay extends StatefulWidget {
  const DiceRollTestOverlay({this.spriteSheetFuture, super.key});

  @visibleForTesting
  final Future<ui.Image>? spriteSheetFuture;

  @override
  State<DiceRollTestOverlay> createState() => _DiceRollTestOverlayState();
}

class _DiceRollTestOverlayState extends State<DiceRollTestOverlay>
    with SingleTickerProviderStateMixin {
  final _random = math.Random();
  late final AnimationController _controller;
  late final Future<List<_DiceFrame>> _framesFuture;

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
    final testSheet = widget.spriteSheetFuture;
    _framesFuture = testSheet == null
        ? _loadFrames()
        : testSheet.then(_framesFromTestSheet);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<_DiceFrame>> _loadFrames() async {
    return Future.wait([
      for (var index = 0; index < 36; index++)
        SpriteFrames.load(
          SpriteFrameId('dice.$index'),
        ).then((frame) => _DiceFrame(image: frame.image, source: frame.source)),
    ]);
  }

  List<_DiceFrame> _framesFromTestSheet(ui.Image image) {
    final frameWidth = image.width / 6;
    final frameHeight = image.height / 6;
    return [
      for (var index = 0; index < 36; index++)
        _DiceFrame(
          image: image,
          source: Rect.fromLTWH(
            (index % 6) * frameWidth,
            (index ~/ 6) * frameHeight,
            frameWidth,
            frameHeight,
          ),
        ),
    ];
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

        return FutureBuilder<List<_DiceFrame>>(
          future: _framesFuture,
          builder: (context, snapshot) {
            final frames = snapshot.data;
            if (snapshot.hasError) {
              return ErrorWidget(
                snapshot.error ?? StateError('Could not load dice sprites'),
              );
            }
            if (frames == null) return const SizedBox.expand();

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
                            frame:
                                frames[_frameIndexFor(
                                  dice[i],
                                  reduceMotion ? 1 : _controller.value,
                                  animating: _controller.isAnimating,
                                )],
                            die: _poseFor(dice[i], reduceMotion: reduceMotion),
                            size: diceSize,
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

class _DiceFrame {
  const _DiceFrame({required this.image, required this.source});

  final ui.Image image;
  final Rect source;
}
