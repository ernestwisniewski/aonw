import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map(int cols, int rows) => MapData(
  cols: cols,
  rows: rows,
  tiles: [
    for (int row = 0; row < rows; row++)
      for (int col = 0; col < cols; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

GameUnit _commander({int col = 0, int row = 0}) {
  return GameUnit.startingCommander(
    ownerPlayerId: 'player_1',
    col: col,
    row: row,
  );
}

GameCity _city({
  String ownerPlayerId = 'player_1',
  int col = 1,
  int row = 1,
  List<CityHex> controlledHexes = const [],
}) {
  return GameCity(
    id: 'city_${ownerPlayerId}_${col}_$row',
    ownerPlayerId: ownerPlayerId,
    name: 'City',
    center: CityHex(col: col, row: row),
    controlledHexes: controlledHexes,
  );
}

/// Helper: dispatch a command through the reducer.
GameStateTransition _dispatch(
  GameStateReducer reducer,
  GameState state,
  GameCommand command,
) {
  return reducer.reduce(state, command);
}

GameState _withFog(GameState state, MapData mapData) {
  return state.copyWith(
    fogOfWar: const FogOfWarService().recompute(
      current: state.fogOfWar,
      mapData: mapData,
      playerIds: {state.activePlayerId},
      units: state.units,
      cities: state.cities,
    ),
  );
}

GameState _withRememberedFog(
  GameState state,
  MapData mapData,
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

void main() {
  group('GameStateReducer integration', () {
    test(
      'tapping commander tile cycles: unit+move -> unit -> tile -> unit+move',
      () {
        final map = _map(3, 3);
        final reducer = GameStateReducer(mapData: map);
        var state = _withFog(
          GameState(
            units: [_commander()],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
          ),
          map,
        );

        // 1st tap: unit selected + move active
        state = _dispatch(reducer, state, const TileTappedCommand(0, 0)).state;
        expect(state.selection?.type, GameSelectionType.unit);
        expect(state.moveCommandActive, isTrue);

        // 2nd tap in move mode on own tile: cancel move, unit still selected
        state = _dispatch(reducer, state, const TileTappedCommand(0, 0)).state;
        expect(state.selection?.type, GameSelectionType.unit);
        expect(state.moveCommandActive, isFalse);

        // 3rd tap with unit selected but no move: switches to tile
        state = _dispatch(reducer, state, const TileTappedCommand(0, 0)).state;
        expect(state.selection?.type, GameSelectionType.tile);

        // 4th tap: unit selected + move auto-activated again
        state = _dispatch(reducer, state, const TileTappedCommand(0, 0)).state;
        expect(state.selection?.type, GameSelectionType.unit);
        expect(state.moveCommandActive, isTrue);
      },
    );

    test('move targeting previews first, confirms on repeated target tap', () {
      final map = _map(3, 3);
      final reducer = GameStateReducer(mapData: map);
      var state = _withFog(
        GameState(
          units: [_commander()],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
        map,
      );

      // Select unit (auto-enables move targeting)
      state = _dispatch(reducer, state, const TileTappedCommand(0, 0)).state;
      expect(state.selection?.type, GameSelectionType.unit);
      expect(state.moveCommandActive, isTrue);

      // Tap adjacent tile — preview
      final previewTransition = _dispatch(
        reducer,
        state,
        const TileTappedCommand(1, 0),
      );
      state = previewTransition.state;
      expect(state.movePreview?.targetCol, 1);
      expect(state.movePreview?.targetRow, 0);
      expect(state.units.single.col, 0); // not moved yet

      // Tap same tile again — confirm move
      final confirmTransition = _dispatch(
        reducer,
        state,
        const TileTappedCommand(1, 0),
      );
      state = confirmTransition.state;
      expect(state.movePreview, isNull);
      expect(state.moveCommandActive, isTrue);
      expect(state.units.single.col, 1);
      expect(state.units.single.row, 0);
      expect(
        confirmTransition.uiEffects,
        contains(isA<AnimateUnitMoveEffect>()),
      );
    });

    test(
      'move targeting selects another own unit when movement cannot target it',
      () {
        final map = _map(3, 1);
        final reducer = GameStateReducer(mapData: map);
        final commander = _commander();
        final worker = GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 1,
          row: 0,
        );
        final state = _withFog(
          GameState(
            units: [commander, worker],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
            selection: GameSelection.unit(commander, tile: map.tileAt(0, 0)),
            moveCommandActive: true,
          ),
          map,
        );

        final result = _dispatch(reducer, state, const TileTappedCommand(1, 0));

        expect(result.state.selectedUnitId, worker.id);
        expect(result.state.moveCommandActive, isTrue);
      },
    );

    test(
      'move targeting keeps the selected unit when tapping an enemy unit hex',
      () {
        final map = _map(3, 1);
        final reducer = GameStateReducer(mapData: map);
        final commander = _commander();
        final enemy = GameUnit.produced(
          id: 'enemy_worker_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.worker,
          col: 1,
          row: 0,
        );
        final state = _withFog(
          GameState(
            units: [commander, enemy],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
            selection: GameSelection.unit(commander, tile: map.tileAt(0, 0)),
            moveCommandActive: true,
          ),
          map,
        );

        final result = _dispatch(reducer, state, const TileTappedCommand(1, 0));

        expect(result.state.selectedUnitId, commander.id);
        expect(result.state.moveCommandActive, isTrue);
      },
    );

    test('pending worked hex selection consumes tile tap and toggles work', () {
      final map = _map(4, 4);
      final reducer = GameStateReducer(mapData: map);
      final city = _city(
        col: 1,
        row: 1,
        controlledHexes: const [CityHex(col: 2, row: 1)],
      );
      final state = _withFog(
        GameState(
          cities: [city],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          selection: GameSelection.city(
            city,
            cityYield: const TileYield(
              food: 2,
              production: 1,
              gold: 0,
              defense: 0,
            ),
            playerColor: 0xFF4a7fc4,
          ),
          pendingAction: const PendingCityWorkedHexSelection(
            ownerPlayerId: 'player_1',
            cityId: 'city_player_1_1_1',
          ),
        ),
        map,
      );

      final transition = _dispatch(
        reducer,
        state,
        const TileTappedCommand(2, 1),
      );

      final updatedCity = transition.state.cities.single;
      expect(updatedCity.workedHexes, contains(const CityHex(col: 2, row: 1)));
      expect(
        transition.state.pendingAction,
        const PendingCityWorkedHexSelection(
          ownerPlayerId: 'player_1',
          cityId: 'city_player_1_1_1',
        ),
      );
    });

    test(
      'pending city expansion selection consumes tile tap and stores target',
      () {
        final map = _map(4, 4);
        final reducer = GameStateReducer(mapData: map);
        final city = _city(
          col: 1,
          row: 1,
          controlledHexes: const [CityHex(col: 2, row: 1)],
        );
        final state = GameState(
          cities: [city],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          research: ResearchState().updatePlayer(
            'player_1',
            PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.urbanization},
            ),
          ),
          selection: GameSelection.city(
            city,
            cityYield: const TileYield(
              food: 2,
              production: 1,
              gold: 0,
              defense: 0,
            ),
            playerColor: 0xFF4a7fc4,
          ),
          pendingAction: const PendingCityExpansionSelection(
            ownerPlayerId: 'player_1',
            cityId: 'city_player_1_1_1',
          ),
        );

        final transition = _dispatch(
          reducer,
          state,
          const TileTappedCommand(1, 2),
        );

        final updatedCity = transition.state.cities.single;
        expect(
          updatedCity.preferredExpansionHex,
          const CityHex(col: 1, row: 2),
        );
        expect(
          transition.state.selection?.city?.preferredExpansionHex,
          updatedCity.preferredExpansionHex,
        );
        expect(
          transition
              .state
              .selection
              ?.cityEconomy
              ?.technologyEffects
              .maxControlledHexesBonus,
          1,
        );
        expect(
          transition.state.pendingAction,
          const PendingCityExpansionSelection(
            ownerPlayerId: 'player_1',
            cityId: 'city_player_1_1_1',
          ),
        );
      },
    );

    test('MoveUnitCommand moves a controllable unit directly', () {
      final map = _map(3, 3);
      final reducer = GameStateReducer(mapData: map);
      final commander = _commander();
      var state = _withFog(
        GameState(
          units: [commander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          selection: GameSelection.unit(commander),
        ),
        map,
      );

      final transition = _dispatch(
        reducer,
        state,
        MoveUnitCommand(commander.id, 1, 0),
      );
      state = transition.state;

      expect(state.units.single.col, 1);
      expect(state.units.single.row, 0);
      expect(state.selection?.unit?.col, 1);
      expect(state.movePreview, isNull);
      expect(
        transition.uiEffects.whereType<AnimateUnitMoveEffect>().single,
        isA<AnimateUnitMoveEffect>()
            .having((effect) => effect.unitId, 'unitId', commander.id)
            .having((effect) => effect.steps.last.col, 'last col', 1)
            .having((effect) => effect.steps.last.row, 'last row', 0),
      );
    });

    test('MoveUnitCommand partially moves and queues the remaining path', () {
      final map = _map(5, 5);
      final reducer = GameStateReducer(mapData: map);
      final commander = _commander().copyWith(movementPoints: 1);
      final state = _withFog(
        GameState(
          units: [commander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
        map,
      );

      final transition = _dispatch(
        reducer,
        state,
        MoveUnitCommand(commander.id, 3, 0),
      );
      final moved = transition.state.units.single;

      expect(moved.col, 1);
      expect(moved.row, 0);
      expect(moved.movementPoints, 0);
      expect(moved.queuedPath?.targetCol, 3);
      expect(moved.queuedPath?.targetRow, 0);
      expect(
        transition.uiEffects.whereType<AnimateUnitMoveEffect>().single,
        isA<AnimateUnitMoveEffect>()
            .having((effect) => effect.steps.last.col, 'last col', 1)
            .having((effect) => effect.steps.last.row, 'last row', 0),
      );
    });

    test('MoveUnitCommand queues path when unit has no movement points', () {
      final map = _map(5, 5);
      final reducer = GameStateReducer(mapData: map);
      final commander = _commander().copyWith(movementPoints: 0);
      final state = _withFog(
        GameState(
          units: [commander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          selection: GameSelection.unit(commander),
        ),
        map,
      );

      final transition = _dispatch(
        reducer,
        state,
        MoveUnitCommand(commander.id, 2, 0),
      );
      final queued = transition.state.units.single;

      expect(queued.col, 0);
      expect(queued.row, 0);
      expect(queued.queuedPath?.targetCol, 2);
      expect(queued.queuedPath?.targetRow, 0);
      expect(transition.state.selection?.unit?.queuedPath, isNotNull);
    });

    test('MoveUnitCommand approaches a hidden occupied target', () {
      final map = _map(3, 2);
      final reducer = GameStateReducer(mapData: map);
      final commander = _commander();
      final blocker = GameUnit.startingCommander(
        ownerPlayerId: 'player_2',
        col: 2,
        row: 0,
      );
      final state = GameState(
        units: [commander, blocker],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              visibleHexes: {const HexCoordinate(col: 0, row: 0)},
            ),
          },
        ),
      );

      final transition = _dispatch(
        reducer,
        state,
        MoveUnitCommand(commander.id, 2, 0),
      );
      final moved = transition.state.units.firstWhere(
        (unit) => unit.id == commander.id,
      );

      expect(moved.col == 0 && moved.row == 0, isFalse);
      expect(moved.col == 2 && moved.row == 0, isFalse);
      expect(
        HexDistance.between(
          HexCoordinate(col: moved.col, row: moved.row),
          const HexCoordinate(col: 2, row: 0),
        ),
        lessThan(2),
      );
      expect(
        transition.uiEffects.whereType<AnimateUnitMoveEffect>().single,
        isA<AnimateUnitMoveEffect>().having(
          (effect) => effect.unitId,
          'unitId',
          commander.id,
        ),
      );
    });

    test('MoveUnitCommand approaches a visible opponent-occupied target', () {
      final map = _map(3, 2);
      final reducer = GameStateReducer(mapData: map);
      final commander = _commander();
      final blocker = GameUnit.startingCommander(
        ownerPlayerId: 'player_2',
        col: 2,
        row: 0,
      );
      final state = _withFog(
        GameState(
          units: [commander, blocker],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
        map,
      );

      final transition = _dispatch(
        reducer,
        state,
        MoveUnitCommand(commander.id, 2, 0),
      );
      final moved = transition.state.units.firstWhere(
        (unit) => unit.id == commander.id,
      );

      expect(moved.col == 0 && moved.row == 0, isFalse);
      expect(moved.col == 2 && moved.row == 0, isFalse);
      expect(
        HexDistance.between(
          HexCoordinate(col: moved.col, row: moved.row),
          const HexCoordinate(col: 2, row: 0),
        ),
        lessThan(2),
      );
    });

    test('MoveUnitCommand ignores units controlled by another player', () {
      final map = _map(3, 3);
      final reducer = GameStateReducer(mapData: map);
      final otherCommander = GameUnit.startingCommander(
        ownerPlayerId: 'player_2',
        col: 0,
        row: 0,
      );
      final state = _withFog(
        GameState(
          units: [otherCommander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
        map,
      );

      final transition = _dispatch(
        reducer,
        state,
        MoveUnitCommand(otherCommander.id, 1, 0),
      );

      expect(transition.state, state);
    });

    test(
      'MoveUnitCommand can use actor context without switching active player',
      () {
        final map = _map(3, 3);
        final reducer = GameStateReducer(mapData: map);
        final playerTwoCommander = GameUnit.startingCommander(
          ownerPlayerId: 'player_2',
          col: 0,
          row: 0,
        );
        final state = GameState(
          units: [playerTwoCommander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        );

        final transition = _dispatch(
          reducer,
          state,
          MoveUnitCommand(playerTwoCommander.id, 1, 0),
        );
        expect(transition.state.units.single.col, 0);

        final contextualTransition = reducer.reduce(
          state,
          MoveUnitCommand(playerTwoCommander.id, 1, 0),
          context: const GameCommandContext(actorPlayerId: 'player_2'),
        );

        expect(contextualTransition.state.activePlayerId, 'player_1');
        expect(contextualTransition.state.units.single.col, 1);
      },
    );

    test('StartBuildingCommand can use actor context in the shared turn', () {
      final map = _map(3, 3);
      final reducer = GameStateReducer(mapData: map);
      final city = _city(ownerPlayerId: 'player_2');
      final state = GameState(
        cities: [city],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      );

      final rejected = reducer.reduce(
        state,
        StartBuildingCommand(city.id, CityBuildingType.granary),
      );
      expect(rejected.state.cities.single.productionQueue, isNull);

      final accepted = reducer.reduce(
        state,
        StartBuildingCommand(city.id, CityBuildingType.granary),
        context: const GameCommandContext(actorPlayerId: 'player_2'),
      );

      expect(accepted.state.activePlayerId, 'player_1');
      expect(
        accepted.state.cities.single.productionQueue?.target,
        const BuildingProductionTarget(CityBuildingType.granary),
      );
    });

    test('active player cannot inspect tiles hidden by fog of war', () {
      final map = _map(6, 6);
      final reducer = GameStateReducer(mapData: map);
      // Commander at (0,0) — fog prevents seeing (5,5) without visibility
      var state = GameState(
        units: [_commander()],
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      );
      // SetActivePlayer to refresh fog context
      state = _dispatch(
        reducer,
        state,
        const SetActivePlayerCommand('player_1', canAct: true),
      ).state;

      state = _dispatch(reducer, state, const TileTappedCommand(5, 5)).state;

      // Hidden tile does not update selection
      expect(state.selection, isNull);
    });

    test(
      'move preview cannot path through hidden fog beyond scouting range',
      () {
        final map = _map(6, 6);
        final reducer = GameStateReducer(mapData: map);
        var state = _withFog(
          GameState(
            units: [_commander()],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
          ),
          map,
        );

        state = _dispatch(reducer, state, const TileTappedCommand(0, 0)).state;
        state = _dispatch(reducer, state, const TileTappedCommand(5, 5)).state;

        expect(state.movePreview, isNull);
        expect(state.units.single.col, 0);
        expect(state.units.single.row, 0);
      },
    );

    test('move preview can path up to three hexes into hidden fog', () {
      final map = _map(5, 1);
      final reducer = GameStateReducer(mapData: map);
      var state = _withFog(
        GameState(
          units: [_commander()],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
        map,
      );

      expect(
        state.activePlayerVisibility.visibilityForHex(
          const HexCoordinate(col: 3, row: 0),
        ),
        FogVisibility.hidden,
      );

      state = _dispatch(reducer, state, const TileTappedCommand(0, 0)).state;
      state = _dispatch(reducer, state, const TileTappedCommand(3, 0)).state;

      expect(state.movePreview, isNotNull);
      expect(state.movePreview?.targetCol, 3);
      expect(state.movePreview?.targetRow, 0);
      expect(state.movePreview?.totalCost, 3);
      expect(state.units.single.col, 0);
      expect(state.units.single.row, 0);

      final confirmTransition = _dispatch(
        reducer,
        state,
        const TileTappedCommand(3, 0),
      );
      state = confirmTransition.state;

      expect(state.units.single.col, 3);
      expect(state.units.single.row, 0);
    });

    test('move preview can path through discovered fog', () {
      final map = _map(6, 1);
      final reducer = GameStateReducer(mapData: map);
      var state = _withRememberedFog(
        GameState(
          units: [_commander()],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
        map,
        const [HexCoordinate(col: 3, row: 0), HexCoordinate(col: 4, row: 0)],
      );

      state = _dispatch(reducer, state, const TileTappedCommand(0, 0)).state;
      state = _dispatch(reducer, state, const TileTappedCommand(4, 0)).state;

      expect(state.movePreview, isNotNull);
      expect(state.movePreview?.targetCol, 4);
      expect(state.movePreview?.targetRow, 0);
      expect(state.movePreview?.canMoveNow, isTrue);
    });

    test(
      'confirming a red preview moves along the planned route this turn',
      () {
        final map = _map(7, 1);
        final reducer = GameStateReducer(mapData: map);
        var state = _withRememberedFog(
          GameState(
            units: [_commander()],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
          ),
          map,
          const [
            HexCoordinate(col: 3, row: 0),
            HexCoordinate(col: 4, row: 0),
            HexCoordinate(col: 5, row: 0),
            HexCoordinate(col: 6, row: 0),
          ],
        );

        state = _dispatch(reducer, state, const TileTappedCommand(0, 0)).state;
        state = _dispatch(reducer, state, const TileTappedCommand(6, 0)).state;

        expect(state.movePreview?.targetCol, 6);
        expect(state.movePreview?.canMoveNow, isFalse);
        expect(state.movePreview?.totalCost, 6);

        final confirmTransition = _dispatch(
          reducer,
          state,
          const TileTappedCommand(6, 0),
        );
        state = confirmTransition.state;

        expect(state.movePreview, isNull);
        expect(
          state.moveCommandActive,
          isFalse,
          reason: 'queueing a route should exit move targeting',
        );
        expect(state.units.single.col, 5);
        expect(state.units.single.row, 0);
        expect(state.units.single.movementPoints, 0);
        expect(state.units.single.queuedPath?.targetCol, 6);
      },
    );

    test('city tap cycles: city -> unit -> tile -> city', () {
      final map = _map(5, 5);
      final reducer = GameStateReducer(mapData: map);
      final commander = _commander(col: 1, row: 1);
      final city = _city(col: 1, row: 1);
      var state = _withFog(
        GameState(
          units: [commander],
          cities: [city],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
        map,
      );

      // 1st tap city: city selected
      state = _dispatch(reducer, state, CityTappedCommand(city.id)).state;
      expect(state.selection?.type, GameSelectionType.city);

      // 2nd tap city: unit selected
      state = _dispatch(reducer, state, CityTappedCommand(city.id)).state;
      expect(state.selection?.type, GameSelectionType.unit);

      // 3rd tap city: tile selected
      state = _dispatch(reducer, state, CityTappedCommand(city.id)).state;
      expect(state.selection?.type, GameSelectionType.tile);

      // 4th tap city: city selected again
      state = _dispatch(reducer, state, CityTappedCommand(city.id)).state;
      expect(state.selection?.type, GameSelectionType.city);
    });

    test('enemy city known from discovered fog is selected as a tile', () {
      final map = _map(8, 8);
      final reducer = GameStateReducer(mapData: map);
      final rememberedEnemyCity = _city(
        ownerPlayerId: 'player_2',
        col: 5,
        row: 5,
      );
      final hiddenEnemyCity = _city(ownerPlayerId: 'player_3', col: 6, row: 6);
      var state = _withRememberedFog(
        GameState(
          units: [_commander()],
          cities: [rememberedEnemyCity, hiddenEnemyCity],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
        map,
        const [HexCoordinate(col: 5, row: 5)],
      );

      expect(state.citiesKnownToActivePlayer, contains(rememberedEnemyCity));
      expect(state.citiesKnownToActivePlayer, isNot(contains(hiddenEnemyCity)));

      state = _dispatch(
        reducer,
        state,
        CityTappedCommand(rememberedEnemyCity.id),
      ).state;

      expect(state.selection?.type, GameSelectionType.tile);
      expect(state.selection?.city, isNull);
      expect(state.selection?.tile?.col, rememberedEnemyCity.center.col);
      expect(state.selection?.tile?.row, rememberedEnemyCity.center.row);
    });

    test('active player selects own city but not opponent city', () {
      final map = _map(4, 4);
      final reducer = GameStateReducer(mapData: map);
      final playerCity = _city(ownerPlayerId: 'player_1', col: 1, row: 1);
      final opponentCity = _city(ownerPlayerId: 'player_2', col: 2, row: 1);
      var state = _withFog(
        GameState(
          cities: [playerCity, opponentCity],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
        map,
      );

      state = _dispatch(
        reducer,
        state,
        CityTappedCommand(opponentCity.id),
      ).state;

      expect(state.selection?.type, GameSelectionType.tile);
      expect(state.selection?.city, isNull);
      expect(state.selection?.tile?.col, opponentCity.center.col);
      expect(state.selection?.tile?.row, opponentCity.center.row);

      state = _dispatch(reducer, state, CityTappedCommand(playerCity.id)).state;

      expect(state.selection?.type, GameSelectionType.city);
      expect(state.selection?.city, playerCity);
    });

    test('SetActivePlayerCommand clears selection and move state', () {
      final map = _map(3, 3);
      final reducer = GameStateReducer(mapData: map);
      final commander = _commander();
      var state = _withFog(
        GameState(
          units: [commander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          moveCommandActive: true,
        ),
        map,
      );
      // Select unit
      state = state.copyWith(selection: GameSelection.unit(commander));

      // Switch to player_2 — commander owned by player_1 should be deselected
      state = _dispatch(
        reducer,
        state,
        const SetActivePlayerCommand('player_2', canAct: true),
      ).state;

      expect(state.activePlayerId, 'player_2');
      expect(state.moveCommandActive, isFalse);
      expect(state.selection, isNull);
    });

    test(
      'FocusNextPendingActionCommand emits JumpCameraEffect to unit position',
      () {
        final map = _map(5, 5);
        final reducer = GameStateReducer(mapData: map);
        final commander = _commander(col: 3, row: 4);
        final state = _withFog(
          GameState(
            units: [commander],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
          ),
          map,
        );

        final transition = _dispatch(
          reducer,
          state,
          const FocusNextPendingActionCommand('player_1'),
        );

        expect(transition.state.selection?.unit?.id, commander.id);
        final jump = transition.uiEffects.whereType<JumpCameraEffect>().single;
        expect(jump.col, 3);
        expect(jump.row, 4);
      },
    );
  });
}
