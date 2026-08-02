import 'package:aonw/editor/domain/map_draft.dart';
import 'package:aonw/editor/engine/editor_state.dart';
import 'package:aonw/editor/engine/editor_world.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists default zoom changes through the draft callback', () {
    final zooms = <double>[];
    final world = EditorWorld(
      draft: MapDraft(
        cols: 1,
        rows: 1,
        tiles: [
          WorldTile(
            col: 0,
            row: 0,
            terrains: [TerrainType.ocean],
            resources: [],
            height: 0,
          ),
        ],
      ),
      editorState: const EditorState(
        selectedTerrains: {TerrainType.ocean},
        selectedResources: {},
        selectedHeight: 0,
        heightActive: false,
      ),
      onDefaultZoomChanged: zooms.add,
    )..defaultZoom = 1.75;

    expect(world.defaultZoom, 1.75);
    expect(world.draft.defaultZoom, 1.75);
    expect(zooms, [1.75]);
  });
}
