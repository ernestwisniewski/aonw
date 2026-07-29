import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_renderer_effect_sequence_builder.dart';
import 'package:aonw/game/presentation/replay/replay_renderer_effect_planner.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameRendererEffectSequenceBuilder', () {
    test('preserves command effects before event-derived effects', () {
      final effects = GameRendererEffectSequenceBuilder.build(
        commandEffects: const [
          ShowFloatingTextEffect(
            text: 'queued',
            col: 2,
            row: 3,
            colorValue: 0xFFFFFFFF,
          ),
        ],
        events: const [
          UnitMovedEvent(
            unitId: 'warrior_1',
            fromCol: 2,
            fromRow: 3,
            toCol: 3,
            toRow: 3,
          ),
        ],
        state: const GameState(),
      );

      expect(effects, hasLength(2));
      expect(effects.first, isA<ShowFloatingTextEffect>());
      expect(effects.last, isA<AnimateUnitMoveEffect>());
    });

    test(
      'skips duplicate event movement when command already animates unit',
      () {
        const commandMove = AnimateUnitMoveEffect(
          unitId: 'warrior_1',
          fromCol: 2,
          fromRow: 3,
          steps: [
            UnitMovementStep(col: 3, row: 3, enterCost: 1, cumulativeCost: 1),
          ],
        );

        final effects = GameRendererEffectSequenceBuilder.build(
          commandEffects: const [commandMove],
          events: const [
            UnitMovedEvent(
              unitId: 'warrior_1',
              fromCol: 2,
              fromRow: 3,
              toCol: 3,
              toRow: 3,
            ),
          ],
          state: const GameState(),
        );

        expect(effects, const [commandMove]);
      },
    );

    test('keeps event movement for units not already animated by command', () {
      const commandMove = AnimateUnitMoveEffect(
        unitId: 'warrior_1',
        fromCol: 2,
        fromRow: 3,
        steps: [
          UnitMovementStep(col: 3, row: 3, enterCost: 1, cumulativeCost: 1),
        ],
      );

      final effects = GameRendererEffectSequenceBuilder.build(
        commandEffects: const [commandMove],
        events: const [
          UnitMovedEvent(
            unitId: 'scout_1',
            fromCol: 4,
            fromRow: 3,
            toCol: 5,
            toRow: 3,
          ),
        ],
        state: const GameState(),
      );

      expect(effects, hasLength(2));
      expect((effects.last as AnimateUnitMoveEffect).unitId, 'scout_1');
    });

    test('does not duplicate combat animation already emitted by command', () {
      const commandCombat = PlayCombatAnimationEffect(
        attackerUnitId: 'attacker',
        defenderUnitId: 'defender',
      );
      final attacker = GameUnit(
        id: 'attacker',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Attacker',
        col: 0,
        row: 0,
      );
      final defender = GameUnit(
        id: 'defender',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: 'Defender',
        col: 1,
        row: 0,
      );

      final effects = GameRendererEffectSequenceBuilder.build(
        commandEffects: const [commandCombat],
        events: [
          CombatResolvedEvent(
            attackerUnitId: 'attacker',
            defenderUnitId: 'defender',
            outcome: CombatOutcome(
              attackerUnitId: 'attacker',
              defenderUnitId: 'defender',
              attackerHpAfter: 5,
              defenderHpAfter: 5,
              attackerKilled: false,
              defenderKilled: false,
              steps: [AttackStep(damage: 1)],
            ),
          ),
        ],
        state: GameState(units: [attacker, defender]),
      );

      expect(effects.whereType<PlayCombatAnimationEffect>(), [commandCombat]);
      expect(effects.whereType<ShakeCameraEffect>(), hasLength(1));
    });

    test(
      'single multiplayer and replay produce one identical combat sequence',
      () {
        final attacker = GameUnit(
          id: 'attacker',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Attacker',
          col: 0,
          row: 0,
        );
        final defender = GameUnit(
          id: 'defender',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          name: 'Defender',
          col: 1,
          row: 0,
        );
        final previousState = GameState(units: [attacker, defender]);
        final state = GameState(units: [defender]);
        final events = [
          CombatResolvedEvent(
            attackerUnitId: 'attacker',
            defenderUnitId: 'defender',
            outcome: CombatOutcome(
              attackerUnitId: 'attacker',
              defenderUnitId: 'defender',
              attackerHpAfter: 0,
              defenderHpAfter: 4,
              attackerKilled: true,
              defenderKilled: false,
              steps: [AttackStep(damage: 2), RetaliationStep(damage: 10)],
            ),
          ),
        ];
        const combatAnimations = [
          CombatAnimationFact(
            eventIndex: 0,
            attackerUnitId: 'attacker',
            defenderId: 'defender',
            attackerFromCol: 0,
            attackerFromRow: 0,
            attackerToCol: 1,
            attackerToRow: 0,
          ),
        ];

        final single = GameRendererEffectSequenceBuilder.build(
          commandEffects: const [],
          events: events,
          state: state,
          previousState: previousState,
          combatAnimations: combatAnimations,
        );
        final multiplayer = GameRendererEffectSequenceBuilder.build(
          commandEffects: const [],
          events: events,
          state: state,
          previousState: previousState,
          combatAnimations: combatAnimations,
        );
        final replay = ReplayRendererEffectPlanner.effectsForStep(
          commandEffects: const [],
          events: events,
          state: state,
          previousState: previousState,
          combatAnimations: combatAnimations,
        );

        expect(_combatSequence(single), _combatSequence(multiplayer));
        expect(_combatSequence(single), _combatSequence(replay));
        expect(single.whereType<PlayCombatAnimationEffect>(), hasLength(1));
        expect(single.whereType<AnimateUnitMoveEffect>(), isEmpty);
        expect(_combatSequence(single), const [
          ('attacker', 'defender', 0, 0, true, false, true),
        ]);
      },
    );

    test('uses the engine fact for removed-attacker city combat geometry', () {
      final attacker = GameUnit(
        id: 'attacker',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Attacker',
        col: 9,
        row: 9,
      );
      const city = GameCity(
        id: 'city',
        ownerPlayerId: 'player_2',
        name: 'City',
        center: CityHex(col: 10, row: 9),
      );
      final previousState = GameState(units: [attacker], cities: const [city]);
      const state = GameState(cities: [city]);
      final event = CombatResolvedEvent(
        attackerUnitId: 'attacker',
        defenderUnitId: 'city',
        outcome: CombatOutcome(
          attackerUnitId: 'attacker',
          defenderUnitId: 'city',
          attackerHpAfter: 0,
          defenderHpAfter: 2,
          attackerKilled: true,
          defenderKilled: false,
          steps: [AttackStep(damage: 3), RetaliationStep(damage: 10)],
        ),
      );

      final effects = GameRendererEffectSequenceBuilder.build(
        commandEffects: const [],
        events: [event],
        state: state,
        previousState: previousState,
        combatAnimations: const [
          CombatAnimationFact(
            eventIndex: 0,
            attackerUnitId: 'attacker',
            defenderId: 'city',
            attackerFromCol: 2,
            attackerFromRow: 3,
            attackerToCol: 3,
            attackerToRow: 3,
          ),
        ],
      );
      final animation = effects.whereType<PlayCombatAnimationEffect>().single;

      expect(
        (
          animation.attackerFromCol,
          animation.attackerFromRow,
          animation.attackerToCol,
          animation.attackerToRow,
        ),
        (2, 3, 3, 3),
      );
    });
  });
}

List<(String, String, int?, int?, bool, bool, bool)> _combatSequence(
  Iterable<RendererEffect> effects,
) {
  return [
    for (final effect in effects.whereType<PlayCombatAnimationEffect>())
      (
        effect.attackerUnitId,
        effect.defenderUnitId,
        effect.attackerFromCol,
        effect.attackerFromRow,
        effect.attackerKilled,
        effect.defenderKilled,
        effect.defenderRetaliated,
      ),
  ];
}
