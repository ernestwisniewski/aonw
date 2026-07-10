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
  });
}
