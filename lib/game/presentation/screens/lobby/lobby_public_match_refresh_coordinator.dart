import 'dart:async';

typedef LobbyPublicRefreshTimerFactory =
    Timer Function(Duration interval, void Function(Timer timer) onTick);
typedef LobbyPublicRefresh = Future<void> Function();
typedef LobbyPublicRefreshGuard = bool Function();

final class LobbyPublicMatchRefreshCoordinator {
  LobbyPublicMatchRefreshCoordinator({
    required this.refresh,
    required this.canRefresh,
    this.interval = const Duration(seconds: 2),
    this.timerFactory = Timer.periodic,
  });

  final LobbyPublicRefresh refresh;
  final LobbyPublicRefreshGuard canRefresh;
  final Duration interval;
  final LobbyPublicRefreshTimerFactory timerFactory;

  Timer? _timer;
  bool _refreshing = false;

  void start() {
    stop();
    _timer = timerFactory(interval, (_) => unawaited(_refreshIfPossible()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _refreshIfPossible() async {
    if (_refreshing || !canRefresh()) return;
    _refreshing = true;
    try {
      await refresh();
    } catch (_) {
      // Background discovery keeps the last successful result on failure.
    } finally {
      _refreshing = false;
    }
  }
}
