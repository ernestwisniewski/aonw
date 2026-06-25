import 'dart:async';

import 'package:aonw/game/presentation/screens/lobby_auto_start_coordinator.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LobbyAutoStartCoordinator', () {
    test('schedules quickplay countdown and auto-start refresh', () {
      final timers = _FakeTimers();
      final periodicTimers = _FakePeriodicTimers();
      final now = DateTime.utc(2026, 6, 2, 12);
      final match = _match(autoStartAt: now.add(const Duration(seconds: 3)));
      final activeMatch = match;
      var refreshCount = 0;
      var tickCount = 0;
      LobbyAutoStartCoordinator(
        timerFactory: timers.create,
        periodicTimerFactory: periodicTimers.create,
        now: () => now,
        isQuickplayMode: () => true,
        activeMatch: () => activeMatch,
        canContinue: () => true,
        refreshActiveMatch: () => refreshCount += 1,
        notifyCountdownChanged: () => tickCount += 1,
      ).schedule(match);

      expect(timers.created.single.delay, const Duration(seconds: 3));
      expect(periodicTimers.created.single.delay, const Duration(seconds: 1));

      periodicTimers.fireLatest();
      expect(tickCount, 1);
      expect(periodicTimers.latest.isActive, isTrue);

      timers.fireLatest();
      expect(refreshCount, 1);
      expect(activeMatch.id, 'match_1');
    });

    test('does not schedule timers outside open quickplay countdown', () {
      final timers = _FakeTimers();
      final periodicTimers = _FakePeriodicTimers();
      LobbyAutoStartCoordinator(
          timerFactory: timers.create,
          periodicTimerFactory: periodicTimers.create,
          now: () => DateTime.utc(2026, 6, 2),
          isQuickplayMode: () => false,
          activeMatch: () => _match(),
          canContinue: () => true,
          refreshActiveMatch: () {},
          notifyCountdownChanged: () {},
        )
        ..schedule(_match(autoStartAt: DateTime.utc(2026, 6, 2, 12)))
        ..schedule(_match(state: 'loading', autoStartAt: DateTime.utc(2026)));

      expect(timers.created, isEmpty);
      expect(periodicTimers.created, isEmpty);
    });

    test('countdown cancels when active match changes', () {
      final timers = _FakeTimers();
      final periodicTimers = _FakePeriodicTimers();
      final autoStartAt = DateTime.utc(2026, 6, 2, 12, 0, 3);
      final scheduledMatch = _match(id: 'match_1', autoStartAt: autoStartAt);
      final activeMatch = _match(id: 'match_2', autoStartAt: autoStartAt);
      var tickCount = 0;
      LobbyAutoStartCoordinator(
        timerFactory: timers.create,
        periodicTimerFactory: periodicTimers.create,
        now: () => DateTime.utc(2026, 6, 2, 12),
        isQuickplayMode: () => true,
        activeMatch: () => activeMatch,
        canContinue: () => true,
        refreshActiveMatch: () {},
        notifyCountdownChanged: () => tickCount += 1,
      ).schedule(scheduledMatch);
      periodicTimers.fireLatest();

      expect(tickCount, 0);
      expect(periodicTimers.latest.isActive, isFalse);
      expect(activeMatch.id, 'match_2');
    });

    test('uses a short retry delay when auto-start is already due', () {
      final timers = _FakeTimers();
      LobbyAutoStartCoordinator(
        timerFactory: timers.create,
        periodicTimerFactory: _FakePeriodicTimers().create,
        now: () => DateTime.utc(2026, 6, 2, 12, 0, 5),
        isQuickplayMode: () => true,
        activeMatch: () => _match(),
        canContinue: () => true,
        refreshActiveMatch: () {},
        notifyCountdownChanged: () {},
      ).schedule(_match(autoStartAt: DateTime.utc(2026, 6, 2, 12, 0, 4)));

      expect(timers.created.single.delay, const Duration(seconds: 1));
    });
  });
}

WireMatch _match({
  String id = 'match_1',
  String state = 'open',
  DateTime? autoStartAt,
}) {
  return WireMatch(
    id: id,
    ownerUserId: 'user_1',
    name: 'Quickplay',
    mapName: 'verdantia',
    players: const [],
    maxPlayers: 4,
    minPlayers: 2,
    turn: 1,
    state: state,
    createdAt: DateTime.utc(2026, 6, 2),
    autoStartAt: autoStartAt,
  );
}

final class _FakeTimers {
  final created = <_FakeTimer>[];

  _FakeTimer get latest => created.last;

  Timer create(Duration delay, void Function() onElapsed) {
    final timer = _FakeTimer(delay, onElapsed);
    created.add(timer);
    return timer;
  }

  void fireLatest() {
    latest.fire();
  }
}

final class _FakePeriodicTimers {
  final created = <_FakePeriodicTimer>[];

  _FakePeriodicTimer get latest => created.last;

  Timer create(Duration delay, void Function(Timer timer) onTick) {
    final timer = _FakePeriodicTimer(delay, onTick);
    created.add(timer);
    return timer;
  }

  void fireLatest() {
    latest.fire();
  }
}

base class _FakeTimer implements Timer {
  final Duration delay;
  final void Function() onElapsed;
  var _active = true;
  var _tick = 0;

  _FakeTimer(this.delay, this.onElapsed);

  @override
  bool get isActive => _active;

  @override
  int get tick => _tick;

  @override
  void cancel() {
    _active = false;
  }

  void fire() {
    if (!_active) return;
    _active = false;
    _tick += 1;
    onElapsed();
  }
}

final class _FakePeriodicTimer extends _FakeTimer {
  final void Function(Timer timer) onTick;

  _FakePeriodicTimer(Duration delay, this.onTick) : super(delay, () {});

  @override
  void fire() {
    if (!isActive) return;
    _tick += 1;
    onTick(this);
  }
}
