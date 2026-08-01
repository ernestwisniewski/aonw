import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/objective.dart';

MapObjectiveProgress? mapObjectiveProgressForTile({
  required WorldMap mapData,
  required WorldTile tileData,
  required GameClientState? gameState,
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

MapObjectiveDefinition? _objectiveAt(WorldMap mapData, WorldTile tileData) {
  for (final objective in mapData.objectives) {
    if (objective.hex.col == tileData.col &&
        objective.hex.row == tileData.row) {
      return objective;
    }
  }
  return null;
}
