import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/services/hidden_ai_renderer_playback.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HiddenAiRendererPlayback', () {
    test(
      'plays command effects in the previous renderer perspective',
      () async {
        final applied = <_AppliedTransition>[];
        const currentAiState = GameState(
          activePlayerId: 'ai_1',
          activePlayerCanAct: true,
        );
        const humanRendererState = GameState(
          activePlayerId: 'human',
          activePlayerCanAct: false,
        );
        const reducerState = GameState(
          activePlayerId: 'ai_1',
          activePlayerCanAct: false,
        );
        const commandMove = AnimateUnitMoveEffect(
          unitId: 'warrior_1',
          fromCol: 2,
          fromRow: 3,
          steps: [
            UnitMovementStep(col: 3, row: 3, enterCost: 1, cumulativeCost: 1),
          ],
        );
        final playback = HiddenAiRendererPlayback(
          rendererStateReader: () => humanRendererState,
          localizationReader: () => null,
          applyTransition: (state, effects) async {
            applied.add(_AppliedTransition(state, effects));
          },
        );

        final previousRendererState = playback.previousRendererState(
          currentAiState,
        );
        final report = await playback.playCommandEffects(
          previousRendererState: previousRendererState,
          commandState: reducerState,
          uiEffects: const [commandMove],
          events: const [],
        );

        expect(report.applied, isTrue);
        expect(report.rendererState.activePlayerId, 'human');
        expect(report.rendererState.activePlayerCanAct, isFalse);
        expect(report.rendererEffects, const [commandMove]);
        expect(applied, hasLength(1));
        expect(applied.single.state.activePlayerId, 'human');
        expect(applied.single.effects, const [commandMove]);
      },
    );

    test(
      'uses fallback state and skips apply when there are no effects',
      () async {
        var applied = false;
        const currentAiState = GameState(
          activePlayerId: 'ai_1',
          activePlayerCanAct: true,
        );
        final playback = HiddenAiRendererPlayback(
          rendererStateReader: () => null,
          localizationReader: () => null,
          applyTransition: (state, effects) async {
            applied = true;
          },
        );

        final previousRendererState = playback.previousRendererState(
          currentAiState,
        );
        final report = await playback.playCommandEffects(
          previousRendererState: previousRendererState,
          commandState: const GameState(activePlayerId: 'ai_1'),
          uiEffects: const [],
          events: const [],
        );

        expect(previousRendererState.activePlayerId, 'ai_1');
        expect(report.applied, isFalse);
        expect(report.rendererEffects, isEmpty);
        expect(applied, isFalse);
      },
    );
  });
}

final class _AppliedTransition {
  final GameState state;
  final List<RendererEffect> effects;

  const _AppliedTransition(this.state, this.effects);
}
