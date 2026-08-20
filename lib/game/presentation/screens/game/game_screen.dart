import 'dart:async';

import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/presentation/audio/game_audio_controller.dart';
import 'package:aonw/game/presentation/controllers/server_map_loaded_notification_policy.dart';
import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/providers/map/map_inspection_binder.dart';
import 'package:aonw/game/presentation/screens/game/game_map_vignette_overlay.dart';
import 'package:aonw/game/presentation/screens/game/game_primary_action_controller.dart';
import 'package:aonw/game/presentation/screens/game/gamepad_renderer_input_binding.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_status_rules.dart';
import 'package:aonw/game/presentation/widgets.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:aonw/game/presentation/widgets/screen/game_startup_asset_preloader.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/map/widgets/dice_roll_test_overlay.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/providers/performance_settings_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/viewport_gesture_layer.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'game_screen_play_surface.dart';
part 'game_screen_renderer_lifecycle.dart';
part 'game_screen_startup_overlay.dart';
part 'game_screen_status_overlays.dart';

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
  Future<void> Function(GameIntent intent)? _rendererCommandDispatcher;
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

  Future<void> _preloadStartupAssets() async {
    try {
      _reportStartupAssetProgress(0);
      await GameStartupAssetPreloader.preload(
        widget.session,
        onProgress: _reportStartupAssetProgress,
      );
    } catch (_) {
      // Renderer loading reports failures, so a platform cache warmup must not
      // leave the player stuck behind an overlay.
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

  Future<void> _dispatchRendererCommand(GameIntent command) async {
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
    unawaited(
      ref.read(networkSessionStateProvider.notifier).rememberMatch(matchId),
    );
  }

  Future<void> _rememberActiveMultiplayerMatch() async {
    final matchId = _activeMultiplayerMatchId();
    if (matchId == null) return;

    await ref.read(networkSessionStateProvider.notifier).rememberMatch(matchId);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final gameplaySettings = ref.watch(gameplaySettingsProvider);
    final hudPanelModes = ref.watch(hudPanelControllerProvider);
    final hudGamepadFocusActive = ref.watch(
      hudGamepadFocusControllerProvider.select((state) => state.active),
    );
    final hudGamepadPopupInputCaptured = ref.watch(
      hudGamepadPopupInputCaptureProvider,
    );
    final rendererGamepadInputEnabled =
        !hudGamepadFocusActive &&
        !hudGamepadPopupInputCaptured &&
        !hudPanelModes.blocksRendererInput;
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
              focusOwnUnitMovementCamera:
                  gameplaySettings.focusOwnUnitMovementCamera,
              followOwnUnitMovementCamera:
                  gameplaySettings.followOwnUnitMovementCamera,
              focusEnemyUnitMovementCamera:
                  gameplaySettings.focusEnemyUnitMovementCamera,
              followEnemyUnitMovementCamera:
                  gameplaySettings.followEnemyUnitMovementCamera,
              cinematicCameraEnabled: gameplaySettings.cinematicCameraEnabled,
              child: ProviderScope(
                overrides: [
                  gamePlayerControlSaveProvider.overrideWithValue(
                    widget.gameSave,
                  ),
                ],
                child: GamepadRendererInputBinding(
                  renderer: _renderer,
                  gamepadSettings: gameplaySettings.gamepad,
                  rendererInputEnabled: rendererGamepadInputEnabled,
                  builder: (context, gamepadInput) =>
                      GamePrimaryActionController(
                        session: session,
                        gameSave: widget.gameSave,
                        animatingUnitIdsListenable:
                            _renderer.animatingUnitIdsListenable,
                        gamepadInputListenable: gamepadInput,
                        child: _GameRendererPlaySurface(
                          selection: widget.selection,
                          session: session,
                          gameSave: widget.gameSave,
                          renderer: _renderer,
                          displaySettings: widget.displaySettings,
                          loadingProgress: _loadingProgressController,
                          gamepadInputListenable: gamepadInput,
                          preloadFuture: _startupAssetPreload,
                          showDiceRollTestOverlay: _showDiceRollTestOverlay,
                          onToggleDiceRollTest: () {
                            setState(() {
                              _showDiceRollTestOverlay =
                                  !_showDiceRollTestOverlay;
                            });
                          },
                          onClose: _returnToMainMenu,
                        ),
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
