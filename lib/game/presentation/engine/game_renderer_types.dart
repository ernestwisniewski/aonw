part of 'game_renderer.dart';

typedef WorkerActionPaletteOptionsBuilder =
    List<ActionPaletteOption> Function({
      required GameState state,
      required GameUnit worker,
      required PendingWorkerActionSelection pendingAction,
      required MapData mapData,
    });
typedef TileInspectionCallback =
    void Function(TileData tileData, Offset anchor);
typedef ArtifactInspectionCallback =
    void Function(WorldArtifact artifact, Offset anchor);
typedef ObjectiveInspectionCallback =
    void Function(MapObjectiveProgress progress, Offset anchor);
