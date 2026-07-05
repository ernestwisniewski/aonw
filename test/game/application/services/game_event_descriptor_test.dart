import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameEventDescriptor', () {
    test('describes combat city context and participants', () {
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
      final event = _combat(
        attackerUnitId: attacker.id,
        defenderUnitId: city.id,
      );

      final descriptor = GameEventDescriptor.forEvent(event);

      expect(descriptor.activityWorthy, isTrue);
      expect(descriptor.messageGroup, GameEventMessageGroup.combat);
      expect(
        descriptor.rendererEffectKind,
        GameEventRendererEffectKind.combatResolved,
      );
      expect(descriptor.soundCueKind, GameEventSoundCueKind.combat);
      expect(descriptor.unitIds, {'attacker', 'city_1'});
      expect(descriptor.cityIds, {'city_1'});
      expect(descriptor.playerIdsFor(state: state, previousState: state), [
        'player_2',
        'player_1',
      ]);
    });

    test('describes map objective focus and ownership', () {
      const event = MapObjectiveSecuredEvent(
        playerId: 'player_1',
        objectiveId: 'pass_1',
        objectiveType: MapObjectiveType.strategicPass,
        col: 2,
        row: 1,
        holdTurns: 3,
        requiredHoldTurns: 3,
        victoryPoints: 2,
        goldPerTurn: 1,
      );

      final descriptor = GameEventDescriptor.forEvent(event);

      expect(descriptor.activityWorthy, isTrue);
      expect(descriptor.messageGroup, GameEventMessageGroup.objective);
      expect(descriptor.rendererEffectKind, GameEventRendererEffectKind.none);
      expect(descriptor.soundCueKind, GameEventSoundCueKind.none);
      expect(descriptor.playerIdsFor(state: const GameState()), ['player_1']);
      final focusHint = descriptor.focusHints.single;
      expect(focusHint, isA<TileGameEventFocusHint>());
      expect((focusHint as TileGameEventFocusHint).id, 'objective_pass_1');
      expect(focusHint.col, 2);
      expect(focusHint.row, 1);
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
