import 'dart:ui';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/map_intent_marker.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flame/components.dart';

class CityTerritory {
  final Color color;
  final CityHex center;
  final List<CityHex> hexes;
  final bool selected;
  // Stable key derived from the hex set so cached boundary geometry can be
  // reused across overlay instances that get rebuilt every time game state
  // changes. Equal `hexes` lists always produce the same key.
  final String hexesSignature;

  CityTerritory({
    required this.color,
    required this.center,
    required List<CityHex> hexes,
    this.selected = false,
  }) : hexes = List.unmodifiable(hexes),
       hexesSignature = _signatureFor(hexes);

  static String _signatureFor(List<CityHex> hexes) {
    final sorted = [...hexes]
      ..sort((a, b) {
        final byRow = a.row.compareTo(b.row);
        return byRow != 0 ? byRow : a.col.compareTo(b.col);
      });
    final buf = StringBuffer();
    for (final hex in sorted) {
      buf
        ..write(hex.col)
        ..write(',')
        ..write(hex.row)
        ..write(';');
    }
    return buf.toString();
  }
}

class CityTerritoryOverlay extends Component {
  late List<CityTerritory> _territories;
  bool _strategicView;
  double _zoomEmphasis;
  // Boundary path + bounds geometry depends only on a territory's hex set.
  // The overlay is persistent across game state syncs, so these caches survive
  // selection, visibility, and strategic-view changes. `_boundaryBoundsCache`
  // stores the path's bounds inflated by the culling margin, used for
  // off-screen rejection.
  final Map<String, Path> _boundaryPathCache;
  final Map<String, Rect> _boundaryBoundsCache;

  CityTerritoryOverlay({
    required List<CityTerritory> territories,
    Map<String, Path>? boundaryPathCache,
    Map<String, Rect>? boundaryBoundsCache,
    bool strategicView = false,
    double zoomEmphasis = 0,
  }) : _strategicView = strategicView,
       _boundaryPathCache = boundaryPathCache ?? <String, Path>{},
       _boundaryBoundsCache = boundaryBoundsCache ?? <String, Rect>{},
       _zoomEmphasis = _clampedZoomEmphasis(zoomEmphasis) {
    updateTerritories(territories: territories, strategicView: strategicView);
  }

  List<CityTerritory> get territories => _territories;

  bool get strategicView => _strategicView;

  double get zoomEmphasis => _zoomEmphasis;

  set zoomEmphasis(double value) {
    _zoomEmphasis = _clampedZoomEmphasis(value);
  }

  void updateTerritories({
    required Iterable<CityTerritory> territories,
    required bool strategicView,
  }) {
    _territories = List.unmodifiable(territories);
    _strategicView = strategicView;
    _pruneBoundaryCache(_territories);
  }

  void _pruneBoundaryCache(List<CityTerritory> territories) {
    if (territories.isEmpty) {
      _boundaryPathCache.clear();
      _boundaryBoundsCache.clear();
      return;
    }
    final liveSignatures = {
      for (final territory in territories) territory.hexesSignature,
    };
    _boundaryPathCache.removeWhere((key, _) => !liveSignatures.contains(key));
    _boundaryBoundsCache.removeWhere((key, _) => !liveSignatures.contains(key));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final clipBounds = canvas.getLocalClipBounds();
    final selectedTerritory = _selectedTerritory();
    _drawTerritoryFills(canvas, clipBounds);
    _drawTerritoryBorders(canvas, clipBounds);
    if (strategicView) {
      _drawStrategicCityCenters(canvas, clipBounds);
    }

    if (selectedTerritory == null) {
      return;
    }

    if (!strategicView) {
      _drawMapDimming(canvas, selectedTerritory);
    }
    _drawSelectedTerritoryBorder(canvas, selectedTerritory);
  }

  Path _cachedBoundaryPath(CityTerritory territory) {
    return _boundaryPathCache.putIfAbsent(
      territory.hexesSignature,
      () => _boundaryPath(CityTerritoryBoundary.edgesFor(territory.hexes)),
    );
  }

