part of 'game_hud_test.dart';

CanonicalGameSnapshot _withHudTestVisibility(CanonicalGameSnapshot snapshot) {
  if (snapshot.fogOfWar != FogOfWarState.empty) return snapshot;
  final playerIds = snapshot.domain.participants
      .map((player) => player.id)
      .where((playerId) => playerId.isNotEmpty);
  return snapshot.copyWith(
    domain: snapshot.domain.copyWith(
      fogOfWar: FogOfWarState(
        players: {
          for (final playerId in playerIds)
            playerId: PlayerFogOfWar(
              playerId: playerId,
              visibleHexes: {
                for (var row = 0; row < 3; row++)
                  for (var col = 0; col < 3; col++)
                    HexCoordinate(col: col, row: row),
              },
            ),
        },
      ),
    ),
  );
}
