import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/unit_animation_controller.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map() => MapData(
  cols: 2,
  rows: 1,
  tiles: [
    for (var col = 0; col < 2; col++)
      TileData(
        col: col,
        row: 0,
        terrains: const [TerrainType.grassland],
        resources: const [],
        height: 0,
      ),
  ],
);

class _FakeUnitMarkerLayer extends UnitMarkerLayer {
  VoidCallback? onMoveComplete;
  VoidCallback? onCombatComplete;

  _FakeUnitMarkerLayer()
    : super(mapData: _map(), colorForPlayer: (_) => 0xFF0000FF);

  @override
  void animateMove({
    required String unitId,
    int? fromCol,
    int? fromRow,
    required List<UnitMovementStep> steps,
    required VoidCallback onComplete,
  }) {
    onMoveComplete = onComplete;
  }

  @override
  void animateCombat({
    required String attackerUnitId,
    required String defenderUnitId,
    required bool attackerKilled,
    required bool defenderKilled,
    required VoidCallback onComplete,
  }) {
    onCombatComplete = onComplete;
  }
}

void main() {
  group('UnitAnimationController', () {
    test('completes move futures when the layer animation completes', () async {
      final layer = _FakeUnitMarkerLayer();
      final controller = UnitAnimationController(layer);
      addTearDown(controller.dispose);
      var synced = false;

      final future = controller.animateUnitMove(
        unitId: 'unit_1',
        steps: const [
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
        onComplete: () => synced = true,
      );

      layer.onMoveComplete!();

      await expectLater(future, completes);
      expect(synced, isTrue);
      expect(controller.animatingUnitIdsListenable.value, isEmpty);
    });

    test(
      'tracks both combat participants until combat animation completes',
      () async {
        final layer = _FakeUnitMarkerLayer();
        final controller = UnitAnimationController(layer);
        addTearDown(controller.dispose);
        var synced = false;

        final future = controller.animateUnitCombat(
          attackerUnitId: 'attacker',
          defenderUnitId: 'defender',
          attackerKilled: false,
          defenderKilled: true,
          onComplete: () => synced = true,
        );

        expect(
          controller.animatingUnitIdsListenable.value,
          containsAll(['attacker', 'defender']),
        );

        layer.onCombatComplete!();

        await expectLater(future, completes);
        expect(synced, isTrue);
        expect(controller.animatingUnitIdsListenable.value, isEmpty);
      },
    );

    test('completes pending move futures with an error on dispose', () async {
      final layer = _FakeUnitMarkerLayer();
      final controller = UnitAnimationController(layer);

      final future = controller.animateUnitMove(
        unitId: 'unit_1',
        steps: const [
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
        onComplete: () {},
      );
      final expectation = expectLater(future, throwsA(isA<StateError>()));

      controller.dispose();

      await expectation;
    });
  });
}
