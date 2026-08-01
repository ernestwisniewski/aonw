part of 'game_renderer.dart';

typedef WorkerActionPaletteOptionsBuilder =
    List<ActionPaletteOption> Function({
      required GameClientState state,
      required GameUnit worker,
      required PendingWorkerActionSelection pendingAction,
      required WorldMap mapData,
    });
typedef TileInspectionCallback =
    void Function(WorldTile tileData, Offset anchor);
typedef ArtifactInspectionCallback =
    void Function(WorldArtifact artifact, Offset anchor);
typedef ObjectiveInspectionCallback =
    void Function(MapObjectiveProgress progress, Offset anchor);

extension _GameRendererLayerFactories on GameRenderer {
  FloatingTextLayer _createFloatingTextLayer() => FloatingTextLayer(
    reduceMotion: _reduceMotion,
    unitPositionFor: _unitMarkerLayer.worldPositionForUnit,
  );
}
