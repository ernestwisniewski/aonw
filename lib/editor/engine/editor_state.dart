import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'editor_state.freezed.dart';

enum EditorObjectivePaintMode { none, place, erase }

@freezed
abstract class EditorState with _$EditorState {
  const EditorState._();

  const factory EditorState({
    required Set<TerrainType> selectedTerrains,
    required Set<ResourceType> selectedResources,
    MapObjectiveType? selectedObjectiveType,
    @Default(EditorObjectivePaintMode.none)
    EditorObjectivePaintMode objectivePaintMode,
    required int selectedHeight,
    required bool heightActive,
  }) = _EditorState;
}
