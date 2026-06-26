import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/overlays/threat_overlay.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/overlays/threat_overlay_layer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThreatOverlayLayer', () {
    test('highlights visible enemy attack range for selected own unit', () {
      final map = _map(3, 3);
      final selected = _unit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        col: 0,
        row: 1,
      );
      final enemy = _unit(
        id: 'warrior_2',
        ownerPlayerId: 'player_2',
        col: 1,
        row: 1,
      );
      final layer = ThreatOverlayLayer()
        ..sync(
          parent: Component(),
          state: GameState(
            units: [selected, enemy],
            selection: GameSelection.unit(selected, tile: _tile(map, 0, 1)),
          ),
          mapData: map,
        );

      final hexes = layer.overlayHexesForTesting;
      expect(hexes, isNotEmpty);
      expect(
        hexes.map((hex) => hex.hex),
        contains(const CityHex(col: 0, row: 1)),
      );
      expect(
        hexes.singleWhere((hex) => hex.hex == const CityHex(col: 0, row: 1)),
        isA<ThreatOverlayHex>()
            .having((hex) => hex.selectedUnitTile, 'selectedUnitTile', isTrue)
            .having((hex) => hex.threatCount, 'threatCount', 1),
      );
    });

    test('ignores hidden enemies and non-attacking units', () {
      final map = _map(3, 3);
      final selected = _unit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        col: 0,
        row: 1,
      );
      final hiddenEnemy = _unit(
        id: 'warrior_2',
        ownerPlayerId: 'player_2',
        col: 1,
        row: 1,
      );
      final worker = _unit(
        id: 'worker_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.worker,
        col: 0,
        row: 0,
      );
      final fog = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 0, row: 1),
            },
          ),
        },
      );
      final layer = ThreatOverlayLayer()
        ..sync(
          parent: Component(),
          state: GameState(
            activePlayerId: 'player_1',
            units: [selected, hiddenEnemy, worker],
            fogOfWar: fog,
            selection: GameSelection.unit(selected, tile: _tile(map, 0, 1)),
          ),
          mapData: map,
        );

      expect(layer.overlayHexesForTesting, isEmpty);
    });

    test('clears previous threat overlay when selection is removed', () {
      final map = _map(3, 3);
      final selected = _unit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        col: 0,
        row: 1,
      );
      final enemy = _unit(
        id: 'warrior_2',
        ownerPlayerId: 'player_2',
        col: 1,
        row: 1,
      );
      final layer = ThreatOverlayLayer()
        ..sync(
          parent: Component(),
          state: GameState(
            units: [selected, enemy],
            selection: GameSelection.unit(selected, tile: _tile(map, 0, 1)),
          ),
          mapData: map,
        );

      expect(layer.overlayHexesForTesting, isNotEmpty);

      layer.sync(
        parent: Component(),
        state: GameState(units: [selected, enemy]),
        mapData: map,
      );

      expect(layer.overlayHexesForTesting, isEmpty);
    });

    test('uses two threat levels and caps alpha while dimmed', () {
      const low = ThreatOverlayHex(
        hex: CityHex(col: 0, row: 0),
        threatCount: 2,
      );
      const high = ThreatOverlayHex(
        hex: CityHex(col: 1, row: 0),
        threatCount: 3,
      );
      final overlay = ThreatOverlay(hexes: const [low, high], dimmed: true);

      expect(overlay.dimmedForTesting, isTrue);
      expect(overlay.fillAlphaForTesting(low), MapAlpha.faint);
      expect(overlay.fillAlphaForTesting(high), MapAlpha.faint);
      expect(overlay.strokeAlphaForTesting(high), MapAlpha.faint);
      expect(overlay.strokeWidthForTesting(low), MapStroke.thin);
      expect(overlay.strokeWidthForTesting(high), MapStroke.regular);
    });
  });
}

MapData _map(int cols, int rows) => MapData(
  cols: cols,
  rows: rows,
  tiles: [
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

TileData _tile(MapData map, int col, int row) =>
    map.tiles.firstWhere((tile) => tile.col == col && tile.row == row);

GameUnit _unit({
  required String id,
  required String ownerPlayerId,
  required int col,
  required int row,
  GameUnitType type = GameUnitType.warrior,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: row,
  );
}
