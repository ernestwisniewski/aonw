import 'dart:ui';

import 'package:aonw/game/presentation/engine/rendering_layers/city/city_territory_boundary_shape.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/map_intent_marker.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:flame/components.dart';

part 'city_territory_overlay_style.dart';
part 'city_territory_overlay_cache.dart';
part 'city_territory_overlay_drawing.dart';
part 'city_territory_overlay_geometry.dart';

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

  static double _clampedZoomEmphasis(double value) {
    return value.clamp(0.0, 1.0).toDouble();
  }
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
