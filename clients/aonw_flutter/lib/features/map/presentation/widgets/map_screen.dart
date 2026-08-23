import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/aonw_tokens.dart';
import '../../../../design_system/widgets/aonw_panel.dart';
import '../../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../application/map_controller.dart';
import '../../application/map_interaction_state.dart';
import '../../read_model/map_scene.dart';
import '../../read_model/map_view.dart';
import '../camera/map_initial_camera.dart';
import '../geometry/odd_q_flat_top_geometry.dart';
import '../map_render_snapshot.dart';
import 'map_canvas.dart';

final class MapScreen extends StatefulWidget {
  const MapScreen({
    required this.controller,
    this.transformationController,
    this.autoLoad = true,
    super.key,
  });

  final MapController controller;
  final TransformationController? transformationController;
  final bool autoLoad;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

final class _MapScreenState extends State<MapScreen> {
  late TransformationController _camera;
  late bool _ownsCamera;

  @override
  void initState() {
    super.initState();
    _ownsCamera = widget.transformationController == null;
    _camera = widget.transformationController ?? TransformationController();
    if (widget.autoLoad) widget.controller.load();
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transformationController != widget.transformationController) {
      if (_ownsCamera) _camera.dispose();
      _ownsCamera = widget.transformationController == null;
      _camera = widget.transformationController ?? TransformationController();
    }
    if (widget.autoLoad &&
        (oldWidget.controller != widget.controller || !oldWidget.autoLoad)) {
      widget.controller.load();
    }
  }

  @override
  void dispose() {
    if (_ownsCamera) _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: widget.controller, builder: _buildState);

  Widget _buildState(BuildContext context, Widget? child) {
    final state = widget.controller.state;
    return switch (state) {
      MapLoadingState() => const _LoadingMap(),
      MapFailureState(:final code, :final message) => _MapFailure(
        code: code,
        message: message,
        retry: widget.controller.load,
      ),
      MapReadyState(:final scene, :final interaction) => _ReadyMap(
        scene: scene,
        interaction: interaction,
        controller: widget.controller,
        camera: _camera,
      ),
    };
  }
}

final class _ReadyMap extends StatelessWidget {
  const _ReadyMap({
    required this.scene,
    required this.interaction,
    required this.controller,
    required this.camera,
  });

  final MapScene scene;
  final MapInteractionState interaction;
  final MapController controller;
  final TransformationController camera;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: _MapViewport(
          scene: scene,
          interaction: interaction,
          controller: controller,
          camera: camera,
        ),
      ),
      Positioned(
        top: AonwSpacing.md,
        right: AonwSpacing.md,
        child: _ReferenceToggle(
          visible: interaction.referenceVisible,
          onPressed: controller.toggleReference,
        ),
      ),
      if (interaction.selected case final selected?)
        Positioned(
          left: AonwSpacing.md,
          bottom: AonwSpacing.md,
          child: _MapSelectionPanel(
            coordinate: selected,
            interaction: interaction,
            onConfirmMove: controller.confirmMove,
          ),
        ),
    ],
  );
}

final class _MapViewport extends StatefulWidget {
  const _MapViewport({
    required this.scene,
    required this.interaction,
    required this.controller,
    required this.camera,
  });

  final MapScene scene;
  final MapInteractionState interaction;
  final MapController controller;
  final TransformationController camera;

  @override
  State<_MapViewport> createState() => _MapViewportState();
}

final class _MapViewportState extends State<_MapViewport> {
  ({String mapId, String contentHash, TransformationController camera})?
  _initialized;
  ({String mapId, String contentHash, TransformationController camera})?
  _pending;

  @override
  void didUpdateWidget(_MapViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene.map.mapId != widget.scene.map.mapId ||
        oldWidget.scene.map.contentHash != widget.scene.map.contentHash ||
        oldWidget.camera != widget.camera) {
      _initialized = null;
      _pending = null;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _buildLayout);

