import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('ParticipantResignationTransition', () {
    test('changes only the resigning participant session slice', () {
      final domain = _domainWithAlivePlayers(const {'p2', 'p3'});
      final session = _session();

      final result = ParticipantResignationTransition.apply(
        domain: domain,
        session: session,
        actorPlayerId: 'p1',
        orderedHumanPlayerIds: const ['p1', 'p2', 'p3'],
      );

      expect(result.changed, isTrue);
      expect(result.disposition, ParticipantResignationDisposition.running);
      expect(result.outcome, isNull);
      expect(result.abandonmentReason, isNull);
      expect(
        result.session,
        session.copyWith(
          turnStatesByPlayerId: const {
            'p1': PlayerTurnState.finished,
            'p2': PlayerTurnState.active,
            'p3': PlayerTurnState.active,
          },
          submittedPlayerIds: const {'p2'},
          afkPlayerIds: const {'existing-afk', 'p1'},
          kickedPlayerIds: const {'existing-kicked', 'p1'},
        ),
      );
      expect(domain.turn, 17);
      expect(
        domain.units.map((unit) => unit.ownerPlayerId),
        unorderedEquals(['p2', 'p3']),
      );
      expect(session.turnStatesByPlayerId['p1'], PlayerTurnState.active);
      expect(session.submittedPlayerIds, {'p1', 'p2'});
      expect(session.kickedPlayerIds, {'existing-kicked'});
    });

    test('does not synthesize a missing turn state', () {
      final session = _session(
        turnStatesByPlayerId: const {
          'p2': PlayerTurnState.active,
          'p3': PlayerTurnState.active,
        },
      );

      final result = ParticipantResignationTransition.apply(
        domain: _domainWithAlivePlayers(const {'p2', 'p3'}),
        session: session,
        actorPlayerId: 'p1',
        orderedHumanPlayerIds: const ['p1', 'p2', 'p3'],
      );

      expect(result.session.turnStatesByPlayerId, isNot(contains('p1')));
      expect(result.session.kickedPlayerIds, contains('p1'));
      expect(result.session.afkPlayerIds, contains('p1'));
    });

    test('accepts an authoritative roster actor absent from the domain', () {
      final result = ParticipantResignationTransition.apply(
        domain: _domainWithAlivePlayers(const {'p2', 'p3'}),
        session: _session(),
        actorPlayerId: 'wire-only',
        orderedHumanPlayerIds: const ['wire-only', 'p2', 'p3'],
      );

      expect(result.disposition, ParticipantResignationDisposition.running);
      expect(result.session.turnStatesByPlayerId, isNot(contains('wire-only')));
      expect(result.session.kickedPlayerIds, contains('wire-only'));
      expect(result.session.afkPlayerIds, contains('wire-only'));
    });

    test('returns the original session when the actor is already kicked', () {
      final session = _session(kickedPlayerIds: const {'p1'});

      final result = ParticipantResignationTransition.apply(
        domain: _domainWithAlivePlayers(const {'p2'}),
        session: session,
        actorPlayerId: 'p1',
        orderedHumanPlayerIds: _throwingRoster(),
      );

      expect(result.changed, isFalse);
      expect(result.disposition, ParticipantResignationDisposition.unchanged);
      expect(result.session, same(session));
      expect(result.outcome, isNull);
      expect(result.abandonmentReason, isNull);
    });

    test('finishes with the only living human from the supplied roster', () {
      final result = ParticipantResignationTransition.apply(
        domain: _domainWithAlivePlayers(const {'p2', 'domain-phantom'}),
        session: _session(),
        actorPlayerId: 'p1',
        orderedHumanPlayerIds: const ['', 'p1', 'p2', 'p2', 'p3'],
      );

      expect(result.disposition, ParticipantResignationDisposition.finished);
      expect(result.outcome, const GameOutcome.resignation('p2'));
      expect(result.abandonmentReason, isNull);
    });

    test('ignores living players outside the authoritative human roster', () {
      final result = ParticipantResignationTransition.apply(
        domain: _domainWithAlivePlayers(const {'domain-phantom', 'wire-ai'}),
        session: _session(),
        actorPlayerId: 'p1',
        orderedHumanPlayerIds: const ['p1', 'p2', 'p3'],
      );

      expect(result.disposition, ParticipantResignationDisposition.abandoned);
      expect(
        result.abandonmentReason,
        ParticipantResignationAbandonmentReason.noAlivePlayersAfterResignation,
      );
      expect(result.outcome, isNull);
    });

    test('distinguishes no living humans from all humans resigned', () {
      final noLivingHumans = ParticipantResignationTransition.apply(
        domain: _domainWithAlivePlayers(const {}),
        session: _session(),
        actorPlayerId: 'p1',
        orderedHumanPlayerIds: const ['p1', 'p2'],
      );
      final allResigned = ParticipantResignationTransition.apply(
        domain: _domainWithAlivePlayers(const {}),
        session: _session(kickedPlayerIds: const {'p2'}),
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

    test('keeps malformed Wire seats in the abandonment classification', () {
      final result = ParticipantResignationTransition.apply(
        domain: _domainWithAlivePlayers(const {}),
        session: _session(),
        actorPlayerId: 'p1',
        orderedHumanPlayerIds: const ['p1', ''],
      );

      expect(result.disposition, ParticipantResignationDisposition.abandoned);
      expect(
        result.abandonmentReason,
        ParticipantResignationAbandonmentReason.noAlivePlayersAfterResignation,
      );
    });

    test('does not mutate caller-owned roster or session collections', () {
      final roster = ['p1', 'p2', 'p3'];
      final turnStates = <String, PlayerTurnState>{
        'p1': PlayerTurnState.active,
        'p2': PlayerTurnState.active,
        'p3': PlayerTurnState.active,
      };
      final submitted = {'p1', 'p2'};
      final afk = {'existing-afk'};
      final kicked = {'existing-kicked'};
      final session = _session(
        turnStatesByPlayerId: turnStates,
        submittedPlayerIds: submitted,
        afkPlayerIds: afk,
        kickedPlayerIds: kicked,
      );

      ParticipantResignationTransition.apply(
        domain: _domainWithAlivePlayers(const {'p2', 'p3'}),
        session: session,
        actorPlayerId: 'p1',
        orderedHumanPlayerIds: roster,
      );

      expect(roster, ['p1', 'p2', 'p3']);
      expect(turnStates['p1'], PlayerTurnState.active);
      expect(submitted, {'p1', 'p2'});
      expect(afk, {'existing-afk'});
      expect(kicked, {'existing-kicked'});
    });

    test('rejects an empty actor identifier', () {
      expect(
        () => ParticipantResignationTransition.apply(
          domain: _domainWithAlivePlayers(const {'p2'}),
          session: _session(),
          actorPlayerId: '',
          orderedHumanPlayerIds: const ['p1', 'p2'],
        ),
        throwsArgumentError,
      );
    });
  });
}

DomainState _domainWithAlivePlayers(Set<String> alivePlayerIds) {
  const participantIds = [
    'p1',
    'p2',
    'p3',
    'domain-phantom',
    'wire-ai',
    'existing-afk',
    'existing-kicked',
  ];
  return DomainState.snapshot(
    turn: 17,
    matchRules: MatchRules.standard,
    participants: [
      for (var index = 0; index < participantIds.length; index++)
        Player(
          id: participantIds[index],
          name: participantIds[index],
          colorValue: Player.palette[index % Player.palette.length],
        ),
    ],
    units: [
      for (final (index, playerId) in alivePlayerIds.indexed)
        GameUnit.startingWarrior(ownerPlayerId: playerId, col: index, row: 0),
    ],
  );
}

MatchSessionState _session({
  Map<String, PlayerTurnState> turnStatesByPlayerId = const {
    'p1': PlayerTurnState.active,
    'p2': PlayerTurnState.active,
    'p3': PlayerTurnState.active,
  },
  Set<String> submittedPlayerIds = const {'p1', 'p2'},
  Set<String> afkPlayerIds = const {'existing-afk'},
  Set<String> kickedPlayerIds = const {'existing-kicked'},
}) {
  return MatchSessionState.snapshot(
    gameMode: GameMode.multiplayer,
    turnStatesByPlayerId: turnStatesByPlayerId,
    submittedPlayerIds: submittedPlayerIds,
    timeoutStreaksByPlayerId: const {'p2': 4},
    afkPlayerIds: afkPlayerIds,
    kickedPlayerIds: kickedPlayerIds,
    turnStartedAt: DateTime.utc(2026, 7, 21, 11, 55),
  );
}

Iterable<String> _throwingRoster() sync* {
  throw StateError('The roster must not be read for an unchanged result.');
}
