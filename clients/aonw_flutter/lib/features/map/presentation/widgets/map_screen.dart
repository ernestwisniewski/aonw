import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/aonw_tokens.dart';
import '../../../../design_system/widgets/aonw_panel.dart';
import '../../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../../../game/aonw_flame_game.dart';
import '../../../../l10n/l10n.dart';
import '../../../settings/presentation/client_settings_scope.dart';
import '../../../turns/application/turn_action_state.dart';
import '../../../turns/application/turn_presentation_queue.dart';
import '../../../turns/presentation/turn_banner.dart';
import '../../../turns/read_model/recipient_turn_view.dart';
import '../../../turns/read_model/turn_activity_view.dart';
import '../../../unit_actions/presentation/unit_action_deck.dart';
import '../../../unit_actions/read_model/unit_action_view.dart';
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
        :final turnAction,
      ) =>
        _ReadyMap(
          scene: scene,
          interaction: interaction,
          turnPresentations: turnPresentations,
          turnAction: turnAction,
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
    required this.turnAction,
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
  final TurnActionState turnAction;
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
      Positioned(
        top: AonwSpacing.md,
        left: 72,
        right: 72,
        child: _TurnHud(
          turn: scene.player.turnView,
          action: turnAction,
          onEndTurn: controller.endTurn,
        ),
      ),
      Positioned(
        right: AonwSpacing.md,
        bottom: AonwSpacing.md,
        child: _ActivityPanel(activities: turnPresentations.activities),
      ),
      _TurnNotification(activity: turnPresentations.latestActivity),
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
            onUnitAction: controller.executeUnitAction,
          ),
        ),
    ],
  );
}

final class _TurnHud extends StatelessWidget {
  const _TurnHud({
    required this.turn,
    required this.action,
    required this.onEndTurn,
  });

  final RecipientTurnView turn;
  final TurnActionState action;
  final VoidCallback onEndTurn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final status = _turnStatus(l10n, turn);
    final failure = _turnFailure(l10n, action.failure);
    return SafeArea(
      child: Center(
        child: AonwPanel(
          maxWidth: 720,
          padding: const EdgeInsets.symmetric(
            horizontal: AonwSpacing.md,
            vertical: AonwSpacing.sm,
          ),
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AonwSpacing.md,
              runSpacing: AonwSpacing.xs,
              children: [
                Text(
                  l10n.turnLabel(turn.number),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(status),
                Text(
                  l10n.turnSubmissionProgress(
                    turn.submittedCount,
                    turn.requiredSubmissionCount,
                  ),
                ),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(3),
                  child: FilledButton.icon(
                    key: const ValueKey('end-turn'),
                    onPressed: turn.canEndTurn && !action.inFlight
                        ? onEndTurn
                        : null,
                    icon: action.inFlight
                        ? const Icon(Icons.hourglass_top)
                        : const Icon(Icons.skip_next),
                    label: Text(
                      action.inFlight ? l10n.endingTurn : l10n.endTurn,
                    ),
                  ),
                ),
                if (failure != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      failure,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.activities});

  final List<TurnActivityView> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox.shrink();
    final visible = activities.skip(
      activities.length > 4 ? activities.length - 4 : 0,
    );
    return SafeArea(
      child: AonwPanel(
        maxWidth: 320,
        semanticLabel: context.aonwL10n.activityLog,
        padding: const EdgeInsets.all(AonwSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.aonwL10n.activityLog,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AonwSpacing.xs),
            for (final activity in visible)
              Text('• ${_activityLabel(context, activity.kind)}'),
          ],
        ),
      ),
    );
  }
}

final class _TurnNotification extends StatelessWidget {
  const _TurnNotification({required this.activity});

