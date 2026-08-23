import 'package:flutter/material.dart';

import '../../../../design_system/map_palette.dart';
import '../../application/map_interaction_state.dart';
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

final class MapGridPainter extends CustomPainter {
  MapGridPainter({required this.map, required this.geometry});

  final MapView map;
  final AonwOddQFlatTopGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = geometry.bounds;
    canvas.translate(-bounds.x, -bounds.y);
    final grid = Paint()
      ..color = MapPalette.grid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final tile in map.tiles) {
      canvas.drawPath(_hexPath(geometry, tile.coordinate), grid);
    }
  }

  @override
  bool shouldRepaint(MapGridPainter oldDelegate) => oldDelegate.map != map;
}

final class MapInteractionPainter extends CustomPainter {
  MapInteractionPainter({required this.interaction, required this.geometry});

  final MapInteractionState interaction;
  final AonwOddQFlatTopGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = geometry.bounds;
    canvas.translate(-bounds.x, -bounds.y);
    _paintHighlight(
      canvas,
      interaction.hovered,
      color: MapPalette.hover,
      width: 3,
    );
    _paintHighlight(
      canvas,
      interaction.selected,
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
  bool shouldRepaint(MapInteractionPainter oldDelegate) =>
      oldDelegate.interaction != interaction;
}

final class MapMovementPainter extends CustomPainter {
  MapMovementPainter({required this.snapshot, required this.geometry});

  final MapRenderSnapshot snapshot;
  final AonwOddQFlatTopGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = geometry.bounds;
    canvas.translate(-bounds.x, -bounds.y);
    final reachable = snapshot.interaction.reachable;
    if (reachable != null) {
      final paint = Paint()
        ..color = MapPalette.reachable
        ..style = PaintingStyle.fill;
      for (final tile in reachable.tiles) {
        canvas.drawPath(_hexPath(geometry, tile.coordinate), paint);
      }
    }
    final route = snapshot.interaction.route;
    if (route == null || route.steps.isEmpty) return;
    final path = Path();
    for (var index = 0; index < route.steps.length; index++) {
      final center = geometry.center(route.steps[index].coordinate);
      if (index == 0) {
        path.moveTo(center.x, center.y);
      } else {
        path.lineTo(center.x, center.y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = MapPalette.route
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(MapMovementPainter oldDelegate) =>
      oldDelegate.snapshot.interaction.reachable !=
          snapshot.interaction.reachable ||
      oldDelegate.snapshot.interaction.route != snapshot.interaction.route;
}

final class MapUnitPainter extends CustomPainter {
  MapUnitPainter({required this.snapshot, required this.geometry});

  final MapRenderSnapshot snapshot;
  final AonwOddQFlatTopGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = geometry.bounds;
    canvas.translate(-bounds.x, -bounds.y);
    for (final unit in snapshot.player.units) {
      final center = geometry.center(unit.coordinate);
      final point = Offset(center.x, center.y);
      final controlled = unit.ownerPlayerId == snapshot.player.actorPlayerId;
      canvas.drawCircle(
        point,
        17,
        Paint()
          ..color = controlled
              ? MapPalette.controlledUnit
              : MapPalette.foreignUnit,
      );
      canvas.drawCircle(
        point,
        17,
        Paint()
          ..color = MapPalette.unitOutline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      if (unit.id == snapshot.interaction.selectedUnitId) {
        canvas.drawCircle(
          point,
          23,
          Paint()
            ..color = MapPalette.selection
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
    }
  }

  @override
  bool shouldRepaint(MapUnitPainter oldDelegate) =>
      oldDelegate.snapshot.player != snapshot.player ||
      oldDelegate.snapshot.interaction.selectedUnitId !=
          snapshot.interaction.selectedUnitId;
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
