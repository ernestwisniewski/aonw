import 'package:aonw_core/application.dart';
import 'package:test/test.dart';

import 'support/match_lifecycle_machine_cases.dart';

void main() {
  const machine = MatchLifecycleMachine();

  group(
    'MatchLifecycleMachine transition matrix',
    () => registerMatchLifecycleMachineCases(machine),
  );

  group('MatchLifecycleWireAdapter', () {
    const adapter = MatchLifecycleWireAdapter();

    test(
      'round-trips every authoritative state without changing wire values',
      () {
        const values = ['open', 'running'];

        for (final value in values) {
          expect(adapter.encodeState(adapter.decodeState(value)), value);
        }
        expect(
          adapter.encodeState(
            adapter.decodeState('finished', terminalReason: 'conquest'),
          ),
          'finished',
        );
        expect(
          adapter.encodeState(
            adapter.decodeState('abandoned', terminalReason: 'owner_left'),
          ),
          'abandoned',
        );
      },
    );

    test('maps loading as an observed client-only state', () {
      expect(
        adapter.decodeObservedState('loading'),
        isA<LoadingObservedMatchLifecycleState>(),
      );
      expect(
        () => adapter.decodeState('loading'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unknown state instead of treating it as a lobby', () {
      expect(
        () => adapter.decodeState('paused'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('paused'),
          ),
        ),
      );
    });

    test('requires the existing terminal reason metadata', () {
      expect(
        () => adapter.decodeState('finished'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => adapter.decodeState('abandoned'),
        throwsA(isA<FormatException>()),
      );
    });

    test('preserves typed terminal reason codes at the boundary', () {
      expect(
        adapter.decodeFinishedReason('resignation'),
        MatchCompletionReason.resignation,
      );
      expect(
        adapter.encodeFinishedReason(MatchCompletionReason.cultural),
        'cultural',
      );
      expect(
        adapter.decodeAbandonmentReason('quickplay_stale'),
        MatchAbandonmentReason.quickplayStale,
      );
      expect(
        adapter.encodeAbandonmentReason(
          MatchAbandonmentReason.noAlivePlayersAfterResignation,
        ),
        'no_alive_players_after_resignation',
      );
      expect(
        adapter.decodeAbandonmentReason('all_players_inactive'),
        MatchAbandonmentReason.allPlayersInactive,
      );
    });
  });
}
