import 'package:aonw/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameEvent hierarchy', () {
    test('CityFoundedEvent holds cityId and playerId', () {
      const e = CityFoundedEvent(cityId: 'c1', ownerPlayerId: 'p1');
      expect(e.cityId, 'c1');
      expect(e.ownerPlayerId, 'p1');
    });

    test('CityBuiltBuildingEvent holds cityId and buildingType', () {
      const e = CityBuiltBuildingEvent(
        cityId: 'c1',
        buildingType: CityBuildingType.granary,
      );
      expect(e.cityId, 'c1');
      expect(e.buildingType, CityBuildingType.granary);
    });

    test('CityProducedUnitEvent holds cityId and unitType', () {
      const e = CityProducedUnitEvent(
        cityId: 'c1',
        unitType: GameUnitType.warrior,
        producedUnitId: 'u1',
      );
      expect(e.cityId, 'c1');
      expect(e.unitType, GameUnitType.warrior);
      expect(e.producedUnitId, 'u1');
    });

    test('CityClaimedHexEvent holds cityId, col, row', () {
      const e = CityClaimedHexEvent(cityId: 'c1', col: 3, row: 4);
      expect(e.cityId, 'c1');
      expect(e.col, 3);
      expect(e.row, 4);
    });

    test('UnitMovedEvent holds unitId, from, to', () {
      const e = UnitMovedEvent(
        unitId: 'u1',
        fromCol: 1,
        fromRow: 2,
        toCol: 3,
        toRow: 4,
      );
      expect(e.unitId, 'u1');
      expect(e.fromCol, 1);
      expect(e.toCol, 3);
    });

    test('UnitGainedExperienceEvent holds XP and rank metadata', () {
      const e = UnitGainedExperienceEvent(
        unitId: 'u1',
        ownerPlayerId: 'p1',
        amount: 3,
        totalExperience: 7,
        rank: UnitVeterancyRank.veteran,
        promoted: true,
      );
      expect(e.unitId, 'u1');
      expect(e.ownerPlayerId, 'p1');
      expect(e.amount, 3);
      expect(e.totalExperience, 7);
      expect(e.rank, UnitVeterancyRank.veteran);
      expect(e.promoted, isTrue);
    });

    test('UnitAttackedEvent holds attacker and defender IDs with owners', () {
      const e = UnitAttackedEvent(
        attackerUnitId: 'a1',
        attackerOwnerPlayerId: 'p1',
        defenderUnitId: 'd1',
        defenderOwnerPlayerId: 'p2',
      );
      expect(e.attackerUnitId, 'a1');
      expect(e.attackerOwnerPlayerId, 'p1');
      expect(e.defenderUnitId, 'd1');
      expect(e.defenderOwnerPlayerId, 'p2');
    });

    test('CombatResolvedEvent holds combat outcome', () {
      final outcome = CombatOutcome(
        attackerUnitId: 'a1',
        defenderUnitId: 'd1',
        attackerHpAfter: 8,
        defenderHpAfter: 0,
        attackerKilled: false,
        defenderKilled: true,
      );
      final e = CombatResolvedEvent(
        attackerUnitId: 'a1',
        defenderUnitId: 'd1',
        outcome: outcome,
      );
      expect(e.outcome, outcome);
    });

    test('UnitKilledEvent holds killed unit and optional attacker', () {
      const e = UnitKilledEvent(
        unitId: 'd1',
        ownerPlayerId: 'p2',
        attackerUnitId: 'a1',
      );
      expect(e.unitId, 'd1');
      expect(e.ownerPlayerId, 'p2');
      expect(e.attackerUnitId, 'a1');
    });

    test('UnitRetreatedEvent holds unit and movement coordinates', () {
      const e = UnitRetreatedEvent(
        unitId: 'd1',
        ownerPlayerId: 'p2',
        fromCol: 2,
        fromRow: 2,
        toCol: 3,
        toRow: 2,
      );
      expect(e.unitId, 'd1');
      expect(e.fromCol, 2);
      expect(e.toCol, 3);
    });

    test('CityCapturedEvent holds old and new owner', () {
      const e = CityCapturedEvent(
        cityId: 'c1',
        previousOwnerPlayerId: 'p2',
        newOwnerPlayerId: 'p1',
      );
      expect(e.cityId, 'c1');
      expect(e.previousOwnerPlayerId, 'p2');
      expect(e.newOwnerPlayerId, 'p1');
    });

    test('CityDestroyedEvent holds old owner and attacker owner', () {
      const e = CityDestroyedEvent(
        cityId: 'c1',
        previousOwnerPlayerId: 'p2',
        attackerOwnerPlayerId: 'p1',
      );
      expect(e.cityId, 'c1');
      expect(e.previousOwnerPlayerId, 'p2');
      expect(e.attackerOwnerPlayerId, 'p1');
    });

    test('TurnEndedEvent holds playerId', () {
      const e = TurnEndedEvent(playerId: 'p1');
      expect(e.playerId, 'p1');
    });

    test('WorkerCompletedJobEvent holds unitId', () {
      const e = WorkerCompletedJobEvent(unitId: 'u1');
      expect(e.unitId, 'u1');
    });

    test('ResearchPointsGainedEvent holds playerId and points', () {
      const e = ResearchPointsGainedEvent(playerId: 'p1', points: 5);
      expect(e.playerId, 'p1');
      expect(e.points, 5);
    });

    test('TechnologyResearchedEvent holds playerId and technologyId', () {
      const e = TechnologyResearchedEvent(
        playerId: 'p1',
        technologyId: TechnologyId.agriculture,
      );
      expect(e.playerId, 'p1');
      expect(e.technologyId, TechnologyId.agriculture);
    });

    test('CommandRejectedEvent holds reason', () {
      const e = CommandRejectedEvent(reason: 'turn_already_submitted');
      expect(e.reason, 'turn_already_submitted');
    });

    test('AllPlayersSubmittedEvent holds turn and player ids', () {
      final e = AllPlayersSubmittedEvent(
        turn: 3,
        playerIds: const ['p1', 'p2'],
      );
      expect(e.turn, 3);
      expect(e.playerIds, ['p1', 'p2']);
    });

    test('PlayerTimedOutEvent holds turn and player id', () {
      const e = PlayerTimedOutEvent(turn: 3, playerId: 'p2');
      expect(e.turn, 3);
      expect(e.playerId, 'p2');
    });

    test('TurnAutoResolvedEvent holds fallback summary', () {
      const e = TurnAutoResolvedEvent(
        turn: 3,
        playerId: 'p2',
        unitOrderCount: 2,
        cityProductionCount: 1,
        researchSelected: true,
      );
      expect(e.turn, 3);
      expect(e.playerId, 'p2');
      expect(e.unitOrderCount, 2);
      expect(e.cityProductionCount, 1);
      expect(e.researchSelected, isTrue);
    });

    test('PlayerKickedEvent holds kick reason', () {
      const e = PlayerKickedEvent(
        turn: 3,
        playerId: 'p2',
        reason: 'turn_timeout',
        timeoutStreak: 3,
      );
      expect(e.turn, 3);
      expect(e.playerId, 'p2');
      expect(e.reason, 'turn_timeout');
      expect(e.timeoutStreak, 3);
    });
  });
}
