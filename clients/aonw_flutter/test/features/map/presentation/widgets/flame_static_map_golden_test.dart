import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'starter_map_golden_support.dart';

void main() {
  testWidgets('freezes the batched Flame static layers', (tester) async {
    final loaded = await loadStarterMapGoldenFixture(tester);
    final map = loaded.map;
    final reference = loaded.reference;
    final game = AonwFlameGame(renderStaticLayers: true);
    await tester.binding.setSurfaceSize(const Size(660, 728));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    game.sceneSink.replaceScene(
      MapRenderSnapshot(
        map: map,
        interaction: const MapInteractionState(referenceVisible: false),
        reference: reference,
        player: PlayerMapView(
          actorPlayerId: 'preview-player',
          stamp: starterMapGoldenStamp(map.contentHash),
          turn: 1,
          pendingAction: null,
          units: const [],
        ),
      ),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: const ValueKey('flame-starter-golden'),
          child: ColoredBox(
            color: Colors.black,
            child: GameWidget<AonwFlameGame>(
              game: game,
              autofocus: false,
              behavior: HitTestBehavior.deferToChild,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await game.toBeLoaded();
    });
    await tester.pump();
    await tester.pump();
    expect(game.debugMountCount, 1);
    await tester.runAsync(game.ready);
    game.stepEngine(stepTime: 0);
    await tester.pump();
    expect(game.world.referenceLayer.debugDecodedPageCount, 1);
    expect(game.world.referenceLayer.isVisible, isFalse);

    await expectLater(
      find.byKey(const ValueKey('flame-starter-golden')),
      matchesGoldenFile('goldens/flame_starter_map.png'),
    );

    game.sceneSink.replaceScene(
      MapRenderSnapshot(
        map: map,
        interaction: const MapInteractionState(),
        reference: reference,
        player: PlayerMapView(
          actorPlayerId: 'preview-player',
          stamp: starterMapGoldenStamp(map.contentHash),
          turn: 1,
          pendingAction: null,
          units: const [],
        ),
      ),
    );
    await tester.pump();
    expect(game.world.terrainLayer.debugCacheUpdateCount, 1);
    expect(game.world.referenceLayer.debugVisibilityUpdateCount, 2);
    expect(game.world.referenceLayer.isVisible, isTrue);
    expect(game.world.gridLayer.debugCacheUpdateCount, 1);
    await expectLater(
      find.byKey(const ValueKey('flame-starter-golden')),
      matchesGoldenFile('goldens/flame_starter_map_reference.png'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
