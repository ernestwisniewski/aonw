import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/objective.dart';

enum EditorObjectivePaintMode { none, place, erase }

class EditorState {
  final Set<TerrainType> selectedTerrains;
  final Set<ResourceType> selectedResources;
  final MapObjectiveType? selectedObjectiveType;
  final EditorObjectivePaintMode objectivePaintMode;
  final int selectedHeight;
  final bool heightActive;

  const EditorState({
    required this.selectedTerrains,
    required this.selectedResources,
    this.selectedObjectiveType,
    this.objectivePaintMode = EditorObjectivePaintMode.none,
    required this.selectedHeight,
    required this.heightActive,
  });

  EditorState copyWith({
    Set<TerrainType>? selectedTerrains,
    Set<ResourceType>? selectedResources,
    Object? selectedObjectiveType = _sentinel,
    EditorObjectivePaintMode? objectivePaintMode,
    int? selectedHeight,
    bool? heightActive,
  }) => EditorState(
    selectedTerrains: selectedTerrains ?? Set.of(this.selectedTerrains),
    selectedResources: selectedResources ?? Set.of(this.selectedResources),
    selectedObjectiveType: identical(selectedObjectiveType, _sentinel)
        ? this.selectedObjectiveType
        : selectedObjectiveType as MapObjectiveType?,
    objectivePaintMode: objectivePaintMode ?? this.objectivePaintMode,
    selectedHeight: selectedHeight ?? this.selectedHeight,
    heightActive: heightActive ?? this.heightActive,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorState &&
          _setsEqual(selectedTerrains, other.selectedTerrains) &&
          _setsEqual(selectedResources, other.selectedResources) &&
          selectedObjectiveType == other.selectedObjectiveType &&
          objectivePaintMode == other.objectivePaintMode &&
          selectedHeight == other.selectedHeight &&
          heightActive == other.heightActive;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(selectedTerrains),
    Object.hashAllUnordered(selectedResources),
    selectedObjectiveType,
    objectivePaintMode,
    selectedHeight,
    heightActive,
  );

  static bool _setsEqual<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}

const Object _sentinel = Object();
