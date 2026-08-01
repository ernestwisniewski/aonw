part of 'game_state_reducer_integration_test.dart';

GameClientState _withRememberedFog(
  GameClientState state,
  WorldMap mapData,
  Iterable<HexCoordinate> rememberedHexes,
) {
  final visibleState = _withFog(state, mapData);
  final playerFog = visibleState.fogOfWar.fogForPlayer(
    visibleState.activePlayerId,
  );
  return visibleState.copyWith(
    fogOfWar: visibleState.fogOfWar.updatePlayer(
      playerFog.copyWith(
        discoveredHexes: {...playerFog.discoveredHexes, ...rememberedHexes},
      ),
    ),
  );
}
