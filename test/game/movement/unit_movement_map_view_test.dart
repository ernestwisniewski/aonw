import 'package:aonw/game/domain/movement.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plans local movement through the canonical immutable map view', () {
    final mapView = _canonicalMapView(cols: 3, rows: 1);
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');

    final plan = UnitMovementPlanner(
      mapData: mapView,
      units: [commander],
    ).planMove(unit: commander, targetTile: mapView.tileAt(2, 0)!);

    expect(plan, isNotNull);
    expect(plan!.path, const [
      (col: 0, row: 0),
      (col: 1, row: 0),
      (col: 2, row: 0),
    ]);
    expect(plan.totalCost, 2);
  });

  test('validates queued movement through the canonical traversal view', () {
    final mapView = _canonicalMapView(cols: 3, rows: 1);
    final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1')
        .copyWithQueuedPath(
          QueuedMovePath(
            targetCol: 2,
            targetRow: 0,
            steps: const [
              UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
              UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
              UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
            ],
          ),
        );

    final validated = UnitMovementTurnRules.validateQueuedPath(
      unit: commander,
      mapData: mapView,
      allUnits: [commander],
    );

    expect(validated.queuedPath, same(commander.queuedPath));
  });

  test('checks fortified visibility through a canonical tile lookup', () {
    final mapView = _canonicalMapView(cols: 5, rows: 1);
    final warrior = GameUnit.startingWarrior(
      ownerPlayerId: 'player_1',
    ).copyWith(movementPoints: 0, posture: UnitPosture.fortified);
    final visibleEnemy = GameUnit.startingWarrior(
      ownerPlayerId: 'player_2',
      col: 2,
      row: 0,
    );

    final reset = UnitMovementTurnRules.resetForNewTurn(
      warrior,
      mapData: mapView,
      allUnits: [warrior, visibleEnemy],
    );

    expect(reset.posture, UnitPosture.active);
    expect(reset.movementPoints, greaterThan(0));
  });
}

MapTraversalView _canonicalMapView({required int cols, required int rows}) {
  return WorldMapReadView(
    WorldMap(
      cols: cols,
      rows: rows,
      tiles: [
        for (var row = 0; row < rows; row += 1)
          for (var col = 0; col < cols; col += 1)
            WorldTile(
              coordinate: HexCoord(col: col, row: row),
              terrains: const [TerrainType.plains],
              resources: const [],
              height: 0,
            ),
      ],
    ),
  );
}
