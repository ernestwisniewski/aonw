import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/aonw_tokens.dart';
import '../../../../design_system/widgets/aonw_panel.dart';
import '../../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../../../game/aonw_flame_game.dart';
import '../../../../l10n/l10n.dart';
import '../../../settings/presentation/client_settings_scope.dart';
import '../../../turns/application/turn_presentation_queue.dart';
import '../../../turns/presentation/turn_banner.dart';
import '../../application/game_session_state.dart';
import '../../application/map_interaction_state.dart';
import '../../read_model/map_scene.dart';
import '../../read_model/map_view.dart';
import '../input/map_input.dart';
import '../input/map_viewport_intent.dart';
import '../map_presentation_controller.dart';
import '../map_render_snapshot.dart';
import 'flame_map_viewport.dart';
import 'map_failure_messages.dart';

final class MapScreen extends StatefulWidget {
  const MapScreen({
    required this.controller,
    this.inputSource,
    this.onOpenSettings,
    this.flameGameFactory = AonwFlameGame.new,
    this.routeObserver,
    this.autoLoad = true,
    super.key,
  });

  final MapPresentationController controller;
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
    _flameFocusNode = FocusNode(debugLabel: 'AoNW Flame viewport');
    _flameGame = widget.flameGameFactory();
    _flameGame.setHexIntentSink(_handleHexIntent);
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
    _flameGame.setHexIntentSink(null);
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
    _flameGame.setReducedMotion(
      settings.reducedMotion || MediaQuery.disableAnimationsOf(context),
    );
    _flameGame.setCameraSensitivity(settings.cameraSensitivity);
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
          onInput: _handleInput,
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
    _flameGame.setHexIntentSink(null);
    _flameGame = widget.flameGameFactory();
    _flameGame.setHexIntentSink(_handleHexIntent);
    _flameGeneration += 1;
  }

  void _retryFlame() {
    setState(_installFreshFlameGame);
    _synchronizeFlameScene();
    _synchronizeFlameLifecycle();
  }

  void _handleInput(MapInputCommand command) {
    if (!_routeVisible || _lifecycleState != AppLifecycleState.resumed) return;
    final state = widget.controller.state;
    if (state is! GameSessionReady) return;
    _handleReadyInput(state, command);
  }

  void _handleReadyInput(GameSessionReady state, MapInputCommand command) {
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

  void _handleHexIntent(MapHexIntent intent) {
    if (!_routeVisible || _lifecycleState != AppLifecycleState.resumed) return;
    switch (intent) {
      case MapHexHoverIntent(:final coordinate):
        widget.controller.hover(coordinate);
      case MapHexSelectIntent(:final coordinate):
        widget.controller.select(coordinate);
    }
  }
}

final class _ReadyMap extends StatelessWidget {
  const _ReadyMap({
    required this.scene,
    required this.interaction,
    required this.turnPresentations,
    required this.controller,
    required this.onInput,
    required this.onOpenSettings,
    required this.flameGame,
    required this.flameGeneration,
    required this.flameFocusNode,
    required this.onRetryFlame,
  });

  final MapScene scene;
  final MapInteractionState interaction;
  final TurnPresentationQueue turnPresentations;
  final MapPresentationController controller;
  final ValueChanged<MapInputCommand> onInput;
  final VoidCallback? onOpenSettings;
  final AonwFlameGame flameGame;
  final int flameGeneration;
  final FocusNode flameFocusNode;
  final VoidCallback onRetryFlame;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: FlameMapViewport(
          scene: scene,
          interaction: interaction,
          onInput: onInput,
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
        child: MapReferenceToggle(
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
              movementFailureMessage(l10n, message),
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
        message: mapFailureMessage(l10n, code),
        actionLabel: l10n.retry,
        onAction: retry,
      ),
    );
  }
}
