import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../application/map_controller.dart';
import '../../application/map_interaction_state.dart';
import '../../read_model/map_scene.dart';
import '../../read_model/map_view.dart';
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
  late final TransformationController _camera;
  late final bool _ownsCamera;

  @override
  void initState() {
    super.initState();
    _ownsCamera = widget.transformationController == null;
    _camera = widget.transformationController ?? TransformationController();
    if (widget.autoLoad) widget.controller.load();
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
        top: 12,
        right: 12,
        child: _ReferenceToggle(
          visible: interaction.referenceVisible,
          onPressed: controller.toggleReference,
        ),
      ),
      if (interaction.selected case final selected?)
        Positioned(
          left: 12,
          bottom: 12,
          child: _SelectedHex(coordinate: selected),
        ),
    ],
  );
}

final class _MapViewport extends StatelessWidget {
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
  Widget build(BuildContext context) => LayoutBuilder(builder: _buildLayout);

  Widget _buildLayout(BuildContext context, BoxConstraints constraints) {
    final geometry = AonwOddQFlatTopGeometry(
      cols: scene.map.cols,
      rows: scene.map.rows,
      radius: aonwMapHexRadius,
    );
    final bounds = geometry.bounds;
    final fit = math.min(
      constraints.maxWidth / bounds.width,
      constraints.maxHeight / bounds.height,
    );
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: InteractiveViewer(
        key: const ValueKey('map-viewport'),
        transformationController: camera,
        constrained: false,
        minScale: math.min(0.25, fit),
        maxScale: math.max(4, scene.map.defaultZoom * 4),
        boundaryMargin: const EdgeInsets.all(360),
        child: MapCanvas(
          snapshot: MapRenderSnapshot(
            map: scene.map,
            interaction: interaction,
            reference: scene.reference,
          ),
          onHover: controller.hover,
          onSelect: controller.select,
        ),
      ),
    );
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

final class _SelectedHex extends StatelessWidget {
  const _SelectedHex({required this.coordinate});

  final MapHexCoordinate coordinate;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text('Hex ${coordinate.col}, ${coordinate.row}'),
      ),
    ),
  );
}

final class _LoadingMap extends StatelessWidget {
  const _LoadingMap();

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: 'Loading map',
      child: const CircularProgressIndicator(),
    ),
  );
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
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Semantics(
        label: 'Map loading failed',
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Map unavailable',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(code, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 16),
                FilledButton(onPressed: retry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
