import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_tile_markers.dart';
import 'package:aonw/map/rendering/map_palette.dart';
import 'package:aonw/map/rendering/terrain_theme.dart';
import 'package:aonw/map/rendering/tile/hex_icon_cache.dart';
import 'package:aonw/map/rendering/tile/hex_tile_geometry_layout.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw/map/rendering/tile/hex_tile_overlay_geometry.dart';
import 'package:aonw/map/rendering/tile/hex_tile_painter.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// A single hex tile with neighbor-aware depth rendering.
///
/// Walls are drawn only on sides where this tile is higher than its neighbor.
/// Wall height scales with the height difference, creating a terracing effect.
/// [neighborHeights]: 3 values (null = no neighbor), indexed by bottom-facing
/// wall direction: 0 = bottom-right, 1 = bottom, 2 = bottom-left.
class HexTile extends PositionComponent with TapCallbacks {
  final double hexRadius;
  final List<TerrainType> terrains;
  final List<ResourceType> resources;
  final int tileHeight;

  /// Heights of the 3 bottom-facing neighbors: [bottom-right, bottom, bottom-left].
  /// null means no neighbor (treat as height 0 for wall purposes).
  final List<int?> neighborHeights;
  final List<int?> outlineNeighborHeights;

  final VoidCallback onTapped;
  bool outlineOnlyTopFace;
  final bool showIcon;
  bool showTerrain;
  bool showResources;
  bool showCitySites;
  bool showCityGrowth;
  final bool alwaysShowHeight;
  bool showHeightBadge;
  final bool showMovementBlockerOverlay;
  final bool movementBlocked;
  final bool liftOnSelect;
  Color outlineColor;
  Color selectionColor;
  Color wallTintColor;
  HexTileMarkers markers;

  bool _isSelected = false;
  bool get isSelected => _isSelected;

  double _liftOffset = 0.0;
  double get liftOffset => _liftOffset;

  static const double _liftTarget = -6.0;
  static const double _animSpeed = 40.0;
  double _targetLift = 0.0;

  /// Resolved icon asset paths split by type.
  late final List<String> _terrainIconPaths;
  late final List<String> _resourceIconPaths;

  late HexTilePainter _painter;
  late HexTileGeometrySnapshot _geometry;
  late HexTileOverlayGeometry _overlays;
  double _cachedLiftOffset = double.nan;

  HexTile({
    required this.hexRadius,
    required this.terrains,
    required this.resources,
    required this.onTapped,
    this.tileHeight = 0,
    this.neighborHeights = const [null, null, null],
    this.outlineNeighborHeights = const [null, null, null, null, null, null],
    this.outlineOnlyTopFace = false,
    this.showIcon = true,
    this.showTerrain = true,
    this.showResources = true,
    this.showCitySites = false,
    this.showCityGrowth = false,
    this.alwaysShowHeight = false,
    this.showHeightBadge = false,
    this.showMovementBlockerOverlay = false,
    this.movementBlocked = false,
    this.liftOnSelect = false,
    this.outlineColor = Colors.black,
    this.selectionColor = Colors.white,
    this.wallTintColor = MapPalette.defaultWallTint,
    this.markers = HexTileMarkers.none,
    super.position,
  }) : super(
         size: Vector2(
           HexTileMetrics.width(hexRadius),
           HexTileMetrics.height(hexRadius),
         ),
         anchor: Anchor.center,
       ) {
    final sortedTerrains = [...terrains]
      ..sort((a, b) => a.name.compareTo(b.name));
    _terrainIconPaths = sortedTerrains.map(TerrainTheme.icon).toList();
    final sortedResources = [...resources]
      ..sort((a, b) => a.name.compareTo(b.name));
    _resourceIconPaths = sortedResources
        .map((r) => TerrainTheme.resourceIcons[r])
        .whereType<String>()
        .toList();
    _painter = _createPainter();
    _geometry = HexTileGeometryLayout.build(
      hexRadius: hexRadius,
      liftOffset: _liftOffset,
      tileHeight: tileHeight,
      neighborHeights: neighborHeights,
      outlineNeighborHeights: outlineNeighborHeights,
    );
    _overlays = _buildOverlayGeometry();
  }

  void select() {
    _isSelected = true;
    if (liftOnSelect) _targetLift = _liftTarget;
  }

  void deselect() {
    _isSelected = false;
    _targetLift = 0.0;
  }

