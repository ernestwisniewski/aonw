import 'dart:async';

import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';

typedef PresentationDelay = Future<void> Function(Duration duration);

final class PresentationScheduleMiss implements Exception {
  const PresentationScheduleMiss({
    required this.eventOffset,
    required this.lateness,
  });

  final int eventOffset;
  final Duration lateness;

  @override
  String toString() =>
      'PresentationScheduleMiss(offset: $eventOffset, lateness: $lateness)';
}

/// Aligns authoritative transitions to the shared UTC presentation clock.
final class AuthoritativePresentationScheduler {
  const AuthoritativePresentationScheduler({
    required Clock clock,
    PresentationDelay delay = _systemDelay,
  }) : _clock = clock,
       _delay = delay;

  final Clock _clock;
  final PresentationDelay _delay;

  Future<void> waitFor(ProjectedGameEffectBatch batch) async {
    final identity = batch.identity;
    if (identity == null ||
        batch.sequenceDirective != PresentationSequenceDirective.advance) {
      return;
    }
    final targetMicros = identity.authoritativeStartMicrosUtc;
    if (targetMicros == null) return;
    final remaining = targetMicros - _nowMicrosUtc;
    if (remaining > 0) {
      await _delay(Duration(microseconds: remaining));
    }
    final latenessMicros = _nowMicrosUtc - targetMicros;
    if (latenessMicros > presentationFrameBudget.inMicroseconds) {
      throw PresentationScheduleMiss(
        eventOffset: identity.eventOffset,
        lateness: Duration(microseconds: latenessMicros),
      );
    }
  }

  /// Preserves a live transition when transport jitter misses its start slot.
  Future<void> waitForOrStartLate(ProjectedGameEffectBatch batch) async {
    try {
      await waitFor(batch);
    } on PresentationScheduleMiss {
      // A late live presentation is safer than dropping its state transition.
    }
  }

  int get _nowMicrosUtc => _clock.nowUtc().microsecondsSinceEpoch;
}

Future<void> _systemDelay(Duration duration) => Future<void>.delayed(duration);
