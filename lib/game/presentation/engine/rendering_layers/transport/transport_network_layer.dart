import 'dart:ui';

import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/transport.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:flame/components.dart';

/// Batched, non-interactive map layer for transport infrastructure.
class TransportNetworkLayer extends PositionComponent with LayerAttachment {
  List<TransportSegment> _segments = const [];
  Set<(int, int)> _cityCenters = const {};
  Path _roadPath = Path();
  Path _markingPath = Path();
  int _geometryBuildCount = 0;
  final Paint _edgePaint = Paint()
    ..color = HudPalette.roadEdge
    ..strokeWidth = 9
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true;
  final Paint _asphaltPaint = Paint()
    ..color = HudPalette.roadAsphalt
    ..strokeWidth = 7
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true;
  final Paint _markingPaint = Paint()
    ..color = HudPalette.roadMarking
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true;

  TransportNetworkLayer() {
    priority = MapPriority.transport;
  }

  void sync({
    required Component parent,
    required Iterable<TransportSegment> segments,
    required Iterable<CityHex> cityCenters,
  }) {
    ensureAttachedTo(parent);
    final nextSegments = List<TransportSegment>.unmodifiable(segments);
    final nextCityCenters = Set<(int, int)>.unmodifiable(
      cityCenters.map((center) => (center.col, center.row)),
    );
    if (_sameSegments(_segments, nextSegments) &&
        _sameCoordinates(_cityCenters, nextCityCenters)) {
      return;
    }
    _segments = nextSegments;
    _cityCenters = nextCityCenters;
    _rebuildGeometry();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_segments.isEmpty) return;
    canvas
      ..drawPath(_roadPath, _edgePaint)
      ..drawPath(_roadPath, _asphaltPaint)
      ..drawPath(_markingPath, _markingPaint);
  }

  void _rebuildGeometry() {
    _geometryBuildCount++;
    final roadPath = Path();
    final markingPath = Path();
    final operational = {
      for (final segment in _segments)
        if (segment.kind == TransportSegmentKind.road && segment.isOperational)
          (segment.hex.col, segment.hex.row),
    };

    for (final coordinate in operational) {
      final center = _center(coordinate.$1, coordinate.$2);
      var connected = false;
      for (final neighbor in HexGeometry.neighbors(
        col: coordinate.$1,
        row: coordinate.$2,
      )) {
        final target = (neighbor.col, neighbor.row);
        final connectsRoad = operational.contains(target);
        final connectsCity = _cityCenters.contains(target);
        if (!connectsRoad && !connectsCity) continue;
        connected = true;
        if (connectsRoad && !_drawsEdge(coordinate, target)) continue;
        final neighborCenter = _center(target.$1, target.$2);
        _addRoadSegment(roadPath, markingPath, center, neighborCenter);
      }
      if (!connected) {
        final start = Offset(center.dx - 8, center.dy);
        final end = Offset(center.dx + 8, center.dy);
        _addRoadSegment(roadPath, markingPath, start, end);
      }
    }
    _roadPath = roadPath;
    _markingPath = markingPath;
  }

  static void _addRoadSegment(
    Path roadPath,
    Path markingPath,
    Offset start,
    Offset end,
  ) {
    roadPath
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
    _addDashedLine(markingPath, start, end);
  }

  static void _addDashedLine(Path path, Offset start, Offset end) {
    const dashLength = 6.0;
    const gapLength = 5.0;
    final delta = end - start;
    final length = delta.distance;
    if (length == 0) return;
    final direction = delta / length;
    for (var offset = 0.0; offset < length; offset += dashLength + gapLength) {
      final finish = offset + dashLength < length
          ? offset + dashLength
          : length;
      final dashStart = start + direction * offset;
      final dashEnd = start + direction * finish;
      path
        ..moveTo(dashStart.dx, dashStart.dy)
        ..lineTo(dashEnd.dx, dashEnd.dy);
    }
  }

  static bool _sameSegments(
    List<TransportSegment> a,
    List<TransportSegment> b,
  ) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  static bool _sameCoordinates(Set<(int, int)> a, Set<(int, int)> b) =>
      a.length == b.length && a.containsAll(b);

  static Offset _center(int col, int row) {
    final center = HexGeometry.topFaceCenter(
      col: col,
      row: row,
      hexRadius: MapConfig.defaultHexRadius,
    );
    return Offset(center.x, center.y);
  }

  static bool _drawsEdge((int, int) source, (int, int) target) {
    final columnOrder = source.$1.compareTo(target.$1);
    return columnOrder < 0 ||
        (columnOrder == 0 && source.$2.compareTo(target.$2) < 0);
  }

  int get segmentCountForTesting => _segments.length;

  int get geometryBuildCountForTesting => _geometryBuildCount;

  int get cityConnectionCountForTesting {
    final operational = {
      for (final segment in _segments)
        if (segment.kind == TransportSegmentKind.road && segment.isOperational)
          (segment.hex.col, segment.hex.row),
    };
    var count = 0;
    for (final road in operational) {
      for (final neighbor in HexGeometry.neighbors(
        col: road.$1,
        row: road.$2,
      )) {
        if (_cityCenters.contains((neighbor.col, neighbor.row))) count++;
      }
    }
    return count;
  }
}
