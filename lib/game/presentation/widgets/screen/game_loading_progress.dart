import 'dart:math' as math;

import 'package:flutter/foundation.dart';

@immutable
final class GameLoadingProgress {
  const GameLoadingProgress({this.value});

  static const initial = GameLoadingProgress();

  final double? value;

  GameLoadingProgress bumpedTo(double minimum) {
    final current = value;
    if (current == null) {
      return GameLoadingProgress(value: minimum.clamp(0.0, 1.0).toDouble());
    }
    return GameLoadingProgress(
      value: math.max(current, minimum).clamp(0.0, 1.0).toDouble(),
    );
  }
}

final class GameLoadingProgressController
    extends ValueNotifier<GameLoadingProgress> {
  GameLoadingProgressController([super.value = GameLoadingProgress.initial]);

  void report(double progress) {
    value = value.bumpedTo(progress);
  }
}
