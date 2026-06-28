import 'dart:ui';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_territory_boundary_shape.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/map_intent_marker.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flame/components.dart';

part 'city_territory_overlay_style.dart';

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
  final Map<_TerritoryRenderStyleKey, _TerritoryRenderStyle>
  _territoryStyleCache;

  CityTerritoryOverlay({
    required List<CityTerritory> territories,
    Map<String, Path>? boundaryPathCache,
    Map<String, Rect>? boundaryBoundsCache,
    bool strategicView = false,
    double zoomEmphasis = 0,
  }) : _strategicView = strategicView,
       _boundaryPathCache = boundaryPathCache ?? <String, Path>{},
       _boundaryBoundsCache = boundaryBoundsCache ?? <String, Rect>{},
       _territoryStyleCache =
           <_TerritoryRenderStyleKey, _TerritoryRenderStyle>{},
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
    _pruneTerritoryStyleCache(_territories);
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

  void _pruneTerritoryStyleCache(List<CityTerritory> territories) {
    if (territories.isEmpty) {
      _territoryStyleCache.clear();
      return;
    }
    final liveColors = {for (final territory in territories) territory.color};
    _territoryStyleCache.removeWhere(
      (key, _) => !liveColors.contains(key.color),
    );
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

  _TerritoryRenderStyle _renderStyleFor(Color color) {
    final key = _TerritoryRenderStyleKey(color, strategicView);
    return _territoryStyleCache.putIfAbsent(
      key,
      () => _TerritoryRenderStyle(color, strategicView: strategicView),
    );
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
      final style = _renderStyleFor(territory.color);
      final fillPaint = HudPaint.fill(
        style.fillColor,
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
      if (!strategicView) {
        _drawTerritoryInsetWash(
          canvas,
          territoryPath,
          style,
          selected: territory.selected,
        );
      }
    }
  }

  void _drawTerritoryBorders(Canvas canvas, Rect clipBounds) {
    for (final territory in territories) {
      if (_isOffscreen(territory, clipBounds)) continue;
      final boundaryPath = _cachedBoundaryPath(territory);
      final style = _renderStyleFor(territory.color);
      if (!strategicView) {
        _drawTerritoryEdgeBand(
          canvas,
          boundaryPath,
          style,
          selected: territory.selected,
        );
      }
      if (strategicView) {
        canvas.drawPath(boundaryPath, style.borderGlowPaint);
      }
      canvas
        ..drawPath(boundaryPath, style.outerBorderPaint)
        ..drawPath(boundaryPath, style.solidBorderPaint)
        ..drawPath(boundaryPath, style.atlasInkBorderPaint)
        ..drawPath(
          boundaryPath,
          style.innerBorderHighlightPaint(
            strategicView
                ? _emphasizedAlpha(MapAlpha.regular, MapAlpha.strong)
                : _emphasizedAlpha(
                    _innerBorderHighlightAlpha,
                    _innerBorderHighlightAlphaZoomedOut,
                  ),
          ),
        );
    }
  }

  void _drawStrategicCityCenters(Canvas canvas, Rect clipBounds) {
    for (final territory in territories) {
      if (_isOffscreen(territory, clipBounds)) continue;
      final center = _hexCenter(territory.center);
      final style = _renderStyleFor(territory.color);
      final ring = _scaledHexPath(territory.center, scale: 0.56);
      canvas
        ..drawPath(ring, style.strategicCenterGlowPaint)
        ..drawPath(ring, _strategicCenterFillPaint)
        ..drawPath(ring, _strategicCenterBorderPaint)
        ..drawPath(ring, style.strategicCenterInnerPaint);
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
    final style = _renderStyleFor(selectedTerritory.color);
    canvas
      ..drawPath(
        boundaryPath,
        style.selectedBorderGlowPaint(
          _emphasizedAlpha(
            _selectedBorderGlowAlpha,
            _selectedBorderGlowAlphaZoomedOut,
          ),
        ),
      )
      ..drawPath(boundaryPath, style.outerBorderPaint)
      ..drawPath(boundaryPath, style.solidBorderPaint)
      ..drawPath(boundaryPath, style.atlasInkBorderPaint)
      ..drawPath(
        boundaryPath,
        style.selectedBorderHighlightPaint(
          _emphasizedAlpha(
            _selectedBorderHighlightAlpha,
            _selectedBorderHighlightAlphaZoomedOut,
          ),
        ),
      );
  }

  void _drawTerritoryInsetWash(
    Canvas canvas,
    Path boundaryPath,
    _TerritoryRenderStyle style, {
    required bool selected,
  }) {
    final washPaint = style.insetWashPaint(
      selected: selected,
      blurred: _zoomEmphasis < _edgeBlurZoomCutoff,
    );
    canvas
      ..save()
      ..clipPath(boundaryPath, doAntiAlias: true)
      ..drawPath(boundaryPath, washPaint)
      ..restore();
  }

  void _drawTerritoryEdgeBand(
    Canvas canvas,
    Path boundaryPath,
    _TerritoryRenderStyle style, {
    required bool selected,
  }) {
    // The blurred glow stroke is the single most expensive draw per
    // territory (gaussian blur is a 2-pass shader on Impeller). When zoomed
    // out the blur radius is sub-pixel anyway, so we drop it past a
    // threshold and rely on the solid band below to convey the edge.
    final glowPaint = HudPaint.stroke(
      style.edgeBandColor,
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
          style.edgeBandColor,
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
    canvas.drawPath(path, _mapDimmingPaint);
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
const int _territoryInsetWashAlpha = 36;
const int _selectedTerritoryInsetWashAlpha = 48;
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
const double _territoryInsetWashWidth = 27.0;
const double _selectedTerritoryInsetWashWidth = 31.0;
const double _territoryInsetWashBlur = 2.4;
const double _territoryEdgeBlur = 5.2;
const double _outerBorderWidth = 5.2;
const double _strategicOuterBorderWidth = 4.6;
const double _solidBorderWidth = 3.2;
const double _strategicSolidBorderWidth = 3.5;
const int _atlasInkBorderAlpha = 190;
const double _atlasInkBorderWidth = 1.25;
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
