import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_renderer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'dispose cannot restart selection camera motion after enemy pre-roll',
    () async {
      final selected = _unit(
        'selected',
        ownerPlayerId: 'player_1',
        col: 2,
        row: 1,
      );
      final enemy = _unit('enemy', ownerPlayerId: 'player_2', col: 0, row: 0);
      final game = GameRenderer(
        mapData: _map(),
        onCommand: (_) async {},
        followEnemyUnitCamera: true,
      );
      addTearDown(game.disposeRenderer);
      game
        ..applyState(
          GameClientState(
            units: [selected, enemy],
            activePlayerId: 'player_1',
            fogOfWar: FogOfWarState(
              players: {
                'player_1': PlayerFogOfWar(
                  playerId: 'player_1',
                  visibleHexes: {
                    const HexCoordinate(col: 0, row: 0),
                    const HexCoordinate(col: 1, row: 0),
                    const HexCoordinate(col: 2, row: 1),
                  },
                ),
              },
            ),
            interaction: InteractionState(
              selection: GameSelection.unit(selected),
            ),
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();
      await _waitForMarker(game, enemy.id);
      await game.handleEffect(const JumpCameraEffect(col: 2, row: 1));

      final transition = game.handleEffect(
        const AnimateUnitMoveEffect(
          unitId: 'enemy',
          fromCol: 0,
          fromRow: 0,
          steps: [
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          ],
        ),
      );
      final expectation = expectLater(transition, throwsA(isA<StateError>()));
      await _flush();
      expect(game.hasPendingCameraMotionForTesting, isTrue);

      game.disposeRenderer();
      await _flush();
      await _flush();

      expect(game.hasPendingCameraMotionForTesting, isFalse);
      final positionAfterDispose = game.camera.viewfinder.position.clone();
      game.update(1);
      expect(game.camera.viewfinder.position, positionAfterDispose);
      await expectation;
    },
  );
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

GameUnit _unit(
  String id, {
  required String ownerPlayerId,
  required int col,
  required int row,
}) {
  return GameUnit.produced(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.warrior,
    col: col,
    row: row,
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

Future<void> _waitForMarker(GameRenderer game, String unitId) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    if (game.unitMarkerPositionForTesting(unitId) != null) return;
    await _flush();
  }
  fail('Unit marker $unitId was not created');
}
