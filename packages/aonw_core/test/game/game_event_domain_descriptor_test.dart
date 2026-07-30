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
          previous: GameEventOwnershipIndex.empty,
          next: GameEventOwnershipIndex.empty,
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

    test('resolves entity ownership from the previous index', () {
      final previousOwnership = GameEventOwnershipIndex.from([
        GameUnit.produced(
          id: 'worker',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 2,
          row: 3,
        ),
      ], const []);
      final descriptor = GameEventDomainDescriptor.forEvent(
        const WorkerCompletedJobEvent(unitId: 'worker'),
      );

      expect(
        descriptor.belongsToPlayer(
          playerId: 'player_1',
          previous: previousOwnership,
          next: GameEventOwnershipIndex.empty,
        ),
        isTrue,
      );
    });

    test('preserves ordered previous, next, global, and closed modes', () {
      final previousOwnership = GameEventOwnershipIndex.from([
        GameUnit.produced(
          id: 'removed-worker',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 2,
          row: 3,
        ),
      ], const []);
      final nextOwnership = GameEventOwnershipIndex.from(const [], const [
        GameCity(
          id: 'current-city',
          ownerPlayerId: 'player_2',
          name: 'Current city',
          center: CityHex(col: 2, row: 3),
        ),
      ]);
      final descriptors = [
        GameEventDomainDescriptor.forEvent(
          const WorkerCompletedJobEvent(unitId: 'removed-worker'),
        ),
        GameEventDomainDescriptor.forEvent(
          const CityClaimedHexEvent(cityId: 'current-city', col: 2, row: 3),
        ),
        GameEventDomainDescriptor.forEvent(
          AllPlayersSubmittedEvent(
            turn: 4,
            playerIds: const ['player_1', 'player_2'],
          ),
        ),
        GameEventDomainDescriptor.forEvent(
          const CommandRejectedEvent(reason: 'fail-closed'),
        ),
      ];

      expect(
        [
          for (final descriptor in descriptors)
            [
              for (final playerId in const ['player_1', 'player_2', 'observer'])
                descriptor.isVisibleToPlayer(
                  playerId: playerId,
                  previous: previousOwnership,
                  next: nextOwnership,
                ),
            ],
        ],
        const [
          [true, false, false],
          [false, true, false],
          [true, true, true],
          [false, false, false],
        ],
      );
    });

    test('routes a city kill event to the attacking city owner', () {
      final ownership = GameEventOwnershipIndex.from(const [], const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Warszawa',
          center: CityHex(col: 2, row: 3),
        ),
      ]);
      final descriptor = GameEventDomainDescriptor.forEvent(
        const UnitKilledEvent(
          unitId: 'attacker',
          ownerPlayerId: 'player_2',
          attackerUnitId: 'city_1',
        ),
      );

      expect(
        _isVisible(descriptor, 'player_1', nextOwnership: ownership),
        isTrue,
      );
      expect(
        _isVisible(descriptor, 'player_2', nextOwnership: ownership),
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

      expect(_isVisible(descriptor, 'player_1'), isTrue);
      expect(_isVisible(descriptor, 'player_2'), isFalse);
    });

    test('marks turn completion as visible to every participant', () {
      final descriptor = GameEventDomainDescriptor.forEvent(
        AllPlayersSubmittedEvent(turn: 4, playerIds: const ['p1', 'p2']),
      );

      expect(descriptor.visibleToAllPlayers, isTrue);
      expect(_isVisible(descriptor, 'p2'), isTrue);
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
      expect(_isVisible(descriptor, 'p2'), isTrue);
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
          _isVisible(descriptor, 'p1'),
          isTrue,
          reason: event.runtimeType.toString(),
        );
        expect(
          _isVisible(descriptor, 'p2'),
          isFalse,
          reason: event.runtimeType.toString(),
        );
      }
    });

    test('routes fortification threats only to the fortifying player', () {
      final descriptor = GameEventDomainDescriptor.forEvent(
        FortifiedUnitThreatenedEvent(
          unitId: 'fortifier',
          ownerPlayerId: 'player_1',
          targets: const [
            FortifiedUnitThreatTarget(unitId: 'enemy', col: 3, row: 2),
          ],
        ),
      );

      expect(_isVisible(descriptor, 'player_1'), isTrue);
      expect(_isVisible(descriptor, 'player_2'), isFalse);
      expect(_isVisible(descriptor, 'observer'), isFalse);
    });
  });
}

bool _isVisible(
  GameEventDomainDescriptor descriptor,
  String playerId, {
  GameEventOwnershipIndex previousOwnership = GameEventOwnershipIndex.empty,
  GameEventOwnershipIndex nextOwnership = GameEventOwnershipIndex.empty,
}) {
  return descriptor.isVisibleToPlayer(
    playerId: playerId,
    previous: previousOwnership,
    next: nextOwnership,
  );
}
