import 'dart:math' as math;

import 'package:aonw/game/presentation/engine/rendering_layers/effects/cloud_drift_layer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CloudDriftLayer', () {
    test('spawns a drifting cloud group that crosses the map', () {
      final layer = _layer(initialDelaySeconds: 0)
        ..sync(
          parent: Component(),
          mapData: _map(cols: 8, rows: 5),
          visibility: _visibility(
            discovered: {const HexCoordinate(col: 0, row: 0)},
          ),
        )
        ..update(0.01);

      expect(layer.activeCloudCountForTesting, inInclusiveRange(1, 3));
      expect(layer.activePuffCountForTesting, inInclusiveRange(8, 11));
      expect(layer.activeCloudWidthForTesting, greaterThan(200));
      expect(
        layer.activeCloudTravelDistanceForTesting,
        greaterThan(layer.mapWidthForTesting),
      );

      layer.update(2.0);

      expect(layer.activeCloudCountForTesting, 0);
      expect(layer.spawnCountdownForTesting, closeTo(1, 0.001));

      layer.update(0.99);

      expect(layer.activeCloudCountForTesting, 0);

      layer.update(0.02);

      expect(layer.activeCloudCountForTesting, 1);
    });

    test('occasionally spawns a restrained cloud cluster', () {
      final layer =
          CloudDriftLayer(
              random: _LowRandom(),
              initialDelaySeconds: 0,
              spawnGapSeconds: const (min: 1, max: 1),
              durationSeconds: const (min: 2, max: 2),
            )
            ..sync(
              parent: Component(),
              mapData: _map(cols: 8, rows: 5),
              visibility: _visibility(
                discovered: {const HexCoordinate(col: 0, row: 0)},
              ),
            )
            ..update(0.01);

      expect(layer.activeCloudCountForTesting, 3);
      expect(layer.activePuffCountForTesting, inInclusiveRange(8, 11));
    });

    test('reduce motion clears and suppresses cloudlets', () {
      final layer = _layer(initialDelaySeconds: 0)
        ..sync(
          parent: Component(),
          mapData: _map(),
          visibility: _visibility(
            discovered: {const HexCoordinate(col: 0, row: 0)},
          ),
        )
        ..update(0.01);

      expect(layer.activeCloudCountForTesting, 1);

      layer.reduceMotion = true;

      expect(layer.activeCloudCountForTesting, 0);

      layer.update(120);

      expect(layer.activeCloudCountForTesting, 0);
    });

    test('spawns only on known fog', () {
      final layer = _layer(initialDelaySeconds: 0)..update(10);

      expect(layer.activeCloudCountForTesting, 0);

      final visibleLayer = _layer(initialDelaySeconds: 0)
        ..sync(
          parent: Component(),
          mapData: _map(),
          visibility: _visibility(
            visible: {const HexCoordinate(col: 0, row: 0)},
            discovered: {const HexCoordinate(col: 1, row: 0)},
          ),
        )
        ..update(10);

      expect(visibleLayer.hasDiscoveredClipForTesting, isTrue);
      expect(visibleLayer.activeCloudCountForTesting, 1);

      final onlyVisibleLayer = _layer(initialDelaySeconds: 0)
        ..sync(
          parent: Component(),
          mapData: _map(),
          visibility: _visibility(
            visible: {const HexCoordinate(col: 0, row: 0)},
          ),
        )
        ..update(10);

      expect(onlyVisibleLayer.hasDiscoveredClipForTesting, isTrue);
      expect(onlyVisibleLayer.activeCloudCountForTesting, 1);

      final hiddenLayer = _layer(initialDelaySeconds: 0)
        ..sync(parent: Component(), mapData: _map(), visibility: _visibility())
        ..update(10);

      expect(hiddenLayer.hasDiscoveredClipForTesting, isFalse);
      expect(hiddenLayer.activeCloudCountForTesting, 0);
    });

    test('renders above city overlays without taking input', () {
      final mapData = _map(cols: 2, rows: 6);
      final parent = Component();
      final layer = _layer(initialDelaySeconds: 0)
        ..sync(
          parent: parent,
          mapData: mapData,
          visibility: _visibility(
            discovered: {const HexCoordinate(col: 1, row: 5)},
          ),
        );

      expect(layer.priority, greaterThan(MapPriority.cityManagementOverlay));
      expect(
        layer.priority,
        greaterThan(MapPriority.perTile(MapPriority.city, col: 1, row: 5)),
      );
      expect(
        layer.priority,
        greaterThan(MapPriority.perTileUnit(mapRows: 6, col: 1, row: 5)),
      );
      expect(layer.attachedOwner, same(parent));
      expect(layer.containsLocalPoint(Vector2.zero()), isFalse);
    });
  });
}

class _LowRandom implements math.Random {
  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}

CloudDriftLayer _layer({required double initialDelaySeconds}) {
  return CloudDriftLayer(
    random: math.Random(7),
    initialDelaySeconds: initialDelaySeconds,
    spawnGapSeconds: const (min: 1, max: 1),
    durationSeconds: const (min: 2, max: 2),
  );
}

MapData _map({int cols = 2, int rows = 1}) {
  return MapData(
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
}

FogVisibilityQuery _visibility({
  Set<HexCoordinate> visible = const {},
  Set<HexCoordinate> discovered = const {},
}) {
  const playerId = 'player_1';
  return FogVisibilityQuery(
    playerId: playerId,
    state: FogOfWarState(
      players: {
        playerId: PlayerFogOfWar(
          playerId: playerId,
          visibleHexes: visible,
          discoveredHexes: discovered,
        ),
      },
    ),
  );
}
