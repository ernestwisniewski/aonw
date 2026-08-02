import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_camera_controller.dart';
import 'package:aonw/game/presentation/engine/game_effect_dispatcher.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/combat_hex_alert_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/floating_text_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/particle_effects_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/unit_animation_controller.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _a1 = AnimateUnitMoveEffect(
  unitId: 'unit_a',
  fromCol: 0,
  fromRow: 0,
  steps: [UnitMovementStep(col: 1, row: 0, enterCost: 7, cumulativeCost: 7)],
);

const _b1 = AnimateUnitMoveEffect(
  unitId: 'unit_b',
  fromCol: 5,
  fromRow: 0,
  steps: [UnitMovementStep(col: 4, row: 0, enterCost: 11, cumulativeCost: 11)],
);

const _a2 = AnimateUnitMoveEffect(
  unitId: 'unit_a',
  fromCol: 1,
  fromRow: 0,
  steps: [UnitMovementStep(col: 2, row: 0, enterCost: 13, cumulativeCost: 20)],
);

const _chainedMoves = <RendererEffect>[_a1, _b1, _a2];

WorldMap _map() => WorldMap(
  cols: 1,
  rows: 1,
  tiles: [
    WorldTile(
      col: 0,
      row: 0,
      terrains: [TerrainType.grassland],
      resources: [],
      height: 0,
    ),
  ],
);

final class _TestUnitMarkerLayer extends UnitMarkerLayer {
  _TestUnitMarkerLayer()
    : super(mapData: _map(), colorForPlayer: (_) => 0xFF0000FF);
}

final class _MoveCall {
  const _MoveCall({
    required this.unitId,
    required this.fromCol,
    required this.steps,
    required this.retainAtDestination,
  });

  final String unitId;
  final int? fromCol;
  final List<UnitMovementStep> steps;
  final bool retainAtDestination;
}

final class _RecordingUnitAnimationController extends UnitAnimationController {
  _RecordingUnitAnimationController({this.failOnCall})
    : super(_TestUnitMarkerLayer());

  final int? failOnCall;
  final List<_MoveCall> moves = [];
  final List<Set<String>> releasedUnitIds = [];
  final List<Set<String>> cancelledUnitIds = [];

  @override
  Future<void> animateUnitMove({
    required String unitId,
    int? fromCol,
    int? fromRow,
    required List<UnitMovementStep> steps,
    bool retainAtDestination = false,
    required VoidCallback onComplete,
  }) {
    moves.add(
      _MoveCall(
        unitId: unitId,
        fromCol: fromCol,
        steps: List<UnitMovementStep>.unmodifiable(steps),
        retainAtDestination: retainAtDestination,
      ),
    );
    if (moves.length == failOnCall) {
      return Future<void>.error(StateError('injected movement failure'));
    }
    onComplete();
    return Future<void>.value();
  }

  @override
  void releaseUnitAnimationState(Iterable<String> unitIds) {
    releasedUnitIds.add(Set<String>.unmodifiable(unitIds));
  }

  @override
  void cancelUnitAnimations(Iterable<String> unitIds) {
    cancelledUnitIds.add(Set<String>.unmodifiable(unitIds));
  }
}

final class _DispatcherHarness {
  _DispatcherHarness({int? failOnCall})
    : controller = _RecordingUnitAnimationController(failOnCall: failOnCall) {
    final parent = Component();
    dispatcher = GameEffectDispatcher(
      unitAnimationController: controller,
      cameraController: GameCameraController(
        camera: CameraComponent(),
        mapData: _map(),
      ),
      particleEffectsLayer: ParticleEffectsLayer(),
      floatingTextLayer: FloatingTextLayer(),
      combatHexAlertLayer: CombatHexAlertLayer(),
      particleParent: parent,
      alertParent: parent,
      onRendererStateChanged: () => syncCount += 1,
      reduceMotion: () => false,
      moveCameraForUnitMovement: () => false,
      followUnitMovementCamera: () => false,
    );
  }

  final _RecordingUnitAnimationController controller;
  late final GameEffectDispatcher dispatcher;
  int syncCount = 0;

  void dispose() => controller.dispose();
}

void main() {
  group('GameEffectDispatcher movement batches', () {
    test(
      'preserves global order and syncs only final unit-chain segments',
      () async {
        final harness = _DispatcherHarness();
        addTearDown(harness.dispose);

        await harness.dispatcher.handleEffects(_chainedMoves);

        expect(harness.controller.moves.map((call) => call.unitId), [
          'unit_a',
          'unit_b',
          'unit_a',
        ]);
        expect(harness.controller.moves.map((call) => call.fromCol), [0, 5, 1]);
        expect(
          harness.controller.moves.map((call) => call.steps.single.enterCost),
          [7, 11, 13],
        );
        expect(
          harness.controller.moves.map(
            (call) => call.steps.single.cumulativeCost,
          ),
          [7, 11, 20],
        );
        expect(
          harness.controller.moves.map((call) => call.retainAtDestination),
          [true, false, false],
        );
        expect(harness.syncCount, 2);
        expect(harness.controller.cancelledUnitIds, isEmpty);
        expect(harness.controller.releasedUnitIds, hasLength(1));
        expect(
          harness.controller.releasedUnitIds.single,
          unorderedEquals(['unit_a', 'unit_b']),
        );
      },
    );

    test('treats handleEffect as a final one-element batch', () async {
      final harness = _DispatcherHarness();
      addTearDown(harness.dispose);

      await harness.dispatcher.handleEffect(_a1);

      expect(harness.controller.moves, hasLength(1));
      expect(harness.controller.moves.single.retainAtDestination, isFalse);
      expect(harness.syncCount, 1);
      expect(harness.controller.cancelledUnitIds, isEmpty);
      expect(harness.controller.releasedUnitIds, hasLength(1));
      expect(
        harness.controller.releasedUnitIds.single,
        unorderedEquals(['unit_a']),
      );
    });

    test('cancels every movement chain when a batch fails', () async {
      final harness = _DispatcherHarness(failOnCall: 2);
      addTearDown(harness.dispose);

      await expectLater(
        harness.dispatcher.handleEffects(_chainedMoves),
        throwsA(isA<StateError>()),
      );

      expect(harness.controller.moves.map((call) => call.unitId), [
        'unit_a',
        'unit_b',
      ]);
      expect(harness.controller.moves.map((call) => call.retainAtDestination), [
        true,
        false,
      ]);
      expect(harness.syncCount, 0);
      expect(harness.controller.releasedUnitIds, isEmpty);
      expect(harness.controller.cancelledUnitIds, hasLength(1));
      expect(
        harness.controller.cancelledUnitIds.single,
        unorderedEquals(['unit_a', 'unit_b']),
      );
    });

    test('cancellation check stops the remaining batch effects', () async {
      final harness = _DispatcherHarness();
      addTearDown(harness.dispose);
      final error = StateError('renderer disposed');
      var checks = 0;

      await expectLater(
        harness.dispatcher.handleEffects(
          _chainedMoves,
          beforeEffect: () {
            checks += 1;
            if (checks == 3) throw error;
          },
        ),
        throwsA(same(error)),
      );

      expect(harness.controller.moves.map((call) => call.unitId), ['unit_a']);
      expect(harness.syncCount, 0);
      expect(harness.controller.releasedUnitIds, isEmpty);
      expect(harness.controller.cancelledUnitIds, hasLength(1));
      expect(
        harness.controller.cancelledUnitIds.single,
        unorderedEquals(['unit_a', 'unit_b']),
      );
    });
  });
}
