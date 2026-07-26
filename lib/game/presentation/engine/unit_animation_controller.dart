import 'dart:async';

import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

/// Coordinates unit move effects and exposes the currently animating unit ids.
class UnitAnimationController {
  UnitAnimationController(this._layer) {
    _layer.bindAnimationLifecycleOwner(_handleLayerRemoved);
  }

  static final _supersededError = StateError('Unit animation superseded');
  static final _cancelledError = StateError('Unit animation cancelled');
  static final _disposedError = StateError('UnitAnimationController disposed');

  final UnitMarkerLayer _layer;
  final ValueNotifier<Set<String>> _animatingUnitIds = ValueNotifier(const {});
  final Map<String, _UnitAnimationOperation> _operations = {};
  bool _isDisposed = false;

  ValueListenable<Set<String>> get animatingUnitIdsListenable =>
      _animatingUnitIds;

  bool isUnitAnimating(String unitId) =>
      _animatingUnitIds.value.contains(unitId);

  Vector2? unitWorldPosition(String unitId) =>
      _layer.worldPositionForUnit(unitId);

  void preparePendingMoveOrigin(
    String unitId, {
    required int col,
    required int row,
  }) {
    _layer.preparePendingMoveOrigin(unitId, col: col, row: row);
  }

  Future<void> animateUnitMove({
    required String unitId,
    int? fromCol,
    int? fromRow,
    required List<UnitMovementStep> steps,
    bool retainAtDestination = false,
    required VoidCallback onComplete,
  }) {
    if (_isDisposed) return Future<void>.error(_disposedError);
    if (steps.isEmpty) {
      final previousOperation = _operations[unitId];
      if (previousOperation != null) {
        _cancelOperation(previousOperation, _supersededError);
      }
      _layer.releasePendingAnimationState({unitId});
      return Future<void>.sync(onComplete);
    }

    final operation = _beginOperation({unitId});
    try {
      _layer.animateMove(
        unitId: unitId,
        fromCol: fromCol,
        fromRow: fromRow,
        steps: steps,
        retainAtDestination: retainAtDestination,
        onComplete: () => _completeOperation(operation, onComplete),
        onError: (error, stackTrace) =>
            _failOperation(operation, error, stackTrace),
      );
    } catch (error, stackTrace) {
      _failOperation(operation, error, stackTrace);
    }
    return operation.completer.future;
  }

  Future<void> animateUnitCombat({
    required String attackerUnitId,
    required String defenderUnitId,
    required bool attackerKilled,
    required bool defenderKilled,
    bool defenderRetaliated = true,
    required VoidCallback onComplete,
  }) {
    if (_isDisposed) return Future<void>.error(_disposedError);

    final operation = _beginOperation({attackerUnitId, defenderUnitId});
    try {
      _layer.animateCombat(
        attackerUnitId: attackerUnitId,
        defenderUnitId: defenderUnitId,
        attackerKilled: attackerKilled,
        defenderKilled: defenderKilled,
        defenderRetaliated: defenderRetaliated,
        onComplete: () => _completeOperation(operation, onComplete),
        onError: (error, stackTrace) =>
            _failOperation(operation, error, stackTrace),
      );
    } catch (error, stackTrace) {
      _failOperation(operation, error, stackTrace);
    }
    return operation.completer.future;
  }

  void cancelUnitAnimations(Iterable<String> unitIds) {
    final ids = unitIds.toSet();
    final operations = {for (final unitId in ids) ?_operations[unitId]};
    for (final operation in operations) {
      _cancelOperation(operation, _cancelledError);
    }
    _layer.releasePendingAnimationState(ids);
  }

  void releaseUnitAnimationState(Iterable<String> unitIds) {
    _layer.releasePendingAnimationState(unitIds.toSet());
  }

  void finishUnitAnimationTransition(
    Iterable<String> unitIds, {
    required bool completed,
    required VoidCallback synchronizeAfterFailure,
  }) {
    final ids = unitIds.toSet();
    _layer.releasePendingAnimationState(ids);
    if (!completed && ids.isNotEmpty) {
      synchronizeAfterFailure();
    }
  }

  _UnitAnimationOperation _beginOperation(Set<String> unitIds) {
    final previousOperations = {
      for (final unitId in unitIds) ?_operations[unitId],
    };
    for (final operation in previousOperations) {
      _cancelOperation(operation, _supersededError);
    }
    final operation = _UnitAnimationOperation(unitIds);
    for (final unitId in operation.unitIds) {
      _operations[unitId] = operation;
    }
    _animatingUnitIds.value = {
      ..._animatingUnitIds.value,
      ...operation.unitIds,
    };
    return operation;
  }

  void _completeOperation(
    _UnitAnimationOperation operation,
    VoidCallback onComplete,
  ) {
    if (_isDisposed || !_isCurrent(operation)) return;
    _removeAnimating(operation.unitIds);
    scheduleMicrotask(() {
      if (_isDisposed || !_isCurrent(operation)) return;
      try {
        onComplete();
        if (!operation.completer.isCompleted) {
          operation.completer.complete();
        }
      } catch (error, stackTrace) {
        if (!operation.completer.isCompleted) {
          operation.completer.completeError(error, stackTrace);
        }
      } finally {
        _removeOperation(operation);
      }
    });
  }

  void _failOperation(
    _UnitAnimationOperation operation,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!_isCurrent(operation)) return;
    _cancelOperation(operation, error, stackTrace);
  }

  void _cancelOperation(
    _UnitAnimationOperation operation,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    _layer.releasePendingAnimationState(operation.unitIds);
    _removeAnimating(operation.unitIds);
    _removeOperation(operation);
    if (operation.completer.isCompleted) return;
    operation.completer.completeError(error, stackTrace);
  }

  bool _isCurrent(_UnitAnimationOperation operation) {
    return operation.unitIds.every(
      (unitId) => identical(_operations[unitId], operation),
    );
  }

  void _removeOperation(_UnitAnimationOperation operation) {
    for (final unitId in operation.unitIds) {
      if (identical(_operations[unitId], operation)) {
        _operations.remove(unitId);
      }
    }
  }

  void _removeAnimating(Iterable<String> unitIds) {
    _animatingUnitIds.value = {..._animatingUnitIds.value}..removeAll(unitIds);
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _layer.clearAnimationLifecycleOwner();
    final operations = _operations.values.toSet();
    for (final operation in operations) {
      _cancelOperation(operation, _disposedError);
    }
    _operations.clear();
    _layer.releaseAllAnimationState();
    _animatingUnitIds.dispose();
  }

  void _handleLayerRemoved() => dispose();
}

final class _UnitAnimationOperation {
  _UnitAnimationOperation(Set<String> unitIds)
    : unitIds = Set<String>.unmodifiable(unitIds);

  final Set<String> unitIds;
  final Completer<void> completer = Completer<void>();
}
