import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/state/game_mode.dart';
import 'package:aonw_core/game/domain/state/match_session_state.dart';
import 'package:test/test.dart';

void main() {
  test('keeps turn, submission, and lifecycle facts independent', () {
    final state = MatchSessionState.snapshot(
      gameMode: GameMode.multiplayer,
      turnStatesByPlayerId: const {
        'finished': PlayerTurnState.finished,
        'active': PlayerTurnState.active,
      },
      submittedPlayerIds: const {'active'},
      kickedPlayerIds: const {'finished'},
    );

    expect(state.turnStatesByPlayerId['finished'], PlayerTurnState.finished);
    expect(state.isKicked('finished'), isTrue);
    expect(state.hasSubmitted('finished'), isFalse);
    expect(state.turnStatesByPlayerId['active'], PlayerTurnState.active);
    expect(state.hasSubmitted('active'), isTrue);
    expect(state.isAfk('active'), isFalse);
  });

  test('owns collection inputs and normalizes the timestamp to UTC', () {
    final turnStates = <String, PlayerTurnState>{
      'player': PlayerTurnState.active,
    };
    final submitted = <String>{'player'};
    final timeouts = <String, int>{'player': 1};
    final afk = <String>{'afk'};
    final kicked = <String>{'kicked'};
    final state = MatchSessionState.snapshot(
      gameMode: GameMode.multiplayer,
      turnStatesByPlayerId: turnStates,
      submittedPlayerIds: submitted,
      timeoutStreaksByPlayerId: timeouts,
      afkPlayerIds: afk,
      kickedPlayerIds: kicked,
      turnStartedAt: DateTime(2026, 7, 17, 12),
    );

    turnStates['other'] = PlayerTurnState.finished;
    submitted.add('other');
    timeouts['other'] = 2;
    afk.add('other');
    kicked.add('other');

    expect(state.turnStatesByPlayerId, {'player': PlayerTurnState.active});
    expect(state.submittedPlayerIds, {'player'});
    expect(state.timeoutStreaksByPlayerId, {'player': 1});
    expect(state.afkPlayerIds, {'afk'});
    expect(state.kickedPlayerIds, {'kicked'});
    expect(state.turnStartedAt, DateTime(2026, 7, 17, 12).toUtc());
    expect(state.turnStartedAt!.isUtc, isTrue);
    expect(
      () => state.submittedPlayerIds.add('forbidden'),
      throwsUnsupportedError,
    );
  });

  test(
    'copyWith shares unchanged collections, owns replacements, and clears',
    () {
      final state = MatchSessionState.snapshot(
        gameMode: GameMode.hotSeat,
        turnStatesByPlayerId: const {'player': PlayerTurnState.active},
        submittedPlayerIds: const {'player'},
        timeoutStreaksByPlayerId: const {'player': 1},
        afkPlayerIds: const {'afk'},
        kickedPlayerIds: const {'kicked'},
        turnStartedAt: DateTime.utc(2026, 7, 17),
      );
      final replacement = <String>{'other'};

      final copied = state.copyWith(
        gameMode: GameMode.multiplayer,
        submittedPlayerIds: replacement,
        turnStartedAt: null,
      );
      replacement.add('mutated');

      expect(copied.gameMode, GameMode.multiplayer);
      expect(copied.submittedPlayerIds, {'other'});
      expect(copied.turnStatesByPlayerId, same(state.turnStatesByPlayerId));
      expect(
        copied.timeoutStreaksByPlayerId,
        same(state.timeoutStreaksByPlayerId),
      );
      expect(copied.afkPlayerIds, same(state.afkPlayerIds));
      expect(copied.kickedPlayerIds, same(state.kickedPlayerIds));
      expect(copied.turnStartedAt, isNull);
    },
  );

  test('uses structural equality and order-independent collection hashes', () {
    final left = MatchSessionState.snapshot(
      gameMode: GameMode.multiplayer,
      turnStatesByPlayerId: const {
        'one': PlayerTurnState.active,
        'two': PlayerTurnState.finished,
      },
      submittedPlayerIds: const {'one', 'two'},
      timeoutStreaksByPlayerId: const {'one': 1, 'two': 2},
      afkPlayerIds: const {'one', 'two'},
      kickedPlayerIds: const {'one', 'two'},
      turnStartedAt: DateTime.utc(2026, 7, 17),
    );
    final right = MatchSessionState.snapshot(
      gameMode: GameMode.multiplayer,
      turnStatesByPlayerId: const {
        'two': PlayerTurnState.finished,
        'one': PlayerTurnState.active,
      },
      submittedPlayerIds: const {'two', 'one'},
      timeoutStreaksByPlayerId: const {'two': 2, 'one': 1},
      afkPlayerIds: const {'two', 'one'},
      kickedPlayerIds: const {'two', 'one'},
      turnStartedAt: DateTime.utc(2026, 7, 17),
    );

    expect(left, right);
    expect(left.hashCode, right.hashCode);
  });
}
