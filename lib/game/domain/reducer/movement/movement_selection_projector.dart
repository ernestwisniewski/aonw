part of 'movement_reducer.dart';

abstract final class _MoveSelection {
  static GameSelection forUnit(
    GameState state,
    GameUnit unit,
    MapTileLookup mapTiles,
  ) {
    final tile = mapTiles.tileAt(unit.col, unit.row);
    return GameSelection.unit(unit, tile: tile).withVisibleResources(
      playerId: state.activePlayerId,
      research: state.research,
    );
  }
}
