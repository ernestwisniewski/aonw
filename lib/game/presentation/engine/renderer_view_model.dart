import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_renderer.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';

abstract interface class RendererViewModel {
  AppLocalizations? get l10n;
  CameraState get cameraState;

  Future<void> handleEffect(RendererEffect effect);
  Future<void> applyTransition(
    GameClientState state,
    Iterable<RendererEffect> effects, {
    int? currentTurn,
  });
  void applyStateWithoutCameraFocus(GameClientState state, {int? currentTurn});
}

final class GameRendererViewModel implements RendererViewModel {
  final GameRenderer _renderer;

  const GameRendererViewModel(this._renderer);

  @override
  AppLocalizations? get l10n => _renderer.l10n;

  @override
  CameraState get cameraState {
    final viewfinder = _renderer.camera.viewfinder;
    return CameraState(
      x: viewfinder.position.x,
      y: viewfinder.position.y,
      zoom: viewfinder.zoom,
    );
  }

  @override
  Future<void> handleEffect(RendererEffect effect) {
    return _renderer.handleEffect(effect);
  }

  @override
  Future<void> applyTransition(
    GameClientState state,
    Iterable<RendererEffect> effects, {
    int? currentTurn,
  }) {
    return _renderer.applyTransition(state, effects, currentTurn: currentTurn);
  }

  Future<void> applyAuthoritativeProjection(
    GameClientState state,
    ProjectedGameEffectBatch batch, {
    int? currentTurn,
  }) {
    return _renderer.applyProjectedTransition(
      state,
      batch,
      currentTurn: currentTurn,
    );
  }

  @override
  void applyStateWithoutCameraFocus(GameClientState state, {int? currentTurn}) {
    _renderer.applyStateWithoutCameraFocus(state, currentTurn: currentTurn);
  }
}

final Expando<ProjectedGameEffectCursor> _projectedEffectCursors = Expando();
final Expando<ProjectedGameTransitionQueue<GameClientState>>
_projectedTransitionQueues = Expando();

extension ProjectedRendererViewModel on RendererViewModel {
  ProjectedGameEffectCursor get _projectedEffectCursor {
    return _projectedEffectCursors[this] ??= ProjectedGameEffectCursor();
  }

  ProjectedGameTransitionQueue<GameClientState> get _projectedTransitionQueue {
    return _projectedTransitionQueues[this] ??=
        ProjectedGameTransitionQueue<GameClientState>();
  }

  Future<void> applyProjectedTransition(
    GameClientState state,
    ProjectedGameEffectBatch batch, {
    int? currentTurn,
  }) async {
    if (this case final GameRendererViewModel production) {
      return production.applyAuthoritativeProjection(
        state,
        batch,
        currentTurn: currentTurn,
      );
    }
    final ready = _projectedTransitionQueue.enqueue(
      ProjectedGameTransition(
        state: state,
        batch: batch,
        currentTurn: currentTurn,
      ),
    );
    for (final transition in ready) {
      final effects = _projectedEffectCursor.consumeBatch(transition.batch);
      await applyTransition(
        transition.state,
        effects,
        currentTurn: transition.currentTurn,
      );
    }
  }

  void resetProjectedEffectCursorForReplaySeek() {
    _projectedEffectCursor.resetForReplaySeek();
    _projectedTransitionQueue.resetForReplaySeek();
  }

  void activateProjectedEffectSource(String sourceId, {int? nextEventOffset}) {
    if (this case final GameRendererViewModel production) {
      production._renderer.activateProjectedEffectSource(
        sourceId,
        nextEventOffset: nextEventOffset,
      );
      return;
    }
    _projectedEffectCursor.activateSource(
      sourceId,
      nextEventOffset: nextEventOffset,
    );
    _projectedTransitionQueue.activateSource(
      sourceId,
      nextEventOffset: nextEventOffset,
    );
  }
}
