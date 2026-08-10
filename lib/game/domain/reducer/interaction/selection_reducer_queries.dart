part of 'selection_reducer.dart';

bool _isSelectedUnit(GameClientState state, GameUnit unit) {
  return state.selection?.type == GameSelectionType.unit &&
      state.selection?.unit?.id == unit.id;
}

bool _isActivePlayerOwned(_ClientState state, String ownerPlayerId) {
  return state.activePlayerId.isNotEmpty &&
      state.activePlayerId == ownerPlayerId;
}

FieldImprovement? _fieldImprovementAt(
  GameClientState state,
  MapTileView tile,
  FogVisibilityQuery visibility,
) {
  if (!visibility.canRememberStaticAt(tile.col, tile.row)) {
    return null;
  }
  for (final improvement in state.fieldImprovements) {
    if (improvement.occupies(tile.col, tile.row)) {
      return improvement;
    }
  }
  return null;
}
