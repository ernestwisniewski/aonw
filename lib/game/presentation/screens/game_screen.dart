import 'dart:async';

import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/presentation/audio/game_audio_controller.dart';
import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/providers/map_inspection_binder.dart';
import 'package:aonw/game/presentation/widgets.dart';
import 'package:aonw/game/presentation/widgets/hud/turn_action_hint.dart';
import 'package:aonw/game/presentation/widgets/screen/game_startup_asset_preloader.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/selection_info/providers.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/widgets/dice_roll_test_overlay.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/providers/performance_settings_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/viewport_gesture_layer.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GameScreen extends ConsumerWidget {
  final MapSelection selection;
  final String saveId;

  const GameScreen({required this.selection, required this.saveId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(gameSessionProvider(selection, saveId));
    final gameSaveAsync = ref.watch(gameSaveProvider(saveId));
    final displaySettings = ref.watch(hexDisplayProvider);

    return sessionAsync.when(
      loading: () =>
          const GameLoadingView(progress: GameLoadingProgress.initial),
      error: (error, _) => GameLoadErrorView(
        mapName: selection.displayName,
        error: error,
        onBack: () => context.go('/new-game'),
      ),
      data: (session) {
        final gameSave = gameSaveAsync.value;
        if (saveId.isNotEmpty) {
          if (gameSaveAsync.hasError) {
            return GameLoadErrorView(
              mapName: selection.displayName,
              error: gameSaveAsync.error!,
              onBack: () => context.go('/new-game'),
            );
          }
          if (gameSave == null) {
            return GameLoadingView(
              progress: GameLoadingProgress.initial.bumpedTo(0.36),
            );
          }
        }

        return _GameRendererSessionHost(
          selection: selection,
          session: session,
          gameSave: gameSave,
          displaySettings: displaySettings,
          l10n: context.l10n,
        );
      },
    );
  }
}

class _GameRendererSessionHost extends ConsumerStatefulWidget {
  final MapSelection selection;
  final GameSession session;
  final GameSave? gameSave;
  final HexDisplaySettings displaySettings;
  final AppLocalizations l10n;

  const _GameRendererSessionHost({
    required this.selection,
    required this.session,
    required this.gameSave,
    required this.displaySettings,
    required this.l10n,
  });

  @override
  ConsumerState<_GameRendererSessionHost> createState() =>
      _GameRendererSessionHostState();
}

