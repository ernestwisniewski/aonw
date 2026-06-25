import 'package:aonw_server/src/multiplayer/quickplay_lobby_policy.dart';
import 'package:test/test.dart';

void main() {
  group('QuickplayLobbyPolicy', () {
    const policy = QuickplayLobbyPolicy();
    final now = DateTime.utc(2026, 6, 12, 10);

    test('waits for players before the minimum joins', () {
      final decision = policy.evaluate(
        humanPlayers: 1,
        minPlayers: 2,
        maxPlayers: 4,
        nowUtc: now,
        currentAutoStartAt: now.add(const Duration(seconds: 30)),
      );

      expect(decision.action, QuickplayLobbyAction.waitForPlayers);
      expect(decision.autoStartAt, isNull);
    });

    test('starts a 30 second countdown when the second player joins', () {
      final decision = policy.evaluate(
        humanPlayers: 2,
        minPlayers: 2,
        maxPlayers: 4,
        nowUtc: now,
        currentAutoStartAt: null,
      );

      expect(decision.action, QuickplayLobbyAction.waitForCountdown);
      expect(decision.autoStartAt, now.add(const Duration(seconds: 30)));
    });

    test('keeps the existing countdown while more players join', () {
      final deadline = now.add(const Duration(seconds: 18));

      final decision = policy.evaluate(
        humanPlayers: 3,
        minPlayers: 2,
        maxPlayers: 4,
        nowUtc: now,
        currentAutoStartAt: deadline,
      );

      expect(decision.action, QuickplayLobbyAction.waitForCountdown);
      expect(decision.autoStartAt, deadline);
    });

    test('starts immediately when the lobby reaches four players', () {
      final decision = policy.evaluate(
        humanPlayers: 4,
        minPlayers: 2,
        maxPlayers: 4,
        nowUtc: now,
        currentAutoStartAt: now.add(const Duration(seconds: 30)),
      );

      expect(decision.action, QuickplayLobbyAction.start);
    });

    test('starts once the countdown deadline is due', () {
      final decision = policy.evaluate(
        humanPlayers: 2,
        minPlayers: 2,
        maxPlayers: 4,
        nowUtc: now.add(const Duration(seconds: 31)),
        currentAutoStartAt: now.add(const Duration(seconds: 30)),
      );

      expect(decision.action, QuickplayLobbyAction.start);
    });

    test('expires one-player waiting lobbies after the join window', () {
      expect(
        policy.isStaleWaitingForPlayers(
          humanPlayers: 1,
          minPlayers: 2,
          createdAt: now.subtract(const Duration(seconds: 59)),
          nowUtc: now,
          currentAutoStartAt: null,
        ),
        isFalse,
      );
      expect(
        policy.isStaleWaitingForPlayers(
          humanPlayers: 1,
          minPlayers: 2,
          createdAt: now.subtract(const Duration(minutes: 1)),
          nowUtc: now,
          currentAutoStartAt: null,
        ),
        isTrue,
      );
      expect(
        policy.isStaleWaitingForPlayers(
          humanPlayers: 2,
          minPlayers: 2,
          createdAt: now.subtract(const Duration(minutes: 2)),
          nowUtc: now,
          currentAutoStartAt: now.add(const Duration(seconds: 10)),
        ),
        isFalse,
      );
    });
  });
}
