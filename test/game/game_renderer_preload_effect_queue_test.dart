import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_renderer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'pre-load camera batch cannot expose the next transition final position',
    () async {
      final unit = GameUnit.produced(
        id: 'unit',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final game = GameRenderer(mapData: _map(), onCommand: (_) async {});
      addTearDown(game.disposeRenderer);
      game.applyState(GameState(units: [unit], activePlayerId: 'player_1'));
      await game.handleEffect(
        const SmoothCameraEffect(col: 2, row: 1, duration: 0.48),
      );

      final transition = game.applyTransition(
        GameState(
          units: [unit.copyWith(col: 1, row: 0)],
          activePlayerId: 'player_1',
        ),
        const [
          AnimateUnitMoveEffect(
            unitId: 'unit',
            fromCol: 0,
            fromRow: 0,
            steps: [
              UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
            ],
          ),
        ],
      );
      final expectation = expectLater(transition, throwsA(isA<StateError>()));
      await _flush();

      game.onGameResize(Vector2(800, 600));
      await game.onLoad();
      await _waitForMarker(game, unit.id);

      _expectAt(game, unit.id, 0, 0);
      game.update(0.24);
      await _flush();
      _expectAt(game, unit.id, 0, 0);

      game.disposeRenderer();
      await expectation;
    },
  );
}

MapData _map() => MapData(
  cols: 3,
  rows: 2,
  tiles: [
    for (var row = 0; row < 2; row++)
      for (var col = 0; col < 3; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

Future<void> _waitForMarker(GameRenderer game, String unitId) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    if (game.unitMarkerPositionForTesting(unitId) != null) return;
    await _flush();
  }
  fail('Unit marker $unitId was not created');
}

void _expectAt(GameRenderer game, String unitId, int col, int row) {
  expect(
    game.unitMarkerPositionForTesting(unitId),
    UnitMarkerLayer.worldPositionFor(col, row),
  );
}
