import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_renderer.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('effect arriving at ready waits for the initial effect flush', () async {
    final game = GameRenderer(mapData: _map(), onCommand: (_) async {});
    addTearDown(game.disposeRenderer);

    await game.handleEffect(
      const SmoothCameraEffect(col: 1, row: 0, duration: 1),
    );
    game.onGameResize(Vector2(800, 600));
    await game.onLoad();
    expect(game.hasPendingCameraMotionForTesting, isTrue);

    var secondCompleted = false;
    final second = game
        .handleEffect(const SmoothCameraEffect(col: 2, row: 0, duration: 1))
        .then((_) => secondCompleted = true);
    await _flush();

    await _advance(game, 1);
    expect(
      secondCompleted,
      isFalse,
      reason: 'the second effect must not cancel the pre-ready effect',
    );
    expect(game.hasPendingCameraMotionForTesting, isTrue);

    await _advance(game, 1);
    await second.timeout(const Duration(seconds: 1));
    expect(secondCompleted, isTrue);
    expect(game.hasPendingCameraMotionForTesting, isFalse);
  });

  test(
    'projected presentation cannot start before renderer readiness',
    () async {
      final game = GameRenderer(
        mapData: _map(),
        onCommand: (_) async {},
        presentationClock: const _FixedClock(2000000),
      );
      addTearDown(game.disposeRenderer);
      var presentationStarted = false;

      final transition = game.applyProjectedTransition(
        GameClientState(),
        ProjectedGameEffectBatch(
          identity: const PresentationBatchIdentity(
            sourceId: 'match_1',
            eventOffset: 1,
            authoritativeStartMicrosUtc: 1000000,
          ),
          sequenceDirective: PresentationSequenceDirective.advance,
        ),
        onPresentationStart: () => presentationStarted = true,
      );
      await _flush();
      expect(presentationStarted, isFalse);

      game.onGameResize(Vector2(800, 600));
      await game.onLoad();
      await transition.timeout(const Duration(seconds: 1));

      expect(presentationStarted, isTrue);
    },
  );
}

final class _FixedClock extends Clock {
  const _FixedClock(this.microsUtc);

  final int microsUtc;

  @override
  DateTime now() => DateTime.fromMicrosecondsSinceEpoch(microsUtc, isUtc: true);
}

WorldMap _map() => WorldMap(
  cols: 3,
  rows: 2,
  tiles: [
    for (var row = 0; row < 2; row++)
      for (var col = 0; col < 3; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

Future<void> _advance(GameRenderer game, double seconds) async {
  game.update(seconds);
  await _flush();
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);
