import 'package:aonw/editor/engine/editor_state.dart';
import 'package:aonw/map/domain/map_constraints.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'editor_providers.g.dart';

@riverpod
class EditorStateNotifier extends _$EditorStateNotifier {
  @override
  EditorState build() => const EditorState(
    selectedTerrains: {TerrainType.ocean},
    selectedResources: {},
    selectedObjectiveType: null,
    objectivePaintMode: EditorObjectivePaintMode.none,
    selectedHeight: 0,
    heightActive: false,
  );

  void toggleTerrain(TerrainType t) {
    final updated = Set<TerrainType>.of(state.selectedTerrains);
    if (!updated.remove(t)) updated.add(t);
    state = state.copyWith(selectedTerrains: updated);
  }

  void toggleResource(ResourceType r) {
    final updated = Set<ResourceType>.of(state.selectedResources);
    if (!updated.remove(r)) updated.add(r);
    state = state.copyWith(selectedResources: updated);
  }

  void selectObjective(MapObjectiveType type) {
    state = state.copyWith(
      selectedObjectiveType: type,
      objectivePaintMode: EditorObjectivePaintMode.place,
    );
  }

  void eraseObjective() {
    state = state.copyWith(
      selectedObjectiveType: null,
      objectivePaintMode: EditorObjectivePaintMode.erase,
    );
  }

  void clearObjectiveTool() {
    state = state.copyWith(
      selectedObjectiveType: null,
      objectivePaintMode: EditorObjectivePaintMode.none,
    );
  }

  void setHeight(int h) =>
      state = state.copyWith(selectedHeight: h.clamp(0, 5), heightActive: true);

  void clearHeightActive() => state = state.copyWith(heightActive: false);

  /// Syncs toolbar state to match a tapped tile's values.
  void syncToTile({
    required List<TerrainType> terrains,
    required List<ResourceType> resources,
    MapObjectiveType? objectiveType,
    required int height,
  }) => state = EditorState(
    selectedTerrains: Set.of(terrains),
    selectedResources: Set.of(resources),
    selectedObjectiveType: objectiveType,
    objectivePaintMode: objectiveType == null
        ? EditorObjectivePaintMode.none
        : EditorObjectivePaintMode.place,
    selectedHeight: height,
    heightActive: height > 0,
  );
}

@riverpod
class EditorMapNotifier extends _$EditorMapNotifier {
  @override
  MapData? build() => null;

  void load(MapData mapData) {
    state = mapData;
  }

  void create(int cols, int rows, TerrainType defaultTerrain) {
    final constrainedCols = cols
        .clamp(MapConstraints.minCols, MapConstraints.maxCols)
        .toInt();
    final constrainedRows = rows
        .clamp(MapConstraints.minRows, MapConstraints.maxRows)
        .toInt();

    state = MapData(
      cols: constrainedCols,
      rows: constrainedRows,
      tiles: [
        for (int r = 0; r < constrainedRows; r++)
          for (int c = 0; c < constrainedCols; c++)
            TileData(
              col: c,
              row: r,
              terrains: [defaultTerrain],
              resources: [],
              height: 0,
            ),
      ],
    );
  }

  void clear() {
    state = null;
  }
}
