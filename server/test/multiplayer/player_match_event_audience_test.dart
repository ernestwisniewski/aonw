import 'package:aonw_core/domain.dart';
import 'package:aonw_server/src/multiplayer/player_match_event_audience.dart';
import 'package:test/test.dart';

void main() {
  group('PlayerMatchEventAudience', () {
    test('uses transition ownership and strips storage-only metadata', () {
      final previousState = PersistentGameState(
        cities: [_city('city-1', ownerPlayerId: 'player-1')],
      );
      final state = PersistentGameState(
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
        previousState: previousState,
        state: state,
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
      final previousState = PersistentGameState(
        units: [_unit('worker-1', ownerPlayerId: 'player-1')],
      );
      final canonical = PlayerMatchEventAudience.annotateForStorage(
        events: const [WorkerCompletedJobEvent(unitId: 'worker-1')],
        participantPlayerIds: const ['player-1', 'player-2'],
        previousState: previousState,
        state: const PersistentGameState(),
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

    test('projects unit and city combat outcomes to both owners', () {
      final previousState = PersistentGameState(
        units: [
          _unit('attacker', ownerPlayerId: 'player-1'),
          _unit('defender', ownerPlayerId: 'player-2'),
        ],
        cities: [_city('city-2', ownerPlayerId: 'player-2')],
      );
      final canonical = PlayerMatchEventAudience.annotateForStorage(
        events: [
          _combatResolved('attacker', 'defender'),
          _combatResolved('attacker', 'city-2'),
        ],
        participantPlayerIds: const ['player-1', 'player-2', 'observer'],
        previousState: previousState,
        state: previousState,
      );

      final attacker = PlayerMatchEventAudience.projectForRecipient(
        canonical,
        recipientPlayerId: 'player-1',
      );
      final defender = PlayerMatchEventAudience.projectForRecipient(
        canonical,
        recipientPlayerId: 'player-2',
      );

      expect(attacker, hasLength(2));
      expect(defender, attacker);
      expect(
        PlayerMatchEventAudience.projectForRecipient(
          canonical,
          recipientPlayerId: 'observer',
        ),
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
        previousState: const PersistentGameState(),
        state: const PersistentGameState(),
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
      final previousState = PersistentGameState(
        units: [_unit('removed-worker', ownerPlayerId: 'player-1')],
      );
      final state = PersistentGameState(
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
        previousState: previousState,
        state: state,
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
