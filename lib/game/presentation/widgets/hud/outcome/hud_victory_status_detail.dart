part of 'hud_victory_status_summary.dart';

class HudVictoryStatusDetail {
  final String label;
  final String value;
  final bool highlighted;

  const HudVictoryStatusDetail({
    required this.label,
    required this.value,
    this.highlighted = false,
  });
}

Map<String, int> _victoryScores(
  GameSave gameSave,
  GameClientState? gameState,
  WorldMap? mapData,
  EmpireScoreCalculator scoreCalculator,
) {
  if (gameState == null) return const {};
  return scoreCalculator.scoresForCollections(
    playerIds: gameSave.players.map((player) => player.id),
    cities: gameState.cities,
    units: gameState.units,
    fieldImprovements: gameState.fieldImprovements,
    research: gameState.research,
    playerGold: gameState.playerGold,
    mapObjectives: mapData?.objectives ?? const [],
    mapObjectiveHoldStatesByObjectiveId:
        gameState.mapObjectiveHoldStatesByObjectiveId,
  );
}
