part of 'city_territory_overlay.dart';

extension _CityTerritoryOverlayGeometry on CityTerritoryOverlay {
  Path _boundaryPath(Iterable<CityTerritoryBoundaryEdge> edges) {
    final segments = <_BoundarySegment>[
      for (final edge in edges)
        switch (_edgeEndpoints(edge)) {
          (final start, final end) => _BoundarySegment(start, end),
        },
    ];
    if (segments.isEmpty) return Path();

    final segmentsByStart = <String, List<_BoundarySegment>>{};
    for (final segment in segments) {
      segmentsByStart
          .putIfAbsent(_boundaryPointKey(segment.start), () => [])
          .add(segment);
    }

    final path = Path();
    final remaining = segments.toSet();
    while (remaining.isNotEmpty) {
      final first = remaining.first;
      remaining.remove(first);
      final points = <Offset>[first.start, first.end];
      var current = first.end;

      while (!_sameBoundaryPoint(current, first.start)) {
        final next = _takeNextBoundarySegment(
          segmentsByStart,
          remaining,
          current,
        );
        if (next == null) break;
        points.add(next.end);
        current = next.end;
      }

      final closed =
          points.length > 2 && _sameBoundaryPoint(points.first, points.last);
      path.addPath(
        cityTerritoryBoundaryShapePath(points, closed: closed),
        Offset.zero,
      );
    }
    return path;
  }

  _BoundarySegment? _takeNextBoundarySegment(
    Map<String, List<_BoundarySegment>> segmentsByStart,
    Set<_BoundarySegment> remaining,
    Offset point,
  ) {
    final candidates = segmentsByStart[_boundaryPointKey(point)];
    if (candidates == null) return null;
    while (candidates.isNotEmpty) {
      final segment = candidates.removeAt(0);
      if (!remaining.remove(segment)) continue;
      return segment;
    }
    return null;
  }

  bool _sameBoundaryPoint(Offset a, Offset b) {
    return _boundaryPointKey(a) == _boundaryPointKey(b);
  }

  String _boundaryPointKey(Offset point) {
    return '${(point.dx * 1000).round()}:${(point.dy * 1000).round()}';
  }

  Path _scaledHexPath(CityHex hex, {required double scale}) {
    final center = _hexCenter(hex);
    final corners = _hexCorners(hex)
        .map(
          (corner) => Offset(
            center.dx + (corner.dx - center.dx) * scale,
            center.dy + (corner.dy - center.dy) * scale,
          ),
        )
        .toList(growable: false);
    final path = Path()..moveTo(corners.first.dx, corners.first.dy);
    for (final corner in corners.skip(1)) {
      path.lineTo(corner.dx, corner.dy);
    }
    return path..close();
  }

  List<Offset> _hexCorners(CityHex hex) {
    return HexGeometry.topFaceCornerOffsets(col: hex.col, row: hex.row);
  }

  (int, int) _cornerIndexesFor(CityHexEdge side) {
    return switch (side) {
      CityHexEdge.northEast => (5, 0),
      CityHexEdge.southEast => (0, 1),
      CityHexEdge.south => (1, 2),
      CityHexEdge.southWest => (2, 3),
      CityHexEdge.northWest => (3, 4),
      CityHexEdge.north => (4, 5),
    };
  }

  (Offset, Offset) _edgeEndpoints(CityTerritoryBoundaryEdge edge) {
    final corners = _hexCorners(edge.hex);
    final indexes = _cornerIndexesFor(edge.side);
    return (corners[indexes.$1], corners[indexes.$2]);
  }

  Offset _hexCenter(CityHex hex) {
    return HexGeometry.topFaceCentroid(col: hex.col, row: hex.row);
  }
}

class _BoundarySegment {
  const _BoundarySegment(this.start, this.end);

  final Offset start;
  final Offset end;
}
