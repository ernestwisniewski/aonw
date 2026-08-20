import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_game_renderer.dart';
import 'support/game_provider_shared_fixtures.dart';

void main() {
  test(
    'end turn persists and presents next-player queued movement once',
    () async {
      final queuedUnit = GameUnit(
        id: 'queued_unit',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 0,
        movementPoints: 0,
        queuedPath: QueuedMovePath(
          targetCol: 1,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          ],
        ),
      );
      final save = providerSave(players: const [player1, player2]);
      final renderer = SpyRenderer(mapData: providerLandMap());
      final gameRepository = FakeGameRepository(
        snapshots: {
          save.id: providerSnapshot(save: save, units: [queuedUnit]),
        },
      );
      final container = ProviderContainer(
        overrides: [
          activeGameSessionProvider.overrideWithValue(
            providerSession(mapData: providerLandMap()),
          ),
          activeGameRendererProvider.overrideWithValue(renderer),
          activeRendererViewModelProvider.overrideWithValue(
            TestRendererViewModel(renderer),
          ),
          gameRepositoryProvider.overrideWithValue(gameRepository),
          ...transportOverrides(),
        ],
      );
      addTearDown(container.dispose);

      await container.read(gameStateProvider(save.id).future);
      final controller = container.read(gameCommandControllerProvider.notifier);
      final presentation = await controller.dispatchForHandoffPresentation(
        const EndTurnCommand('player_1'),
      );

      final persisted = gameRepository.snapshots[save.id]!;
      expect(persisted.units.single.col, 1);
      expect(persisted.units.single.row, 0);
      expect(persisted.units.single.queuedPath, isNull);
      expect(persisted.eventLogOffset, 1);
      expect(presentation.events.whereType<TurnEndedEvent>(), hasLength(1));
      expect(presentation.events.whereType<UnitMovedEvent>(), hasLength(1));
      expect(
        presentation.uiEffects.whereType<AnimateUnitMoveEffect>(),
        isEmpty,
      );
      expect(presentation.movementExecutions, hasLength(1));
      expect(presentation.offset, 1);
      expect(
        renderer.handledEffects.whereType<AnimateUnitMoveEffect>(),
        isEmpty,
      );

      await controller.presentHandoffPresentation(presentation);

      final animations = renderer.handledEffects
          .whereType<AnimateUnitMoveEffect>()
          .toList();
      expect(animations, hasLength(1));
      expect(animations.single.unitId, queuedUnit.id);
      expect(animations.single.fromCol, 0);
      expect(animations.single.steps.single.col, 1);

      container.invalidate(gameStateProvider(save.id));
      final reloaded = await container.read(gameStateProvider(save.id).future);
      expect(reloaded.units.single.col, 1);
      expect(reloaded.units.single.queuedPath, isNull);
    },
  );
}
