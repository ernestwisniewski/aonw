import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_renderer.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';

abstract interface class RendererViewModel {
  AppLocalizations? get l10n;
  CameraState get cameraState;

  Future<void> handleEffect(RendererEffect effect);
  Future<void> applyTransition(
    GameState state,
    Iterable<RendererEffect> effects,
  );
  void applyStateWithoutCameraFocus(GameState state);
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
    GameState state,
    Iterable<RendererEffect> effects,
  ) {
    return _renderer.applyTransition(state, effects);
  }

  @override
  void applyStateWithoutCameraFocus(GameState state) {
    _renderer.applyStateWithoutCameraFocus(state);
  }
}
