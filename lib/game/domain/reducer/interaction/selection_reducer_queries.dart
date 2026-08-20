part of 'selection_reducer.dart';

bool _isSelectedUnit(GameClientState state, GameUnit unit) {
  return state.selection?.type == GameSelectionType.unit &&
      state.selection?.unit?.id == unit.id;
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
