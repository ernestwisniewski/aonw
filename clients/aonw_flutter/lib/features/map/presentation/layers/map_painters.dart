import 'package:flutter/material.dart';

import '../../../../design_system/map_palette.dart';
import '../../read_model/map_view.dart';
import '../geometry/odd_q_flat_top_geometry.dart';
import '../map_render_snapshot.dart';

final class MapTerrainPainter extends CustomPainter {
  MapTerrainPainter({required this.snapshot, required this.geometry});

  final MapRenderSnapshot snapshot;
  final AonwOddQFlatTopGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = geometry.bounds;
    canvas.translate(-bounds.x, -bounds.y);
    for (final tile in snapshot.map.tiles) {
      final path = _hexPath(geometry, tile.coordinate);
      canvas.drawPath(
        path,
        Paint()..color = MapPalette.terrain(tile.displayTerrain),
      );
    }
  }

  @override
  bool shouldRepaint(MapTerrainPainter oldDelegate) =>
      oldDelegate.snapshot.map != snapshot.map;
}

final class MapOverlayPainter extends CustomPainter {
  MapOverlayPainter({required this.snapshot, required this.geometry});

  final MapRenderSnapshot snapshot;
  final AonwOddQFlatTopGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = geometry.bounds;
    canvas.translate(-bounds.x, -bounds.y);
    final grid = Paint()
      ..color = MapPalette.grid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final tile in snapshot.map.tiles) {
      canvas.drawPath(_hexPath(geometry, tile.coordinate), grid);
    }
    _paintHighlight(
      canvas,
      snapshot.interaction.hovered,
      color: MapPalette.hover,
      width: 3,
    );
    _paintHighlight(
      canvas,
      snapshot.interaction.selected,
      color: MapPalette.selection,
      width: 5,
    );
  }

  void _paintHighlight(
    Canvas canvas,
    MapHexCoordinate? coordinate, {
    required Color color,
    required double width,
  }) {
    if (coordinate == null) return;
    canvas.drawPath(
      _hexPath(geometry, coordinate),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(MapOverlayPainter oldDelegate) =>
      oldDelegate.snapshot.interaction != snapshot.interaction ||
      oldDelegate.snapshot.map != snapshot.map;
}

final class MapHexClipper extends CustomClipper<Path> {
  const MapHexClipper({required this.map, required this.geometry});

  final MapView map;
  final AonwOddQFlatTopGeometry geometry;

  @override
  Path getClip(Size size) {
    final bounds = geometry.bounds;
    final path = Path();
    for (final tile in map.tiles) {
      final hex = _hexPath(geometry, tile.coordinate);
      path.addPath(hex, Offset(-bounds.x, -bounds.y));
    }
    return path;
  }

  @override
  bool shouldReclip(MapHexClipper oldClipper) => oldClipper.map != map;
}

Path _hexPath(AonwOddQFlatTopGeometry geometry, MapHexCoordinate coordinate) {
  final first = geometry.corner(coordinate, 0);
  final path = Path()..moveTo(first.x, first.y);
  for (var corner = 1; corner < 6; corner++) {
    final point = geometry.corner(coordinate, corner);
    path.lineTo(point.x, point.y);
  }
  return path..close();
}
