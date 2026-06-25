import 'package:aonw/game/application/services/game_activity_event_projector.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameActivityEventProjector', () {
    test('projects combat activity for both combat participants', () {
      final attacker = GameUnit.produced(
        id: 'attacker',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final defender = GameUnit.produced(
        id: 'defender',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 1,
        row: 0,
      );
      final state = GameState(units: [attacker, defender]);

      final activity = GameActivityEventProjector.project(
        events: [
          _combat(attackerUnitId: attacker.id, defenderUnitId: defender.id),
        ],
        state: state,
        previousState: state,
      );

      expect(activity.map((entry) => entry.playerId), ['player_1', 'player_2']);
      expect(activity.map((entry) => entry.eventIndex).toSet(), {0});
    });

    test('filters combat activity to the visible player', () {
      final attacker = GameUnit.produced(
        id: 'attacker',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final defender = GameUnit.produced(
        id: 'defender',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 1,
        row: 0,
      );
      final state = GameState(units: [attacker, defender]);

      final activity = GameActivityEventProjector.project(
        events: [
          _combat(attackerUnitId: attacker.id, defenderUnitId: defender.id),
        ],
        state: state,
        previousState: state,
        visiblePlayerId: 'player_2',
      );

      expect(activity, hasLength(1));
      expect(activity.single.playerId, 'player_2');
    });

    test('projects city combat activity for attacker and city owner', () {
      final attacker = GameUnit.produced(
        id: 'attacker',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 4,
        row: 4,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Warszawa',
        center: CityHex(col: 3, row: 4),
      );
      final state = GameState(units: [attacker], cities: const [city]);

      final activity = GameActivityEventProjector.project(
        events: [_combat(attackerUnitId: attacker.id, defenderUnitId: city.id)],
        state: state,
        previousState: state,
      );

      expect(activity.map((entry) => entry.playerId), ['player_2', 'player_1']);
      expect(activity.first.context.units, contains('attacker'));
      expect(activity.first.context.cities, contains('city_1'));
    });

    test('projects secured map objective activity to controlling player', () {
      final activity = GameActivityEventProjector.project(
        events: const [
          MapObjectiveSecuredEvent(
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
        ],
        state: const GameState(),
        visiblePlayerId: 'player_1',
      );

      expect(activity, hasLength(1));
      expect(activity.single.playerId, 'player_1');
      expect(activity.single.context.units, isEmpty);
      expect(activity.single.context.cities, isEmpty);
    });
  });
}

CombatResolvedEvent _combat({
  required String attackerUnitId,
  required String defenderUnitId,
}) {
  return CombatResolvedEvent(
    attackerUnitId: attackerUnitId,
    defenderUnitId: defenderUnitId,
    outcome: CombatOutcome(
      attackerUnitId: attackerUnitId,
      defenderUnitId: defenderUnitId,
      attackerHpAfter: 10,
      defenderHpAfter: 7,
      attackerKilled: false,
      defenderKilled: false,
      steps: [AttackStep(damage: 3)],
    ),
  );
}