class _GameRendererSessionHostState
    extends ConsumerState<_GameRendererSessionHost>
    with WidgetsBindingObserver {
  late GameRenderer _renderer;
  late final GameAudioController _audioController;
  late final MapZoomDebugController _mapZoomDebugController;
  late final GameLoadingProgressController _loadingProgressController;
  late Future<void> _startupAssetPreload;
  Future<void> Function(GameCommand command)? _rendererCommandDispatcher;
  double _startupAssetProgress = 0;
  double _rendererLoadProgress = 0;
  bool _showDiceRollTestOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioController = ref.read(gameAudioControllerProvider);
    _mapZoomDebugController = ref.read(mapZoomDebugProvider.notifier);
    _loadingProgressController = GameLoadingProgressController(
      GameLoadingProgress.initial.bumpedTo(0.42),
    );
    _loadMapDisplayColors();
    _renderer = _createRenderer();
    _attachMapZoomDebugListener(_renderer);
    _startupAssetPreload = _preloadStartupAssets();
    _scheduleResumeMatchPersistence();
    unawaited(_audioController.startNatureLoop());
  }

  @override
  void didUpdateWidget(_GameRendererSessionHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection != widget.selection ||
        oldWidget.session.saveId != widget.session.saveId) {
      _resetStartupLoadingProgress();
    }
    if (oldWidget.selection != widget.selection) {
      _loadMapDisplayColors();
    }
    if (oldWidget.session.saveId != widget.session.saveId ||
        oldWidget.gameSave?.gameMode != widget.gameSave?.gameMode) {
      _scheduleResumeMatchPersistence();
    }
    if (_shouldRecreateRenderer(oldWidget)) {
      final oldRenderer = _renderer;
      _detachMapZoomDebugListener(oldRenderer);
      _resetStartupLoadingProgress();
      _renderer = _createRenderer();
      _attachMapZoomDebugListener(_renderer);
      _startupAssetPreload = _preloadStartupAssets();
      _releaseRendererAfterFrame(oldRenderer);
    }
  }

  void _loadMapDisplayColors() {
    unawaited(
      ref.read(hexDisplayProvider.notifier).loadMapColors(widget.selection),
    );
  }

  @override
  void dispose() {
    unawaited(_audioController.stopNatureLoop());
    WidgetsBinding.instance.removeObserver(this);
    _detachMapZoomDebugListener(_renderer);
    _clearMapZoomDebugAfterLifecycle();
    _renderer.disposeRenderer();
    _loadingProgressController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _scheduleResumeMatchPersistence();
        break;
      case AppLifecycleState.resumed:
        break;
    }
  }

  GameRenderer _createRenderer() {
    final session = widget.session;
    final gameplaySettings = ref.read(gameplaySettingsProvider);
    final mapInspection = MapInspectionBinder(ref: ref, session: session);
    return GameRenderer(
      mapData: session.mapData,
      imagePath: session.imagePath,
      initialCamera: session.initialCamera,
      focusActivePlayerOnFirstState:
          session.saveId.isNotEmpty &&
          (session.initialCamera == null ||
              session.initialCamera == CameraState.zero),
      initialViewMode: session.viewMode,
      onCommand: _dispatchRendererCommand,
      onCityDescriptionRequested: (_) {
        ref.read(mapInspectionControllerProvider.notifier).clear();
        ref
            .read(openSelectionDetailControllerProvider.notifier)
            .open(SelectionInfoChipId.description);
      },
      onTileInspected: mapInspection.inspectTile,
      onTileInspectionPreviewed: mapInspection.previewTile,
      onArtifactInspected: (artifact, anchor) {
        ref
            .read(mapInspectionControllerProvider.notifier)
            .inspectArtifact(artifact, anchor: anchor);
      },
      onObjectiveInspected: (progress, anchor) {
        ref
            .read(mapInspectionControllerProvider.notifier)
            .inspectObjective(progress, anchor: anchor);
      },
      onTileInspectionConfirmed: () {
        ref.read(mapInspectionControllerProvider.notifier).confirmPreview();
      },
      onTileInspectionCanceled: () {
        ref.read(mapInspectionControllerProvider.notifier).cancelPreview();
      },
      onLoadingProgress: _reportRendererLoadProgress,
      l10n: widget.l10n,
      followUnitMovementCamera: gameplaySettings.followUnitMovementCamera,
      followEnemyUnitCamera: gameplaySettings.followEnemyUnitCamera,
      cinematicCameraEnabled: gameplaySettings.cinematicCameraEnabled,
    );
  }

  void _attachMapZoomDebugListener(GameRenderer renderer) {
    renderer.zoomListenable.addListener(_syncMapZoomDebugValue);
    _syncMapZoomDebugValue(renderer);
  }

  void _detachMapZoomDebugListener(GameRenderer renderer) {
    renderer.zoomListenable.removeListener(_syncMapZoomDebugValue);
  }

  void _syncMapZoomDebugValue([GameRenderer? source]) {
    final renderer = source ?? _renderer;
    final zoom = renderer.zoomListenable.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_renderer, renderer)) return;
      _mapZoomDebugController.setZoom(zoom);
    });
  }

  void _clearMapZoomDebugAfterLifecycle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapZoomDebugController.clear();
      } on Object {
        // The owning provider scope may already be gone during app teardown.
      }
    });
  }

  Future<void> _preloadStartupAssets() async {
    try {
      _reportStartupAssetProgress(0);
      await GameStartupAssetPreloader.preload(
        widget.session,
        onProgress: _reportStartupAssetProgress,
      );
    } catch (_) {
      // Renderer loading still reports asset failures; the preloader should not
      // leave the player stuck behind an overlay if a platform-specific cache
      // warmup fails.
      _reportStartupAssetProgress(1);
    }
  }

  void _reportStartupAssetProgress(double value) {
    _startupAssetProgress = value.clamp(0.0, 1.0).toDouble();
    _publishLoadingProgress();
  }

  void _reportRendererLoadProgress(double value) {
    _rendererLoadProgress = value.clamp(0.0, 1.0).toDouble();
    _publishLoadingProgress();
  }

  void _publishLoadingProgress() {
    if (!mounted) return;
    final progress =
        0.42 + _startupAssetProgress * 0.26 + _rendererLoadProgress * 0.26;
    _loadingProgressController.report(progress);
  }

  void _resetStartupLoadingProgress() {
    _startupAssetProgress = 0;
    _rendererLoadProgress = 0;
    _loadingProgressController.value = GameLoadingProgress.initial.bumpedTo(
      0.42,
    );
  }

  Future<void> _dispatchRendererCommand(GameCommand command) async {
    ref.read(mapInspectionControllerProvider.notifier).clear();
    await _rendererCommandDispatcher?.call(command);
  }

  Future<void> _returnToMainMenu() async {
    await _rememberActiveMultiplayerMatch();
    if (!mounted) return;
    context.go('/');
  }

  void _scheduleResumeMatchPersistence() {
    final matchId = _activeMultiplayerMatchId();
    if (matchId == null) return;
    unawaited(const NetworkSessionStore().saveMatchId(matchId));
  }

  Future<void> _rememberActiveMultiplayerMatch() async {
    final matchId = _activeMultiplayerMatchId();
    if (matchId == null) return;

    await const NetworkSessionStore().saveMatchId(matchId);
  }

  String? _activeMultiplayerMatchId() {
    final gameSave = widget.gameSave;
    final saveId = widget.session.saveId;
    if (gameSave?.gameMode != GameMode.multiplayer || saveId.isEmpty) {
      return null;
    }

    final networkSession = ref.read(networkSessionProvider);
    final sessionMatchId = networkSession?.matchId;
    if (sessionMatchId != null && sessionMatchId != saveId) return null;
    return saveId;
  }

  bool _shouldRecreateRenderer(_GameRendererSessionHost oldWidget) {
    final oldSession = oldWidget.session;
    final session = widget.session;
    return oldSession.saveId != session.saveId ||
        oldSession.mapData != session.mapData ||
        oldSession.imagePath != session.imagePath ||
        oldSession.initialCamera != session.initialCamera ||
        oldWidget.l10n.localeName != widget.l10n.localeName;
  }

  void _releaseRendererAfterFrame(GameRenderer renderer) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!identical(_renderer, renderer)) {
        renderer.disposeRenderer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final gameplaySettings = ref.watch(gameplaySettingsProvider);
    return ProviderScope(
      overrides: [
        activeGameSessionProvider.overrideWithValue(session),
        activeGameRendererProvider.overrideWithValue(_renderer),
      ],
      child: _GameStateReadyGate(
        selection: widget.selection,
        session: session,
        child: ScopedRendererCommandDispatcher(
          session: session,
          onDispatcherChanged: (dispatcher) {
            _rendererCommandDispatcher = dispatcher;
          },
          child: Scaffold(
            backgroundColor: GameUiTheme.bg,
            body: GameRuntimeBinding(
              session: session,
              renderer: _renderer,
              displaySettings: widget.displaySettings,
              reduceMotion:
                  MediaQuery.maybeOf(context)?.disableAnimations ?? false,
              followUnitMovementCamera:
                  gameplaySettings.followUnitMovementCamera,
              followEnemyUnitCamera: gameplaySettings.followEnemyUnitCamera,
              cinematicCameraEnabled: gameplaySettings.cinematicCameraEnabled,
              child: ProviderScope(
                overrides: [
                  gamePlayerControlSaveProvider.overrideWithValue(
                    widget.gameSave,
                  ),
                ],
                child: _GamePrimaryActionShortcutController(
                  session: session,
                  gameSave: widget.gameSave,
                  animatingUnitIdsListenable:
                      _renderer.animatingUnitIdsListenable,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ViewportGestureLayer(
                          game: _renderer,
                          child: GameWidget(
                            key: ValueKey(_renderer),
                            game: _renderer,
                            loadingBuilder: (_) =>
                                ValueListenableBuilder<GameLoadingProgress>(
                                  valueListenable: _loadingProgressController,
                                  builder: (context, progress, _) {
                                    return GameLoadingPanel(progress: progress);
                                  },
                                ),
                          ),
                        ),
                      ),
                      const Positioned.fill(child: _MapVignetteOverlay()),
                      if (_showDiceRollTestOverlay)
                        const Positioned.fill(child: DiceRollTestOverlay()),
                      Positioned.fill(
                        child: GameHud(
                          session: session,
                          animatingUnitIdsListenable:
                              _renderer.animatingUnitIdsListenable,
                          initialCameraFocusReadyListenable:
                              _renderer.initialCameraFocusReadyListenable,
                          gameSave: widget.gameSave,
                          allowGraphicMode: session.imagePath != null,
                          displaySettings: widget.displaySettings,
                          onToggleTerrain: () => ref
                              .read(hexDisplayProvider.notifier)
                              .toggleTerrain(),
                          onToggleResources: () => ref
                              .read(hexDisplayProvider.notifier)
                              .toggleResources(),
                          onToggleHeightBadge: () => ref
                              .read(hexDisplayProvider.notifier)
                              .toggleHeightBadge(),
                          onToggleCitySites: () => ref
                              .read(hexDisplayProvider.notifier)
                              .toggleCitySites(),
                          onToggleCityGrowth: () => ref
                              .read(hexDisplayProvider.notifier)
                              .toggleCityGrowth(),
                          onToggleHexBorders: () => unawaited(
                            ref
                                .read(hexDisplayProvider.notifier)
                                .setHexBordersVisibleForMap(
                                  widget.selection,
                                  !widget.displaySettings.hexBordersVisible,
                                ),
                          ),
                          onToggleHeightWalls: () => unawaited(
                            ref
                                .read(hexDisplayProvider.notifier)
                                .setHeightWallsVisibleForMap(
                                  widget.selection,
                                  !widget.displaySettings.heightWallsVisible,
                                ),
                          ),
                          onHexBorderColorChanged: (color) => unawaited(
                            ref
                                .read(hexDisplayProvider.notifier)
                                .setHexBorderColorForMap(
                                  widget.selection,
                                  color,
                                ),
                          ),
                          onWallTintColorChanged: (color) => unawaited(
                            ref
                                .read(hexDisplayProvider.notifier)
                                .setWallTintColorForMap(
                                  widget.selection,
                                  color,
                                ),
                          ),
                          onResetHexBorderColor: () => unawaited(
                            ref
                                .read(hexDisplayProvider.notifier)
                                .resetHexBorderColorForMap(widget.selection),
                          ),
                          onResetWallTintColor: () => unawaited(
                            ref
                                .read(hexDisplayProvider.notifier)
                                .resetWallTintColorForMap(widget.selection),
                          ),
                          showDiceRollTest: _showDiceRollTestOverlay,
                          aiAutopilotEnabled: true,
                          onToggleDiceRollTest: () {
                            setState(() {
                              _showDiceRollTestOverlay =
                                  !_showDiceRollTestOverlay;
                            });
                          },
                          onClose: _returnToMainMenu,
                          onViewModeChanged: (value) {
                            if (value == MapViewMode.graphic &&
                                session.imagePath == null) {
                              return;
                            }
                            ref
                                .read(
                                  gameSessionProvider(
                                    widget.selection,
                                    session.saveId,
                                  ).notifier,
                                )
                                .setViewMode(value);
                          },
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 12,
                        right: 12,
                        child: _MultiplayerConnectionBanner(
                          saveId: session.saveId,
                        ),
                      ),
                      Positioned.fill(
                        child: _GameStartupLoadingOverlay(
                          saveId: session.saveId,
                          multiplayer: session.gameMode == GameMode.multiplayer,
                          preloadFuture: _startupAssetPreload,
                          rendererReady: _renderer.readyListenable,
                          initialCameraFocusReady:
                              _renderer.initialCameraFocusReadyListenable,
                          loadingProgress: _loadingProgressController,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GamePrimaryActionShortcutController extends ConsumerWidget {
  const _GamePrimaryActionShortcutController({
    required this.session,
    required this.gameSave,
    required this.animatingUnitIdsListenable,
    required this.child,
  });

  final GameSession session;
  final GameSave? gameSave;
  final ValueListenable<Set<String>> animatingUnitIdsListenable;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GamePrimaryActionShortcutScope(
      enabled: gameSave != null && session.saveId.isNotEmpty,
      onActivate: () => _activate(ref),
      child: child,
    );
  }

  void _activate(WidgetRef ref) {
    final save = gameSave;
    if (save == null || session.saveId.isEmpty) return;
    if (animatingUnitIdsListenable.value.isNotEmpty) return;

    final playerControl = PlayerControlCoordinator.normalize(
      current: ref.read(gamePlayerControlControllerProvider),
      save: save,
    );
    final activePlayerId = playerControl.activePlayerId;
    if (activePlayerId.isEmpty || !playerControl.canAct) return;
    if (save.playerStates[activePlayerId] == PlayerTurnState.finished) {
      return;
    }

    final gameState = ref.read(gameStateProvider(session.saveId)).value;
    if (gameState == null || gameState.hasSubmittedTurn(activePlayerId)) {
      return;
    }

    final technologyViewModel = ref.read(
      technologyPanelViewModelProvider(session.saveId, activePlayerId),
    );
    final readyToEndTurn = hudPlayerReadyToEndTurn(
      gameState: gameState,
      activePlayerId: activePlayerId,
      technologyViewModel: technologyViewModel,
    );

    unawaited(
      ref
          .read(hudCommandDispatcherProvider)
          .endTurn(
            animatingUnitIdsListenable: animatingUnitIdsListenable,
            gameSave: save,
            activePlayerId: activePlayerId,
            readyToEndTurn: readyToEndTurn,
            currentState: () =>
                ref.read(gameStateProvider(session.saveId)).value,
          ),
    );
  }
}

class _GameStartupLoadingOverlay extends ConsumerStatefulWidget {
  final String saveId;
  final bool multiplayer;
  final Future<void> preloadFuture;
  final ValueListenable<bool> rendererReady;
  final ValueListenable<bool> initialCameraFocusReady;
  final ValueListenable<GameLoadingProgress> loadingProgress;

  const _GameStartupLoadingOverlay({
    required this.saveId,
    required this.multiplayer,
    required this.preloadFuture,
    required this.rendererReady,
    required this.initialCameraFocusReady,
    required this.loadingProgress,
  });

  @override
  ConsumerState<_GameStartupLoadingOverlay> createState() =>
      _GameStartupLoadingOverlayState();
}

class _GameStartupLoadingOverlayState
    extends ConsumerState<_GameStartupLoadingOverlay> {
  String? _mapLoadedSentFor;

  @override
  void didUpdateWidget(_GameStartupLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.saveId != widget.saveId) {
      _mapLoadedSentFor = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameLoadingProgress>(
      valueListenable: widget.loadingProgress,
      builder: (context, progress, _) {
        return FutureBuilder<void>(
          future: widget.preloadFuture,
          builder: (context, snapshot) {
            final assetsReady =
                snapshot.connectionState == ConnectionState.done;
            return ValueListenableBuilder<bool>(
              valueListenable: widget.rendererReady,
              builder: (context, rendererReady, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: widget.initialCameraFocusReady,
                  builder: (context, cameraReady, _) {
                    final localReady =
                        assetsReady && rendererReady && cameraReady;
                    if (localReady) {
                      _notifyServerMapLoadedIfNeeded();
                    }
                    final waitingForNetwork = _waitingForNetworkStart();
                    if (localReady && !waitingForNetwork) {
                      return const SizedBox.shrink();
                    }
                    return GameLoadingPanel(
                      key: const Key('gameScreen.startupLoadingOverlay'),
                      progress: localReady ? progress.bumpedTo(0.98) : progress,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  bool _waitingForNetworkStart() {
    if (!widget.multiplayer || widget.saveId.isEmpty) return false;
    final session = ref.watch(networkSessionProvider);
    if (session == null ||
        !session.isConnected ||
        session.matchId != widget.saveId) {
      return false;
    }
    final match = ref.watch(
      multiplayerMatchProvider.select((matches) => matches[widget.saveId]),
    );
    return match == null || match.state == 'loading';
  }

  void _notifyServerMapLoadedIfNeeded() {
    if (!widget.multiplayer || widget.saveId.isEmpty) return;
    if (_mapLoadedSentFor == widget.saveId) return;
    final session = ref.read(networkSessionProvider);
    if (session == null ||
        !session.isConnected ||
        session.matchId != widget.saveId) {
      return;
    }
    _mapLoadedSentFor = widget.saveId;
    unawaited(
      NetworkSessionClient(
            serverpodHost: ref.read(apiConfigProvider).baseUrl.toString(),
          )
          .markMapLoaded(token: session.token, matchId: widget.saveId)
          .then((match) {
            if (!mounted) return;
            ref.read(multiplayerMatchProvider.notifier).upsert(match);
          })
          .catchError((Object error, StackTrace stackTrace) {
            if (!mounted) return;
            ref
                .read(multiplayerConnectionStatusProvider.notifier)
                .setStatus(
                  MultiplayerConnectionStatusSnapshot(
                    saveId: widget.saveId,
                    status: NetworkConnectionStatus.reconnecting,
                    message: error.toString(),
                    changedAt: ref.read(gameClockProvider).nowUtc(),
                  ),
                );
          }),
    );
  }
}

class _MultiplayerConnectionBanner extends ConsumerWidget {
  final String saveId;

  const _MultiplayerConnectionBanner({required this.saveId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(multiplayerConnectionStatusProvider);
    if (state == null || state.saveId != saveId) {
      return const SizedBox.shrink();
    }
    if (state.status == NetworkConnectionStatus.connected) {
      return const SizedBox.shrink();
    }

    final message = switch (state.status) {
      NetworkConnectionStatus.connecting =>
        'Connecting to multiplayer match...',
      NetworkConnectionStatus.reconnecting =>
        'Reconnecting to multiplayer match...',
      NetworkConnectionStatus.offline =>
        state.message == null || state.message!.isEmpty
            ? 'Multiplayer connection is offline.'
            : 'Multiplayer connection is offline. ${state.message}',
      NetworkConnectionStatus.connected => '',
    };

    return SafeArea(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: GameUiTheme.bg.withAlpha(228),
              border: Border.all(color: GameUiTheme.gold.withAlpha(150)),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                message,
                key: const Key('gameScreen.multiplayerConnectionBanner'),
                textAlign: TextAlign.center,
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameStateReadyGate extends ConsumerWidget {
  final MapSelection selection;
  final GameSession session;
  final Widget child;

  const _GameStateReadyGate({
    required this.selection,
    required this.session,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (session.saveId.isEmpty) return child;
    final loadingProgress = GameLoadingProgress.initial.bumpedTo(0.42);

    return ref
        .watch(gameStateProvider(session.saveId))
        .when(
          loading: () =>
              GameLoadingView(progress: loadingProgress.bumpedTo(0.46)),
          error: (error, _) => GameLoadErrorView(
            mapName: selection.displayName,
            error: error,
            onBack: () => context.go('/new-game'),
          ),
          data: (state) {
            if (state.activePlayerId.isEmpty) {
              return GameLoadingView(progress: loadingProgress.bumpedTo(0.48));
            }
            return child;
          },
        );
  }
}

class _MapVignetteOverlay extends StatelessWidget {
  const _MapVignetteOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      key: const Key('gameScreen.mapVignette'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.92,
            colors: [Colors.transparent, GameUiTheme.bg.withAlpha(120)],
            stops: const [0.68, 1.0],
          ),
        ),
      ),
    );
  }
}
