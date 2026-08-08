import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/turn/turn_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'focuses a unit and builds production bubbles from canonical lookup',
    () {
      final unit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 1,
        row: 1,
      );
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: const CityHex(col: 2, row: 2),
        controlledHexes: const [CityHex(col: 1, row: 2)],
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );
      final state = GameClientState(
        activePlayerId: 'player_1',
        units: [unit],
        cities: [city],
        research: _activeResearch(),
      );
      final MapTileLookup mapTiles = _worldMap();

      expect(
        TurnReducer.pendingTurnActionCount(state, 'player_1', mapTiles),
        1,
      );
      final result = TurnReducer.focusTurnStartAction(
        state,
        'player_1',
        mapTiles,
      );

      expect(result.state.selection?.unit, same(unit));
      expect(result.state.selection?.tile?.col, 1);
      expect(result.state.selection?.tile?.row, 1);
      expect(result.uiEffects.whereType<JumpCameraEffect>(), hasLength(1));
      final focus = result.uiEffects
          .whereType<ShowActionTargetFocusEffect>()
          .single;
      expect(focus.col, 1);
      expect(focus.row, 1);
      expect(
        result.uiEffects.whereType<ShowCityProductionBubbleEffect>(),
        hasLength(1),
      );
      expect(
        TurnReducer.currentPendingTurnActionIndex(
          result.state,
          'player_1',
          mapTiles,
        ),
        0,
      );
    },
  );

  test('focuses and projects a city through canonical lookup', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 2, row: 2),
      controlledHexes: [CityHex(col: 1, row: 2)],
    );
    final state = GameClientState(
      activePlayerId: 'player_1',
      cities: const [city],
      research: _activeResearch(),
    );
    final MapTileLookup mapTiles = _worldMap();

    final targets = TurnReducer.pendingTurnActionTargets(
      state,
      'player_1',
      mapTiles,
    );
    final result = TurnReducer.focusNextPendingAction(
      state,
      'player_1',
      mapTiles,
    );

    expect(targets.single, isA<CityProductionTurnActionTarget>());
    expect(result.state.selection?.city, same(state.cities.single));
    expect(result.state.selection?.cityTileYieldBreakdown, isNotNull);
    expect(result.state.selection?.cityEconomy, isNotNull);
    expect(result.uiEffects.whereType<JumpCameraEffect>(), hasLength(1));
    final focus = result.uiEffects
        .whereType<ShowActionTargetFocusEffect>()
        .single;
    expect(focus.col, city.center.col);
    expect(focus.row, city.center.row);
  });
}

ResearchState _activeResearch() {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(
        activeTechnologyId: TechnologyId.agriculture,
      ),
    },
  );
}

WorldMap _worldMap() {
  return WorldMap(
    cols: 5,
    rows: 5,
    tiles: [
      for (var row = 0; row < 5; row += 1)
        for (var col = 0; col < 5; col += 1)
          WorldTile.at(
            coordinate: HexCoord(col: col, row: row),
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
