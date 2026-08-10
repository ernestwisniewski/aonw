part of 'cloud_drift_layer.dart';

extension _CloudDriftVisibility on CloudDriftLayer {
  _DiscoveredCloudClip? _buildDiscoveredClip({
    required WorldMap mapData,
    required FogVisibilityQuery visibility,
  }) {
    final path = Path();
    var hasKnownTile = false;
    for (final tile in mapData.tiles) {
      if (!visibility.visibilityForTile(tile).isKnown) {
        continue;
      }
      path.addPath(_hexPath(tile.col, tile.row), Offset.zero);
      hasKnownTile = true;
    }
    return hasKnownTile ? _DiscoveredCloudClip(path) : null;
  }

  Rect _mapBoundsFor(WorldMap mapData) {
    if (mapData.tiles.isEmpty) return Rect.zero;

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final tile in mapData.tiles) {
      final corners = HexGeometry.topFaceCorners(
        center: HexGeometry.tilePosition(
          col: tile.col,
          row: tile.row,
          hexRadius: MapConfig.defaultHexRadius,
        ),
        radius: MapConfig.defaultHexRadius,
      );
      for (final corner in corners) {
        final worldCorner = _projectGridPoint(corner);
        minX = math.min(minX, worldCorner.x);
        minY = math.min(minY, worldCorner.y);
        maxX = math.max(maxX, worldCorner.x);
        maxY = math.max(maxY, worldCorner.y);
      }
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Path _hexPath(int col, int row) {
    return HexGeometry.tileOverlayPath(
      col: col,
      row: row,
      hexRadius: MapConfig.defaultHexRadius,
      perspectiveY: HexGrid.perspectiveY,
    );
  }

  Vector2 _projectGridPoint(Vector2 point) {
    return Vector2(point.x, point.y * HexGrid.perspectiveY);
  }

  int _priorityFor(WorldMap mapData) {
    var maxMarkerPriority = MapPriority.city;
    for (final tile in mapData.tiles) {
      maxMarkerPriority = math.max(
        maxMarkerPriority,
        MapPriority.perTile(MapPriority.city, col: tile.col, row: tile.row),
      );
      maxMarkerPriority = math.max(
        maxMarkerPriority,
        MapPriority.perTileUnit(
          mapRows: mapData.rows,
          col: tile.col,
          row: tile.row,
        ),
      );
    }
    return math.max(MapPriority.cityManagementOverlay, maxMarkerPriority) + 1;
  }

  void _clearClouds() {
    _clouds.clear();
  }
}

class _DiscoveredCloudClip {
  const _DiscoveredCloudClip(this.path);

  final Path path;
}
