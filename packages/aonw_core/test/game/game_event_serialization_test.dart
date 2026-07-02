import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('GameEventSerializer', () {
    GameEvent roundTrip(GameEvent event) {
      return GameEventSerializer.fromJson(GameEventSerializer.toJson(event));
    }

    test('round-trips representative gameplay events', () {
      final events = <GameEvent>[
        const CityFoundedEvent(cityId: 'city_1', ownerPlayerId: 'player_1'),
        const CityBuiltBuildingEvent(
          cityId: 'city_1',
          buildingType: CityBuildingType.granary,
        ),
        const CityProducedUnitEvent(
          cityId: 'city_1',
          unitType: GameUnitType.warrior,
          producedUnitId: 'warrior_1',
        ),
        const UnitMovedEvent(
          unitId: 'warrior_1',
          fromCol: 1,
          fromRow: 1,
          toCol: 2,
          toRow: 1,
        ),
        CombatResolvedEvent(
          attackerUnitId: 'attacker',
          defenderUnitId: 'defender',
          outcome: _sampleOutcome(),
        ),
        const UnitKilledEvent(
          unitId: 'defender',
          ownerPlayerId: 'player_2',
          attackerUnitId: 'attacker',
        ),
        const CityDestroyedEvent(
          cityId: 'city_2',
          previousOwnerPlayerId: 'player_2',
          attackerOwnerPlayerId: 'player_1',
        ),
        const TechnologyResearchedEvent(
          playerId: 'player_1',
          technologyId: TechnologyId.mining,
        ),
        const StrategicResourceDiscoveredEvent(
          playerId: 'player_1',
          resourceType: ResourceType.oil,
          controlledCount: 1,
          rivalControlledCount: 0,
          unclaimedCount: 2,
          pressure: StrategicResourceDiscoveryPressure.expansionRace,
          nearestUnclaimedCol: 4,
          nearestUnclaimedRow: 1,
        ),
        const MapObjectiveSecuredEvent(
          playerId: 'player_1',
          objectiveId: 'pass_1',
          objectiveType: MapObjectiveType.strategicPass,
          col: 2,
          row: 1,
          holdTurns: 3,
          requiredHoldTurns: 3,
          victoryPoints: 2,
          goldPerTurn: 1,
        ),
        const CivilizationMetEvent(
          playerId: 'player_1',
          metPlayerId: 'player_2',
        ),
        const DiplomaticProposalSentEvent(
          proposalId: 'proposal_1',
          fromPlayerId: 'player_1',
          toPlayerId: 'player_2',
          kind: DiplomaticProposalKind.friendship,
          expiresOnTurn: 12,
        ),
        const DiplomaticProposalRespondedEvent(
          proposalId: 'proposal_1',
          fromPlayerId: 'player_1',
          toPlayerId: 'player_2',
          kind: DiplomaticProposalKind.friendship,
          accepted: true,
        ),
        const DiplomaticProposalExpiredEvent(
          proposalId: 'proposal_2',
          fromPlayerId: 'player_1',
          toPlayerId: 'player_2',
          kind: DiplomaticProposalKind.truce,
        ),
        const DiplomaticRelationChangedEvent(
          playerAId: 'player_1',
          playerBId: 'player_2',
          oldStatus: DiplomaticRelationStatus.neutral,
          newStatus: DiplomaticRelationStatus.war,
          reason: DiplomaticRelationChangeReason.declarationOfWar,
        ),
        const DiplomaticMessageSentEvent(
          messageId: 'message_1',
          fromPlayerId: 'player_1',
          toPlayerId: 'player_2',
          topic: DiplomaticMessageTopic.citiesTooClose,
          category: DiplomaticMessageCategory.complaint,
          expiresOnTurn: 13,
        ),
        const DiplomaticMessageRespondedEvent(
          messageId: 'message_1',
          fromPlayerId: 'player_1',
          toPlayerId: 'player_2',
          topic: DiplomaticMessageTopic.citiesTooClose,
          response: DiplomaticMessageResponse.evasive,
          relationDelta: -8,
          relationScoreAfter: -18,
          promiseDueTurn: 16,
        ),
        const DiplomaticScoreChangedEvent(
          playerAId: 'player_1',
          playerBId: 'player_2',
          delta: -8,
          scoreAfter: -18,
          reason: DiplomaticScoreChangeReason.messageResponse,
          sourceId: 'message_1',
        ),
        const DiplomaticPromiseBrokenEvent(
          messageId: 'message_1',
          playerAId: 'player_1',
          playerBId: 'player_2',
          delta: -15,
          scoreAfter: -33,
        ),
        const DominationThresholdReachedEvent(
          playerId: 'player_1',
          controlPercent: 50,
          requiredControlPercent: 42,
          holdTurns: 1,
          requiredHoldTurns: 4,
        ),
        const StabilityBandChangedEvent(
          playerId: 'player_1',
          previousBand: StabilityBand.stable,
          newBand: StabilityBand.strained,
          net: -2,
        ),
        const CommandRejectedEvent(reason: 'turn_already_submitted'),
        AllPlayersSubmittedEvent(
          turn: 7,
          playerIds: const ['player_1', 'player_2'],
        ),
        const PlayerTimedOutEvent(turn: 7, playerId: 'player_2'),
        const TurnAutoResolvedEvent(
          turn: 7,
          playerId: 'player_2',
          unitOrderCount: 2,
          cityProductionCount: 1,
          researchSelected: true,
        ),
        const PlayerKickedEvent(
          turn: 7,
          playerId: 'player_2',
          reason: 'turn_timeout',
          timeoutStreak: 3,
        ),
      ];

      for (final event in events) {
        final restored = roundTrip(event);
        expect(restored.runtimeType, event.runtimeType);
        expect(
          GameEventSerializer.toJson(restored),
          GameEventSerializer.toJson(event),
        );
      }
    });

    test('encodes system events through shared wire helpers', () {
      expect(
        GameEventSerializer.toJson(
          AllPlayersSubmittedEvent(
            turn: 3,
            playerIds: const ['player_1', 'player_2'],
          ),
        ),
        {
          'type': 'AllPlayersSubmittedEvent',
          'turn': 3,
          'playerIds': ['player_1', 'player_2'],
        },
      );
    });

    test('decodes combat outcome payload', () {
      final event = roundTrip(
        CombatResolvedEvent(
          attackerUnitId: 'attacker',
          defenderUnitId: 'defender',
          outcome: _sampleOutcome(),
        ),
      );

      expect(event, isA<CombatResolvedEvent>());
      expect((event as CombatResolvedEvent).outcome, _sampleOutcome());
    });

    test('infers strategic resource pressure from older payloads', () {
      final event = GameEventSerializer.fromJson({
        'type': 'StrategicResourceDiscovered',
        'playerId': 'player_1',
        'resourceType': 'oil',
        'controlledCount': 0,
        'rivalControlledCount': 2,
        'unclaimedCount': 0,
      });

      expect(event, isA<StrategicResourceDiscoveredEvent>());
      expect(
        (event as StrategicResourceDiscoveredEvent).pressure,
        StrategicResourceDiscoveryPressure.rivalMonopoly,
      );
    });

    test('rejects missing discriminator', () {
      expect(
        () => GameEventSerializer.fromJson({}),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'GameEvent.type',
          ),
        ),
      );
    });

    test('rejects malformed player list', () {
      expect(
        () => GameEventSerializer.fromJson({
          'type': 'AllPlayersSubmittedEvent',
          'turn': 3,
          'playerIds': ['player_1', ''],
        }),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'AllPlayersSubmittedEvent.playerIds',
          ),
        ),
      );
    });
  });
}

CombatOutcome _sampleOutcome() {
  return CombatOutcome(
    attackerUnitId: 'attacker',
    defenderUnitId: 'defender',
    attackerHpAfter: 7,
    defenderHpAfter: 0,
    attackerKilled: false,
    defenderKilled: true,
    steps: [
      AttackStep(
        damage: 5,
        active: const [
          TerrainModifier(
            label: 'terrain.hills',
            target: CombatStatTarget.attack,
            delta: 1,
          ),
        ],
      ),
      const RollStep(seed: 7, value: 0),
    ],
  );
}
