import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentTurnPipeline', () {
    test('advancePlayer advances one player without simultaneous events', () {
      final result = PersistentTurnPipeline.advancePlayer(
        state: const PersistentGameState(),
        playerId: 'player_1',
        mapView: _mapData(),
      );

      expect(result.events.whereType<AllPlayersSubmittedEvent>(), isEmpty);
      expect(
        result.events.whereType<TurnEndedEvent>().map(
          (event) => event.playerId,
        ),
        ['player_1'],
      );
    });

    test(
      'advancePlayer applies plain peace decay when turn number is unknown',
      () {
        final state = PersistentGameState(
          playerWarWeariness: const {'player_1': 7},
          runtimeState: GameRuntimeState(
            diplomacy: DiplomacyState(
              relations: {
                'player_1|player_2': const DiplomaticRelation(
                  playerAId: 'player_1',
                  playerBId: 'player_2',
                  status: DiplomaticRelationStatus.truce,
                  lastChangedTurn: 1,
                ),
              },
            ),
          ),
        );

        final result = PersistentTurnPipeline.advancePlayer(
          state: state,
          playerId: 'player_1',
          mapView: _mapData(),
        );

        expect(result.state.playerWarWeariness['player_1'], 6);
      },
    );
  });
}

MapData _mapData() {
  return MapData(
    cols: 3,
    rows: 3,
    tiles: [
      for (var col = 0; col < 3; col++)
        for (var row = 0; row < 3; row++)
          TileData(
            col: col,
            row: row,
            terrains: [TerrainType.grassland],
            resources: const [],
            height: 1,
          ),
    ],
  );
}
