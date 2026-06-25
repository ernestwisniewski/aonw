import 'dart:ui';

import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_chip_id.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mapInspectionControllerProvider =
    NotifierProvider<MapInspectionController, MapInspectionState>(
      MapInspectionController.new,
    );

class MapInspectionState {
  const MapInspectionState({
    this.selection,
    this.artifact,
    this.objectiveProgress,
    this.openChipId,
    this.anchor,
    this.previewing = false,
  });

  static const empty = MapInspectionState();

  final GameSelection? selection;
  final WorldArtifact? artifact;
  final MapObjectiveProgress? objectiveProgress;
  final String? openChipId;
  final Offset? anchor;
  final bool previewing;

  bool get active =>
      selection != null || artifact != null || objectiveProgress != null;

  bool get anchored => anchor != null;
}

class MapInspectionController extends Notifier<MapInspectionState> {
  @override
  MapInspectionState build() => MapInspectionState.empty;

  void inspectTile(
    TileData tileData, {
    Offset? anchor,
    MapObjectiveProgress? objectiveProgress,
  }) {
    state = MapInspectionState(
      selection: GameSelection.tile(tileData),
      objectiveProgress: objectiveProgress,
      openChipId: SelectionInfoChipId.description,
      anchor: anchor,
    );
  }

  void inspectArtifact(WorldArtifact artifact, {Offset? anchor}) {
    state = MapInspectionState(artifact: artifact, anchor: anchor);
  }

  void inspectObjective(MapObjectiveProgress progress, {Offset? anchor}) {
    state = MapInspectionState(objectiveProgress: progress, anchor: anchor);
  }

  void previewTile(
    TileData tileData, {
    Offset? anchor,
    MapObjectiveProgress? objectiveProgress,
  }) {
    state = MapInspectionState(
      selection: GameSelection.tile(tileData),
      objectiveProgress: objectiveProgress,
      openChipId: SelectionInfoChipId.description,
      anchor: anchor,
      previewing: true,
    );
  }

  void confirmPreview() {
    if (!state.previewing) return;
    state = MapInspectionState(
      selection: state.selection,
      artifact: state.artifact,
      objectiveProgress: state.objectiveProgress,
      openChipId: state.openChipId,
      anchor: state.anchor,
    );
  }

  void cancelPreview() {
    if (!state.previewing) return;
    state = MapInspectionState.empty;
  }

  void toggleDetail(String chipId) {
    final selection = state.selection;
    if (selection == null) return;
    state = MapInspectionState(
      selection: selection,
      objectiveProgress: state.objectiveProgress,
      openChipId: state.openChipId == chipId ? null : chipId,
      anchor: state.anchor,
      previewing: false,
    );
  }

  void clear() {
    if (!state.active) return;
    state = MapInspectionState.empty;
  }
}
