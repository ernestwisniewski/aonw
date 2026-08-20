import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/game_hover_intent_resolver.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/hover_intent_marker.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameHoverIntentResolver', () {
    test('marks impassable move targets as blocked', () {
      final map = _map(blockedHex: const CityHex(col: 1, row: 1));
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final state = GameClientState(
        units: [commander],
        interaction: InteractionState(
          selection: GameSelection.unit(commander, tile: _tile(map, 0, 0)),
          moveCommandActive: true,
        ),
      );

      final intents = _moveIntents(state, map, col: 1, row: 1);

      for (final intent in intents) {
        expect(intent?.kind, HoverIntentKind.move);
        expect(intent?.blocked, isTrue);
        expect(intent?.color, HudPalette.danger);
      }
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
      final scoutState = GameClientState(
        units: [scout],
        interaction: InteractionState(
          selection: GameSelection.unit(scout, tile: _tile(map, 0, 0)),
          moveCommandActive: true,
        ),
      );
      final cavalryState = GameClientState(
        units: [cavalry],
        interaction: InteractionState(
          selection: GameSelection.unit(cavalry, tile: _tile(map, 0, 0)),
          moveCommandActive: true,
        ),
      );

      final scoutIntents = _moveIntents(scoutState, map, col: 1, row: 0);
      final cavalryIntents = _moveIntents(cavalryState, map, col: 1, row: 0);

      for (final intent in scoutIntents) {
        expect(intent?.kind, HoverIntentKind.move);
        expect(intent?.blocked, isTrue);
        expect(intent?.color, HudPalette.danger);
      }
      for (final intent in cavalryIntents) {
        expect(intent?.kind, HoverIntentKind.move);
        expect(intent?.blocked, isFalse);
        expect(intent?.color, HudPalette.roadMarking);
      }
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
      final state = GameClientState(
        units: [carrier],
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'City',
            center: CityHex(col: 1, row: 0),
          ),
        ],
        interaction: InteractionState(
          selection: GameSelection.unit(carrier, tile: _tile(map, 0, 0)),
          moveCommandActive: true,
        ),
      );

      final intents = _moveIntents(state, map, col: 1, row: 0);

      for (final intent in intents) {
        expect(intent?.kind, HoverIntentKind.move);
        expect(intent?.blocked, isFalse);
        expect(intent?.color, HudPalette.roadMarking);
      }
    });

    test('hidden unit does not alter a movement hover marker', () {
      final map = _map(cols: 3, rows: 1);
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final enemy = GameUnit.startingWarrior(
        ownerPlayerId: 'player_2',
        col: 1,
        row: 0,
      );
      final state = GameClientState(
        activePlayerId: 'player_1',
        units: [commander, enemy],
        fogOfWar: _movementFog(),
        interaction: InteractionState(
          selection: GameSelection.unit(commander, tile: _tile(map, 0, 0)),
          moveCommandActive: true,
        ),
      );

      final intents = _moveIntents(state, map, col: 2, row: 0);

      for (final intent in intents) {
        expect(intent?.kind, HoverIntentKind.move);
        expect(intent?.blocked, isFalse);
        expect(intent?.color, HudPalette.roadMarking);
      }
    });

    test('hidden foreign city does not alter a movement hover marker', () {
      final map = _map(cols: 3, rows: 1);
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      const city = GameCity(
        id: 'hidden_city',
        ownerPlayerId: 'player_2',
        name: 'Hidden city',
        center: CityHex(col: 1, row: 0),
      );
      final state = GameClientState(
        activePlayerId: 'player_1',
        units: [commander],
        cities: const [city],
        fogOfWar: _movementFog(),
        interaction: InteractionState(
          selection: GameSelection.unit(commander, tile: _tile(map, 0, 0)),
          moveCommandActive: true,
        ),
      );

      final intents = _moveIntents(state, map, col: 2, row: 0);

      for (final intent in intents) {
        expect(intent?.kind, HoverIntentKind.move);
        expect(intent?.blocked, isFalse);
        expect(intent?.color, HudPalette.roadMarking);
      }
    });

    test('missing actor fog entry does not limit movement hover distance', () {
      final map = _map(cols: 5, rows: 1);
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final state = GameClientState(
        activePlayerId: 'player_1',
        units: [commander],
        interaction: InteractionState(
          selection: GameSelection.unit(commander, tile: _tile(map, 0, 0)),
          moveCommandActive: true,
        ),
      );

      final intents = _moveIntents(state, map, col: 4, row: 0);

      for (final intent in intents) {
        expect(intent?.kind, HoverIntentKind.move);
        expect(intent?.blocked, isFalse);
        expect(intent?.color, HudPalette.roadMarking);
      }
    });

    test('uses founding player color and reduce-motion preference', () {
      final map = _map();
      final state = GameClientState(
        playerColors: {'player_1': 0xFF123456},
        interaction: InteractionState(
          cityFoundingDraft: CityFoundingDraft(
            unitId: 'settler_1',
            ownerPlayerId: 'player_1',
            center: const CityHex(col: 0, row: 0),
          ),
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
      final resolver = _resolver(GameClientState(), _map());

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

FogOfWarState _movementFog() {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        visibleHexes: {const HexCoordinate(col: 0, row: 0)},
      ),
    },
  );
}

GameHoverIntentResolver _resolver(
  GameClientState state,
  MapTraversalView mapView, {
  bool reduceMotion = false,
}) {
  return GameHoverIntentResolver(
    state: state,
    mapView: mapView,
    reduceMotion: reduceMotion,
    colorForPlayer: (playerId) => state.colorForPlayer(playerId) ?? 0xFF000000,
  );
}

List<HoverIntentMarkerSpec?> _moveIntents(
  GameClientState state,
  WorldMap legacyMap, {
  required int col,
  required int row,
}) {
  final canonicalView = WorldMap.fromTileViews(
    cols: legacyMap.cols,
    rows: legacyMap.rows,
    tiles: legacyMap.tiles,
  );
  return [
    _resolver(state, legacyMap).resolve(legacyMap.tileAt(col, row)!),
    _resolver(state, canonicalView).resolve(canonicalView.tileAt(col, row)!),
  ];
}

WorldMap _map({
  CityHex? blockedHex,
  int cols = 3,
  int rows = 3,
  Map<({int col, int row}), List<TerrainType>> terrainOverrides = const {},
}) {
  return WorldMap(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          WorldTile(
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

WorldTile _tile(WorldMap map, int col, int row) {
  return map.tiles.firstWhere((tile) => tile.col == col && tile.row == row);
}
