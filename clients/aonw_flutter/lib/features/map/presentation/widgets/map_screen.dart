import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/aonw_tokens.dart';
import '../../../../design_system/widgets/aonw_panel.dart';
import '../../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../../../game/aonw_flame_game.dart';
import '../../../../l10n/l10n.dart';
import '../../../settings/application/client_settings.dart';
import '../../../settings/presentation/client_settings_scope.dart';
import '../../../turns/application/turn_presentation_queue.dart';
import '../../../turns/presentation/turn_banner.dart';
import '../../application/game_session_state.dart';
import '../../application/map_controller.dart';
import '../../application/map_interaction_state.dart';
import '../../read_model/map_scene.dart';
import '../../read_model/map_view.dart';
import '../../read_model/movement_view.dart';
import '../camera/map_initial_camera.dart';
import '../geometry/odd_q_flat_top_geometry.dart';
import '../input/map_input.dart';
import '../map_render_snapshot.dart';
import 'map_canvas.dart';

final class MapScreen extends StatefulWidget {
  const MapScreen({
    required this.controller,
    this.transformationController,
    this.inputSource,
    this.onOpenSettings,
    this.flameGameFactory = AonwFlameGame.new,
    this.routeObserver,
    this.autoLoad = true,
    super.key,
  });

  final MapController controller;
  final TransformationController? transformationController;
  final MapInputSource? inputSource;
  final VoidCallback? onOpenSettings;
  final AonwFlameGameFactory flameGameFactory;
  final RouteObserver<ModalRoute<void>>? routeObserver;
  final bool autoLoad;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

final class _MapScreenState extends State<MapScreen>
    with WidgetsBindingObserver, RouteAware {
  late TransformationController _camera;
  late bool _ownsCamera;
  late AonwFlameGame _flameGame;
  late FocusNode _flameFocusNode;
  late AppLifecycleState _lifecycleState;
  ModalRoute<void>? _subscribedRoute;
  var _routeVisible = true;
  var _flameGeneration = 0;
  StreamSubscription<MapInputCommand>? _inputSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _ownsCamera = widget.transformationController == null;
    _camera = widget.transformationController ?? TransformationController();
    _flameFocusNode = FocusNode(
      debugLabel: 'AoNW Flame viewport',
      canRequestFocus: false,
    );
    _flameGame = widget.flameGameFactory();
    widget.controller.addListener(_synchronizeFlameScene);
    _listenToInput(widget.inputSource);
    if (widget.autoLoad) widget.controller.load();
    _synchronizeFlameScene();
    _synchronizeFlameLifecycle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeToRoute();
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_synchronizeFlameScene);
      widget.controller.addListener(_synchronizeFlameScene);
    }
    if (oldWidget.transformationController != widget.transformationController) {
      if (_ownsCamera) _camera.dispose();
      _ownsCamera = widget.transformationController == null;
      _camera = widget.transformationController ?? TransformationController();
    }
    if (oldWidget.inputSource != widget.inputSource) {
      _listenToInput(widget.inputSource);
    }
    if (oldWidget.flameGameFactory != widget.flameGameFactory) {
      _installFreshFlameGame();
    }
    if (oldWidget.routeObserver != widget.routeObserver) {
      oldWidget.routeObserver?.unsubscribe(this);
      _subscribedRoute = null;
      _subscribeToRoute();
    }
    if (widget.autoLoad &&
        (oldWidget.controller != widget.controller || !oldWidget.autoLoad)) {
      widget.controller.load();
    }
    _synchronizeFlameScene();
    _synchronizeFlameLifecycle();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.routeObserver?.unsubscribe(this);
    widget.controller.removeListener(_synchronizeFlameScene);
    unawaited(_inputSubscription?.cancel());
    if (_ownsCamera) _camera.dispose();
    _flameFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _synchronizeFlameLifecycle();
  }

  @override
  void didPush() => _setRouteVisible(true);

  @override
  void didPopNext() => _setRouteVisible(true);

  @override
  void didPushNext() => _setRouteVisible(false);

  @override
  void didPop() => _setRouteVisible(false);

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: widget.controller, builder: _buildState);

  Widget _buildState(BuildContext context, Widget? child) {
    final state = widget.controller.state;
    final settings = ClientSettingsScope.settingsOf(context);
    return switch (state) {
      GameSessionLoading() => const _LoadingMap(),
      GameSessionFailure(:final code) => _MapFailure(
        code: code,
        retry: widget.controller.load,
      ),
      GameSessionReady(
        :final scene,
        :final interaction,
        :final turnPresentations,
      ) =>
        _ReadyMap(
          scene: scene,
          interaction: interaction,
          turnPresentations: turnPresentations,
          controller: widget.controller,
          camera: _camera,
          onInput: _handleInput,
          settings: settings,
          onOpenSettings: widget.onOpenSettings,
          flameGame: _flameGame,
          flameGeneration: _flameGeneration,
          flameFocusNode: _flameFocusNode,
          onRetryFlame: _retryFlame,
        ),
    };
  }

  void _listenToInput(MapInputSource? source) {
    unawaited(_inputSubscription?.cancel());
    _inputSubscription = source?.commands.listen(_handleInput);
  }

  void _subscribeToRoute() {
    final route = ModalRoute.of(context);
    if (route is! ModalRoute<void> || route == _subscribedRoute) return;
    widget.routeObserver?.unsubscribe(this);
    _subscribedRoute = route;
    widget.routeObserver?.subscribe(this, route);
  }

  void _setRouteVisible(bool visible) {
    if (_routeVisible == visible) return;
    _routeVisible = visible;
    _synchronizeFlameLifecycle();
  }

  void _synchronizeFlameLifecycle() {
    _flameGame.setViewportActive(
      _routeVisible && _lifecycleState == AppLifecycleState.resumed,
    );
  }

  void _synchronizeFlameScene() {
    switch (widget.controller.state) {
      case GameSessionReady(:final scene, :final interaction):
        _flameGame.sceneSink.replaceScene(
          MapRenderSnapshot(
            map: scene.map,
            interaction: interaction,
            reference: scene.reference,
            player: scene.player,
          ),
        );
      case GameSessionLoading() || GameSessionFailure():
        _flameGame.sceneSink.clearScene();
    }
  }

  void _installFreshFlameGame() {
    _flameGame = widget.flameGameFactory();
    _flameGeneration += 1;
  }

  void _retryFlame() {
    setState(_installFreshFlameGame);
    _synchronizeFlameScene();
    _synchronizeFlameLifecycle();
  }

  void _handleInput(MapInputCommand command) {
    final state = widget.controller.state;
    if (state is! GameSessionReady) return;
    switch (command) {
      case MapInputCommand.activate:
        widget.controller.select(
          state.interaction.hovered ??
              state.interaction.selected ??
              MapInputCursor.initial(state.scene.map),
        );
      case MapInputCommand.cancel:
        widget.controller.hover(null);
        widget.controller.select(null);
      case MapInputCommand.toggleReference:
        widget.controller.toggleReference();
      case MapInputCommand.cursorUp:
      case MapInputCommand.cursorDown:
      case MapInputCommand.cursorLeft:
      case MapInputCommand.cursorRight:
        final current =
            state.interaction.hovered ??
            state.interaction.selected ??
            MapInputCursor.initial(state.scene.map);
        widget.controller.hover(
          MapInputCursor.move(state.scene.map, current, command),
        );
    }
  }
}

