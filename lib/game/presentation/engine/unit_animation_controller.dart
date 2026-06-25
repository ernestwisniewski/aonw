import 'dart:async';

import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_layer.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

/// Coordinates unit move effects and exposes the currently animating unit ids.
class UnitAnimationController {
  UnitAnimationController(this._layer);

  static final _supersededError = StateError('Unit animation superseded');
  static final _disposedError = StateError('UnitAnimationController disposed');

  final UnitMarkerLayer _layer;
  final ValueNotifier<Set<String>> _animatingUnitIds = ValueNotifier(const {});
  final Map<String, Completer<void>> _completers = {};
  bool _isDisposed = false;

  ValueListenable<Set<String>> get animatingUnitIdsListenable =>
      _animatingUnitIds;

  bool isUnitAnimating(String unitId) =>
      _animatingUnitIds.value.contains(unitId);

  Vector2? unitWorldPosition(String unitId) =>
      _layer.worldPositionForUnit(unitId);

  Future<void> animateUnitMove({
    required String unitId,
    int? fromCol,
    int? fromRow,
    required List<UnitMovementStep> steps,
    required VoidCallback onComplete,
  }) {
    if (steps.isEmpty) return Future<void>.value();
    if (_isDisposed) return Future<void>.error(_disposedError);

    final completer = Completer<void>();
    final previous = _completers.remove(unitId);
    if (previous != null && !previous.isCompleted) {
      previous.completeError(_supersededError);
    }
    _completers[unitId] = completer;
    _animatingUnitIds.value = {..._animatingUnitIds.value, unitId};

    _layer.animateMove(
      unitId: unitId,
      fromCol: fromCol,
      fromRow: fromRow,
      steps: steps,
      onComplete: () =>
          _onLayerAnimationComplete(unitId, completer, onComplete),
    );
    return completer.future;
  }

  Future<void> animateUnitCombat({
    required String attackerUnitId,
    required String defenderUnitId,
    required bool attackerKilled,
    required bool defenderKilled,
    required VoidCallback onComplete,
  }) {
    if (_isDisposed) return Future<void>.error(_disposedError);

    final unitIds = {attackerUnitId, defenderUnitId};
    final completer = Completer<void>();
    final previousCompleters = <Completer<void>>{};
    for (final unitId in unitIds) {
      final previous = _completers.remove(unitId);
      if (previous != null) previousCompleters.add(previous);
    }
    for (final previous in previousCompleters) {
      if (!previous.isCompleted) previous.completeError(_supersededError);
    }
    for (final unitId in unitIds) {
      _completers[unitId] = completer;
    }
    _animatingUnitIds.value = {..._animatingUnitIds.value, ...unitIds};

    _layer.animateCombat(
      attackerUnitId: attackerUnitId,
      defenderUnitId: defenderUnitId,
      attackerKilled: attackerKilled,
      defenderKilled: defenderKilled,
      onComplete: () =>
          _onLayerAnimationCompleteFor(unitIds, completer, onComplete),
    );
    return completer.future;
  }

  void _onLayerAnimationComplete(
    String unitId,
    Completer<void> completer,
    VoidCallback onComplete,
  ) {
    if (_isDisposed || !identical(_completers[unitId], completer)) return;
    _animatingUnitIds.value = {..._animatingUnitIds.value}..remove(unitId);
    scheduleMicrotask(() {
      if (_isDisposed || !identical(_completers[unitId], completer)) return;
      onComplete();
      _completers.remove(unitId);
      if (!completer.isCompleted) completer.complete();
    });
  }

  void _onLayerAnimationCompleteFor(
    Set<String> unitIds,
    Completer<void> completer,
    VoidCallback onComplete,
  ) {
    if (_isDisposed) return;
    for (final unitId in unitIds) {
      if (!identical(_completers[unitId], completer)) return;
    }
    _animatingUnitIds.value = {..._animatingUnitIds.value}..removeAll(unitIds);
    scheduleMicrotask(() {
      if (_isDisposed) return;
      for (final unitId in unitIds) {
        if (!identical(_completers[unitId], completer)) return;
      }
      onComplete();
      for (final unitId in unitIds) {
        _completers.remove(unitId);
      }
      if (!completer.isCompleted) completer.complete();
    });
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    for (final c in _completers.values) {
      if (!c.isCompleted) c.completeError(_disposedError);
    }
    _completers.clear();
    _animatingUnitIds.dispose();
  }
}
