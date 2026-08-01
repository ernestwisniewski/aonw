import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_event_notification_focus_target.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('gameEventNotificationFocusTarget', () {
    test('focuses the defender city before the attacker in city combat', () {
      final attacker = GameUnit.produced(
        id: 'attacker',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 2,
        row: 3,
      );
      const city = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Target',
        center: CityHex(col: 4, row: 5),
      );
      final state = GameClientState(units: [attacker], cities: const [city]);

      final target = gameEventNotificationFocusTarget(
        _combat(attackerUnitId: attacker.id, defenderUnitId: city.id),
        state,
      );

      expect(target, isA<CityNotificationFocusTarget>());
      expect(target?.id, 'city_2');
      expect(target?.col, 4);
      expect(target?.row, 5);
      expect(target?.selectCommand, const SelectCityCommand('city_2'));
    });

    test('focuses secured map objectives as tile targets', () {
      final target = gameEventNotificationFocusTarget(
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
        GameClientState(),
      );

      expect(target, isA<TileNotificationFocusTarget>());
      expect(target?.id, 'objective_pass_1');
      expect(target?.col, 2);
      expect(target?.row, 1);
      expect(target?.selectCommand, const SelectTileCommand(2, 1));
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