final class _ReadyMap extends StatelessWidget {
  const _ReadyMap({
    required this.scene,
    required this.interaction,
    required this.turnPresentations,
    required this.controller,
    required this.camera,
    required this.onInput,
    required this.settings,
    required this.onOpenSettings,
    required this.flameGame,
    required this.flameGeneration,
    required this.flameFocusNode,
    required this.onRetryFlame,
  });

  final MapScene scene;
  final MapInteractionState interaction;
  final TurnPresentationQueue turnPresentations;
  final MapController controller;
  final TransformationController camera;
  final ValueChanged<MapInputCommand> onInput;
  final ClientSettings settings;
  final VoidCallback? onOpenSettings;
  final AonwFlameGame flameGame;
  final int flameGeneration;
  final FocusNode flameFocusNode;
  final VoidCallback onRetryFlame;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: _MapViewport(
          scene: scene,
          interaction: interaction,
          controller: controller,
          camera: camera,
          onInput: onInput,
          settings: settings,
        ),
      ),
      Positioned.fill(
        child: _FlameViewport(
          game: flameGame,
          generation: flameGeneration,
          focusNode: flameFocusNode,
          onRetry: onRetryFlame,
        ),
      ),
      TurnBanner(
        presentation: turnPresentations.active,
        onFinished: controller.completeTurnPresentation,
      ),
      if (onOpenSettings case final openSettings?)
        Positioned(
          top: AonwSpacing.md,
          left: AonwSpacing.md,
          child: IconButton.filledTonal(
            key: const ValueKey('open-settings'),
            tooltip: context.aonwL10n.openSettings,
            onPressed: openSettings,
            icon: const Icon(Icons.settings),
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

final class _FlameViewport extends StatelessWidget {
  const _FlameViewport({
    required this.game,
    required this.generation,
    required this.focusNode,
    required this.onRetry,
  });

  final AonwFlameGame game;
  final int generation;
  final FocusNode focusNode;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ClipRect(
    key: const ValueKey('flame-viewport-clip'),
    child: RepaintBoundary(
      key: const ValueKey('flame-viewport-repaint-boundary'),
      child: GameWidget<AonwFlameGame>(
        key: ValueKey(('flame-viewport', generation)),
        game: game,
        focusNode: focusNode,
        autofocus: false,
        addRepaintBoundary: false,
        behavior: HitTestBehavior.deferToChild,
        loadingBuilder: (_) =>
            const SizedBox.expand(key: ValueKey('flame-viewport-loading')),
        errorBuilder: (context, error) {
          final l10n = context.aonwL10n;
          return Center(
            child: AonwMessagePanel(
              key: const ValueKey('flame-load-error'),
              semanticLabel: l10n.mapLoadingFailed,
              title: l10n.mapUnavailable,
              message: l10n.mapLoadFailure,
              actionLabel: l10n.retry,
              onAction: onRetry,
            ),
          );
        },
      ),
    ),
  );
}

final class _MapViewport extends StatefulWidget {
  const _MapViewport({
    required this.scene,
    required this.interaction,
    required this.controller,
    required this.camera,
    required this.onInput,
    required this.settings,
  });

  final MapScene scene;
  final MapInteractionState interaction;
  final MapController controller;
  final TransformationController camera;
  final ValueChanged<MapInputCommand> onInput;
  final ClientSettings settings;

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
        scaleFactor: 200 / widget.settings.cameraSensitivity,
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
          onInput: widget.onInput,
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
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return IconButton.filledTonal(
      key: const ValueKey('reference-toggle'),
      tooltip: visible ? l10n.hideReferenceLayer : l10n.showReferenceLayer,
      onPressed: onPressed,
      icon: Icon(visible ? Icons.layers : Icons.layers_clear),
    );
  }
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
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return AonwPanel(
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
          Text(l10n.hexLabel(coordinate.col, coordinate.row)),
          if (interaction.selectedUnitId case final unitId?) ...[
            const SizedBox(height: AonwSpacing.xs),
            Text(l10n.unitLabel(unitId)),
            if (interaction.route case final route?) ...[
              Text(
                l10n.routeSummary(
                  route.totalCostUnits,
                  route.remainingMovementUnits,
                ),
              ),
              const SizedBox(height: AonwSpacing.sm),
              FilledButton.icon(
                key: const ValueKey('confirm-move'),
                onPressed: interaction.movementPending ? null : onConfirmMove,
                icon: const Icon(Icons.directions_walk),
                label: Text(l10n.confirmMove),
              ),
            ] else if (!interaction.movementPending)
              Text(l10n.chooseHighlightedDestination),
          ],
          if (interaction.movementPending) ...[
            const SizedBox(height: AonwSpacing.sm),
            AonwProgressIndicator(
              semanticLabel: l10n.movingUnit,
              compact: true,
            ),
          ],
          if (interaction.movementError case final message?) ...[
            const SizedBox(height: AonwSpacing.sm),
            Text(
              _movementFailureMessage(l10n, message),
              key: const ValueKey('movement-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

final class _LoadingMap extends StatelessWidget {
  const _LoadingMap();

  @override
  Widget build(BuildContext context) => Center(
    child: AonwProgressIndicator(semanticLabel: context.aonwL10n.loadingMap),
  );
}

final class _MapFailure extends StatelessWidget {
  const _MapFailure({required this.code, required this.retry});

  final MapLoadFailureViewCode code;
  final AsyncCallback retry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Center(
      child: AonwMessagePanel(
        semanticLabel: l10n.mapLoadingFailed,
        title: l10n.mapUnavailable,
        message: _mapFailureMessage(l10n, code),
        actionLabel: l10n.retry,
        onAction: retry,
      ),
    );
  }
}

String _mapFailureMessage(
  AonwLocalizations l10n,
  MapLoadFailureViewCode code,
) => switch (code) {
  MapLoadFailureViewCode.adapterUnavailable => l10n.mapAdapterUnavailable,
  MapLoadFailureViewCode.incompatibleClient => l10n.mapClientIncompatible,
  MapLoadFailureViewCode.loadSuperseded => l10n.mapLoadSuperseded,
  MapLoadFailureViewCode.mapUnavailable => l10n.mapLoadFailure,
};

String _movementFailureMessage(
  AonwLocalizations l10n,
  MapMovementFailure failure,
) => switch (failure.code) {
  MapMovementFailureViewCode.requestFailed => l10n.movementRequestFailed,
  MapMovementFailureViewCode.responseIncompatible =>
    l10n.movementResponseIncompatible,
  MapMovementFailureViewCode.sessionUnavailable =>
    l10n.movementSessionUnavailable,
  MapMovementFailureViewCode.moveRejected => _moveRejectionMessage(
    l10n,
    failure.rejectionCode!,
  ),
};

String _moveRejectionMessage(
  AonwLocalizations l10n,
  CommandRejectionCodeView code,
) => switch (code) {
  CommandRejectionCodeView.staleRevision => l10n.moveRejectedStale,
  CommandRejectionCodeView.unitNotFound ||
  CommandRejectionCodeView.unitNotControlled ||
  CommandRejectionCodeView.unitUnavailable ||
  CommandRejectionCodeView.unitOutOfBounds => l10n.moveRejectedUnitUnavailable,
  CommandRejectionCodeView.unitUsesTradeRoutes ||
  CommandRejectionCodeView.unitBusy => l10n.moveRejectedUnitBusy,
  CommandRejectionCodeView.moveTargetOutOfBounds ||
  CommandRejectionCodeView.moveTargetIsCurrentTile ||
  CommandRejectionCodeView.moveTargetIsForeignCityCenter ||
  CommandRejectionCodeView.moveTargetOccupied =>
    l10n.moveRejectedTargetUnavailable,
  CommandRejectionCodeView.unitMovementCapacityInsufficient =>
    l10n.moveRejectedMovementInsufficient,
  CommandRejectionCodeView.movePathNotFound => l10n.moveRejectedPathUnavailable,
  CommandRejectionCodeView.unitDefinitionMissing ||
  CommandRejectionCodeView.stateRevisionOverflow ||
  CommandRejectionCodeView.invalidQueuedMovementPath ||
  CommandRejectionCodeView.invalidUnit ||
  CommandRejectionCodeView.movementUnitUpdateFailed =>
    l10n.moveRejectedInternal,
};
