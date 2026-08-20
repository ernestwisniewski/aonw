import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/game_renderer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('artifact and objective icons open their inspection popups', () async {
    final tile = WorldTile(
      col: 0,
      row: 0,
      terrains: const [TerrainType.grassland],
      resources: const [],
      height: 0,
    );
    const objective = MapObjectiveDefinition(
      id: 'ruins_1',
      type: MapObjectiveType.ruins,
      hex: HexCoord(col: 0, row: 0),
    );
    final map = WorldMap(
      cols: 1,
      rows: 1,
      tiles: [tile],
      objectives: const [objective],
    );
    final artifact = WorldArtifact.placed(
      type: WorldArtifactType.heroSword,
      col: 0,
      row: 0,
    );
    final inspectedArtifactIds = <String>[];
    final inspectedObjectiveIds = <String>[];
    final game = GameRenderer(
      mapData: map,
      onCommand: (_) async {},
      onArtifactInspected: (value, _) {
        inspectedArtifactIds.add(value.id);
      },
      onObjectiveInspected: (value, _) {
        inspectedObjectiveIds.add(value.definition.id);
      },
    );
    addTearDown(game.disposeRenderer);
    game.onGameResize(Vector2(800, 600));
    await game.onLoad();
    game
      ..applyState(
        GameClientState(
          activePlayerId: 'player_1',
          artifacts: [artifact],
          fogOfWar: FogOfWarState.empty.updatePlayer(
            PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: <HexCoordinate>{
                const HexCoordinate(col: 0, row: 0),
              },
            ),
          ),
        ),
      )
      ..handleTileLongPressedForTesting(tile)
      ..finishTileLongPressForTesting();
    final artifactTargetKey = 'artifact:${artifact.id}';
    expect(
      game.hexSelectionPaletteForTesting!.targets.map((target) => target.key),
      containsAll([artifactTargetKey, 'objective:ruins_1']),
    );
    game.hexSelectionPaletteForTesting!.selectForTesting(artifactTargetKey);

    expect(inspectedArtifactIds, [artifact.id]);

    game
      ..handleTileLongPressedForTesting(tile)
      ..finishTileLongPressForTesting();
    game.hexSelectionPaletteForTesting!.selectForTesting('objective:ruins_1');

    expect(inspectedObjectiveIds, ['ruins_1']);
  });
}
