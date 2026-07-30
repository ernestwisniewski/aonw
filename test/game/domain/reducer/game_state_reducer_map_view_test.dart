import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/game_intent_test_resolver.dart';

void main() {
  late MapReadView mapView;

  setUp(() {
    mapView = WorldMapReadView(_worldMap());
  });

  test(
    'dispatches tile and production commands through canonical map view',
    () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 1)],
      );
      final reducer = GameStateReducer(mapData: mapView);
      final initial = GameState(
        cities: const [city],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: {const HexCoordinate(col: 2, row: 1)},
            ),
          },
        ),
        interaction: const GameInteractionState(
          pendingAction: PendingResearchSelection(ownerPlayerId: 'player_1'),
        ),
      );

      final inspected = resolveGameIntent(
        reducer,
        initial,
        const TileTappedCommand(2, 1),
      );

      expect(reducer.mapData, same(mapView));
      expect(inspected.state.selection?.type, GameSelectionType.tile);
      expect(inspected.state.selection?.tile, isA<SelectedTile>());
      expect(inspected.state.selection?.tile?.col, 2);
      expect(inspected.state.selection?.tile?.row, 1);
      expect(
        inspected.state.selection?.tile?.primaryTerrain,
        TerrainType.plains,
      );

      final produced = resolveGameIntent(
        reducer,
        inspected.state,
        const StartUnitProductionCommand('city_1', GameUnitType.warrior),
      );

      expect(
        produced.state.cities.single.productionQueue,
        CityProductionQueue.unit(
          unitType: GameUnitType.warrior,
          investedProduction: 0,
        ),
      );
    },
  );

  test('environment copy keeps the same canonical map view', () {
    final environment = ReducerEnvironment(mapData: mapView);

    final copied = environment.copyWith();

    expect(copied.mapData, same(mapView));
  });

  test('local simultaneous finalization reuses canonical reducer view', () {
    final savedAt = DateTime.utc(2026, 7, 16, 12);
    final save = GameSave(
      id: 'save_1',
      name: 'Canonical local game',
      mapName: 'canonical_map',
      turn: 1,
      playerStates: const {
        'player_1': PlayerTurnState.finished,
        'player_2': PlayerTurnState.active,
      },
      savedAt: savedAt.subtract(const Duration(minutes: 1)),
      camera: CameraState.zero,
      players: const [
        Player(id: 'player_1', name: 'Player 1', colorValue: 0xFF123456),
        Player(id: 'player_2', name: 'Player 2', colorValue: 0xFF654321),
      ],
      gameMode: GameMode.multiplayer,
    );
    const state = GameState(
      activePlayerId: 'player_2',
      activePlayerCanAct: true,
      submittedPlayerIds: {'player_1'},
    );
    final reducer = GameStateReducer(mapData: mapView);

    final result = LocalCommandResolver(reducer: reducer).resolve(
      baseSnapshot: SaveSnapshot.fromGameState(save: save, state: state),
      currentState: state,
      command: const SubmitTurnCommand('player_2'),
      savedAt: savedAt,
    );

    expect(reducer.mapData, same(mapView));
    expect(result.snapshot.domain.turn, 2);
    expect(result.state.submittedPlayerIds, isEmpty);
    expect(result.events.whereType<AllPlayersSubmittedEvent>(), hasLength(1));
    expect(result.events.whereType<TurnEndedEvent>(), hasLength(2));
  });
}

WorldMap _worldMap() {
  return WorldMap(
    cols: 3,
    rows: 3,
    mapName: 'canonical_map',
    tiles: [
      for (var row = 0; row < 3; row += 1)
        for (var col = 0; col < 3; col += 1)
          WorldTile(
            coordinate: HexCoord(col: col, row: row),
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
