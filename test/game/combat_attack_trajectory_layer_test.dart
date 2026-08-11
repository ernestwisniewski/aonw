import 'package:aonw/game/presentation/engine/rendering_layers/effects/combat_attack_trajectory_layer.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CombatAttackTrajectoryLayer', () {
    test('tracks both attacking and attacked unit markers', () {
      final positions = <String, Vector2>{
        'attacker': Vector2(100, 62),
        'defender': Vector2(220, 124),
      };
      final layer =
          CombatAttackTrajectoryLayer(
            unitPositionFor: (id) => positions[id]?.clone(),
          )..show(
            parent: Component(),
            attackerUnitId: 'attacker',
            targetId: 'defender',
            fromCol: 0,
            fromRow: 0,
            toCol: 1,
            toRow: 1,
          );

      _expectEndpoints(layer, from: Vector2(100, 100), to: Vector2(220, 200));

      final stableRevision = layer.geometryRevisionForTesting(
        'attacker',
        'defender',
      );
      layer.update(0.1);
      expect(
        layer.geometryRevisionForTesting('attacker', 'defender'),
        stableRevision,
        reason: 'stationary endpoints must reuse the cached curve path',
      );

      positions
        ..['attacker'] = Vector2(130, 93)
        ..['defender'] = Vector2(250, 155);
      layer.update(0.105);

      _expectEndpoints(layer, from: Vector2(130, 150), to: Vector2(250, 250));
      expect(
        layer.dashProgressForTesting('attacker', 'defender'),
        closeTo(0.25, 0.0001),
      );
      expect(
        layer.geometryRevisionForTesting('attacker', 'defender'),
        greaterThan(stableRevision!),
      );
    });

    test('tracks a city target and keeps its last visible endpoint', () {
      final unitPositions = <String, Vector2>{'attacker': Vector2(80, 62)};
      final cityPositions = <String, Vector2>{'city': Vector2(320, 186)};
      final layer =
          CombatAttackTrajectoryLayer(
            unitPositionFor: (id) => unitPositions[id]?.clone(),
            cityPositionFor: (id) => cityPositions[id]?.clone(),
          )..show(
            parent: Component(),
            attackerUnitId: 'attacker',
            targetId: 'city',
            fromCol: 0,
            fromRow: 0,
            toCol: 2,
            toRow: 2,
          );

      _expectEndpoints(layer, from: Vector2(80, 100), to: Vector2(320, 300));

      unitPositions['attacker'] = Vector2(110, 77.5);
      cityPositions['city'] = Vector2(350, 217);
      layer.update(0.1);
      _expectEndpoints(layer, from: Vector2(110, 125), to: Vector2(350, 350));

      cityPositions.remove('city');
      layer.update(0.1);
      _expectEndpoints(layer, from: Vector2(110, 125), to: Vector2(350, 350));
    });

    test('expires only when no attacked-target alert is bound', () {
      final layer = CombatAttackTrajectoryLayer()
        ..show(
          parent: Component(),
          attackerUnitId: 'attacker',
          targetId: 'target',
          fromCol: 0,
          fromRow: 0,
          toCol: 1,
          toRow: 0,
        )
        ..update(1.27);
      expect(layer.trajectoryCountForTesting(), 1);

      layer.update(0.02);
      expect(layer.trajectoryCountForTesting(), 0);
    });

    test('matches the attacked-target hex alert lifetime', () {
      var targetAlertVisible = true;
      final layer = CombatAttackTrajectoryLayer()
        ..show(
          parent: Component(),
          attackerUnitId: 'attacker',
          targetId: 'target',
          fromCol: 0,
          fromRow: 0,
          toCol: 1,
          toRow: 0,
        )
        ..syncTargetAlerts(hasTargetAlert: (_) => targetAlertVisible)
        ..update(20);

      expect(layer.trajectoryCountForTesting(), 1);

      targetAlertVisible = false;
      layer.syncTargetAlerts(hasTargetAlert: (_) => targetAlertVisible);

      expect(layer.trajectoryCountForTesting(), 0);
    });

    test('uses a static direction dash when reduced motion is enabled', () {
      final layer = CombatAttackTrajectoryLayer()
        ..show(
          parent: Component(),
          attackerUnitId: 'attacker',
          targetId: 'target',
          fromCol: 0,
          fromRow: 0,
          toCol: 1,
          toRow: 0,
          reduceMotion: true,
        );

      final initial = layer.dashProgressForTesting('attacker', 'target');
      layer.update(0.4);

      expect(initial, 0.72);
      expect(layer.dashProgressForTesting('attacker', 'target'), initial);
    });

    test('keeps only the latest attacker trajectory for a target', () {
      final layer = CombatAttackTrajectoryLayer()
        ..show(
          parent: Component(),
          attackerUnitId: 'first',
          targetId: 'target',
          fromCol: 0,
          fromRow: 0,
          toCol: 1,
          toRow: 0,
        )
        ..show(
          parent: Component(),
          attackerUnitId: 'second',
          targetId: 'target',
          fromCol: 2,
          fromRow: 0,
          toCol: 1,
          toRow: 0,
        );

      expect(layer.trajectoryCountForTesting(), 1);
      expect(layer.endpointsForTesting('first', 'target'), isNull);
      expect(layer.endpointsForTesting('second', 'target'), isNotNull);
    });
  });
}

void _expectEndpoints(
  CombatAttackTrajectoryLayer layer, {
  required Vector2 from,
  required Vector2 to,
}) {
  final endpoints =
      layer.endpointsForTesting('attacker', 'defender') ??
      layer.endpointsForTesting('attacker', 'city');
  expect(endpoints, isNotNull);
  expect(endpoints!.from.x, closeTo(from.x, 0.0001));
  expect(endpoints.from.y, closeTo(from.y, 0.0001));
  expect(endpoints.to.x, closeTo(to.x, 0.0001));
  expect(endpoints.to.y, closeTo(to.y, 0.0001));
  expect(HexGrid.perspectiveY, 0.62);
}
