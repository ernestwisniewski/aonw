import 'dart:async';

import 'package:aonw/game/presentation/screens/lobby/lobby_public_match_refresh_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refreshes public matches periodically only while active', () async {
    late _ManualPeriodicTimer timer;
    var enabled = true;
    var refreshes = 0;
    final coordinator = LobbyPublicMatchRefreshCoordinator(
      canRefresh: () => enabled,
      refresh: () async {
        refreshes += 1;
      },
      timerFactory: (interval, onTick) {
        expect(interval, const Duration(seconds: 2));
        return timer = _ManualPeriodicTimer(onTick);
      },
    );
    final start = coordinator.start;
    final stop = coordinator.stop;

    start();
    timer.fire();
    await Future<void>.delayed(Duration.zero);
    expect(refreshes, 1);

    enabled = false;
    timer.fire();
    await Future<void>.delayed(Duration.zero);
    expect(refreshes, 1);

    stop();
    expect(timer.isActive, isFalse);
  });
}

final class _ManualPeriodicTimer implements Timer {
  _ManualPeriodicTimer(this.onTick);

  final void Function(Timer timer) onTick;
  bool _active = true;
  int _ticks = 0;

  void fire() {
    if (!_active) return;
    _ticks += 1;
    onTick(this);
  }

  @override
  bool get isActive => _active;

  @override
  int get tick => _ticks;

  @override
  void cancel() => _active = false;
}
