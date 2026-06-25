import 'dart:async';

import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';

final class AiTurnCommandPauseReport {
  final bool paused;
  final Duration duration;

  const AiTurnCommandPauseReport({
    required this.paused,
    required this.duration,
  });

  static const none = AiTurnCommandPauseReport(
    paused: false,
    duration: Duration.zero,
  );
}

final class AiTurnCommandPacer {
  final Future<void> Function(Duration duration) delay;
  final Stopwatch Function() stopwatchFactory;

  const AiTurnCommandPacer({
    this.delay = Future<void>.delayed,
    this.stopwatchFactory = Stopwatch.new,
  });

  Future<AiTurnCommandPauseReport> pauseAfterDispatch({
    required DispatchCommandResult result,
    required Duration interCommandDelay,
  }) async {
    if (interCommandDelay <= Duration.zero || result.uiEffects.isEmpty) {
      return AiTurnCommandPauseReport.none;
    }

    final stopwatch = stopwatchFactory()..start();
    await delay(interCommandDelay);
    stopwatch.stop();
    return AiTurnCommandPauseReport(paused: true, duration: stopwatch.elapsed);
  }
}
