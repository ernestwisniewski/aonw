part of 'game_event_renderer_effect_mapper.dart';

bool _canRenderTransientAt(
  GameClientState state,
  int col,
  int row, {
  String? viewerPlayerId,
}) {
  return MapFocusVisibility.canRenderTransientAt(
    state,
    col,
    row,
    viewerPlayerId: viewerPlayerId,
  );
}

int _colorForPlayer(GameClientState state, String playerId) {
  return PlayerColorTheme.resolveValue(
    state.colorForPlayer(playerId) ?? Player.palette.first,
  );
}
