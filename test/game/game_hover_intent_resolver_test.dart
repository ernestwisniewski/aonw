import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/game_hover_intent_resolver.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/hover_intent_marker.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameHoverIntentResolver', () {
    test('marks impassable move targets as blocked', () {
      final map = _map(blockedHex: const CityHex(col: 1, row: 1));
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final state = GameState(
        units: [commander],
        selection: GameSelection.unit(commander, tile: _tile(map, 0, 0)),
        moveCommandActive: true,
      );

      final intent = _resolver(state, map).resolve(_tile(map, 1, 1));

      expect(intent?.kind, HoverIntentKind.move);
      expect(intent?.blocked, isTrue);
      expect(intent?.color, HudPalette.danger);
    });

    test('marks targets beyond unit movement capacity as blocked', () {
      final map = _map(
        cols: 2,
        rows: 1,
        terrainOverrides: {
          (col: 1, row: 0): const [
            TerrainType.grassland,
            TerrainType.forest,
            TerrainType.jungle,
            TerrainType.hills,
          ],
        },
      );
      final scout = GameUnit.produced(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        col: 0,
        row: 0,
      );
      final cavalry = GameUnit.produced(
        id: 'cavalry_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.cavalry,
        col: 0,
        row: 0,
      );
      final scoutState = GameState(
        units: [scout],
        selection: GameSelection.unit(scout, tile: _tile(map, 0, 0)),
        moveCommandActive: true,
      );
      final cavalryState = GameState(
        units: [cavalry],
        selection: GameSelection.unit(cavalry, tile: _tile(map, 0, 0)),
        moveCommandActive: true,
      );

      final scoutIntent = _resolver(scoutState, map).resolve(_tile(map, 1, 0));
      final cavalryIntent = _resolver(
        cavalryState,
        map,
      ).resolve(_tile(map, 1, 0));

      expect(scoutIntent?.kind, HoverIntentKind.move);
      expect(scoutIntent?.blocked, isTrue);
      expect(scoutIntent?.color, HudPalette.danger);
      expect(cavalryIntent?.blocked, isFalse);
      expect(cavalryIntent?.color, HudPalette.gold);
    });

    test('does not block artifact carrier hover into own rough city', () {
      final map = _map(
        cols: 2,
        rows: 1,
        terrainOverrides: {
          (col: 1, row: 0): const [
            TerrainType.grassland,
            TerrainType.forest,
            TerrainType.hills,
          ],
        },
      );
      final carrier = GameUnit.produced(
        id: 'carrier_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        col: 0,
        row: 0,
      ).copyWith(movementPoints: 2).copyWithCarriedArtifact('artifact_1');
      final state = GameState(
        units: [carrier],
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'City',
            center: CityHex(col: 1, row: 0),
          ),
        ],
        selection: GameSelection.unit(carrier, tile: _tile(map, 0, 0)),
        moveCommandActive: true,
      );

      final intent = _resolver(state, map).resolve(_tile(map, 1, 0));

      expect(intent?.kind, HoverIntentKind.move);
      expect(intent?.blocked, isFalse);
      expect(intent?.color, HudPalette.gold);
    });

    test('uses founding player color and reduce-motion preference', () {
      final map = _map();
      final state = GameState(
        playerColors: {'player_1': 0xFF123456},
        cityFoundingDraft: CityFoundingDraft(
          unitId: 'settler_1',
          ownerPlayerId: 'player_1',
          center: const CityHex(col: 0, row: 0),
        ),
      );

      final intent = _resolver(
        state,
        map,
        reduceMotion: true,
      ).resolve(_tile(map, 2, 1));

      expect(intent?.kind, HoverIntentKind.founding);
      expect(intent?.color.toARGB32(), 0xFF123456);
      expect(intent?.reduceMotion, isTrue);
    });

    test('keeps inspect hover active only during long-press inspection', () {
      final resolver = _resolver(const GameState(), _map());

      expect(
        resolver.isStale(HoverIntentKind.inspect, longPressInspectActive: true),
        isFalse,
      );
      expect(
        resolver.isStale(
          HoverIntentKind.inspect,
          longPressInspectActive: false,
        ),
        isTrue,
      );
    });
  });
}

GameHoverIntentResolver _resolver(
  GameState state,
  MapData map, {
  bool reduceMotion = false,
}) {
  return GameHoverIntentResolver(
    state: state,
    mapData: map,
    reduceMotion: reduceMotion,
    colorForPlayer: (playerId) => state.colorForPlayer(playerId) ?? 0xFF000000,
  );
}

MapData _map({
  CityHex? blockedHex,
  int cols = 3,
  int rows = 3,
  Map<({int col, int row}), List<TerrainType>> terrainOverrides = const {},
}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains:
                terrainOverrides[(col: col, row: row)] ??
                (blockedHex?.col == col && blockedHex?.row == row
                    ? const [TerrainType.grassland, TerrainType.mountain]
                    : const [TerrainType.grassland]),
            resources: const [],
            height: 0,
          ),
    ],
  );
}

TileData _tile(MapData map, int col, int row) {
  return map.tiles.firstWhere((tile) => tile.col == col && tile.row == row);
}
