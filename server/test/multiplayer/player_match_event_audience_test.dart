import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_server/src/multiplayer/player_match_event_audience.dart';
import 'package:test/test.dart';

void main() {
  group('PlayerMatchEventAudience', () {
    test('uses transition ownership and strips storage-only metadata', () {
      final previousOwnership = _ownership(
        cities: [_city('city-1', ownerPlayerId: 'player-1')],
      );
      final nextOwnership = _ownership(
        cities: [_city('city-1', ownerPlayerId: 'player-2')],
      );
      final canonical = PlayerMatchEventAudience.annotateForStorage(
        events: const [
          CityCapturedEvent(
            cityId: 'city-1',
            previousOwnerPlayerId: 'player-1',
            newOwnerPlayerId: 'player-2',
          ),
        ],
        participantPlayerIds: const ['player-1', 'player-2', 'observer'],
        previous: previousOwnership,
        next: nextOwnership,
      );
      canonical.single['secret'] = 'must-not-cross-the-wire';

      final previousOwner = PlayerMatchEventAudience.projectForRecipient(
        canonical,
        recipientPlayerId: 'player-1',
      );
      final newOwner = PlayerMatchEventAudience.projectForRecipient(
        canonical,
        recipientPlayerId: 'player-2',
      );
      final observer = PlayerMatchEventAudience.projectForRecipient(
        canonical,
        recipientPlayerId: 'observer',
      );

      expect(previousOwner, hasLength(1));
      expect(newOwner, previousOwner);
      expect(observer, isEmpty);
      expect(previousOwner.single.keys, isNot(contains(startsWith('_'))));
      expect(previousOwner.single, isNot(contains('secret')));
    });

    test('resolves removed entity ownership from the previous state', () {
      final previousOwnership = _ownership(
        units: [_unit('worker-1', ownerPlayerId: 'player-1')],
      );
      final canonical = PlayerMatchEventAudience.annotateForStorage(
        events: const [WorkerCompletedJobEvent(unitId: 'worker-1')],
        participantPlayerIds: const ['player-1', 'player-2'],
        previous: previousOwnership,
        next: GameEventOwnershipIndex.empty,
      );

      expect(
        PlayerMatchEventAudience.projectForRecipient(
          canonical,
          recipientPlayerId: 'player-1',
        ),
        hasLength(1),
      );
      expect(
        PlayerMatchEventAudience.projectForRecipient(
          canonical,
          recipientPlayerId: 'player-2',
        ),
        isEmpty,
      );
    });

    test(
      'projects one ordered combat sequence to owners and visible observers',
      () {
        final ownership = _ownership(
          units: [
            _unit('attacker', ownerPlayerId: 'player-1'),
            _unit('defender', ownerPlayerId: 'player-2'),
          ],
          cities: [_city('city-2', ownerPlayerId: 'player-2')],
        );
        const origin = HexCoordinate(col: 1, row: 1);
        const target = HexCoordinate(col: 2, row: 1);
        final fog = FogOfWarState(
          players: {
            for (final playerId in const ['player-1', 'player-2', 'observer'])
              playerId: PlayerFogOfWar(
                playerId: playerId,
                visibleHexes: {origin, target},
              ),
            'hidden': PlayerFogOfWar(playerId: 'hidden'),
          },
        );
        final events = [
          const UnitAttackedEvent(
            attackerUnitId: 'attacker',
            attackerOwnerPlayerId: 'player-1',
            defenderUnitId: 'defender',
            defenderOwnerPlayerId: 'player-2',
          ),
          _combatResolved('attacker', 'defender'),
          const UnitGainedExperienceEvent(
            unitId: 'attacker',
            ownerPlayerId: 'player-1',
            amount: 1,
            totalExperience: 1,
            rank: UnitVeterancyRank.recruit,
            promoted: false,
          ),
        ];
        final canonical = PlayerMatchEventAudience.annotateForStorage(
          events: events,
          combatAnimations: const [
            CombatAnimationFact(
              eventIndex: 1,
              attackerUnitId: 'attacker',
              defenderId: 'defender',
              attackerFromCol: 1,
              attackerFromRow: 1,
              attackerToCol: 2,
              attackerToRow: 1,
            ),
          ],
          participantPlayerIds: const [
            'player-1',
            'player-2',
            'observer',
            'hidden',
          ],
          previous: ownership,
          next: ownership,
          previousFog: fog,
          nextFog: fog,
        );

        final attacker = PlayerMatchEventAudience.projectForRecipient(
          canonical,
          recipientPlayerId: 'player-1',
        );
        final defender = PlayerMatchEventAudience.projectForRecipient(
          canonical,
          recipientPlayerId: 'player-2',
        );
        final observer = PlayerMatchEventAudience.projectForRecipient(
          canonical,
          recipientPlayerId: 'observer',
        );
        final hidden = PlayerMatchEventAudience.projectForRecipient(
          canonical,
          recipientPlayerId: 'hidden',
        );

        expect(attacker, hasLength(events.length));
        expect(defender, attacker);
        expect(observer, attacker);
        expect(observer[1]['combatAnimation'], const {
          'attackerUnitId': 'attacker',
          'defenderId': 'defender',
          'attackerFromCol': 1,
          'attackerFromRow': 1,
          'attackerToCol': 2,
          'attackerToRow': 1,
        });
        expect(hidden, isEmpty);
        expect(hidden.toString(), isNot(contains('attacker')));
        expect(hidden.toString(), isNot(contains('defender')));
        expect(hidden.toString(), isNot(contains('attackerFromCol')));
      },
    );

    test('requires origin and target on one coherent fog side', () {
      const origin = HexCoordinate(col: 1, row: 1);
      const target = HexCoordinate(col: 2, row: 1);
      final ownership = _ownership(
        units: [
          _unit('attacker', ownerPlayerId: 'player-1'),
          _unit('defender', ownerPlayerId: 'player-2'),
        ],
      );
      const fact = CombatAnimationFact(
        eventIndex: 0,
        attackerUnitId: 'attacker',
        defenderId: 'defender',
        attackerFromCol: 1,
        attackerFromRow: 1,
        attackerToCol: 2,
        attackerToRow: 1,
      );

      List<Map<String, dynamic>> project({
        required Set<HexCoordinate> previousVisible,
        required Set<HexCoordinate> nextVisible,
      }) {
        final canonical = PlayerMatchEventAudience.annotateForStorage(
          events: [_combatResolved('attacker', 'defender')],
          combatAnimations: const [fact],
          participantPlayerIds: const ['observer'],
          previous: ownership,
          next: ownership,
          previousFog: _fog('observer', previousVisible),
          nextFog: _fog('observer', nextVisible),
        );
        return PlayerMatchEventAudience.projectForRecipient(
          canonical,
          recipientPlayerId: 'observer',
        );
      }

      expect(
        project(previousVisible: {origin, target}, nextVisible: const {}),
        hasLength(1),
        reason: 'A lethal battle can remove post-combat visibility.',
      );
      expect(
        project(previousVisible: const {}, nextVisible: {origin, target}),
        hasLength(1),
        reason: 'A battle can create post-combat visibility.',
      );
      expect(
        project(previousVisible: {origin}, nextVisible: {target}),
        isEmpty,
        reason: 'Visibility cannot be assembled across transition sides.',
      );
      expect(
        project(previousVisible: const {}, nextVisible: const {}),
        isEmpty,
      );
    });

    test('makes turn-completion events visible to all participants', () {
      final canonical = PlayerMatchEventAudience.annotateForStorage(
        events: [
          AllPlayersSubmittedEvent(
            turn: 7,
            playerIds: const ['player-1', 'player-2'],
          ),
        ],
        participantPlayerIds: const ['player-1', 'player-2'],
        previous: GameEventOwnershipIndex.empty,
        next: GameEventOwnershipIndex.empty,
      );

      for (final playerId in const ['player-1', 'player-2']) {
        expect(
          PlayerMatchEventAudience.projectForRecipient(
            canonical,
            recipientPlayerId: playerId,
          ),
          hasLength(1),
        );
      }
      expect(
        PlayerMatchEventAudience.projectForRecipient(
          canonical,
          recipientPlayerId: 'not-a-participant',
        ),
        isEmpty,
      );
    });

    test('normalizes participants and preserves ordered ownership modes', () {
      final previousOwnership = _ownership(
        units: [_unit('removed-worker', ownerPlayerId: 'player-1')],
      );
      final nextOwnership = _ownership(
        cities: [_city('current-city', ownerPlayerId: 'player-2')],
      );

      final canonical = PlayerMatchEventAudience.annotateForStorage(
        events: [
          const WorkerCompletedJobEvent(unitId: 'removed-worker'),
          const CityClaimedHexEvent(cityId: 'current-city', col: 2, row: 1),
          AllPlayersSubmittedEvent(
            turn: 7,
            playerIds: const ['player-1', 'player-2'],
          ),
          const CommandRejectedEvent(reason: 'fail-closed'),
        ],
        participantPlayerIds: const [
          'player-2',
          '',
          'observer',
          'player-1',
          'player-2',
        ],
        previous: previousOwnership,
        next: nextOwnership,
      );

      expect(
        canonical.map((event) => event['_serverAudiencePlayerIds']).toList(),
        const [
          ['player-1'],
          ['player-2'],
          ['observer', 'player-1', 'player-2'],
          <String>[],
        ],
      );
    });

    test('redacts legacy events without server-owned audience metadata', () {
      final canonical = [
        GameEventSerializer.toJson(
          const TechnologyResearchedEvent(
            playerId: 'player-1',
            technologyId: TechnologyId.agriculture,
          ),
        ),
      ];

      expect(
        PlayerMatchEventAudience.projectForRecipient(
          canonical,
          recipientPlayerId: 'player-1',
        ),
        isEmpty,
      );
    });

    test('rejects malformed audience metadata instead of exposing events', () {
      final canonical = [
        {
          ...GameEventSerializer.toJson(
            const TechnologyResearchedEvent(
              playerId: 'player-1',
              technologyId: TechnologyId.agriculture,
            ),
          ),
          '_serverAudiencePlayerIds': ['player-1', 7],
        },
      ];

      expect(
        () => PlayerMatchEventAudience.projectForRecipient(
          canonical,
          recipientPlayerId: 'player-1',
        ),
        throwsFormatException,
      );
    });
  });
}

GameEventOwnershipIndex _ownership({
  Iterable<GameUnit> units = const [],
  Iterable<GameCity> cities = const [],
}) {
  return GameEventOwnershipIndex.from(units, cities);
}

GameCity _city(String id, {required String ownerPlayerId}) {
  return GameCity(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: const CityHex(col: 1, row: 1),
  );
}

GameUnit _unit(String id, {required String ownerPlayerId}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.worker,
    name: id,
    col: 1,
    row: 1,
  );
}

CombatResolvedEvent _combatResolved(String attackerId, String defenderId) {
  return CombatResolvedEvent(
    attackerUnitId: attackerId,
    defenderUnitId: defenderId,
    outcome: CombatOutcome(
      attackerUnitId: attackerId,
      defenderUnitId: defenderId,
      attackerHpAfter: 5,
      defenderHpAfter: 4,
      attackerKilled: false,
      defenderKilled: false,
      steps: [AttackStep(damage: 1)],
    ),
  );
}

FogOfWarState _fog(String playerId, Set<HexCoordinate> visibleHexes) {
  return FogOfWarState(
    players: {
      playerId: PlayerFogOfWar(playerId: playerId, visibleHexes: visibleHexes),
    },
  );
}
