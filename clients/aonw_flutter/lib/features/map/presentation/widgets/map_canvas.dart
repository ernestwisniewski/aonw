import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/l10n.dart';
import '../../read_model/map_view.dart';
import '../camera/map_viewport_projection.dart';
import '../geometry/odd_q_flat_top_geometry.dart';
import '../input/map_input.dart';
import '../layers/map_painters.dart';
import '../map_render_snapshot.dart';

void _ignoreMapInput(MapInputCommand _) {}

final class MapCanvas extends StatelessWidget {
  const MapCanvas({
    required this.snapshot,
    required this.onHover,
    required this.onSelect,
    this.onInput = _ignoreMapInput,
    super.key,
  });

  final MapRenderSnapshot snapshot;
  final ValueChanged<MapHexCoordinate?> onHover;
  final ValueChanged<MapHexCoordinate?> onSelect;
  final ValueChanged<MapInputCommand> onInput;

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
    final l10n = context.aonwL10n;
    return Semantics(
      label: l10n.mapSemanticsLabel(map.mapId, map.cols, map.rows),
      hint: l10n.mapInputHint,
      value: selection == null
          ? l10n.noHexSelected
          : l10n.selectedHex(selection.col, selection.row),
      child: _MapInputRegion(
        projection: projection,
        onHover: onHover,
        onSelect: onSelect,
        onInput: onInput,
        child: _MapLayers(
          snapshot: snapshot,
          geometry: geometry,
          size: Size(bounds.width, bounds.height),
        ),
      ),
    );
  }
}

final class _MapInputRegion extends StatefulWidget {
  const _MapInputRegion({
    required this.projection,
    required this.onHover,
    required this.onSelect,
    required this.onInput,
    required this.child,
  });

  final MapViewportProjection projection;
  final ValueChanged<MapHexCoordinate?> onHover;
  final ValueChanged<MapHexCoordinate?> onSelect;
  final ValueChanged<MapInputCommand> onInput;
  final Widget child;

  @override
  State<_MapInputRegion> createState() => _MapInputRegionState();
}

final class _MapInputRegionState extends State<_MapInputRegion> {
  static final _commandsByKey = <LogicalKeyboardKey, MapInputCommand>{
    LogicalKeyboardKey.arrowUp: MapInputCommand.cursorUp,
    LogicalKeyboardKey.keyW: MapInputCommand.cursorUp,
    LogicalKeyboardKey.arrowDown: MapInputCommand.cursorDown,
    LogicalKeyboardKey.keyS: MapInputCommand.cursorDown,
    LogicalKeyboardKey.arrowLeft: MapInputCommand.cursorLeft,
    LogicalKeyboardKey.keyA: MapInputCommand.cursorLeft,
    LogicalKeyboardKey.arrowRight: MapInputCommand.cursorRight,
    LogicalKeyboardKey.keyD: MapInputCommand.cursorRight,
    LogicalKeyboardKey.enter: MapInputCommand.activate,
    LogicalKeyboardKey.space: MapInputCommand.activate,
    LogicalKeyboardKey.escape: MapInputCommand.cancel,
    LogicalKeyboardKey.keyR: MapInputCommand.toggleReference,
  };

  final _focusNode = FocusNode(debugLabel: 'AoNW map input');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focusNode,
    autofocus: true,
    onKeyEvent: _onKeyEvent,
    child: Listener(
      onPointerDown: (_) => _focusNode.requestFocus(),
      child: MouseRegion(
        onExit: (_) => widget.onHover(null),
        onHover: (event) => widget.onHover(_hexAt(event.localPosition)),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => widget.onSelect(_hexAt(details.localPosition)),
          child: widget.child,
        ),
      ),
    ),
  );

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final command = _commandForKey(event.logicalKey);
    if (command == null) return KeyEventResult.ignored;
    widget.onInput(command);
    return KeyEventResult.handled;
  }

  MapInputCommand? _commandForKey(LogicalKeyboardKey key) =>
      _commandsByKey[key];

  MapHexCoordinate? _hexAt(Offset point) =>
      widget.projection.hexAt((x: point.dx, y: point.dy));
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
        RepaintBoundary(
          key: const ValueKey('static-terrain-layer'),
          child: CustomPaint(
            painter: MapTerrainPainter(snapshot: snapshot, geometry: geometry),
          ),
        ),
        if (snapshot.interaction.referenceVisible)
          RepaintBoundary(
            key: const ValueKey('static-reference-layer'),
            child: _ReferenceLayer(snapshot: snapshot, geometry: geometry),
          ),
        RepaintBoundary(
          key: const ValueKey('static-grid-layer'),
          child: CustomPaint(
            painter: MapGridPainter(map: snapshot.map, geometry: geometry),
          ),
        ),
        IgnorePointer(
          child: RepaintBoundary(
            key: const ValueKey('movement-layer'),
            child: CustomPaint(
              painter: MapMovementPainter(
                snapshot: snapshot,
                geometry: geometry,
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: RepaintBoundary(
            key: const ValueKey('interaction-layer'),
            child: CustomPaint(
              painter: MapInteractionPainter(
                interaction: snapshot.interaction,
                geometry: geometry,
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: RepaintBoundary(
            key: const ValueKey('unit-layer'),
            child: CustomPaint(
              painter: MapUnitPainter(snapshot: snapshot, geometry: geometry),
            ),
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
