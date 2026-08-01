import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/services/hidden_ai_renderer_playback.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HiddenAiRendererPlayback', () {
    test(
      'plays command effects in the previous renderer perspective',
      () async {
        final applied = <_AppliedTransition>[];
        final currentAiState = GameClientState(
          activePlayerId: 'ai_1',
          activePlayerCanAct: true,
        );
        final beforeUnit = GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'ai_1',
          type: GameUnitType.warrior,
          col: 2,
          row: 3,
        );
        final afterUnit = beforeUnit.copyWith(col: 3);
        final humanRendererState = GameClientState(
          activePlayerId: 'human',
          activePlayerCanAct: false,
          units: [beforeUnit],
        );
        final reducerState = GameClientState(
          activePlayerId: 'ai_1',
          activePlayerCanAct: false,
          units: [afterUnit],
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
          uiEffects: const [],
          events: const [
            UnitMovedEvent(
              unitId: 'warrior_1',
              fromCol: 2,
              fromRow: 3,
              toCol: 3,
              toRow: 3,
            ),
          ],
          movementExecutions: [
            MovementCommandExecution(
              unitId: 'warrior_1',
              fromCol: 2,
              fromRow: 3,
              steps: const [
                UnitMovementStep(
                  col: 3,
                  row: 3,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
              ],
            ),
          ],
        );

        expect(report.applied, isTrue);
        expect(report.rendererState.activePlayerId, 'human');
        expect(report.rendererState.activePlayerCanAct, isFalse);
        final projectedMove = report.rendererEffects
            .whereType<AnimateUnitMoveEffect>()
            .single;
        expect(projectedMove.unitId, commandMove.unitId);
        expect(projectedMove.fromCol, commandMove.fromCol);
        expect(projectedMove.fromRow, commandMove.fromRow);
        expect(projectedMove.steps, commandMove.steps);
        expect(applied, hasLength(1));
        expect(applied.single.state.activePlayerId, 'human');
        expect(applied.single.effects, report.rendererEffects);
      },
    );

    test(
      'uses fallback state and skips apply when there are no effects',
      () async {
        var applied = false;
        final currentAiState = GameClientState(
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
          commandState: GameClientState(activePlayerId: 'ai_1'),
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
  final GameClientState state;
  final List<RendererEffect> effects;

  const _AppliedTransition(this.state, this.effects);
}
