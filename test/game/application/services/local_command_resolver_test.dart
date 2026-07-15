import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local submit rejection falls back to persisted player states', () {
    final save = GameSave(
      id: 'save_1',
      name: 'Metadata-free local save',
      mapName: 'verdantia',
      turn: 7,
      playerStates: const {'player_1': PlayerTurnState.active},
      savedAt: DateTime.utc(2026, 7, 11),
      camera: CameraState.zero,
    );
    const state = GameState(activePlayerId: 'player_1');
    final savedAt = DateTime.utc(2026, 7, 11, 12);

    final result =
        LocalCommandResolver(
          reducer: GameStateReducer(mapData: _mapData()),
        ).resolve(
          baseSnapshot: SaveSnapshot.fromGameState(save: save, state: state),
          currentState: state,
          command: const SubmitTurnCommand('not-a-player'),
          savedAt: savedAt,
        );

    expect(result.save.playerStates, save.playerStates);
    expect(result.save.savedAt, savedAt);
    expect(result.state, state);
    expect(result.events, isEmpty);
  });
}

MapData _mapData() => MapData(
  cols: 1,
  rows: 1,
  tiles: [
    const TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
