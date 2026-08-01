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

extension ProjectedRendererViewModel on RendererViewModel {
  ProjectedGameEffectCursor get _projectedEffectCursor {
    return _projectedEffectCursors[this] ??= ProjectedGameEffectCursor();
  }

  Future<void> applyProjectedTransition(
    GameClientState state,
    ProjectedGameEffectBatch batch, {
    int? currentTurn,
  }) {
    if (this case final GameRendererViewModel production) {
      return production.applyAuthoritativeProjection(
        state,
        batch,
        currentTurn: currentTurn,
      );
    }
    final effects = _projectedEffectCursor.consume(batch.projectedEffects);
    return applyTransition(state, effects, currentTurn: currentTurn);
  }

  void resetProjectedEffectCursorForReplaySeek() {
    _projectedEffectCursor.resetForReplaySeek();
  }

  void activateProjectedEffectSource(String sourceId) {
    if (this case final GameRendererViewModel production) {
      production._renderer.activateProjectedEffectSource(sourceId);
      return;
    }
    _projectedEffectCursor.activateSource(sourceId);
  }
}
