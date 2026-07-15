import 'package:aonw/editor/domain/map_draft.dart';
import 'package:aonw/editor/engine/editor_grid.dart';
import 'package:aonw/editor/engine/editor_state.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_constraints.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('removing the outer row drops objectives outside the new bounds', () {
    const removedRow = MapConstraints.minRows;
    final mapData =
        MapDraft(
          cols: MapConstraints.minCols,
          rows: MapConstraints.minRows + 1,
          tiles: [
            for (var row = 0; row <= removedRow; row++)
              for (var col = 0; col < MapConstraints.minCols; col++)
                TileData(
                  col: col,
                  row: row,
                  terrains: const [TerrainType.grassland],
                  resources: const [],
                  height: 0,
                ),
          ],
        )..placeObjective(
          const MapObjectiveDefinition(
            id: 'pass_removed_row',
            type: MapObjectiveType.strategicPass,
            hex: HexCoord(col: 0, row: removedRow),
            victoryPoints: 2,
          ),
        );
    var objectiveChangeCount = 0;
    EditorGrid(
        draft: mapData,
        config: MapConfig.defaultConfig,
        editorState: const EditorState(
          selectedTerrains: {TerrainType.grassland},
          selectedResources: {},
          selectedHeight: 0,
          heightActive: false,
        ),
        onObjectivesChanged: () => objectiveChangeCount++,
      )
      ..rebuild()
      ..removeRow();

    expect(mapData.rows, MapConstraints.minRows);
    expect(mapData.objectives, isEmpty);
    expect(objectiveChangeCount, 1);
  });
}
