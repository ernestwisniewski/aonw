import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MapObjectiveRules', () {
    test('advances hold turns for a lone unit on an objective', () {
      final objective = _objective(requiredHoldTurns: 2);
      final state = PersistentGameState(
        units: [
          GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 2, row: 1),
        ],
      );

      final firstHold = MapObjectiveRules.advanceHoldStates(
        objectives: [objective],
        cities: state.cities,
        units: state.units,
      );
      final secondHold = MapObjectiveRules.advanceHoldStates(
        objectives: [objective],
        cities: state.cities,
        units: state.units,
        previousHoldStatesByObjectiveId: firstHold,
      );
      final snapshot = MapObjectiveRules.snapshot(
        objectives: [objective],
        cities: state.cities,
        units: state.units,
        holdStatesByObjectiveId: secondHold,
      );

      expect(firstHold['pass_1']!.holdTurns, 1);
      expect(secondHold['pass_1']!.holdTurns, 2);
      expect(snapshot.entryFor('pass_1')!.completed, isTrue);
      expect(snapshot.victoryPointsByPlayerId(), {'player_1': 3});
      expect(snapshot.goldPerTurnByPlayerId(), {'player_1': 2});
    });

    test('resets control when multiple players contest an objective', () {
      final objective = _objective();
      final previous = {
        'pass_1': const MapObjectiveHoldState(
          objectiveId: 'pass_1',
          playerId: 'player_1',
          holdTurns: 2,
        ),
      };
      final state = PersistentGameState(
        units: [
          GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 2, row: 1),
          GameUnit.startingWarrior(ownerPlayerId: 'player_2', col: 2, row: 1),
        ],
      );

      final nextHold = MapObjectiveRules.advanceHoldStates(
        objectives: [objective],
        cities: state.cities,
        units: state.units,
        previousHoldStatesByObjectiveId: previous,
      );
      final snapshot = MapObjectiveRules.snapshot(
        objectives: [objective],
        cities: state.cities,
        units: state.units,
        holdStatesByObjectiveId: nextHold,
      );

      expect(nextHold, isEmpty);
      expect(snapshot.entryFor('pass_1')!.controlled, isFalse);
      expect(snapshot.entryFor('pass_1')!.contested, isTrue);
      expect(snapshot.entryFor('pass_1')!.holdTurns, 0);
    });

    test('uses city territory as map objective control', () {
      final objective = _objective(requiredHoldTurns: 1);
      const state = PersistentGameState(
        cities: [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Krakow',
            center: CityHex(col: 1, row: 1),
            controlledHexes: [CityHex(col: 2, row: 1)],
          ),
        ],
      );

      final hold = MapObjectiveRules.advanceHoldStates(
        objectives: [objective],
        cities: state.cities,
        units: state.units,
      );
      final snapshot = MapObjectiveRules.snapshot(
        objectives: [objective],
        cities: state.cities,
        units: state.units,
        holdStatesByObjectiveId: hold,
      );

      expect(snapshot.entryFor('pass_1')!.controllingPlayerId, 'player_1');
      expect(snapshot.entryFor('pass_1')!.completed, isTrue);
      expect(snapshot.victoryPointsByPlayerId(), {'player_1': 3});
    });

    test('starts a fresh hold when control changes owner', () {
      final objective = _objective();
      final previous = {
        'pass_1': const MapObjectiveHoldState(
          objectiveId: 'pass_1',
          playerId: 'player_1',
          holdTurns: 3,
        ),
      };
      final state = PersistentGameState(
        units: [
          GameUnit.startingWarrior(ownerPlayerId: 'player_2', col: 2, row: 1),
        ],
      );

      final nextHold = MapObjectiveRules.advanceHoldStates(
        objectives: [objective],
        cities: state.cities,
        units: state.units,
        previousHoldStatesByObjectiveId: previous,
      );

      expect(nextHold['pass_1']!.playerId, 'player_2');
      expect(nextHold['pass_1']!.holdTurns, 1);
    });
  });
}

MapObjectiveDefinition _objective({int requiredHoldTurns = 3}) {
  return MapObjectiveDefinition(
    id: 'pass_1',
    type: MapObjectiveType.strategicPass,
    hex: const CityHex(col: 2, row: 1),
    requiredHoldTurns: requiredHoldTurns,
    victoryPoints: 3,
    goldPerTurn: 2,
  );
}
