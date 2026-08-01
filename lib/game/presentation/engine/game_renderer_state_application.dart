part of 'game_renderer.dart';

extension GameRendererStateApplication on GameRenderer {
  void applyStateWithoutCameraFocus(
    GameClientState state, {
    int? currentTurn,
  }) => _applyState(state, suppressCameraFocus: true, currentTurn: currentTurn);
}