  final TurnActivityView? activity;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final current = activity;
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: const Alignment(0, 0.74),
          child: AnimatedSwitcher(
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            child: current == null
                ? const SizedBox.shrink()
                : Semantics(
                    key: ValueKey(current.identity),
                    liveRegion: true,
                    child: AonwPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AonwSpacing.md,
                        vertical: AonwSpacing.xs,
                      ),
                      child: Text(_activityLabel(context, current.kind)),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

String _turnStatus(AonwLocalizations l10n, RecipientTurnView turn) {
  if (turn.outcome.isTerminal) {
    return l10n.gameOutcome(turn.outcome.condition.name);
  }
  if (turn.pendingAction != null) return l10n.turnPendingAction;
  if (turn.ownSubmitted) return l10n.turnSubmitted;
  return switch (turn.ownState) {
    RecipientTurnStateView.active => l10n.turnActive,
    RecipientTurnStateView.finished => l10n.turnFinished,
    null => l10n.turnWaiting,
  };
}

String? _turnFailure(AonwLocalizations l10n, TurnActionFailureView? failure) {
  if (failure == null) return null;
  final code = failure.rejectionCode?.wireCode ?? failure.code?.name ?? 'other';
  return l10n.turnFailure(code);
}

String _activityLabel(BuildContext context, TurnActivityKindView kind) =>
    context.aonwL10n.activityEvent(_activityCategory(kind));

String _activityCategory(TurnActivityKindView kind) => switch (kind) {
  TurnActivityKindView.artifactExcavationStarted ||
  TurnActivityKindView.artifactCarried ||
  TurnActivityKindView.artifactStored => 'artifact',
  TurnActivityKindView.cityFounded ||
  TurnActivityKindView.cityBuiltBuilding ||
  TurnActivityKindView.cityProducedUnit ||
  TurnActivityKindView.cityBuiltWonder ||
  TurnActivityKindView.wonderProductionRefunded ||
  TurnActivityKindView.cityClaimedHex => 'city',
  TurnActivityKindView.technologyResearched ||
  TurnActivityKindView.researchPointsGained => 'research',
  TurnActivityKindView.stabilityBandChanged ||
  TurnActivityKindView.mapObjectiveSecured ||
  TurnActivityKindView.dominationThresholdReached => 'objective',
  TurnActivityKindView.matchEnded => 'outcome',
  TurnActivityKindView.unitAttacked ||
  TurnActivityKindView.cityAttacked ||
  TurnActivityKindView.combatResolved ||
  TurnActivityKindView.unitGainedExperience ||
  TurnActivityKindView.unitKilled ||
  TurnActivityKindView.unitRetreated ||
  TurnActivityKindView.cityCaptured ||
  TurnActivityKindView.cityDestroyed => 'combat',
  TurnActivityKindView.diplomaticScoreChanged ||
  TurnActivityKindView.diplomaticProposalSent ||
  TurnActivityKindView.diplomaticProposalResponded ||
  TurnActivityKindView.diplomaticProposalExpired ||
  TurnActivityKindView.diplomaticMessageSent ||
  TurnActivityKindView.diplomaticMessageResponded ||
  TurnActivityKindView.diplomaticPromiseBroken ||
  TurnActivityKindView.diplomaticRelationChanged => 'diplomacy',
  TurnActivityKindView.unitMoved ||
  TurnActivityKindView.autoExplorePlanned ||
  TurnActivityKindView.merchantRouteAssigned ||
  TurnActivityKindView.merchantTravelQueued ||
  TurnActivityKindView.troopDetached => 'unit',
  TurnActivityKindView.turnEnded ||
  TurnActivityKindView.allPlayersSubmitted ||
  TurnActivityKindView.playerTimedOut ||
  TurnActivityKindView.playerKicked => 'turn',
  TurnActivityKindView.workerCompletedJob => 'worker',
};

final class _MapSelectionPanel extends StatelessWidget {
  const _MapSelectionPanel({
    required this.coordinate,
    required this.interaction,
    required this.onConfirmMove,
    required this.onUnitAction,
  });

  final MapHexCoordinate coordinate;
  final MapInteractionState interaction;
  final VoidCallback onConfirmMove;
  final ValueChanged<UnitActionKindView> onUnitAction;

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
            _MovementControls(
              interaction: interaction,
              onConfirmMove: onConfirmMove,
            ),
            if (interaction.actionDeck case final actionDeck?)
              UnitActionDeck(
                state: actionDeck,
                enabled: !interaction.movementPending,
                onAction: onUnitAction,
              ),
          ],
          _MovementFeedback(interaction: interaction),
        ],
      ),
    );
  }
}

final class _MovementControls extends StatelessWidget {
  const _MovementControls({
    required this.interaction,
    required this.onConfirmMove,
  });

  final MapInteractionState interaction;
  final VoidCallback onConfirmMove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final route = interaction.route;
    if (route == null) {
      return interaction.movementPending
          ? const SizedBox.shrink()
          : Text(l10n.chooseHighlightedDestination);
    }
    final commandPending =
        interaction.movementPending ||
        (interaction.actionDeck?.commandPending ?? false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.routeSummary(route.totalCostUnits, route.remainingMovementUnits),
        ),
        const SizedBox(height: AonwSpacing.sm),
        FilledButton.icon(
          key: const ValueKey('confirm-move'),
          onPressed: commandPending ? null : onConfirmMove,
          icon: const Icon(Icons.directions_walk),
          label: Text(l10n.confirmMove),
        ),
      ],
    );
  }
}

final class _MovementFeedback extends StatelessWidget {
  const _MovementFeedback({required this.interaction});

  final MapInteractionState interaction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (interaction.movementPending) ...[
          const SizedBox(height: AonwSpacing.sm),
          AonwProgressIndicator(semanticLabel: l10n.movingUnit, compact: true),
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
