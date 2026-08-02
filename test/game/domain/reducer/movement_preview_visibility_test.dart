import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/movement/movement_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MovementReducer preview visibility', () {
    test('hidden target unit does not alter the movement preview', () {
      final mapData = _map(5, 5);
      final commander = _commander();
      final enemy = GameUnit.startingWarrior(
        ownerPlayerId: 'player_2',
        col: 1,
        row: 0,
      );
      final currentHex = HexCoordinate(col: commander.col, row: commander.row);
      final state = GameClientState(
        units: [commander, enemy],
        activePlayerId: 'player_1',
        fogOfWar: _fog(discovered: {currentHex}, visible: {currentHex}),
        interaction: InteractionState(
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        ),
      );

      final baseline = MovementReducer.handleMoveTargetTile(
        state.copyWith(units: [commander]),
        mapData.tileAt(1, 0)!,
        mapData,
      );
      final result = MovementReducer.handleMoveTargetTile(
        state,
        mapData.tileAt(1, 0)!,
        mapData,
      );

      expect(result.uiEffects, isEmpty);
      expect(result.state.movePreview, isNotNull);
      expect(result.state.movePreview?.path, baseline.state.movePreview?.path);
    });

    test('hidden intermediate unit does not alter the movement preview', () {
      final lineMap = _map(3, 1);
      final commander = _commander();
      final enemy = GameUnit.startingWarrior(
        ownerPlayerId: 'player_2',
        col: 1,
        row: 0,
      );
      final currentHex = HexCoordinate(col: commander.col, row: commander.row);
      final state = GameClientState(
        units: [commander, enemy],
        activePlayerId: 'player_1',
        fogOfWar: _fog(discovered: {currentHex}, visible: {currentHex}),
        interaction: InteractionState(
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        ),
      );

      final baseline = MovementReducer.handleMoveTargetTile(
        state.copyWith(units: [commander]),
        lineMap.tileAt(2, 0)!,
        lineMap,
      );
      final result = MovementReducer.handleMoveTargetTile(
        state,
        lineMap.tileAt(2, 0)!,
        lineMap,
      );

      expect(result.uiEffects, isEmpty);
      expect(result.state.movePreview, isNotNull);
      expect(result.state.movePreview?.path, baseline.state.movePreview?.path);
    });

    test('missing actor fog entry does not limit preview distance', () {
      final lineMap = _map(6, 1);
      final commander = _commander();
      final state = GameClientState(
        units: [commander],
        activePlayerId: 'player_1',
        interaction: InteractionState(
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        ),
      );

      final result = MovementReducer.handleMoveTargetTile(
        state,
        lineMap.tileAt(5, 0)!,
        lineMap,
      );

      expect(result.uiEffects, isEmpty);
      expect(result.state.movePreview?.targetCol, 5);
    });

    test('terrain memory does not reveal a hidden foreign city', () {
      final mapData = _map(5, 5);
      final commander = _commander();
      const city = GameCity(
        id: 'hidden_enemy_city',
        ownerPlayerId: 'player_2',
        name: 'Hidden enemy city',
        center: CityHex(col: 1, row: 0),
      );
      final state = GameClientState(
        units: [commander],
        cities: const [city],
        activePlayerId: 'player_1',
        fogOfWar: _fog(
          discovered: {
            const HexCoordinate(col: 0, row: 0),
            const HexCoordinate(col: 1, row: 0),
          },
          visible: {const HexCoordinate(col: 0, row: 0)},
        ),
        interaction: InteractionState(
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        ),
      );

      final result = MovementReducer.handleMoveTargetTile(
        state,
        mapData.tileAt(1, 0)!,
        mapData,
      );

      expect(result.uiEffects, isEmpty);
      expect(result.state.movePreview?.targetCol, 1);
    });

    test('known intermediate foreign city blocks preview routing', () {
      final lineMap = _map(3, 1);
      final commander = _commander();
      const city = GameCity(
        id: 'intermediate_enemy_city',
        ownerPlayerId: 'player_2',
        name: 'Intermediate enemy city',
        center: CityHex(col: 1, row: 0),
      );
      final state = GameClientState(
        units: [commander],
        cities: const [city],
        activePlayerId: 'player_1',
        interaction: InteractionState(
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        ),
      );

      final result = MovementReducer.handleMoveTargetTile(
        state,
        lineMap.tileAt(2, 0)!,
        lineMap,
      );

      expect(result.state.movePreview, isNull);
      expect(
        result.uiEffects.whereType<ShowHudFeedbackEffect>().single.reason,
        HudFeedbackReason.movementNoRoute,
      );
    });
  });
}

WorldMap _map(int cols, int rows) => WorldMap(
  cols: cols,
  rows: rows,
  tiles: [
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

GameUnit _commander() => GameUnit.startingCommander(ownerPlayerId: 'player_1');

FogOfWarState _fog({
  Set<HexCoordinate> discovered = const {},
  Set<HexCoordinate> visible = const {},
}) {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        discoveredHexes: discovered,
        visibleHexes: visible,
      ),
    },
  );
}
