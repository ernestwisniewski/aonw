import 'package:aonw_core/application.dart';
import 'package:test/test.dart';

void main() {
  group('TimeoutActorSelector', () {
    test('prefers submitted players in participant order', () {
      expect(
        TimeoutActorSelector.select(
          orderedParticipantPlayerIds: const ['seat-2', 'seat-1', 'seat-3'],
          submittedPlayerIds: const {'seat-1', 'seat-2'},
          kickedPlayerIds: const {},
        ),
        'seat-2',
      );
    });

    test('prefers a later submitted player over an earlier fallback', () {
      expect(
        TimeoutActorSelector.select(
          orderedParticipantPlayerIds: const ['fallback', 'submitted'],
          submittedPlayerIds: const {'submitted'},
          kickedPlayerIds: const {},
        ),
        'submitted',
      );
    });

    test('uses participant order when no player submitted', () {
      expect(
        TimeoutActorSelector.select(
          orderedParticipantPlayerIds: const ['seat-3', 'seat-1', 'seat-2'],
          submittedPlayerIds: const {},
          kickedPlayerIds: const {},
        ),
        'seat-3',
      );
    });

    test('deduplicates participants and ignores empty identifiers', () {
      expect(
        TimeoutActorSelector.select(
          orderedParticipantPlayerIds: const ['', 'seat-2', 'seat-2', 'seat-1'],
          submittedPlayerIds: const {},
          kickedPlayerIds: const {},
        ),
        'seat-2',
      );
    });

    test('skips kicked players in submitted and fallback passes', () {
      expect(
        TimeoutActorSelector.select(
          orderedParticipantPlayerIds: const ['kicked', 'active'],
          submittedPlayerIds: const {'kicked'},
          kickedPlayerIds: const {'kicked'},
        ),
        'active',
      );
      expect(
        TimeoutActorSelector.select(
          orderedParticipantPlayerIds: const ['kicked', 'active'],
          submittedPlayerIds: const {},
          kickedPlayerIds: const {'kicked'},
        ),
        'active',
      );
    });

    test('does not admit foreign submitted or kicked identifiers', () {
      expect(
        TimeoutActorSelector.select(
          orderedParticipantPlayerIds: const ['seat-2', 'seat-1'],
          submittedPlayerIds: const {'foreign-submitted'},
          kickedPlayerIds: const {'foreign-kicked'},
        ),
        'seat-2',
      );
    });

    test('returns null without an eligible participant', () {
      expect(
        TimeoutActorSelector.select(
          orderedParticipantPlayerIds: const ['', 'kicked', 'kicked'],
          submittedPlayerIds: const {'kicked'},
          kickedPlayerIds: const {'kicked'},
        ),
        isNull,
      );
    });

    test('does not mutate caller-owned collections', () {
      final participants = ['seat-2', '', 'seat-1', 'seat-2'];
      final submitted = {'seat-1'};
      final kicked = {'foreign'};

      TimeoutActorSelector.select(
        orderedParticipantPlayerIds: participants,
        submittedPlayerIds: submitted,
        kickedPlayerIds: kicked,
      );

      expect(participants, ['seat-2', '', 'seat-1', 'seat-2']);
      expect(submitted, {'seat-1'});
      expect(kicked, {'foreign'});
    });
  });
}
