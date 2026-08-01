import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('ParticipantResignationTransition', () {
    test('updates lifecycle in the same canonical domain state', () {
      final domain = _domain(alivePlayerIds: const {'p2', 'p3'});

      final result = ParticipantResignationTransition.apply(
        domain: domain,
        actorPlayerId: 'p1',
        orderedHumanPlayerIds: const ['p1', 'p2', 'p3'],
      );

      expect(result.disposition, ParticipantResignationDisposition.running);
      expect(result.domain.units, same(domain.units));
      expect(result.domain.turn, domain.turn);
      expect(
        result.domain.turnStatesByPlayerId['p1'],
        PlayerTurnState.finished,
      );
      expect(result.domain.submittedPlayerIds, const {'p2'});
      expect(result.domain.afkPlayerIds, contains('p1'));
      expect(result.domain.kickedPlayerIds, contains('p1'));
    });

    test('returns the same state when the actor is already kicked', () {
      final domain = _domain(
        alivePlayerIds: const {'p2'},
        kickedPlayerIds: const {'p1'},
      );

      final result = ParticipantResignationTransition.apply(
        domain: domain,
        actorPlayerId: 'p1',
        orderedHumanPlayerIds: _throwingRoster(),
      );

      expect(result.disposition, ParticipantResignationDisposition.unchanged);
      expect(result.domain, same(domain));
    });

    test('finishes with the only living human in the supplied roster', () {
      final result = ParticipantResignationTransition.apply(
        domain: _domain(alivePlayerIds: const {'p2', 'domain-phantom'}),
        actorPlayerId: 'p1',
        orderedHumanPlayerIds: const ['p1', 'p2', 'p3'],
      );

      expect(result.disposition, ParticipantResignationDisposition.finished);
      expect(result.outcome, const GameOutcome.resignation('p2'));
    });

    test('distinguishes all resigned from no living humans', () {
      final noLivingHumans = ParticipantResignationTransition.apply(
        domain: _domain(alivePlayerIds: const {}),
        actorPlayerId: 'p1',
        orderedHumanPlayerIds: const ['p1', 'p2'],
      );
      final allResigned = ParticipantResignationTransition.apply(
        domain: _domain(
          alivePlayerIds: const {},
          kickedPlayerIds: const {'p2'},
        ),
        actorPlayerId: 'p1',
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

    test('rejects an empty actor identifier', () {
      expect(
        () => ParticipantResignationTransition.apply(
          domain: _domain(alivePlayerIds: const {'p2'}),
          actorPlayerId: '',
          orderedHumanPlayerIds: const ['p1', 'p2'],
        ),
        throwsArgumentError,
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

Iterable<String> _throwingRoster() sync* {
  throw StateError('The roster must not be read for an unchanged result.');
}
