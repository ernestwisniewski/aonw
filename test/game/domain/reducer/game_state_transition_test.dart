import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameStateTransition', () {
    const state = GameState();

    test('defaults to empty uiEffects and events', () {
      const t = GameStateTransition(state: state);
      expect(t.uiEffects, isEmpty);
      expect(t.events, isEmpty);
    });

    test('uiEffects accepts JumpCameraEffect', () {
      const t = GameStateTransition(
        state: state,
        uiEffects: [JumpCameraEffect(col: 1, row: 2)],
      );
      expect(t.uiEffects, [isA<JumpCameraEffect>()]);
    });

    test('events accepts GameEvent list', () {
      const t = GameStateTransition(
        state: state,
        events: [TurnEndedEvent(playerId: 'p1')],
      );
      expect(t.events, [isA<TurnEndedEvent>()]);
    });

    test('renderer effects include jump camera and unit animation effects', () {
      const jump = JumpCameraEffect(col: 3, row: 4);
      expect(jump, isA<UiEffect>());
      expect(jump, isA<RendererEffect>());
      expect(jump.col, 3);
      expect(jump.row, 4);

      const anim = AnimateUnitMoveEffect(
        unitId: 'u',
        fromCol: 0,
        fromRow: 0,
        steps: [],
      );
      expect(anim, isA<UiEffect>());
      expect(anim, isA<RendererEffect>());
      expect(anim.unitId, 'u');

      const combat = PlayCombatAnimationEffect(
        attackerUnitId: 'attacker',
        defenderUnitId: 'defender',
        defenderKilled: true,
      );
      expect(combat, isA<UiEffect>());
      expect(combat, isA<RendererEffect>());
      expect(combat.attackerUnitId, 'attacker');
      expect(combat.defenderUnitId, 'defender');
      expect(combat.attackerKilled, isFalse);
      expect(combat.defenderKilled, isTrue);

      const shake = ShakeCameraEffect(intensity: 6, duration: 0.2);
      expect(shake, isA<UiEffect>());
      expect(shake, isA<RendererEffect>());
      expect(shake.intensity, 6);
      expect(shake.duration, 0.2);

      const particles = SpawnParticleBurstEffect(
        kind: ParticleBurstKind.cityFounded,
        col: 2,
        row: 3,
        colorValue: 0xFF2563EB,
      );
      expect(particles, isA<UiEffect>());
      expect(particles, isA<RendererEffect>());
      expect(particles.kind, ParticleBurstKind.cityFounded);
      expect(particles.col, 2);
      expect(particles.row, 3);

      const floatingText = ShowFloatingTextEffect(
        text: '+1 food',
        col: 4,
        row: 5,
        colorValue: 0xFF86EFAC,
      );
      expect(floatingText, isA<UiEffect>());
      expect(floatingText, isA<RendererEffect>());
      expect(floatingText.text, '+1 food');
      expect(floatingText.col, 4);
      expect(floatingText.row, 5);
      expect(floatingText.delay, Duration.zero);
      expect(floatingText.presentation, FloatingTextPresentation.plain);
      const delayedFloatingText = ShowFloatingTextEffect(
        text: 'KO',
        col: 4,
        row: 5,
        colorValue: 0xFFF87171,
        delay: Duration(milliseconds: 180),
      );
      expect(delayedFloatingText.delay, const Duration(milliseconds: 180));

      const productionBubble = ShowCityProductionBubbleEffect(
        target: UnitProductionTarget(GameUnitType.worker),
        col: 2,
        row: 1,
        turnsRemaining: 3,
      );
      expect(productionBubble, isA<UiEffect>());
      expect(productionBubble, isA<RendererEffect>());
      expect(productionBubble.turnsRemaining, 3);
    });

    test('ui effect stream can be split by dispatcher kind', () {
      const effects = <UiEffect>[JumpCameraEffect(col: 1, row: 2)];

      expect(effects.rendererEffects, [isA<JumpCameraEffect>()]);
      expect(effects.overlayEffects, isEmpty);
    });
  });
}
