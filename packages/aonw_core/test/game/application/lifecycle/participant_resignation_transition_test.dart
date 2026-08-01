import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('ParticipantResignationTransition', () {
    test('returns running when multiple non-resigned humans remain', () {
      final domain = _domain(
        alivePlayerIds: const {'p2', 'p3'},
        kickedPlayerIds: const {'p1'},
      );

      final result = ParticipantResignationTransition.resolve(
        domain: domain,
        orderedHumanPlayerIds: const ['p1', 'p2', 'p3'],
      );

      expect(result.disposition, ParticipantResignationDisposition.running);
    });

    test('finishes with the only living human in the supplied roster', () {
      final result = ParticipantResignationTransition.resolve(
        domain: _domain(
          alivePlayerIds: const {'p2', 'domain-phantom'},
          kickedPlayerIds: const {'p1'},
        ),
        orderedHumanPlayerIds: const ['p1', 'p2', 'p3'],
      );

      expect(result.disposition, ParticipantResignationDisposition.finished);
      expect(result.outcome, const GameOutcome.resignation('p2'));
    });

    test('distinguishes all resigned from no living humans', () {
      final noLivingHumans = ParticipantResignationTransition.resolve(
        domain: _domain(
          alivePlayerIds: const {},
          kickedPlayerIds: const {'p1'},
        ),
        orderedHumanPlayerIds: const ['p1', 'p2'],
      );
      final allResigned = ParticipantResignationTransition.resolve(
        domain: _domain(
          alivePlayerIds: const {},
          kickedPlayerIds: const {'p1', 'p2'},
        ),
        orderedHumanPlayerIds: const ['p1', 'p2'],
      );

      expect(
        noLivingHumans.abandonmentReason,
        ParticipantResignationAbandonmentReason.noAlivePlayersAfterResignation,
      );
      expect(
        allResigned.abandonmentReason,
        ParticipantResignationAbandonmentReason.allPlayersResigned,
      );
    });
  });
}

DomainState _domain({
  required Set<String> alivePlayerIds,
  Set<String> kickedPlayerIds = const {},
}) {
  const participantIds = ['p1', 'p2', 'p3', 'domain-phantom'];
  return DomainState.snapshot(
    turn: 17,
    participants: [
      for (var index = 0; index < participantIds.length; index++)
        Player(
          id: participantIds[index],
          name: participantIds[index],
          colorValue: Player.palette[index % Player.palette.length],
        ),
    ],
    gameMode: GameMode.multiplayer,
    turnStatesByPlayerId: const {
      'p1': PlayerTurnState.active,
      'p2': PlayerTurnState.active,
      'p3': PlayerTurnState.active,
    },
    submittedPlayerIds: const {'p1', 'p2'},
    kickedPlayerIds: kickedPlayerIds,
    units: [
      for (final (index, playerId) in alivePlayerIds.indexed)
        GameUnit.startingWarrior(ownerPlayerId: playerId, col: index, row: 0),
    ],
  );
}
