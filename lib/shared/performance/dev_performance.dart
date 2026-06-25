import 'dart:async';

import 'package:flutter/foundation.dart';

abstract final class DevPerformance {
  static const bool _enabledByFlag = bool.fromEnvironment('AONW_PERF');

  static bool get isEnabled => _enabledByFlag && !kReleaseMode;

  static void log(String message) {
    if (!isEnabled) return;
    debugPrint('[perf] $message');
  }

  static T timeSync<T>(String label, T Function() body) {
    if (!isEnabled) return body();

    final sw = Stopwatch()..start();
    try {
      return body();
    } finally {
      sw.stop();
      log('$label: ${sw.elapsedMicroseconds / 1000}ms');
    }
  }

  static Future<T> timeAsync<T>(
    String label,
    FutureOr<T> Function() body,
  ) async {
    if (!isEnabled) return body();

    final sw = Stopwatch()..start();
    try {
      return await body();
    } finally {
      sw.stop();
      log('$label: ${sw.elapsedMicroseconds / 1000}ms');
    }
  }
}

class DevFrameStats {
  final String label;
  final double reportEverySeconds;

  double _elapsed = 0;
  final List<double> _frameSamplesMs = <double>[];
  final List<double> _updateSamplesMs = <double>[];
  final List<double> _renderSamplesMs = <double>[];
  int? _lastComponentCount;

  DevFrameStats(this.label, {this.reportEverySeconds = 5});

  void recordUpdate(
    double dt,
    Duration duration, {
    int Function()? sampleComponentCount,
  }) {
    if (!DevPerformance.isEnabled) return;

    _elapsed += dt;
    _frameSamplesMs.add(dt * 1000);
    _updateSamplesMs.add(duration.inMicroseconds / 1000);
    if (sampleComponentCount != null) {
      _lastComponentCount = sampleComponentCount();
    }

    if (_elapsed < reportEverySeconds) return;

    final frames = _frameSamplesMs.length;
    final fps = frames / _elapsed;
    final frame = _summary(_frameSamplesMs);
    final update = _summary(_updateSamplesMs);
    final render = _summary(_renderSamplesMs);
    final components = _lastComponentCount == null
        ? ''
        : ', components=$_lastComponentCount';

    DevPerformance.log(
      '$label: fps=${fps.toStringAsFixed(1)}, '
      'frame=${frame.format()}ms, '
      'update=${update.format()}ms, '
      'render=${render.format()}ms$components',
    );

    _elapsed = 0;
    _frameSamplesMs.clear();
    _updateSamplesMs.clear();
    _renderSamplesMs.clear();
    _lastComponentCount = null;
  }

  void recordRender(Duration duration) {
    if (!DevPerformance.isEnabled) return;
    _renderSamplesMs.add(duration.inMicroseconds / 1000);
  }

  _FrameSampleSummary _summary(List<double> samples) {
    if (samples.isEmpty) return const _FrameSampleSummary.empty();

    final sorted = [...samples]..sort();
    final count = sorted.length;
    final avg = sorted.reduce((a, b) => a + b) / count;
    final p95Index = ((count - 1) * 0.95).round();
    return _FrameSampleSummary(
      avg: avg,
      p95: sorted[p95Index],
      worst: sorted.last,
    );
  }
}

class _FrameSampleSummary {
  final double avg;
  final double p95;
  final double worst;

  const _FrameSampleSummary({
    required this.avg,
    required this.p95,
    required this.worst,
  });

  const _FrameSampleSummary.empty() : avg = 0, p95 = 0, worst = 0;

  String format() {
    return '${avg.toStringAsFixed(2)}/${p95.toStringAsFixed(2)}/'
        '${worst.toStringAsFixed(2)}';
  }
}
