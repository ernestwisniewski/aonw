import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/objective.dart';

MapObjectiveProgress? mapObjectiveProgressForTile({
  required MapData mapData,
  required TileData tileData,
  required GameState? gameState,
}) {
  final objective = _objectiveAt(mapData, tileData);
  if (objective == null) return null;
  if (gameState == null) {
    return MapObjectiveProgress(
      definition: objective,
      controllingPlayerId: null,
      holdTurns: 0,
    );
  }
  return MapObjectiveRules.snapshot(
    objectives: [objective],
    cities: gameState.cities,
    units: gameState.units,
    holdStatesByObjectiveId: gameState.mapObjectiveHoldStatesByObjectiveId,
  ).entryFor(objective.id);
}

MapObjectiveDefinition? _objectiveAt(MapData mapData, TileData tileData) {
  for (final objective in mapData.objectives) {
    if (objective.hex.col == tileData.col &&
        objective.hex.row == tileData.row) {
      return objective;
    }
  }
  return null;
}