  void applyPresentationSettings({
    required bool outlineOnlyTopFace,
    required bool showTerrain,
    required bool showResources,
    required bool showCitySites,
    required bool showCityGrowth,
    required bool showHeightBadge,
    required Color outlineColor,
    required Color selectionColor,
    required Color wallTintColor,
  }) {
    if (this.outlineOnlyTopFace == outlineOnlyTopFace &&
        this.showTerrain == showTerrain &&
        this.showResources == showResources &&
        this.showCitySites == showCitySites &&
        this.showCityGrowth == showCityGrowth &&
        this.showHeightBadge == showHeightBadge &&
        this.outlineColor == outlineColor &&
        this.selectionColor == selectionColor &&
        this.wallTintColor == wallTintColor) {
      return;
    }

    this.outlineOnlyTopFace = outlineOnlyTopFace;
    this.showTerrain = showTerrain;
    this.showResources = showResources;
    this.showCitySites = showCitySites;
    this.showCityGrowth = showCityGrowth;
    this.showHeightBadge = showHeightBadge;
    this.outlineColor = outlineColor;
    this.selectionColor = selectionColor;
    this.wallTintColor = wallTintColor;
    _painter = _createPainter();
    _cachedLiftOffset = double.nan;
  }

  void applyMarkers(HexTileMarkers value) {
    if (markers == value) return;
    markers = value;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (!showIcon) return;
    // Load into the global cache; already-cached paths are no-ops.
    final allPaths = {..._terrainIconPaths, ..._resourceIconPaths};
    await HexIconCache.loadAll(allPaths);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if ((_liftOffset - _targetLift).abs() > 0.1) {
      final dir = (_targetLift - _liftOffset).sign;
      _liftOffset += dir * _animSpeed * dt;
      if (dir > 0 && _liftOffset > _targetLift) _liftOffset = _targetLift;
      if (dir < 0 && _liftOffset < _targetLift) _liftOffset = _targetLift;
    } else {
      _liftOffset = _targetLift;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _ensureGeometryCache();

    _painter.render(
      canvas: canvas,
      geometry: _geometry,
      isSelected: _isSelected,
      showIcon: showIcon,
      showTerrain: showTerrain,
      showResources: showResources,
      showCitySiteMarker:
          (showCitySites || markers.forceShowCitySite) && markers.canFoundCity,
      showRecommendedCitySiteMarker: markers.recommendedCitySite,
      showCityGrowthMarker: showCityGrowth && markers.canGrowCity,
      showWorkerImprovementNowMarker: markers.canImproveNow,
      showWorkerImprovementTechMarker: markers.canImproveAfterTechnology,
      showWorkerImprovementCandidateMarker: markers.workerImprovementCandidate,
      showWorkerBuildAvailableBorder: markers.workerBuildAvailable,
      showWorkerBuildBlockedBorder: markers.workerBuildBlocked,
      showAttackTargetMarker: markers.canAttackTarget,
      showHeightBadge: showHeightBadge,
      alwaysShowHeight: alwaysShowHeight,
      showMovementBlockerOverlay: showMovementBlockerOverlay && movementBlocked,
      overlays: _overlays,
      terrainIconPaths: _terrainIconPaths,
      resourceIconPaths: _resourceIconPaths,
      heightPerspectiveY: HexGrid.perspectiveY,
    );
  }

  void _ensureGeometryCache() {
    if (_cachedLiftOffset == _liftOffset) return;

    _cachedLiftOffset = _liftOffset;
    _geometry = HexTileGeometryLayout.build(
      hexRadius: hexRadius,
      liftOffset: _liftOffset,
      tileHeight: tileHeight,
      neighborHeights: neighborHeights,
      outlineNeighborHeights: outlineNeighborHeights,
    );
    _overlays = _buildOverlayGeometry();
  }

  HexTilePainter _createPainter() {
    final primaryTerrain = terrains.isNotEmpty
        ? terrains.first
        : TerrainType.ocean;
    return HexTilePainter(
      topColor: TerrainTheme.topColor(primaryTerrain, null),
      outlineOnlyTopFace: outlineOnlyTopFace,
      outlineColor: outlineColor,
      selectionColor: selectionColor,
      wallTintColor: wallTintColor,
      tileHeight: tileHeight,
    );
  }

  HexTileOverlayGeometry _buildOverlayGeometry() {
    return HexTileOverlayGeometry.build(
      topCenter: _geometry.topCenter,
      terrainIconCount: _terrainIconPaths.length,
      resourceIconCount: _resourceIconPaths.length,
      hexRadius: hexRadius,
      heightParagraphHeight: _painter.heightParagraphHeight,
      heightPerspectiveY: HexGrid.perspectiveY,
    );
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    _ensureGeometryCache();
    return HexGeometry.containsPoint(point, _geometry.topCorners);
  }

  @override
  void onTapUp(TapUpEvent event) => onTapped();
}
