import 'dart:async';

import 'package:aonw/map/domain/hex_grid_topology.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_selection_overlay.dart';
import 'package:aonw/map/rendering/hex_tile.dart';
import 'package:aonw/map/rendering/hex_tile_markers.dart';
import 'package:aonw/shared/performance/dev_performance.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

typedef HexTileMarkerBuilder = HexTileMarkers Function(TileData tileData);

/// Grid of [HexTile]s laid out from [MapData].
///
/// Applies Y-scale for isometric perspective.
class HexGrid extends PositionComponent {
  final MapData mapData;
  final MapConfig config;
  MapViewMode _viewMode;
  HexDisplaySettings _displaySettings;
  Set<ResourceType>? _visibleResourceTypes;
  final void Function(TileData tileData)? onTileTapped;
  final bool autoSelectOnTap;
  final HexTileMarkerBuilder? tileMarkerBuilder;

  static const double perspectiveY = 0.62;

  HexTile? _selectedTile;
  HexSelectionOverlay? _selectionOverlay;
  ({int col, int row})? _selectedTileCoords;
  final Map<(int, int), HexTile> _tilesByCoordinate = {};
  final Map<(int, int), HexTileMarkers> _dynamicMarkersByCoordinate = {};
  bool _usesDynamicMarkers = false;

  HexGrid({
    required this.mapData,
    required this.config,
    MapViewMode viewMode = MapViewMode.tile,
    HexDisplaySettings? displaySettings,
    this.onTileTapped,
    this.autoSelectOnTap = true,
    this.tileMarkerBuilder,
  }) : _viewMode = viewMode,
       _displaySettings = displaySettings ?? const HexDisplaySettings(),
       super(scale: Vector2(1.0, perspectiveY));

  MapViewMode get viewMode => _viewMode;

  HexDisplaySettings get displaySettings => _displaySettings;

  ({int col, int row})? get selectedTileCoords => _selectedTileCoords;

  set visibleResourceTypes(Set<ResourceType>? value) {
    final current = _visibleResourceTypes;
    if (current == null && value == null) return;
    if (current != null && value != null && setEquals(current, value)) return;

    _visibleResourceTypes = value == null ? null : Set.unmodifiable(value);
    rebuild();
  }

  @visibleForTesting
  bool get selectionOverlayVisibleForTesting =>
      _selectionOverlay?.visibleForTesting ?? false;

  @visibleForTesting
  int? get selectionOverlayPriorityForTesting => _selectionOverlay?.priority;

  @visibleForTesting
  Color? get selectionOverlayColorForTesting =>
      _selectionOverlay?.colorForTesting;

  @visibleForTesting
  double? get selectionOverlayStrokeWidthForTesting =>
      _selectionOverlay?.highlightStrokeWidthForTesting;

  HexTileMarkers markersForCoordinate(int col, int row) {
    final tile = _tilesByCoordinate[(col, row)];
    return tile?.markers ?? HexTileMarkers.none;
  }

  TileData? tileDataAtWorldPoint(Vector2 worldPoint) {
    final localPoint = absoluteToLocal(worldPoint);
    final coords = HexGeometry.tileAt(
      point: localPoint,
      hexRadius: config.hexRadius,
      cols: mapData.cols,
      rows: mapData.rows,
    );
    if (coords == null) return null;
    return mapData.tileAt(coords.col, coords.row);
  }

  set viewMode(MapViewMode value) {
    if (_viewMode == value) return;
    _viewMode = value;
    _applyPresentationSettingsToTiles();
  }

  set displaySettings(HexDisplaySettings value) {
    if (_displaySettings == value) return;
    _displaySettings = value;
    _applyPresentationSettingsToTiles();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    rebuild();
  }

  /// Builds a height lookup map from MapData: (col, row) → height.
  Map<(int, int), int> buildHeightMap() {
    return {for (final t in mapData.tiles) (t.col, t.row): t.height};
  }

  /// Returns neighborHeights for a tile at (col, row):
  /// [bottom-right neighbor height, bottom neighbor height, bottom-left neighbor height].
  /// null if the neighbor does not exist in the map.
  List<int?> neighborHeights(int col, int row, Map<(int, int), int> heightMap) {
    final isOdd = col.isOdd;
    final bottomRight = isOdd ? (col + 1, row + 1) : (col + 1, row);
    final bottom = (col, row + 1);
    final bottomLeft = isOdd ? (col - 1, row + 1) : (col - 1, row);
    return [heightMap[bottomRight], heightMap[bottom], heightMap[bottomLeft]];
  }

  List<int?> outlineNeighborHeights(
    int col,
    int row,
    Map<(int, int), int> heightMap,
  ) {
    final neighbors = HexGridTopology.neighbors(col: col, row: row);
    final edgeNeighbors = [
      neighbors[1],
      neighbors[2],
      neighbors[3],
      neighbors[4],
      neighbors[5],
      neighbors[0],
    ];
    return [
      for (final neighbor in edgeNeighbors)
        heightMap[(neighbor.col, neighbor.row)],
    ];
  }

  HexTile buildTileComponent({
    required TileData tileData,
    required Vector2 position,
    required void Function() onTapped,
    required List<int?> neighborHeights,
    required List<int?> outlineNeighborHeights,
  }) {
    return HexTile(
      hexRadius: config.hexRadius,
      terrains: tileData.terrains,
      resources: _resourcesForTile(tileData),
      tileHeight: tileData.height,
      neighborHeights: neighborHeights,
      outlineNeighborHeights: outlineNeighborHeights,
      outlineOnlyTopFace: viewMode.usesOutlineHexes,
      showIcon: true,
      showTerrain: displaySettings.showTerrain,
      showResources: displaySettings.showResources,
      showCitySites: displaySettings.showCitySites,
      showCityGrowth: displaySettings.showCityGrowth,
      showHeightBadge: displaySettings.showHeightBadge,
      outlineColor: displaySettings.hexBorderColor,
      selectionColor: displaySettings.selectedHexColor,
      wallTintColor: displaySettings.wallTintColor,
      markers: markersForTile(tileData),
      position: position,
      onTapped: onTapped,
    );
  }

