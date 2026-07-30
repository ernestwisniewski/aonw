import 'package:aonw_core/application.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/match_lifecycle_state_adapter.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:test/test.dart';

void main() {
  const adapter = MatchLifecycleStateAdapter();
  final endedAt = DateTime.utc(2026, 7, 30, 12);

  test('start clears terminal metadata and preserves exact wire phase', () {
    final result = adapter.apply(
      _state(state: 'open', autoStartAt: DateTime.utc(2026, 7, 30, 13)),
      const StartMatchLifecycle(),
    );

    expect(result.changed, isTrue);
    expect(result.state.match.state, 'running');
    expect(result.state.match.endedAt, isNull);
    expect(result.state.match.outcomeCondition, isNull);
    expect(result.state.match.winnerPlayerId, isNull);
    expect(result.state.match.autoStartAt, isNull);
    expect(result.state.snapshot.state['phase'], 'running');
  });

  test('finish atomically sets terminal metadata and snapshot phase', () {
    final result = adapter.apply(
      _state(state: 'running'),
      const FinishMatchLifecycle(MatchCompletionReason.conquest),
      endedAt: endedAt,
      winnerPlayerId: 'player-1',
    );

    expect(result.changed, isTrue);
    expect(result.state.match.state, 'finished');
    expect(result.state.match.endedAt, endedAt);
    expect(result.state.match.outcomeCondition, 'conquest');
    expect(result.state.match.winnerPlayerId, 'player-1');
    expect(result.state.match.autoStartAt, isNull);
    expect(result.state.snapshot.state['phase'], 'finished');
  });

  test('draw rejects a winner and non-draw finish requires one', () {
    expect(
      () => adapter.apply(
        _state(state: 'running'),
        const FinishMatchLifecycle(MatchCompletionReason.conquest),
        endedAt: endedAt,
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => adapter.apply(
        _state(state: 'running'),
        const FinishMatchLifecycle(MatchCompletionReason.draw),
        endedAt: endedAt,
        winnerPlayerId: 'player-1',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('abandon atomically stores terminal metadata and typed reason', () {
    final result = adapter.apply(
      _state(state: 'running'),
      const AbandonMatchLifecycle(MatchAbandonmentReason.playerLeft),
      endedAt: endedAt,
      userIdentifier: 'user-1',
    );

    expect(result.changed, isTrue);
    expect(result.state.match.state, 'abandoned');
    expect(result.state.match.endedAt, endedAt);
    expect(result.state.match.outcomeCondition, isNull);
    expect(result.state.match.winnerPlayerId, isNull);
    expect(result.state.snapshot.state, {
      'phase': 'abandoned',
      'reason': 'player_left',
      'leftUserIdentifier': 'user-1',
    });
  });

  test('same terminal transition is an identity-preserving no-op', () {
    final state = _state(
      state: 'finished',
      outcomeCondition: 'conquest',
      winnerPlayerId: 'player-1',
      endedAt: endedAt,
    );

    final result = adapter.apply(
      state,
      const FinishMatchLifecycle(MatchCompletionReason.conquest),
      endedAt: endedAt.add(const Duration(hours: 1)),
      winnerPlayerId: 'player-1',
    );

    expect(result.changed, isFalse);
    expect(result.state, same(state));
  });

  test('forbidden transition returns typed rejection without mutation', () {
    final state = _state(state: 'open');

    final result = adapter.apply(
      state,
      const FinishMatchLifecycle(MatchCompletionReason.conquest),
      endedAt: endedAt,
      winnerPlayerId: 'player-1',
    );

    expect(result.changed, isFalse);
    expect(result.state, same(state));
    expect(result.rejection?.code, 'invalid_lifecycle_transition');
  });

  test('loading cannot be decoded by the authoritative server adapter', () {
    expect(
      () => adapter.lifecycleOf(_state(state: 'loading')),
      throwsA(isA<FormatException>()),
    );
  });

  group('rejects corrupt persisted lifecycle metadata', () {
    final corruptStates = <({String name, StoredMatchState state})>[
      (
        name: 'open with endedAt',
        state: _state(state: 'open', endedAt: endedAt),
      ),
      (
        name: 'open with outcome',
        state: _state(state: 'open', outcomeCondition: 'conquest'),
      ),
      (
        name: 'running with auto-start',
        state: _state(
          state: 'running',
          autoStartAt: endedAt.add(const Duration(hours: 1)),
        ),
      ),
      (
        name: 'running with terminal winner',
        state: _state(state: 'running', winnerPlayerId: 'player-1'),
      ),
      (
        name: 'finished without endedAt',
        state: _state(
          state: 'finished',
          outcomeCondition: 'conquest',
          winnerPlayerId: 'player-1',
        ),
      ),
      (
        name: 'finished non-draw without winner',
        state: _state(
          state: 'finished',
          endedAt: endedAt,
          outcomeCondition: 'conquest',
        ),
      ),
      (
        name: 'finished draw with winner',
        state: _state(
          state: 'finished',
          endedAt: endedAt,
          outcomeCondition: 'draw',
          winnerPlayerId: 'player-1',
        ),
      ),
      (
        name: 'finished with auto-start',
        state: _state(
          state: 'finished',
          endedAt: endedAt,
          outcomeCondition: 'conquest',
          winnerPlayerId: 'player-1',
          autoStartAt: endedAt.add(const Duration(hours: 1)),
        ),
      ),
      (
        name: 'abandoned without endedAt',
        state: _state(state: 'abandoned', abandonmentReason: 'player_left'),
      ),
      (
        name: 'abandoned with outcome',
        state: _state(
          state: 'abandoned',
          endedAt: endedAt,
          outcomeCondition: 'conquest',
          abandonmentReason: 'player_left',
        ),
      ),
      (
        name: 'abandoned with winner',
        state: _state(
          state: 'abandoned',
          endedAt: endedAt,
          winnerPlayerId: 'player-1',
          abandonmentReason: 'player_left',
        ),
      ),
      (
        name: 'abandoned with auto-start',
        state: _state(
          state: 'abandoned',
          endedAt: endedAt,
          autoStartAt: endedAt.add(const Duration(hours: 1)),
          abandonmentReason: 'player_left',
        ),
      ),
    ];

    for (final corrupt in corruptStates) {
      test(corrupt.name, () {
        final action = switch (corrupt.state.match.state) {
          'finished' => FinishMatchLifecycle(
            corrupt.state.match.outcomeCondition == 'draw'
                ? MatchCompletionReason.draw
                : MatchCompletionReason.conquest,
          ),
          'abandoned' => const AbandonMatchLifecycle(
            MatchAbandonmentReason.playerLeft,
          ),
          _ => const StartMatchLifecycle(),
        };
        final result = adapter.apply(corrupt.state, action);

        expect(result.changed, isFalse);
        expect(result.state, same(corrupt.state));
        expect(result.rejection?.code, 'invalid_lifecycle_metadata');
      });
    }
  });
}

StoredMatchState _state({
  required String state,
  DateTime? endedAt,
  String? outcomeCondition,
  String? winnerPlayerId,
  DateTime? autoStartAt,
  String? abandonmentReason,
}) {
  return StoredMatchState(
    match: WireMatch(
      id: 'match-1',
      ownerUserId: 'user-1',
      name: 'Match',
      mapName: 'verdantia',
      players: const [],
      maxPlayers: 2,
      minPlayers: 2,
      turn: 1,
      state: state,
      createdAt: DateTime.utc(2026, 7, 30),
      endedAt: endedAt,
      outcomeCondition: outcomeCondition,
      winnerPlayerId: winnerPlayerId,
      autoStartAt: autoStartAt,
    ),
    snapshot: WireSnapshot(
      matchId: 'match-1',
      offset: 0,
      save: const {},
      state: {'phase': state, 'reason': ?abandonmentReason},
    ),
  );
}
