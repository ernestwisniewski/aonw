import 'package:aonw/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GameEvent roundTrip(GameEvent e) {
    final json = GameEventSerializer.toJson(e);
    return GameEventSerializer.fromJson(json);
  }

  group('GameEventSerializer', () {
    test('CityFoundedEvent round-trips', () {
      final e = roundTrip(
        const CityFoundedEvent(cityId: 'c1', ownerPlayerId: 'p1'),
      );
      expect(e, isA<CityFoundedEvent>());
      final typed = e as CityFoundedEvent;
      expect(typed.cityId, 'c1');
      expect(typed.ownerPlayerId, 'p1');
    });

    test('CityBuiltBuildingEvent round-trips', () {
      final e = roundTrip(
        const CityBuiltBuildingEvent(
          cityId: 'c2',
          buildingType: CityBuildingType.granary,
        ),
      );
      expect(e, isA<CityBuiltBuildingEvent>());
      final typed = e as CityBuiltBuildingEvent;
      expect(typed.cityId, 'c2');
      expect(typed.buildingType, CityBuildingType.granary);
    });

    test('CityProducedUnitEvent round-trips', () {
      final e = roundTrip(
        const CityProducedUnitEvent(
          cityId: 'c3',
          unitType: GameUnitType.warrior,
          producedUnitId: 'u99',
        ),
      );
      expect(e, isA<CityProducedUnitEvent>());
      final typed = e as CityProducedUnitEvent;
      expect(typed.cityId, 'c3');
      expect(typed.unitType, GameUnitType.warrior);
      expect(typed.producedUnitId, 'u99');
    });

    test('CityClaimedHexEvent round-trips', () {
      final e = roundTrip(
        const CityClaimedHexEvent(cityId: 'c4', col: 5, row: 6),
      );
      expect(e, isA<CityClaimedHexEvent>());
      final typed = e as CityClaimedHexEvent;
      expect(typed.col, 5);
      expect(typed.row, 6);
    });

    test('UnitMovedEvent round-trips', () {
      final e = roundTrip(
        const UnitMovedEvent(
          unitId: 'u1',
          fromCol: 1,
          fromRow: 2,
          toCol: 3,
          toRow: 4,
        ),
      );
      expect(e, isA<UnitMovedEvent>());
      final typed = e as UnitMovedEvent;
      expect(typed.unitId, 'u1');
      expect(typed.fromCol, 1);
      expect(typed.toCol, 3);
    });

    test('UnitGainedExperienceEvent round-trips', () {
      final e = roundTrip(
        const UnitGainedExperienceEvent(
          unitId: 'u1',
          ownerPlayerId: 'p1',
          amount: 3,
          totalExperience: 7,
          rank: UnitVeterancyRank.veteran,
          promoted: true,
        ),
      );
      expect(e, isA<UnitGainedExperienceEvent>());
      final typed = e as UnitGainedExperienceEvent;
      expect(typed.unitId, 'u1');
      expect(typed.ownerPlayerId, 'p1');
      expect(typed.amount, 3);
      expect(typed.totalExperience, 7);
      expect(typed.rank, UnitVeterancyRank.veteran);
      expect(typed.promoted, isTrue);
    });

    test('UnitAttackedEvent round-trips', () {
      final e = roundTrip(
        const UnitAttackedEvent(
          attackerUnitId: 'a1',
          attackerOwnerPlayerId: 'p1',
          defenderUnitId: 'd1',
          defenderOwnerPlayerId: 'p2',
        ),
      );
      expect(e, isA<UnitAttackedEvent>());
      final typed = e as UnitAttackedEvent;
      expect(typed.attackerUnitId, 'a1');
      expect(typed.attackerOwnerPlayerId, 'p1');
      expect(typed.defenderUnitId, 'd1');
      expect(typed.defenderOwnerPlayerId, 'p2');
    });

    test('CombatResolvedEvent round-trips with outcome breakdown', () {
      final e = roundTrip(
        CombatResolvedEvent(
          attackerUnitId: 'a1',
          defenderUnitId: 'd1',
          outcome: _sampleOutcome(),
        ),
      );
      expect(e, isA<CombatResolvedEvent>());
      final typed = e as CombatResolvedEvent;
      expect(typed.attackerUnitId, 'a1');
      expect(typed.defenderUnitId, 'd1');
      expect(typed.outcome, _sampleOutcome());
    });

    test('UnitKilledEvent round-trips', () {
      final e = roundTrip(
        const UnitKilledEvent(
          unitId: 'd1',
          ownerPlayerId: 'p2',
          attackerUnitId: 'a1',
        ),
      );
      expect(e, isA<UnitKilledEvent>());
      final typed = e as UnitKilledEvent;
      expect(typed.unitId, 'd1');
      expect(typed.ownerPlayerId, 'p2');
      expect(typed.attackerUnitId, 'a1');
    });

    test('UnitRetreatedEvent round-trips', () {
      final e = roundTrip(
        const UnitRetreatedEvent(
          unitId: 'd1',
          ownerPlayerId: 'p2',
          fromCol: 2,
          fromRow: 2,
          toCol: 3,
          toRow: 2,
        ),
      );
      expect(e, isA<UnitRetreatedEvent>());
      final typed = e as UnitRetreatedEvent;
      expect(typed.unitId, 'd1');
      expect(typed.ownerPlayerId, 'p2');
      expect(typed.fromCol, 2);
      expect(typed.toCol, 3);
    });

    test('CityCapturedEvent round-trips', () {
      final e = roundTrip(
        const CityCapturedEvent(
          cityId: 'c1',
          previousOwnerPlayerId: 'p2',
          newOwnerPlayerId: 'p1',
        ),
      );
      expect(e, isA<CityCapturedEvent>());
      final typed = e as CityCapturedEvent;
      expect(typed.cityId, 'c1');
      expect(typed.previousOwnerPlayerId, 'p2');
      expect(typed.newOwnerPlayerId, 'p1');
    });

    test('CityDestroyedEvent round-trips', () {
      final e = roundTrip(
        const CityDestroyedEvent(
          cityId: 'c1',
          previousOwnerPlayerId: 'p2',
          attackerOwnerPlayerId: 'p1',
        ),
      );
      expect(e, isA<CityDestroyedEvent>());
      final typed = e as CityDestroyedEvent;
      expect(typed.cityId, 'c1');
      expect(typed.previousOwnerPlayerId, 'p2');
      expect(typed.attackerOwnerPlayerId, 'p1');
    });

    test('TurnEndedEvent round-trips', () {
      final e = roundTrip(const TurnEndedEvent(playerId: 'p2'));
      expect(e, isA<TurnEndedEvent>());
      expect((e as TurnEndedEvent).playerId, 'p2');
    });

    test('WorkerCompletedJobEvent round-trips', () {
      final e = roundTrip(const WorkerCompletedJobEvent(unitId: 'u5'));
      expect(e, isA<WorkerCompletedJobEvent>());
      expect((e as WorkerCompletedJobEvent).unitId, 'u5');
    });

    test('ResearchPointsGainedEvent round-trips', () {
      final e = roundTrip(
        const ResearchPointsGainedEvent(playerId: 'p1', points: 12),
      );
      expect(e, isA<ResearchPointsGainedEvent>());
      final typed = e as ResearchPointsGainedEvent;
      expect(typed.playerId, 'p1');
      expect(typed.points, 12);
    });

    test('TechnologyResearchedEvent round-trips', () {
      final e = roundTrip(
        const TechnologyResearchedEvent(
          playerId: 'p1',
          technologyId: TechnologyId.mining,
        ),
      );
      expect(e, isA<TechnologyResearchedEvent>());
      final typed = e as TechnologyResearchedEvent;
      expect(typed.technologyId, TechnologyId.mining);
    });

    test('CivilizationMetEvent round-trips', () {
      final e = roundTrip(
        const CivilizationMetEvent(playerId: 'p1', metPlayerId: 'p2'),
      );
      expect(e, isA<CivilizationMetEvent>());
      final typed = e as CivilizationMetEvent;
      expect(typed.playerId, 'p1');
      expect(typed.metPlayerId, 'p2');
    });

    test('CommandRejectedEvent round-trips', () {
      final e = roundTrip(
        const CommandRejectedEvent(reason: 'turn_already_submitted'),
      );
      expect(e, isA<CommandRejectedEvent>());
      expect((e as CommandRejectedEvent).reason, 'turn_already_submitted');
    });

    test('AllPlayersSubmittedEvent round-trips', () {
      final e = roundTrip(
        AllPlayersSubmittedEvent(turn: 3, playerIds: const ['p1', 'p2']),
      );
      expect(e, isA<AllPlayersSubmittedEvent>());
      final typed = e as AllPlayersSubmittedEvent;
      expect(typed.turn, 3);
      expect(typed.playerIds, ['p1', 'p2']);
    });

    test('PlayerTimedOutEvent round-trips', () {
      final e = roundTrip(const PlayerTimedOutEvent(turn: 3, playerId: 'p2'));
      expect(e, isA<PlayerTimedOutEvent>());
      final typed = e as PlayerTimedOutEvent;
      expect(typed.turn, 3);
      expect(typed.playerId, 'p2');
    });

    test('TurnAutoResolvedEvent round-trips', () {
      final e = roundTrip(
        const TurnAutoResolvedEvent(
          turn: 3,
          playerId: 'p2',
          unitOrderCount: 2,
          cityProductionCount: 1,
          researchSelected: true,
        ),
      );
      expect(e, isA<TurnAutoResolvedEvent>());
      final typed = e as TurnAutoResolvedEvent;
      expect(typed.turn, 3);
      expect(typed.playerId, 'p2');
      expect(typed.unitOrderCount, 2);
      expect(typed.cityProductionCount, 1);
      expect(typed.researchSelected, isTrue);
    });

    test('PlayerKickedEvent round-trips', () {
      final e = roundTrip(
        const PlayerKickedEvent(
          turn: 3,
          playerId: 'p2',
          reason: 'turn_timeout',
          timeoutStreak: 3,
        ),
      );
      expect(e, isA<PlayerKickedEvent>());
      final typed = e as PlayerKickedEvent;
      expect(typed.turn, 3);
      expect(typed.playerId, 'p2');
      expect(typed.reason, 'turn_timeout');
      expect(typed.timeoutStreak, 3);
    });

    test('toJson includes type discriminator for every event', () {
      final events = <GameEvent>[
        const CityFoundedEvent(cityId: 'c', ownerPlayerId: 'p'),
        const CityBuiltBuildingEvent(
          cityId: 'c',
          buildingType: CityBuildingType.granary,
        ),
        const CityProducedUnitEvent(
          cityId: 'c',
          unitType: GameUnitType.warrior,
          producedUnitId: 'u',
        ),
        const CityClaimedHexEvent(cityId: 'c', col: 0, row: 0),
        const UnitMovedEvent(
          unitId: 'u',
          fromCol: 0,
          fromRow: 0,
          toCol: 1,
          toRow: 1,
        ),
        const UnitGainedExperienceEvent(
          unitId: 'u',
          ownerPlayerId: 'p',
          amount: 1,
          totalExperience: 1,
          rank: UnitVeterancyRank.recruit,
          promoted: false,
        ),
        const UnitAttackedEvent(
          attackerUnitId: 'a',
          attackerOwnerPlayerId: 'p',
          defenderUnitId: 'd',
          defenderOwnerPlayerId: 'q',
        ),
        CombatResolvedEvent(
          attackerUnitId: 'a',
          defenderUnitId: 'd',
          outcome: _sampleOutcome(),
        ),
        const UnitKilledEvent(unitId: 'd', ownerPlayerId: 'q'),
        const UnitRetreatedEvent(
          unitId: 'd',
          ownerPlayerId: 'q',
          fromCol: 0,
          fromRow: 0,
          toCol: 1,
          toRow: 0,
        ),
        const CityCapturedEvent(
          cityId: 'c',
          previousOwnerPlayerId: 'q',
          newOwnerPlayerId: 'p',
        ),
        const CityDestroyedEvent(
          cityId: 'c',
          previousOwnerPlayerId: 'q',
          attackerOwnerPlayerId: 'p',
        ),
        const TurnEndedEvent(playerId: 'p'),
        const WorkerCompletedJobEvent(unitId: 'u'),
        const ResearchPointsGainedEvent(playerId: 'p', points: 1),
        const TechnologyResearchedEvent(
          playerId: 'p',
          technologyId: TechnologyId.agriculture,
        ),
        const CivilizationMetEvent(playerId: 'p', metPlayerId: 'q'),
        const CommandRejectedEvent(reason: 'rejected'),
        AllPlayersSubmittedEvent(turn: 1, playerIds: const ['p', 'q']),
        const PlayerTimedOutEvent(turn: 1, playerId: 'q'),
        const TurnAutoResolvedEvent(
          turn: 1,
          playerId: 'q',
          unitOrderCount: 1,
          cityProductionCount: 0,
          researchSelected: false,
        ),
        const PlayerKickedEvent(
          turn: 1,
          playerId: 'q',
          reason: 'turn_timeout',
          timeoutStreak: 3,
        ),
      ];
      for (final e in events) {
        final json = GameEventSerializer.toJson(e);
        expect(json['type'], isA<String>(), reason: '$e missing type');
        expect(json['type'], isNotEmpty, reason: '$e empty type');
      }
    });

    test('fromJson unknown type throws ArgumentError', () {
      expect(
        () => GameEventSerializer.fromJson({'type': '__unknown__'}),
        throwsArgumentError,
      );
    });

    test('fromJson missing type reports discriminator field', () {
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

    test('fromJson missing payload field reports event field', () {
      expect(
        () => GameEventSerializer.fromJson({
          'type': 'CityFounded',
          'ownerPlayerId': 'p1',
        }),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'CityFounded.cityId',
          ),
        ),
      );
    });

    test('fromJson wrong payload type reports event field', () {
      expect(
        () => GameEventSerializer.fromJson({
          'type': 'UnitMoved',
          'unitId': 'u1',
          'fromCol': '1',
          'fromRow': 2,
          'toCol': 3,
          'toRow': 4,
        }),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'UnitMoved.fromCol',
          ),
        ),
      );
    });

    test('fromJson unknown enum payload reports event field', () {
      expect(
        () => GameEventSerializer.fromJson({
          'type': 'CityProducedUnit',
          'cityId': 'city-1',
          'unitType': 'futureUnit',
          'producedUnitId': 'unit-1',
        }),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'CityProducedUnit.unitType',
          ),
        ),
      );
    });
  });
}

CombatOutcome _sampleOutcome() {
  return CombatOutcome(
    attackerUnitId: 'a1',
    defenderUnitId: 'd1',
    attackerHpAfter: 7,
    defenderHpAfter: 0,
    attackerKilled: false,
    defenderKilled: true,
    steps: [
      AttackStep(
        damage: 5,
        active: const [
          TerrainModifier(
            label: 'terrain.hill',
            target: CombatStatTarget.attack,
            delta: 1,
          ),
        ],
      ),
      const RollStep(seed: 7, value: 0),
    ],
  );
}