  // Bounds of a territory's boundary path, inflated to cover the widest
  // border stroke + maskFilter blur applied by the various draw passes. If
  // this rect does not intersect the canvas clip bounds the territory is
  // entirely off-screen and every draw pass can skip it.
  Rect _cachedBoundaryBounds(CityTerritory territory) {
    return _boundaryBoundsCache.putIfAbsent(
      territory.hexesSignature,
      () => _cachedBoundaryPath(territory).getBounds().inflate(_cullingMargin),
    );
  }

  bool _isOffscreen(CityTerritory territory, Rect clipBounds) {
    if (clipBounds.isEmpty) return false;
    return !_cachedBoundaryBounds(territory).overlaps(clipBounds);
  }

  CityTerritory? _selectedTerritory() {
    for (final territory in territories) {
      if (territory.selected) {
        return territory;
      }
    }
    return null;
  }

  void _drawTerritoryFills(Canvas canvas, Rect clipBounds) {
    for (final territory in territories) {
      if (_isOffscreen(territory, clipBounds)) continue;
      final fillColor = strategicView
          ? Color.lerp(territory.color, HudPalette.goldLight, 0.18)!
          : territory.color;
      final fillPaint = HudPaint.fill(
        fillColor,
        alpha: strategicView
            ? _tileTerritoryFillAlpha
            : territory.selected
            ? _emphasizedAlpha(
                _selectedTerritoryFillAlpha,
                _selectedTerritoryFillAlphaZoomedOut,
              )
            : _emphasizedAlpha(
                _territoryFillAlpha,
                _territoryFillAlphaZoomedOut,
              ),
      );
      final territoryPath = _cachedBoundaryPath(territory);
      canvas.drawPath(territoryPath, fillPaint);
    }
  }

  void _drawTerritoryBorders(Canvas canvas, Rect clipBounds) {
    for (final territory in territories) {
      if (_isOffscreen(territory, clipBounds)) continue;
      final boundaryPath = _cachedBoundaryPath(territory);
      if (!strategicView) {
        _drawTerritoryEdgeBand(
          canvas,
          boundaryPath,
          territory.color,
          selected: territory.selected,
        );
      }
      if (strategicView) {
        final glowPaint = _borderGlowPaint(territory.color);
        canvas.drawPath(boundaryPath, glowPaint);
      }
      final edgePaint = _solidBorderPaint(territory.color);
      canvas
        ..drawPath(boundaryPath, _outerBorderPaint(territory.color))
        ..drawPath(boundaryPath, edgePaint)
        ..drawPath(boundaryPath, _innerBorderHighlightPaint(territory.color));
    }
  }

