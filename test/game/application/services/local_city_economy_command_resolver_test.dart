import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local production rejection exposes strategic shortage metadata', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 0, row: 0),
      population: 8,
    );
    final state = GameClientState(
      activePlayerId: 'player_1',
      cities: const [city],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.massProduction},
          ),
        },
      ),
    );
    final snapshot = GameSnapshotFactory.fromClientState(
      save: GameSave(
        id: 'save_1',
        name: 'Strategic shortage',
        mapName: 'verdantia',
        turn: 7,
        playerStates: const {'player_1': PlayerTurnState.active},
        savedAt: DateTime.utc(2026, 7, 29),
        camera: CameraState.zero,
        players: const [
          Player(id: 'player_1', name: 'Alice', colorValue: 0xFF000001),
        ],
      ),
      state: state,
    );

    final result =
        LocalCommandResolver(
          reducer: GameStateReducer(mapData: _mapData),
        ).resolve(
          baseSnapshot: snapshot,
          currentState: state,
          command: const StartUnitProductionCommand(
            'city_1',
            GameUnitType.tank,
          ),
          savedAt: DateTime.utc(2026, 7, 29, 18),
          context: const GameCommandContext(actorPlayerId: 'player_1'),
        );

    expect(result.state, same(state));
    expect(result.accepted, isFalse);
    expect(
      result.rejectionReason,
      'unit_production_missing_strategic_resource',
    );
  });
}

final _mapData = WorldMap(
  cols: 1,
  rows: 1,
  tiles: [
    WorldTile(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
