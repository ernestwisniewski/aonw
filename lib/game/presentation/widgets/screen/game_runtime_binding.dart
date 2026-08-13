import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Applies the bootstrapped Riverpod state to the active [GameRenderer].
///
/// Later command updates are pushed through `GameRenderer.applyTransition` so
/// movement animations can reserve marker positions before layer sync runs.
class GameRuntimeBinding extends ConsumerStatefulWidget {
  final GameSession session;
  final GameRenderer renderer;
  final HexDisplaySettings displaySettings;
  final bool reduceMotion;
  final bool focusOwnUnitMovementCamera;
  final bool followOwnUnitMovementCamera;
  final bool focusEnemyUnitMovementCamera;
  final bool followEnemyUnitMovementCamera;
  final bool cinematicCameraEnabled;
  final Widget child;

  const GameRuntimeBinding({
    required this.session,
    required this.renderer,
    required this.displaySettings,
    this.reduceMotion = false,
    this.focusOwnUnitMovementCamera = true,
    this.followOwnUnitMovementCamera = false,
    this.focusEnemyUnitMovementCamera = false,
    this.followEnemyUnitMovementCamera = false,
    this.cinematicCameraEnabled = false,
    required this.child,
    super.key,
  });

  @override
  ConsumerState<GameRuntimeBinding> createState() => _GameRuntimeBindingState();
}

class _GameRuntimeBindingState extends ConsumerState<GameRuntimeBinding> {
  GameClientState? _appliedState;

  @override
  void initState() {
    super.initState();
    _syncRenderer();
  }

  @override
  void didUpdateWidget(GameRuntimeBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.renderer != widget.renderer ||
        oldWidget.displaySettings != widget.displaySettings ||
        oldWidget.reduceMotion != widget.reduceMotion ||
        oldWidget.focusOwnUnitMovementCamera !=
            widget.focusOwnUnitMovementCamera ||
        oldWidget.followOwnUnitMovementCamera !=
            widget.followOwnUnitMovementCamera ||
        oldWidget.focusEnemyUnitMovementCamera !=
            widget.focusEnemyUnitMovementCamera ||
        oldWidget.followEnemyUnitMovementCamera !=
            widget.followEnemyUnitMovementCamera ||
        oldWidget.cinematicCameraEnabled != widget.cinematicCameraEnabled) {
      _syncRenderer();
    }
  }

  void _syncRenderer() {
    final gameplaySettings = ref.read(gameplaySettingsProvider);
    widget.renderer
      ..viewMode = widget.session.viewMode
      ..displaySettings = widget.displaySettings
      ..reduceMotion = widget.reduceMotion
      ..applyMovementCameraSettings((
        focusOwnUnitMovementCamera: widget.focusOwnUnitMovementCamera,
        followOwnUnitMovementCamera: widget.followOwnUnitMovementCamera,
        focusEnemyUnitMovementCamera: widget.focusEnemyUnitMovementCamera,
        followEnemyUnitMovementCamera: widget.followEnemyUnitMovementCamera,
        cinematicCameraEnabled: widget.cinematicCameraEnabled,
        unitAnimationsEnabled: gameplaySettings.showAnimations,
        cameraTransitionsEnabled: gameplaySettings.animateCameraTransitions,
      ));
    _applyCurrentStateIfReady();
  }

  void _applyCurrentStateIfReady() {
    final next = ref.read(gameStateProvider(widget.session.saveId));
    if (next.isLoading) return;
    final state = next.value;
    if (state == null) return;
    widget.renderer.applyState(state, currentTurn: _currentTurn());
    _appliedState = state;
  }

  @override
  Widget build(BuildContext context) {
    _keepCommandControllerAlive();
    _listenForBootstrapState();
    _listenForAnimationSettings();
    return widget.child;
  }

  void _listenForAnimationSettings() {
    ref.listen(gameplaySettingsProvider, (_, _) => _syncRenderer());
  }

  void _keepCommandControllerAlive() {
    ref.watch(gameCommandControllerProvider);
  }

  void _listenForBootstrapState() {
    ref.listen<AsyncValue<GameClientState>>(
      gameStateProvider(widget.session.saveId),
      (_, next) {
        if (next.isLoading) return;
        if (_appliedState != null) return;
        final state = next.value;
        if (state == null) return;
        if (!identical(ref.read(activeGameSessionProvider), widget.session)) {
          return;
        }
        widget.renderer.applyState(state, currentTurn: _currentTurn());
        _appliedState = state;
      },
    );
  }

  int? _currentTurn() {
    final saveId = widget.session.saveId;
    if (saveId.isEmpty) return null;
    return ref.read(gameSaveProvider(saveId)).value?.turn;
  }
}
