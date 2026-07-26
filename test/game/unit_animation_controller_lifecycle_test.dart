import 'dart:async';

import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw/game/presentation/engine/unit_animation_controller.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitAnimationController lifecycle', () {
    test('synchronous layer error settles once and releases state', () async {
      final layer = _ControlledUnitMarkerLayer()..throwOnMove = true;
      final controller = UnitAnimationController(layer);
      addTearDown(controller.dispose);
      layer
        ..pinPendingMovePositions(const {'unit_a'})
        ..retainPendingMoveMarkers(const {'unit_a'});

      final future = controller.animateUnitMove(
        unitId: 'unit_a',
        steps: _steps,
        onComplete: () => fail('failed animation must not sync'),
      );

      await expectLater(future, throwsA(isA<StateError>()));
      _expectReleased(controller, layer, 'unit_a');
    });

    test('asynchronous layer error settles once and releases state', () async {
      final layer = _ControlledUnitMarkerLayer();
      final controller = UnitAnimationController(layer);
      addTearDown(controller.dispose);
      layer
        ..pinPendingMovePositions(const {'unit_a'})
        ..retainPendingMoveMarkers(const {'unit_a'});
      var syncCount = 0;
      final error = StateError('animation attach failed');

      final future = controller.animateUnitMove(
        unitId: 'unit_a',
        steps: _steps,
        onComplete: () => syncCount += 1,
      );
      final expectation = expectLater(future, throwsA(same(error)));
      layer.moves.single.onError(error, StackTrace.current);

      await expectation;
      expect(syncCount, 0);
      _expectReleased(controller, layer, 'unit_a');
    });

    test(
      'renderer sync error does not poison the following animation',
      () async {
        final layer = _ControlledUnitMarkerLayer();
        final controller = UnitAnimationController(layer);
        addTearDown(controller.dispose);
        final error = StateError('renderer sync failed');

        final failed = controller.animateUnitMove(
          unitId: 'unit_a',
          steps: _steps,
          onComplete: () => throw error,
        );
        final failedExpectation = expectLater(failed, throwsA(same(error)));
        layer.moves.single.onComplete();
        await failedExpectation;

        var syncCount = 0;
        final recovered = controller.animateUnitMove(
          unitId: 'unit_a',
          steps: _steps,
          onComplete: () => syncCount += 1,
        );
        layer.moves.last.onComplete();

        await expectLater(recovered, completes);
        expect(syncCount, 1);
        expect(controller.animatingUnitIdsListenable.value, isEmpty);
      },
    );

    test('superseded stale callback cannot settle the replacement', () async {
      final layer = _ControlledUnitMarkerLayer();
      final controller = UnitAnimationController(layer);
      addTearDown(controller.dispose);
      var syncCount = 0;

      final first = controller.animateUnitMove(
        unitId: 'unit_a',
        steps: _steps,
        onComplete: () => syncCount += 1,
      );
      final firstExpectation = expectLater(first, throwsA(isA<StateError>()));
      final second = controller.animateUnitMove(
        unitId: 'unit_a',
        steps: _steps,
        onComplete: () => syncCount += 1,
      );
      var secondCompleted = false;
      unawaited(second.then((_) => secondCompleted = true));

      await firstExpectation;
      layer.moves.first.onComplete();
      await _flush();

      expect(secondCompleted, isFalse);
      expect(controller.animatingUnitIdsListenable.value, const {'unit_a'});

      layer.moves.last.onComplete();
      await expectLater(second, completes);
      expect(syncCount, 1);
      expect(controller.animatingUnitIdsListenable.value, isEmpty);
    });

    test('empty move supersedes an active move exactly once', () async {
      final layer = _ControlledUnitMarkerLayer();
      final controller = UnitAnimationController(layer);
      addTearDown(controller.dispose);
      Object? firstError;
      var firstSettled = false;
      var syncCount = 0;

      final first = controller.animateUnitMove(
        unitId: 'unit_a',
        steps: _steps,
        onComplete: () => syncCount += 1,
      );
      final observedFirst = first.then<void>(
        (_) => firstSettled = true,
        onError: (Object error, StackTrace stackTrace) {
          firstError = error;
          firstSettled = true;
        },
      );
      final empty = controller.animateUnitMove(
        unitId: 'unit_a',
        steps: const [],
        onComplete: () => syncCount += 1,
      );

      await expectLater(empty, completes);
      await _flush();
      expect(firstSettled, isTrue);
      expect(
        firstError,
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Unit animation superseded',
        ),
      );
      expect(controller.animatingUnitIdsListenable.value, isEmpty);
      expect(syncCount, 1);

      layer.moves.single.onComplete();
      await _flush();
      expect(syncCount, 1);
      await observedFirst;
    });

    test('superseding one combat participant releases both', () async {
      final layer = _ControlledUnitMarkerLayer();
      final controller = UnitAnimationController(layer);
      addTearDown(controller.dispose);

      final combat = controller.animateUnitCombat(
        attackerUnitId: 'unit_a',
        defenderUnitId: 'unit_b',
        attackerKilled: false,
        defenderKilled: false,
        onComplete: () {},
      );
      final combatExpectation = expectLater(combat, throwsA(isA<StateError>()));
      final move = controller.animateUnitMove(
        unitId: 'unit_a',
        steps: _steps,
        onComplete: () {},
      );

      await combatExpectation;
      expect(controller.animatingUnitIdsListenable.value, const {'unit_a'});
      layer.combats.single.onComplete();
      await _flush();
      expect(controller.animatingUnitIdsListenable.value, const {'unit_a'});

      layer.moves.single.onComplete();
      await expectLater(move, completes);
      expect(controller.animatingUnitIdsListenable.value, isEmpty);
    });

    test('explicit cancellation ignores a later layer callback', () async {
      final layer = _ControlledUnitMarkerLayer();
      final controller = UnitAnimationController(layer);
      addTearDown(controller.dispose);
      var syncCount = 0;

      final future = controller.animateUnitMove(
        unitId: 'unit_a',
        steps: _steps,
        onComplete: () => syncCount += 1,
      );
      final expectation = expectLater(future, throwsA(isA<StateError>()));
      controller.cancelUnitAnimations(const {'unit_a'});
      layer.moves.single.onComplete();

      await expectation;
      await _flush();
      expect(syncCount, 0);
      _expectReleased(controller, layer, 'unit_a');
    });

    test('explicit cancellation restores a moving marker to idle', () async {
      final parent = PositionComponent();
      final unit = GameUnit.produced(
        id: 'unit_a',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final layer = UnitMarkerLayer(
        mapData: _map(),
        colorForPlayer: (_) => 0xFF0000FF,
      )..sync(parent: parent, units: [unit], selectedUnitId: null);
      final controller = UnitAnimationController(layer);
      addTearDown(controller.dispose);

      final move = controller.animateUnitMove(
        unitId: unit.id,
        fromCol: unit.col,
        fromRow: unit.row,
        steps: _steps,
        onComplete: () => fail('cancelled movement must not complete'),
      );
      final expectation = expectLater(move, throwsA(isA<StateError>()));
      expect(layer.markerActionForTesting(unit.id), UnitSpriteAction.walk);

      controller.cancelUnitAnimations({unit.id});

      await expectation;
      expect(layer.markerActionForTesting(unit.id), UnitSpriteAction.idle);
    });

    test('layer removal errors active move and combat exactly once', () async {
      final layer = _ControlledUnitMarkerLayer();
      final controller = UnitAnimationController(layer);
      addTearDown(controller.dispose);
      var syncCount = 0;
      final move = controller.animateUnitMove(
        unitId: 'unit_a',
        steps: _steps,
        onComplete: () => syncCount += 1,
      );
      final combat = controller.animateUnitCombat(
        attackerUnitId: 'unit_b',
        defenderUnitId: 'unit_c',
        attackerKilled: false,
        defenderKilled: false,
        onComplete: () => syncCount += 1,
      );
      final disposedError = isA<StateError>().having(
        (error) => error.message,
        'message',
        'UnitAnimationController disposed',
      );
      final moveExpectation = expectLater(move, throwsA(disposedError));
      final combatExpectation = expectLater(combat, throwsA(disposedError));

      layer.onRemove();
      layer.moves.single
        ..onComplete()
        ..onError(StateError('late move error'), StackTrace.current);
      layer.combats.single
        ..onComplete()
        ..onError(StateError('late combat error'), StackTrace.current);

      await Future.wait([moveExpectation, combatExpectation]);
      await _flush();
      expect(syncCount, 0);
    });

    test('partial combat release clears both retained participants', () {
      final parent = PositionComponent();
      final attacker = GameUnit.produced(
        id: 'unit_a',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final defender = GameUnit.produced(
        id: 'unit_b',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 1,
        row: 0,
      );
      final layer =
          UnitMarkerLayer(mapData: _map(), colorForPlayer: (_) => 0xFF0000FF)
            ..sync(
              parent: parent,
              units: [attacker, defender],
              selectedUnitId: null,
            )
            ..retainPendingAnimationMarkers({attacker.id, defender.id})
            ..animateCombat(
              attackerUnitId: attacker.id,
              defenderUnitId: defender.id,
              attackerKilled: false,
              defenderKilled: false,
              onComplete: () => fail('cancelled combat must not complete'),
            );
      expect(layer.animatingUnitIds, {attacker.id, defender.id});

      layer.releasePendingAnimationState({attacker.id});

      expect(layer.animatingUnitIds, isEmpty);
      expect(layer.isAnimationMarkerRetainedForTesting(attacker.id), isFalse);
      expect(layer.isAnimationMarkerRetainedForTesting(defender.id), isFalse);
    });

    test('failed transition releases holds and requests one final sync', () {
      final layer = _ControlledUnitMarkerLayer()
        ..pinPendingMovePositions(const {'unit_a'})
        ..retainPendingMoveMarkers(const {'unit_a'});
      final controller = UnitAnimationController(layer);
      addTearDown(controller.dispose);
      var syncCount = 0;

      controller.finishUnitAnimationTransition(
        const {'unit_a'},
        completed: false,
        synchronizeAfterFailure: () => syncCount += 1,
      );

      expect(syncCount, 1);
      _expectReleased(controller, layer, 'unit_a');
    });

    test('dispose clears a completed intermediate hold', () async {
      final parent = PositionComponent();
      final unit = GameUnit.produced(
        id: 'unit_a',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final layer =
          UnitMarkerLayer(
              mapData: _map(),
              colorForPlayer: (_) => 0xFF0000FF,
              reduceMotion: true,
            )
            ..sync(parent: parent, units: [unit], selectedUnitId: null)
            ..pinPendingMovePositions(const {'unit_a'})
            ..retainPendingMoveMarkers(const {'unit_a'});
      final controller = UnitAnimationController(layer);

      await controller.animateUnitMove(
        unitId: 'unit_a',
        steps: _steps,
        retainAtDestination: true,
        onComplete: () {},
      );
      expect(layer.isPositionLockedForTesting('unit_a'), isTrue);
      expect(layer.isAnimationMarkerRetainedForTesting('unit_a'), isTrue);

      controller.dispose();

      expect(layer.isPositionLockedForTesting('unit_a'), isFalse);
      expect(layer.isAnimationMarkerRetainedForTesting('unit_a'), isFalse);
    });
  });
}

