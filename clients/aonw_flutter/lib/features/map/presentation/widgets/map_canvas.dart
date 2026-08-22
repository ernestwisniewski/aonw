import 'package:flutter/material.dart';

import '../../read_model/map_view.dart';
import '../camera/map_viewport_projection.dart';
import '../geometry/odd_q_flat_top_geometry.dart';
import '../layers/map_painters.dart';
import '../map_render_snapshot.dart';

final class MapCanvas extends StatelessWidget {
  const MapCanvas({
    required this.snapshot,
    required this.onHover,
    required this.onSelect,
    super.key,
  });

  final MapRenderSnapshot snapshot;
  final ValueChanged<MapHexCoordinate?> onHover;
  final ValueChanged<MapHexCoordinate?> onSelect;

  @override
  Widget build(BuildContext context) {
    final map = snapshot.map;
    final geometry = AonwOddQFlatTopGeometry(
      cols: map.cols,
      rows: map.rows,
      radius: aonwMapHexRadius,
    );
    final projection = MapViewportProjection(geometry);
    final bounds = geometry.bounds;
    final selection = snapshot.interaction.selected;
    return Semantics(
      label: 'Map ${map.mapId}, ${map.cols} by ${map.rows} hexes',
      value: selection == null
          ? 'No hex selected'
          : 'Selected hex ${selection.col}, ${selection.row}',
      child: _MapInputRegion(
        projection: projection,
        onHover: onHover,
        onSelect: onSelect,
        child: _MapLayers(
          snapshot: snapshot,
          geometry: geometry,
          size: Size(bounds.width, bounds.height),
        ),
      ),
    );
  }
}

final class _MapInputRegion extends StatelessWidget {
  const _MapInputRegion({
    required this.projection,
    required this.onHover,
    required this.onSelect,
    required this.child,
  });

  final MapViewportProjection projection;
  final ValueChanged<MapHexCoordinate?> onHover;
  final ValueChanged<MapHexCoordinate?> onSelect;
  final Widget child;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onExit: (_) => onHover(null),
    onHover: (event) => onHover(_hexAt(event.localPosition)),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => onSelect(_hexAt(details.localPosition)),
      child: child,
    ),
  );

  MapHexCoordinate? _hexAt(Offset point) =>
      projection.hexAt((x: point.dx, y: point.dy));
}

final class _MapLayers extends StatelessWidget {
  const _MapLayers({
    required this.snapshot,
    required this.geometry,
    required this.size,
  });

  final MapRenderSnapshot snapshot;
  final AonwOddQFlatTopGeometry geometry;
  final Size size;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    key: const ValueKey('map-canvas'),
    size: size,
    child: Stack(
      clipBehavior: Clip.hardEdge,
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: MapTerrainPainter(snapshot: snapshot, geometry: geometry),
        ),
        if (snapshot.interaction.referenceVisible)
          _ReferenceLayer(snapshot: snapshot, geometry: geometry),
        IgnorePointer(
          child: CustomPaint(
            painter: MapOverlayPainter(snapshot: snapshot, geometry: geometry),
          ),
        ),
      ],
    ),
  );
}

final class _ReferenceLayer extends StatelessWidget {
  const _ReferenceLayer({required this.snapshot, required this.geometry});

  final MapRenderSnapshot snapshot;
  final AonwOddQFlatTopGeometry geometry;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: 0.52,
    child: ClipPath(
      clipper: MapHexClipper(map: snapshot.map, geometry: geometry),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const SizedBox.expand(),
          for (final page in snapshot.reference.pages)
            Positioned(
              left: page.destination.x,
              top: page.destination.y,
              width: page.destination.width,
              height: page.destination.height,
              child: Image.memory(
                page.bytes,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
            ),
        ],
      ),
    ),
  );
}
