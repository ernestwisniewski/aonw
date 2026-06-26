import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/game/presentation/providers.dart';
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
  final bool followUnitMovementCamera;
  final bool followEnemyUnitCamera;
  final bool cinematicCameraEnabled;
  final Widget child;

  const GameRuntimeBinding({
    required this.session,
    required this.renderer,
    required this.displaySettings,
    this.reduceMotion = false,
    this.followUnitMovementCamera = false,
    this.followEnemyUnitCamera = false,
    this.cinematicCameraEnabled = false,
    required this.child,
    super.key,
  });

  @override
  ConsumerState<GameRuntimeBinding> createState() => _GameRuntimeBindingState();
}

class _GameRuntimeBindingState extends ConsumerState<GameRuntimeBinding> {
  GameState? _appliedState;

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
        oldWidget.followUnitMovementCamera != widget.followUnitMovementCamera ||
        oldWidget.followEnemyUnitCamera != widget.followEnemyUnitCamera ||
        oldWidget.cinematicCameraEnabled != widget.cinematicCameraEnabled) {
      _syncRenderer();
    }
  }

  void _syncRenderer() {
    widget.renderer
      ..viewMode = widget.session.viewMode
      ..displaySettings = widget.displaySettings
      ..reduceMotion = widget.reduceMotion
      ..followUnitMovementCamera = widget.followUnitMovementCamera
      ..followEnemyUnitCamera = widget.followEnemyUnitCamera
      ..cinematicCameraEnabled = widget.cinematicCameraEnabled;
    _applyCurrentStateIfReady();
  }

  void _applyCurrentStateIfReady() {
    final state = ref.read(gameStateProvider(widget.session.saveId)).value;
    if (state == null || !_canApplyState(state)) return;
    widget.renderer.applyState(state, currentTurn: _currentTurn());
    _appliedState = state;
  }

  bool _canApplyState(GameState state) {
    if (widget.session.saveId.isEmpty) return true;
    return state.activePlayerId.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    _keepCommandControllerAlive();
    _listenForBootstrapState();
    return widget.child;
  }

  void _keepCommandControllerAlive() {
    ref.watch(gameCommandControllerProvider);
  }

  void _listenForBootstrapState() {
    ref.listen<AsyncValue<GameState>>(
      gameStateProvider(widget.session.saveId),
      (_, next) {
        if (_appliedState != null) return;
        final state = next.value;
        if (state == null || !_canApplyState(state)) return;
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