  List<ResourceType> _resourcesForTile(TileData tileData) {
    final visible = _visibleResourceTypes;
    if (visible == null) return tileData.resources;
    return [
      for (final resource in tileData.resources)
        if (visible.contains(resource)) resource,
    ];
  }

  @protected
  HexTileMarkers markersForTile(TileData tileData) {
    final key = (tileData.col, tileData.row);
    if (_usesDynamicMarkers) {
      return _dynamicMarkersByCoordinate[key] ?? HexTileMarkers.none;
    }
    return tileMarkerBuilder?.call(tileData) ?? HexTileMarkers.none;
  }

  void setTileMarkers(Map<(int, int), HexTileMarkers> markersByCoordinate) {
    final next = <(int, int), HexTileMarkers>{
      for (final entry in markersByCoordinate.entries)
        if (entry.value.hasAny) entry.key: entry.value,
    };
    if (_usesDynamicMarkers && mapEquals(_dynamicMarkersByCoordinate, next)) {
      return;
    }

    _usesDynamicMarkers = true;
    _dynamicMarkersByCoordinate
      ..clear()
      ..addAll(next);
    _applyMarkersToTiles();
  }

  void rebuild() {
    DevPerformance.timeSync(
      'HexGrid.rebuild ${mapData.cols}x${mapData.rows}',
      () {
        _selectedTile = null;
        _selectedTileCoords = null;
        _selectionOverlay?.hide();
        _tilesByCoordinate.clear();
        removeWhere((component) => component is HexTile);
        final tiles = <HexTile>[];
        final heightMap = buildHeightMap();

        for (final tileData in mapData.tiles) {
          final pos = HexGeometry.tilePosition(
            col: tileData.col,
            row: tileData.row,
            hexRadius: config.hexRadius,
          );
          final neighbors = neighborHeights(
            tileData.col,
            tileData.row,
            heightMap,
          );
          final outlineNeighbors = outlineNeighborHeights(
            tileData.col,
            tileData.row,
            heightMap,
          );

          late final HexTile tile;
          tile = buildTileComponent(
            tileData: tileData,
            position: pos,
            neighborHeights: neighbors,
            outlineNeighborHeights: outlineNeighbors,
            onTapped: () => _onTileTapped(tile, tileData),
          );
          _tilesByCoordinate[(tileData.col, tileData.row)] = tile;
          tiles.add(tile);
        }

        addTilesSorted(tiles);
        _ensureSelectionOverlay();
      },
    );
  }

  /// Sorts [tiles] by Y position (painter's algorithm) and adds them all.
  @protected
  void addTilesSorted(List<HexTile> tiles) {
    tiles.sort((a, b) => a.position.y.compareTo(b.position.y));
    unawaited(Future<void>.value(addAll(tiles)));
  }

  void _onTileTapped(HexTile tile, TileData tileData) {
    if (autoSelectOnTap) {
      if (_selectedTile == tile) {
        clearSelection();
      } else {
        selectTile(tileData.col, tileData.row);
      }
    }
    onTileTapped?.call(tileData);
  }

  void _applyPresentationSettingsToTiles() {
    for (final tile in children.query<HexTile>()) {
      tile.applyPresentationSettings(
        outlineOnlyTopFace: viewMode.usesOutlineHexes,
        showTerrain: displaySettings.showTerrain,
        showResources: displaySettings.showResources,
        showCitySites: displaySettings.showCitySites,
        showCityGrowth: displaySettings.showCityGrowth,
        showHeightBadge: displaySettings.showHeightBadge,
        outlineColor: displaySettings.hexBorderColor,
        selectionColor: displaySettings.selectedHexColor,
        wallTintColor: displaySettings.wallTintColor,
      );
    }
    _selectionOverlay?.updateColor(displaySettings.selectedHexColor);
  }

  void _applyMarkersToTiles() {
    for (final entry in _tilesByCoordinate.entries) {
      final tile = entry.value;
      final (col, row) = entry.key;
      final tileData = mapData.tileAt(col, row);
      tile.applyMarkers(
        tileData == null ? HexTileMarkers.none : markersForTile(tileData),
      );
    }
  }

  void selectTile(int col, int row) {
    final tile = _tilesByCoordinate[(col, row)];
    if (tile == null) return;
    if (_selectedTile == tile) {
      _selectedTileCoords = (col: col, row: row);
      _showSelectionOverlay(tile);
      return;
    }

    _selectedTile?.deselect();
    tile.select();
    _selectedTile = tile;
    _selectedTileCoords = (col: col, row: row);
    _showSelectionOverlay(tile);
  }

  void clearSelection() {
    _selectedTile?.deselect();
    _selectedTile = null;
    _selectedTileCoords = null;
    _selectionOverlay?.hide();
  }

  void _showSelectionOverlay(HexTile tile) {
    _ensureSelectionOverlay();
    _selectionOverlay?.showAt(
      position: tile.position,
      color: displaySettings.selectedHexColor,
    );
  }

  void _ensureSelectionOverlay() {
    final overlay = _selectionOverlay ??= HexSelectionOverlay(
      hexRadius: config.hexRadius,
      color: displaySettings.selectedHexColor,
    );
    if (overlay.parent == this) return;
    unawaited(Future<void>.value(add(overlay)));
  }
}
