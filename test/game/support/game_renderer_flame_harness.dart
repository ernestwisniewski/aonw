import 'dart:async';

import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/game_renderer.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

typedef GameRendererFactory = GameRenderer Function();
typedef GameRendererTestBody = FutureOr<void> Function(GameRenderer game);

/// Shared `flame_test` harness for ordinary, fully loaded renderer tests.
///
/// `testWithGame` owns the Flame lifecycle and initializes the game at its
/// deterministic 800x600 test viewport. Renderer-specific resources are
/// released before Flame removes the game from the component tree.
final class GameRendererFlameTester {
  const GameRendererFlameTester();

  static const viewportSize = (width: 800.0, height: 600.0);

  /// Applies an initial presentation state before mounting the renderer.
  Future<void> initializeWithState(GameRenderer game, GameClientState state) {
    game.applyState(state);
    return initialize(game);
  }

  /// Initializes an already constructed renderer while preserving the local
  /// test's fixture scope. Prefer [test] when the game can be factory-created
  /// without sharing setup values with the verification body.
  Future<void> initialize(GameRenderer game) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    addTearDown(() {
      game
        ..disposeRenderer()
        ..onRemove();
    });
    final initializedGame = await initializeGame<GameRenderer>(() => game);
    assert(identical(initializedGame, game));
    await initializedGame.ready();
    _assertViewportSize(game);
  }

  void test(
    String description,
    GameRendererFactory createGame,
    GameRendererTestBody testBody,
  ) {
    TestWidgetsFlutterBinding.ensureInitialized();
    testWithGame<GameRenderer>(description, createGame, (game) async {
      await game.ready();
      _assertViewportSize(game);
      try {
        await testBody(game);
      } finally {
        game.disposeRenderer();
      }
    });
  }

  void _assertViewportSize(GameRenderer game) {
    assert(
      game.size.x == viewportSize.width && game.size.y == viewportSize.height,
      'flame_test changed its default game size; update this harness.',
    );
  }
}

const gameRendererFlameTester = GameRendererFlameTester();