const _steps = [
  UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
];

final class _ControlledUnitMarkerLayer extends UnitMarkerLayer {
  _ControlledUnitMarkerLayer()
    : super(mapData: _map(), colorForPlayer: (_) => 0xFF0000FF);

  bool throwOnMove = false;
  final moves = <_MoveInvocation>[];
  final combats = <_CombatInvocation>[];

  @override
  void animateMove({
    required String unitId,
    int? fromCol,
    int? fromRow,
    required List<UnitMovementStep> steps,
    bool retainAtDestination = false,
    required VoidCallback onComplete,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    if (throwOnMove) throw StateError('layer setup failed');
    moves.add(_MoveInvocation(onComplete, onError!));
  }

  @override
  void animateCombat({
    required String attackerUnitId,
    required String defenderUnitId,
    required bool attackerKilled,
    required bool defenderKilled,
    bool defenderRetaliated = true,
    required VoidCallback onComplete,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    combats.add(_CombatInvocation(onComplete, onError!));
  }
}

final class _MoveInvocation {
  const _MoveInvocation(this.onComplete, this.onError);

  final VoidCallback onComplete;
  final void Function(Object error, StackTrace stackTrace) onError;
}

final class _CombatInvocation {
  const _CombatInvocation(this.onComplete, this.onError);

  final VoidCallback onComplete;
  final void Function(Object error, StackTrace stackTrace) onError;
}

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

void _expectReleased(
  UnitAnimationController controller,
  UnitMarkerLayer layer,
  String unitId,
) {
  expect(controller.animatingUnitIdsListenable.value, isNot(contains(unitId)));
  expect(layer.isPositionLockedForTesting(unitId), isFalse);
  expect(layer.isAnimationMarkerRetainedForTesting(unitId), isFalse);
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);
