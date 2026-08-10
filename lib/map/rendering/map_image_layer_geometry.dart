part of 'map_image_layer.dart';

extension _MapImageLayerGeometry on MapImageLayer {
  void _updateSize() {
    final r = config.hexRadius;
    final maxX = r + (_cols - 1) * 1.5 * r + r;
    final lastColIsOdd = (_cols - 1).isOdd;
    final maxY =
        (math.sqrt(3) / 2 * r) +
        (_rows - 1) * math.sqrt(3) * r +
        (lastColIsOdd ? math.sqrt(3) / 2 * r : 0) +
        (math.sqrt(3) / 2 * r);
    size = Vector2(maxX, maxY);
    _updateSingleDst();
  }

  void _updateSingleDst() {
    if (_image == null) return;
    _singleDst = Rect.fromLTWH(0, 0, size.x, size.y);
  }

  Rect _sliceDst(int col, int row) {
    final r = config.hexRadius;
    final sqrt3 = math.sqrt(3);
    final tileH = sqrt3 * r;
    final cx = r + col * 1.5 * r;
    final cy =
        (sqrt3 / 2 * r) + row * sqrt3 * r + (col.isOdd ? sqrt3 / 2 * r : 0);
    return Rect.fromLTWH(cx - r, cy - tileH / 2, 2 * r, tileH);
  }

  Path _sliceClipPath(int col, int row) {
    return HexGeometry.tileOverlayPath(
      col: col,
      row: row,
      hexRadius: config.hexRadius,
    );
  }
}
