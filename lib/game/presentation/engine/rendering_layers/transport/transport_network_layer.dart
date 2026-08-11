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

  TransportNetworkLayer() {
    priority = MapPriority.transport;
  }

  void sync({
    required Component parent,
    required Iterable<TransportSegment> segments,
    required Iterable<CityHex> cityCenters,
  }) {
    ensureAttachedTo(parent);
    _segments = List.unmodifiable(segments);
    _cityCenters = Set.unmodifiable(
      cityCenters.map((center) => (center.col, center.row)),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_segments.isEmpty) return;

    final operational = {
      for (final segment in _segments)
        if (segment.kind == TransportSegmentKind.road && segment.isOperational)
          (segment.hex.col, segment.hex.row),
    };
    final edgePaint = Paint()
      ..color = HudPalette.roadEdge
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    final asphaltPaint = Paint()
      ..color = HudPalette.roadAsphalt
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    final markingPaint = Paint()
      ..color = HudPalette.roadMarking
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

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
        _drawRoadSegment(
          canvas,
          center,
          neighborCenter,
          edgePaint: edgePaint,
          asphaltPaint: asphaltPaint,
          markingPaint: markingPaint,
        );
      }
      if (!connected) {
        final start = Offset(center.dx - 8, center.dy);
        final end = Offset(center.dx + 8, center.dy);
        _drawRoadSegment(
          canvas,
          start,
          end,
          edgePaint: edgePaint,
          asphaltPaint: asphaltPaint,
          markingPaint: markingPaint,
        );
      }
    }
  }

  static void _drawRoadSegment(
    Canvas canvas,
    Offset start,
    Offset end, {
    required Paint edgePaint,
    required Paint asphaltPaint,
    required Paint markingPaint,
  }) {
    canvas
      ..drawLine(start, end, edgePaint)
      ..drawLine(start, end, asphaltPaint);
    _drawDashedLine(canvas, start, end, markingPaint);
  }

  static void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
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
      canvas.drawLine(
        start + direction * offset,
        start + direction * finish,
        paint,
      );
    }
  }

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
