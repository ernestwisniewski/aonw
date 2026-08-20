part of 'hover_intent_marker_test.dart';

Future<ui.Rect?> _paintedMoveCueBounds(HoverIntentMarker marker) async {
  const imageSize = 160;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final worldCenter = HexGeometry.topFaceCentroid(col: 0, row: 0);
  canvas.translate(80 - worldCenter.dx, 80 - worldCenter.dy);
  marker.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(imageSize, imageSize);
  picture.dispose();
  final bytes = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  image.dispose();
  if (bytes == null) return null;

  var left = imageSize;
  var top = imageSize;
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < imageSize; y++) {
    for (var x = 0; x < imageSize; x++) {
      final alpha = bytes.getUint8(((y * imageSize) + x) * 4 + 3);
      if (alpha == 0) continue;
      left = math.min(left, x);
      top = math.min(top, y);
      right = math.max(right, x);
      bottom = math.max(bottom, y);
    }
  }
  if (right < left || bottom < top) return null;
  return ui.Rect.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    (right + 1).toDouble(),
    (bottom + 1).toDouble(),
  );
}

Future<GameRenderer> _loadedGame(
  WorldMap map, {
  Future<void> Function(GameIntent command)? onCommand,
  TileInspectionCallback? onTileInspected,
}) async {
  final game = GameRenderer(
    mapData: map,
    onCommand: onCommand ?? (_) async {},
    onTileInspected: onTileInspected,
  );
  addTearDown(game.disposeRenderer);
  game.onGameResize(Vector2(800, 600));
  await game.onLoad();
  return game;
}

WorldMap _map({CityHex? blockedHex, int cols = 3, int rows = 3}) => WorldMap(
  cols: cols,
  rows: rows,
  tiles: [
    for (int row = 0; row < rows; row++)
      for (int col = 0; col < cols; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: blockedHex?.col == col && blockedHex?.row == row
              ? const [TerrainType.grassland, TerrainType.mountain]
              : const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

WorldTile _tile(WorldMap map, int col, int row) {
  return map.tiles.firstWhere((tile) => tile.col == col && tile.row == row);
}

GameCity _city({required String id, required int col, required int row}) {
  return GameCity(
    id: id,
    ownerPlayerId: 'player_1',
    name: id,
    center: CityHex(col: col, row: row),
    controlledHexes: [CityHex(col: col, row: row)],
  );
}
