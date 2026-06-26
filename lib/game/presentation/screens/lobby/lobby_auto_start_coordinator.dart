import 'dart:async';

import 'package:aonw_core/protocol.dart';

typedef LobbyAutoStartTimerFactory =
    Timer Function(Duration delay, void Function() onElapsed);
typedef LobbyCountdownTimerFactory =
    Timer Function(Duration delay, void Function(Timer timer) onTick);
typedef LobbyClockReader = DateTime Function();
typedef LobbyModeReader = bool Function();
typedef LobbyActiveMatchReader = WireMatch? Function();
typedef LobbyContinuationReader = bool Function();
typedef LobbyRefreshRequester = void Function();
typedef LobbyCountdownNotifier = void Function();

final class LobbyAutoStartCoordinator {
  final LobbyAutoStartTimerFactory timerFactory;
  final LobbyCountdownTimerFactory periodicTimerFactory;
  final LobbyClockReader now;
  final LobbyModeReader isQuickplayMode;
  final LobbyActiveMatchReader activeMatch;
  final LobbyContinuationReader canContinue;
  final LobbyRefreshRequester refreshActiveMatch;
  final LobbyCountdownNotifier notifyCountdownChanged;

  Timer? _autoStartTimer;
  Timer? _countdownTimer;

  LobbyAutoStartCoordinator({
    this.timerFactory = Timer.new,
    this.periodicTimerFactory = Timer.periodic,
    required this.now,
    required this.isQuickplayMode,
    required this.activeMatch,
    required this.canContinue,
    required this.refreshActiveMatch,
    required this.notifyCountdownChanged,
  });

  void schedule(WireMatch match) {
    _autoStartTimer?.cancel();
    _autoStartTimer = null;
    _scheduleCountdown(match);
    if (!_shouldTrack(match)) return;

    final autoStartAt = match.autoStartAt;
    if (autoStartAt == null) return;
    _autoStartTimer = timerFactory(
      _autoStartDelay(autoStartAt),
      refreshActiveMatch,
    );
  }

  void cancel() {
    _autoStartTimer?.cancel();
    _autoStartTimer = null;
    cancelCountdown();
  }

  void cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _scheduleCountdown(WireMatch match) {
    cancelCountdown();
    if (!_shouldTrack(match)) return;

    final autoStartAt = match.autoStartAt;
    if (autoStartAt == null) return;
    _countdownTimer = periodicTimerFactory(
      const Duration(seconds: 1),
      (timer) =>
          _tickCountdown(timer, matchId: match.id, autoStartAt: autoStartAt),
    );
  }

  void _tickCountdown(
    Timer timer, {
    required String matchId,
    required DateTime autoStartAt,
  }) {
    if (!_isStillCurrentCountdown(matchId: matchId, autoStartAt: autoStartAt)) {
      _cancelCountdownTimer(timer);
      return;
    }

    notifyCountdownChanged();
    if (!autoStartAt.isAfter(now())) {
      _cancelCountdownTimer(timer);
    }
  }

  bool _shouldTrack(WireMatch match) {
    return canContinue() &&
        isQuickplayMode() &&
        match.state == 'open' &&
        match.autoStartAt != null;
  }

  bool _isStillCurrentCountdown({
    required String matchId,
    required DateTime autoStartAt,
  }) {
    final current = activeMatch();
    final currentAutoStartAt = current?.autoStartAt;
    return canContinue() &&
        isQuickplayMode() &&
        current?.id == matchId &&
        currentAutoStartAt != null &&
        currentAutoStartAt.toUtc().isAtSameMomentAs(autoStartAt.toUtc());
  }

  Duration _autoStartDelay(DateTime autoStartAt) {
    final delay = autoStartAt.difference(now());
    return delay.isNegative ? const Duration(seconds: 1) : delay;
  }

  void _cancelCountdownTimer(Timer timer) {
    timer.cancel();
    if (identical(_countdownTimer, timer)) {
      _countdownTimer = null;
    }
  }
}