  void _drawStrategicCityCenters(Canvas canvas, Rect clipBounds) {
    for (final territory in territories) {
      if (_isOffscreen(territory, clipBounds)) continue;
      final center = _hexCenter(territory.center);
      final playerColor = Color.lerp(
        territory.color,
        HudPalette.goldLight,
        0.22,
      )!;
      final ring = _scaledHexPath(territory.center, scale: 0.56);
      canvas
        ..drawPath(
          ring,
          HudPaint.stroke(
            playerColor,
            alpha: MapAlpha.strong,
            strokeWidth: MapStroke.glow,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        )
        ..drawPath(ring, HudPaint.fill(HudPalette.bg, alpha: MapAlpha.regular))
        ..drawPath(
          ring,
          HudPaint.stroke(
            HudPalette.goldLight,
            alpha: MapAlpha.opaque,
            strokeWidth: MapStroke.regular,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        )
        ..drawPath(
          ring,
          HudPaint.stroke(
            playerColor,
            alpha: MapAlpha.solid,
            strokeWidth: MapStroke.hairline,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        );
      MapIntentMarker.paintGlyph(
        canvas,
        center,
        MapIntentGlyph.city,
        color: HudPalette.goldLight,
        scale: 1.05,
      );
    }
  }

  void _drawSelectedTerritoryBorder(
    Canvas canvas,
    CityTerritory selectedTerritory,
  ) {
    final boundaryPath = _cachedBoundaryPath(selectedTerritory);
    canvas
      ..drawPath(
        boundaryPath,
        _selectedBorderGlowPaint(selectedTerritory.color),
      )
      ..drawPath(boundaryPath, _outerBorderPaint(selectedTerritory.color))
      ..drawPath(boundaryPath, _solidBorderPaint(selectedTerritory.color))
      ..drawPath(
        boundaryPath,
        _selectedBorderHighlightPaint(selectedTerritory.color),
      );
  }

  void _drawTerritoryEdgeBand(
    Canvas canvas,
    Path boundaryPath,
    Color color, {
    required bool selected,
  }) {
    final bandColor = Color.lerp(color, HudPalette.copper, 0.18)!;
    // The blurred glow stroke is the single most expensive draw per
    // territory (gaussian blur is a 2-pass shader on Impeller). When zoomed
    // out the blur radius is sub-pixel anyway, so we drop it past a
    // threshold and rely on the solid band below to convey the edge.
    final glowPaint = HudPaint.stroke(
      bandColor,
      alpha: selected
          ? _emphasizedAlpha(
              _selectedTerritoryEdgeGlowAlpha,
              _selectedTerritoryEdgeGlowAlphaZoomedOut,
            )
          : _emphasizedAlpha(
              _territoryEdgeGlowAlpha,
              _territoryEdgeGlowAlphaZoomedOut,
            ),
      strokeWidth: selected
          ? _selectedTerritoryEdgeGlowWidth
          : _territoryEdgeGlowWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
    if (_zoomEmphasis < _edgeBlurZoomCutoff) {
      glowPaint.maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        _territoryEdgeBlur,
      );
    }
    canvas
      ..drawPath(boundaryPath, glowPaint)
      ..drawPath(
        boundaryPath,
        HudPaint.stroke(
          bandColor,
          alpha: selected
              ? _emphasizedAlpha(
                  _selectedTerritoryEdgeBandAlpha,
                  _selectedTerritoryEdgeBandAlphaZoomedOut,
                )
              : _emphasizedAlpha(
                  _territoryEdgeBandAlpha,
                  _territoryEdgeBandAlphaZoomedOut,
                ),
          strokeWidth: selected
              ? _selectedTerritoryEdgeBandWidth
              : _territoryEdgeBandWidth,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
  }

  Paint _outerBorderPaint(Color color) {
    final borderShadow = Color.lerp(color, HudPalette.bg, 0.72)!;
    return HudPaint.stroke(
      borderShadow,
      alpha: strategicView ? MapAlpha.strong : MapAlpha.solid,
      strokeWidth: strategicView
          ? _strategicOuterBorderWidth
          : _outerBorderWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
  }

  Paint _solidBorderPaint(Color color) {
    final playerColor = Color.lerp(
      color,
      HudPalette.bg,
      strategicView ? _strategicBorderPlayerDarken : _solidBorderPlayerDarken,
    )!;
    return HudPaint.stroke(
      playerColor,
      alpha: strategicView ? MapAlpha.opaque : MapAlpha.full,
      strokeWidth: strategicView
          ? _strategicSolidBorderWidth
          : _solidBorderWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
  }

  Paint _borderGlowPaint(Color color) {
    final glow = Color.lerp(color, HudPalette.goldLight, 0.34)!;
    return HudPaint.stroke(
      glow,
      alpha: MapAlpha.regular,
      strokeWidth: MapStroke.glow,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  }

  Paint _innerBorderHighlightPaint(Color color) {
    final playerColor = Color.lerp(color, HudPalette.textBright, 0.26)!;
    return HudPaint.stroke(
      playerColor,
      alpha: strategicView
          ? _emphasizedAlpha(MapAlpha.regular, MapAlpha.strong)
          : _emphasizedAlpha(
              _innerBorderHighlightAlpha,
              _innerBorderHighlightAlphaZoomedOut,
            ),
      strokeWidth: strategicView
          ? _strategicInnerBorderWidth
          : _innerBorderWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
  }

  Paint _selectedBorderGlowPaint(Color color) {
    final glow = Color.lerp(color, HudPalette.goldLight, 0.18)!;
    return HudPaint.stroke(
      glow,
      alpha: _emphasizedAlpha(
        _selectedBorderGlowAlpha,
        _selectedBorderGlowAlphaZoomedOut,
      ),
      strokeWidth: _selectedBorderGlowWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.6);
  }

  Paint _selectedBorderHighlightPaint(Color color) {
    final highlight = Color.lerp(color, HudPalette.textBright, 0.34)!;
    return HudPaint.stroke(
      highlight,
      alpha: _emphasizedAlpha(
        _selectedBorderHighlightAlpha,
        _selectedBorderHighlightAlphaZoomedOut,
      ),
      strokeWidth: _selectedBorderHighlightWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
  }

  void _drawMapDimming(Canvas canvas, CityTerritory selectedTerritory) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(
        const Rect.fromLTRB(
          -_mapDimmingExtent,
          -_mapDimmingExtent,
          _mapDimmingExtent,
          _mapDimmingExtent,
        ),
      )
      ..addPath(_cachedBoundaryPath(selectedTerritory), Offset.zero);
    canvas.drawPath(
      path,
      HudPaint.fill(HudPalette.bg, alpha: MapAlpha.regular),
    );
  }

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

      path.addPath(_civLikeBoundaryPath(points), Offset.zero);
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

  Path _civLikeBoundaryPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    final closed =
        points.length > 2 && _sameBoundaryPoint(points.first, points.last);
    final baseLoopPoints = closed
        ? points.sublist(0, points.length - 1)
        : points;
    final loopPoints = closed
        ? _organicBoundaryPoints(baseLoopPoints)
        : baseLoopPoints;
    if (!closed || loopPoints.length < 3) {
      path.moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      return path;
    }

    final smoothedPoints = _smoothBoundaryPoints(loopPoints);
    return _curvedLoopPath(smoothedPoints);
  }

  Path _curvedLoopPath(List<Offset> points) {
    final path = Path();
    if (points.length < 3) return path;

    final start = _midpoint(points.last, points.first);
    path.moveTo(start.dx, start.dy);
    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      final end = _midpoint(current, next);
      path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
    }
    return path..close();
  }

  List<Offset> _smoothBoundaryPoints(List<Offset> points) {
    var smoothed = points;
    for (var pass = 0; pass < _boundarySmoothingPasses; pass++) {
      final nextPoints = <Offset>[];
      for (var i = 0; i < smoothed.length; i++) {
        final current = smoothed[i];
        final next = smoothed[(i + 1) % smoothed.length];
        final delta = next - current;
        nextPoints
          ..add(current + delta * _boundaryCornerCut)
          ..add(current + delta * (1 - _boundaryCornerCut));
      }
      smoothed = nextPoints;
    }
    return smoothed;
  }

  List<Offset> _organicBoundaryPoints(List<Offset> points) {
    if (points.length < 2) return points;

    final organic = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final start = points[i];
      final end = points[(i + 1) % points.length];
      organic.add(start);

      final delta = end - start;
      final length = delta.distance;
      if (length <= _organicMinSegmentLength) continue;

      final normal = Offset(-delta.dy / length, delta.dx / length);
      for (var step = 1; step <= _organicSegmentSteps; step++) {
        final t = step / (_organicSegmentSteps + 1);
        final base = Offset(start.dx + delta.dx * t, start.dy + delta.dy * t);
        final jitter =
            _boundaryNoise(start: start, end: end, step: step) *
            _organicBoundaryJitter;
        organic.add(base + normal * jitter);
      }
    }
    return organic;
  }

  double _boundaryNoise({
    required Offset start,
    required Offset end,
    required int step,
  }) {
    var hash = 17;
    hash = _hashBoundaryValue(hash, start.dx);
    hash = _hashBoundaryValue(hash, start.dy);
    hash = _hashBoundaryValue(hash, end.dx);
    hash = _hashBoundaryValue(hash, end.dy);
    hash = 37 * hash + step * 104729;
    final value = hash.abs() % 2001;
    return value / 1000.0 - 1.0;
  }

  int _hashBoundaryValue(int hash, double value) {
    return 37 * hash + (value * 1000).round();
  }

  Offset _midpoint(Offset a, Offset b) =>
      Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

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
    final hexRadius = MapConfig.defaultConfig.hexRadius;
    final center = HexGeometry.tilePosition(
      col: hex.col,
      row: hex.row,
      hexRadius: hexRadius,
    );
    final topFaceCenter = Vector2(
      center.x,
      center.y + HexTileMetrics.topCenterAnchorOffsetY(hexRadius),
    );
    final corners = HexGeometry.topFaceCorners(
      center: topFaceCenter,
      radius: hexRadius,
    );
    return [for (final corner in corners) Offset(corner.x, corner.y)];
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
    final corners = _hexCorners(hex);
    var dx = 0.0;
    var dy = 0.0;
    for (final corner in corners) {
      dx += corner.dx;
      dy += corner.dy;
    }
    return Offset(dx / corners.length, dy / corners.length);
  }

  int _emphasizedAlpha(int baseAlpha, int zoomedOutAlpha) {
    return lerpDouble(
      baseAlpha.toDouble(),
      zoomedOutAlpha.toDouble(),
      _zoomEmphasis,
    )!.round();
  }

  static double _clampedZoomEmphasis(double value) {
    return value.clamp(0.0, 1.0).toDouble();
  }
}

class _BoundarySegment {
  const _BoundarySegment(this.start, this.end);

  final Offset start;
  final Offset end;
}

const double _mapDimmingExtent = 100000.0;
const int _territoryFillAlpha = 42;
const int _selectedTerritoryFillAlpha = 56;
const int _tileTerritoryFillAlpha = 230;
const int _territoryFillAlphaZoomedOut = 150;
const int _selectedTerritoryFillAlphaZoomedOut = 176;
const int _territoryEdgeGlowAlpha = 88;
const int _selectedTerritoryEdgeGlowAlpha = 106;
const int _territoryEdgeBandAlpha = 60;
const int _selectedTerritoryEdgeBandAlpha = 78;
const int _innerBorderHighlightAlpha = 118;
const int _selectedBorderGlowAlpha = 132;
const int _selectedBorderHighlightAlpha = 168;
const int _territoryEdgeGlowAlphaZoomedOut = 126;
const int _selectedTerritoryEdgeGlowAlphaZoomedOut = 148;
const int _territoryEdgeBandAlphaZoomedOut = 92;
const int _selectedTerritoryEdgeBandAlphaZoomedOut = 112;
const int _innerBorderHighlightAlphaZoomedOut = 150;
const int _selectedBorderGlowAlphaZoomedOut = 164;
const int _selectedBorderHighlightAlphaZoomedOut = 196;
const double _territoryEdgeGlowWidth = 17.0;
const double _selectedTerritoryEdgeGlowWidth = 19.0;
const double _territoryEdgeBandWidth = 9.2;
const double _selectedTerritoryEdgeBandWidth = 10.8;
const double _territoryEdgeBlur = 5.2;
const int _organicSegmentSteps = 1;
const double _organicBoundaryJitter = 2.4;
const double _organicMinSegmentLength = 18.0;
const int _boundarySmoothingPasses = 2;
const double _boundaryCornerCut = 0.18;
const double _outerBorderWidth = 5.2;
const double _strategicOuterBorderWidth = 4.6;
const double _solidBorderWidth = 3.2;
const double _strategicSolidBorderWidth = 3.5;
const double _innerBorderWidth = 1.1;
const double _strategicInnerBorderWidth = 1.2;
const double _selectedBorderGlowWidth = 8.8;
const double _selectedBorderHighlightWidth = 1.6;
const double _solidBorderPlayerDarken = 0.48;
const double _strategicBorderPlayerDarken = 0.12;
// Inflation around boundary path bounds for off-screen culling. Must cover
// the widest stroke half-width (~20 px for selected territory edge glow) and
// the maskFilter blur radius (~5 px). 40 px is a comfortable bound.
const double _cullingMargin = 40.0;
// Past this zoom-out emphasis the edge glow blur is too small to see but
// still costs a 2-pass shader per territory. Drop the blur entirely.
const double _edgeBlurZoomCutoff = 0.5;
