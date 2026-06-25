import 'dart:math' as math;

import 'package:aonw/map/domain/hex_grid_topology.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_tile.dart';
import 'package:aonw/map/rendering/hex_tile_markers.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map() => MapData(
  cols: 2,
  rows: 2,
  tiles: [
    for (int r = 0; r < 2; r++)
      for (int c = 0; c < 2; c++)
        TileData(
          col: c,
          row: r,
          terrains: const [TerrainType.ocean],
          resources: const [],
          height: 0,
        ),
  ],
);

void main() {
  group('HexGeometry tilePosition', () {
    const radius = 36.0;

    test('col=0 row=0 is at (radius, sqrt(3)/2 * radius)', () {
      final pos = HexGeometry.tilePosition(col: 0, row: 0, hexRadius: radius);
      expect(pos.x, closeTo(radius, 0.01));
      expect(pos.y, closeTo(radius * math.sqrt(3) / 2, 0.01));
    });

    test('col=1 is offset right by 1.5 * radius', () {
      final pos0 = HexGeometry.tilePosition(col: 0, row: 0, hexRadius: radius);
      final pos1 = HexGeometry.tilePosition(col: 1, row: 0, hexRadius: radius);
      expect(pos1.x - pos0.x, closeTo(1.5 * radius, 0.01));
    });

    test('odd column is shifted down by sqrt(3)/2 * radius', () {
      final even = HexGeometry.tilePosition(col: 0, row: 0, hexRadius: radius);
      final odd = HexGeometry.tilePosition(col: 1, row: 0, hexRadius: radius);
      expect(odd.y - even.y, closeTo(math.sqrt(3) / 2 * radius, 0.01));
    });
  });

  group('HexGridTopology neighbors', () {
    test('even columns use odd-q neighbor offsets', () {
      final neighbors = HexGridTopology.neighbors(col: 0, row: 1);
      expect(
        neighbors,
        containsAll([
          (col: 1, row: 0),
          (col: 1, row: 1),
          (col: 0, row: 2),
          (col: -1, row: 1),
          (col: -1, row: 0),
          (col: 0, row: 0),
        ]),
      );
    });

    test('odd columns use shifted neighbor offsets', () {
      final neighbors = HexGridTopology.neighbors(col: 1, row: 1);
      expect(
        neighbors,
        containsAll([
          (col: 2, row: 1),
          (col: 2, row: 2),
          (col: 1, row: 2),
          (col: 0, row: 2),
          (col: 0, row: 1),
          (col: 1, row: 0),
        ]),
      );
    });

    test('areNeighbors accepts adjacent hexes and rejects distant ones', () {
      expect(
        HexGridTopology.areNeighbors(
          col: 0,
          row: 0,
          targetCol: 1,
          targetRow: 0,
        ),
        isTrue,
      );
      expect(
        HexGridTopology.areNeighbors(
          col: 0,
          row: 0,
          targetCol: 2,
          targetRow: 0,
        ),
        isFalse,
      );
    });
  });

  group('HexGrid selection', () {
    test('outline neighbor heights are ordered by top outline edge', () {
      final mapData = MapData(
        cols: 3,
        rows: 3,
        tiles: [
          for (var row = 0; row < 3; row++)
            for (var col = 0; col < 3; col++)
              TileData(
                col: col,
                row: row,
                terrains: const [TerrainType.ocean],
                resources: const [],
                height: row * 3 + col,
              ),
        ],
      );
      final grid = HexGrid(
        mapData: mapData,
        config: MapConfig.defaultConfig,
        autoSelectOnTap: false,
      );
      final heights = grid.outlineNeighborHeights(1, 1, grid.buildHeightMap());

      expect(heights, [8, 7, 6, 3, 1, 5]);
    });

    test('tileDataAtWorldPoint resolves a perspective-scaled tile hit', () {
      final grid = HexGrid(
        mapData: _map(),
        config: MapConfig.defaultConfig,
        autoSelectOnTap: false,
      );
      final tileCenter = HexGeometry.tilePosition(
        col: 1,
        row: 0,
        hexRadius: MapConfig.defaultConfig.hexRadius,
      );
      final worldPoint = grid.positionOf(tileCenter);

      final tile = grid.tileDataAtWorldPoint(worldPoint);

      expect(tile?.col, 1);
      expect(tile?.row, 0);
    });

    test('selectTile and clearSelection control tile highlight state', () {
      final grid = HexGrid(
        mapData: _map(),
        config: MapConfig.defaultConfig,
        autoSelectOnTap: false,
      )..rebuild();
      expect(grid.selectedTileCoords, isNull);

      grid.selectTile(0, 0);
      expect(grid.selectedTileCoords, (col: 0, row: 0));

      grid.selectTile(1, 0);
      expect(grid.selectedTileCoords, (col: 1, row: 0));

      grid.clearSelection();
      expect(grid.selectedTileCoords, isNull);
    });

    test('selected tile overlay is rendered above terrain tiles', () {
      final grid = HexGrid(
        mapData: _map(),
        config: MapConfig.defaultConfig,
        autoSelectOnTap: false,
      )..rebuild();

      expect(grid.selectionOverlayVisibleForTesting, isFalse);

      grid.selectTile(1, 0);

      final tilePriorities = grid.children.query<HexTile>().map(
        (tile) => tile.priority,
      );
      final highestTilePriority = tilePriorities.reduce(math.max);
      expect(grid.selectionOverlayVisibleForTesting, isTrue);
      expect(
        grid.selectionOverlayPriorityForTesting,
        greaterThan(highestTilePriority),
      );
      expect(grid.selectionOverlayStrokeWidthForTesting, greaterThan(3));
      expect(
        grid.selectionOverlayColorForTesting,
        const HexDisplaySettings().selectedHexColor,
      );

      grid.clearSelection();

      expect(grid.selectionOverlayVisibleForTesting, isFalse);
    });
  });

  group('HexGrid planning markers', () {
    test('updates live tile markers without rebuilding the grid', () {
      final grid = HexGrid(
        mapData: _map(),
        config: MapConfig.defaultConfig,
        autoSelectOnTap: false,
      )..rebuild();

      expect(grid.markersForCoordinate(0, 0), HexTileMarkers.none);

      grid.setTileMarkers({
        (0, 0): const HexTileMarkers(canFoundCity: true),
        (1, 0): const HexTileMarkers(canGrowCity: true),
      });

      expect(grid.markersForCoordinate(0, 0).canFoundCity, isTrue);
      expect(grid.markersForCoordinate(0, 0).canGrowCity, isFalse);
      expect(grid.markersForCoordinate(1, 0).canFoundCity, isFalse);
      expect(grid.markersForCoordinate(1, 0).canGrowCity, isTrue);
    });
  });
}