  Widget _buildLayout(BuildContext context, BoxConstraints constraints) {
    final geometry = AonwOddQFlatTopGeometry(
      cols: widget.scene.map.cols,
      rows: widget.scene.map.rows,
      radius: aonwMapHexRadius,
    );
    final bounds = geometry.bounds;
    final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
    final contentSize = Size(bounds.width, bounds.height);
    final initialScale = MapInitialCamera.scaleFor(
      viewport: viewportSize,
      content: contentSize,
      authoredZoom: widget.scene.map.defaultZoom,
    );
    _scheduleInitialCamera(viewportSize, contentSize);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: InteractiveViewer(
        key: const ValueKey('map-viewport'),
        transformationController: widget.camera,
        constrained: false,
        minScale: math.min(0.25, initialScale),
        maxScale: math.max(4, initialScale * 4),
        boundaryMargin: const EdgeInsets.all(360),
        child: MapCanvas(
          snapshot: MapRenderSnapshot(
            map: widget.scene.map,
            interaction: widget.interaction,
            reference: widget.scene.reference,
            player: widget.scene.player,
          ),
          onHover: widget.controller.hover,
          onSelect: widget.controller.select,
        ),
      ),
    );
  }

  void _scheduleInitialCamera(Size viewport, Size content) {
    final key = (
      mapId: widget.scene.map.mapId,
      contentHash: widget.scene.map.contentHash,
      camera: widget.camera,
    );
    if (_initialized == key || _pending == key) return;
    _pending = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pending != key) return;
      widget.camera.value = MapInitialCamera.centeredFit(
        viewport: viewport,
        content: content,
        authoredZoom: widget.scene.map.defaultZoom,
      );
      _initialized = key;
      _pending = null;
    });
  }
}

final class _ReferenceToggle extends StatelessWidget {
  const _ReferenceToggle({required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    key: const ValueKey('reference-toggle'),
    tooltip: visible ? 'Hide reference layer' : 'Show reference layer',
    onPressed: onPressed,
    icon: Icon(visible ? Icons.layers : Icons.layers_clear),
  );
}

final class _MapSelectionPanel extends StatelessWidget {
  const _MapSelectionPanel({
    required this.coordinate,
    required this.interaction,
    required this.onConfirmMove,
  });

  final MapHexCoordinate coordinate;
  final MapInteractionState interaction;
  final VoidCallback onConfirmMove;

  @override
  Widget build(BuildContext context) => AonwPanel(
    liveRegion: true,
    maxWidth: 320,
    padding: const EdgeInsets.symmetric(
      horizontal: AonwSpacing.md,
      vertical: AonwSpacing.sm,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hex ${coordinate.col}, ${coordinate.row}'),
        if (interaction.selectedUnitId case final unitId?) ...[
          const SizedBox(height: AonwSpacing.xs),
          Text('Unit $unitId'),
          if (interaction.route case final route?) ...[
            Text(
              'Route: ${route.totalCostUnits} movement units · '
              '${route.remainingMovementUnits} remaining',
            ),
            const SizedBox(height: AonwSpacing.sm),
            FilledButton.icon(
              key: const ValueKey('confirm-move'),
              onPressed: interaction.movementPending ? null : onConfirmMove,
              icon: const Icon(Icons.directions_walk),
              label: const Text('Confirm move'),
            ),
          ] else if (!interaction.movementPending)
            const Text('Choose a highlighted destination.'),
        ],
        if (interaction.movementPending) ...[
          const SizedBox(height: AonwSpacing.sm),
          const AonwProgressIndicator(
            semanticLabel: 'Moving unit',
            compact: true,
          ),
        ],
        if (interaction.movementError case final message?) ...[
          const SizedBox(height: AonwSpacing.sm),
          Text(
            message,
            key: const ValueKey('movement-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    ),
  );
}

final class _LoadingMap extends StatelessWidget {
  const _LoadingMap();

  @override
  Widget build(BuildContext context) =>
      const Center(child: AonwProgressIndicator(semanticLabel: 'Loading map'));
}

final class _MapFailure extends StatelessWidget {
  const _MapFailure({
    required this.code,
    required this.message,
    required this.retry,
  });

  final String code;
  final String message;
  final AsyncCallback retry;

  @override
  Widget build(BuildContext context) => Center(
    child: AonwMessagePanel(
      semanticLabel: 'Map loading failed',
      title: 'Map unavailable',
      message: message,
      detail: code,
      actionLabel: 'Retry',
      onAction: retry,
    ),
  );
}
