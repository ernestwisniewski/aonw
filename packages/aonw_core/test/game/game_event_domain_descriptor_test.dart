import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('GameEventDomainDescriptor', () {
    test('describes combat hostility and war-weariness activity', () {
      const event = UnitAttackedEvent(
        attackerUnitId: 'attacker',
        attackerOwnerPlayerId: 'player_1',
        defenderUnitId: 'defender',
        defenderOwnerPlayerId: 'player_2',
      );

      final descriptor = GameEventDomainDescriptor.forEvent(event);

      expect(descriptor.combat, isTrue);
      expect(descriptor.attackingPlayerIds, ['player_1']);
      expect(descriptor.hostilities, hasLength(1));
      expect(descriptor.hostilities.single.victimPlayerId, 'player_2');
      expect(descriptor.hostilities.single.hostilePlayerId, 'player_1');
      expect(descriptor.hostilePlayerIdFor(playerId: 'player_2'), 'player_1');
      expect(
        descriptor.belongsToPlayer(
          playerId: 'player_1',
          state: const PersistentGameState(),
        ),
        isTrue,
      );
    });

    test('describes symmetric war and signed peace', () {
      const war = DiplomaticRelationChangedEvent(
        playerAId: 'player_1',
        playerBId: 'player_2',
        oldStatus: DiplomaticRelationStatus.hostile,
        newStatus: DiplomaticRelationStatus.war,
        reason: DiplomaticRelationChangeReason.declarationOfWar,
      );
      const peace = DiplomaticRelationChangedEvent(
        playerAId: 'player_1',
        playerBId: 'player_2',
        oldStatus: DiplomaticRelationStatus.war,
        newStatus: DiplomaticRelationStatus.truce,
        reason: DiplomaticRelationChangeReason.proposalAccepted,
      );

      final warDescriptor = GameEventDomainDescriptor.forEvent(war);
      final peaceDescriptor = GameEventDomainDescriptor.forEvent(peace);

      expect(warDescriptor.hostilities, hasLength(2));
      expect(warDescriptor.signedPeacePlayerIds, isEmpty);
      expect(peaceDescriptor.hostilities, isEmpty);
      expect(peaceDescriptor.signedPeacePlayerIds, {'player_1', 'player_2'});
    });

    test('resolves entity ownership from the previous state', () {
      final previousState = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'worker',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 2,
            row: 3,
          ),
        ],
      );
      final descriptor = GameEventDomainDescriptor.forEvent(
        const WorkerCompletedJobEvent(unitId: 'worker'),
      );

      expect(
        descriptor.belongsToPlayer(
          playerId: 'player_1',
          state: const PersistentGameState(),
          previousState: previousState,
        ),
        isTrue,
      );
    });

    test('routes a city kill event to the attacking city owner', () {
      const state = PersistentGameState(
        cities: [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Warszawa',
            center: CityHex(col: 2, row: 3),
          ),
        ],
      );
      final descriptor = GameEventDomainDescriptor.forEvent(
        const UnitKilledEvent(
          unitId: 'attacker',
          ownerPlayerId: 'player_2',
          attackerUnitId: 'city_1',
        ),
      );

      expect(
        descriptor.isVisibleToPlayer(playerId: 'player_1', state: state),
        isTrue,
      );
      expect(
        descriptor.isVisibleToPlayer(playerId: 'player_2', state: state),
        isTrue,
      );
    });

    test('keeps asymmetric civilization events visible to their subject', () {
      final descriptor = GameEventDomainDescriptor.forEvent(
        const CivilizationMetEvent(
          playerId: 'player_1',
          metPlayerId: 'player_2',
        ),
      );

      expect(
        descriptor.isVisibleToPlayer(
          playerId: 'player_1',
          state: const PersistentGameState(),
        ),
        isTrue,
      );
      expect(
        descriptor.isVisibleToPlayer(
          playerId: 'player_2',
          state: const PersistentGameState(),
        ),
        isFalse,
      );
    });

    test('marks turn completion as visible to every participant', () {
      final descriptor = GameEventDomainDescriptor.forEvent(
        AllPlayersSubmittedEvent(turn: 4, playerIds: const ['p1', 'p2']),
      );

      expect(descriptor.visibleToAllPlayers, isTrue);
      expect(
        descriptor.isVisibleToPlayer(
          playerId: 'p2',
          state: const PersistentGameState(),
        ),
        isTrue,
      );
    });

    test('marks domination threshold alerts as globally visible', () {
      final descriptor = GameEventDomainDescriptor.forEvent(
        const DominationThresholdReachedEvent(
          playerId: 'p1',
          controlPercent: 51,
          requiredControlPercent: 50,
          holdTurns: 1,
          requiredHoldTurns: 3,
        ),
      );

      expect(descriptor.visibleToAllPlayers, isTrue);
      expect(
        descriptor.isVisibleToPlayer(
          playerId: 'p2',
          state: const PersistentGameState(),
        ),
        isTrue,
      );
    });

    test('routes player system and research events only to their player', () {
      for (final event in <GameEvent>[
        const ResearchPointsGainedEvent(playerId: 'p1', points: 3),
        const PlayerTimedOutEvent(turn: 2, playerId: 'p1'),
        const TurnAutoResolvedEvent(
          turn: 2,
          playerId: 'p1',
          unitOrderCount: 1,
          cityProductionCount: 1,
          researchSelected: true,
        ),
        const PlayerKickedEvent(
          turn: 2,
          playerId: 'p1',
          reason: 'timeout',
          timeoutStreak: 3,
        ),
      ]) {
        final descriptor = GameEventDomainDescriptor.forEvent(event);
        expect(
          descriptor.isVisibleToPlayer(
            playerId: 'p1',
            state: const PersistentGameState(),
          ),
          isTrue,
          reason: event.runtimeType.toString(),
        );
        expect(
          descriptor.isVisibleToPlayer(
            playerId: 'p2',
            state: const PersistentGameState(),
          ),
          isFalse,
          reason: event.runtimeType.toString(),
        );
      }
    });
  });
}
