import 'dart:async';

import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_combat_animator.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

class UnitMarkerLayerAnimator {
  UnitMarkerLayerAnimator({
    required UnitMarker? Function(String unitId) markerFor,
    required Vector2 Function(int col, int row) worldPositionFor,
    bool reduceMotion = false,
  }) : _markerFor = markerFor,
       _reduceMotion = reduceMotion,
       _worldPositionFor = worldPositionFor {
    _combatAnimator = UnitMarkerCombatAnimator(markerFor: markerFor);
  }

  final UnitMarker? Function(String unitId) _markerFor;
  final Vector2 Function(int col, int row) _worldPositionFor;
  late final UnitMarkerCombatAnimator _combatAnimator;
  bool _reduceMotion;

  final Set<String> _movingUnitIds = {};
  final Set<String> _positionLockedUnitIds = {};
  final Set<String> _movementRetainedUnitIds = {};
  final Map<String, Object> _moveTokens = {};
  final Map<String, SequenceEffect> _moveEffects = {};

  Set<String> get animatingUnitIds => Set.unmodifiable({
    ..._movingUnitIds,
    ..._combatAnimator.animatingUnitIds,
  });

  bool get reduceMotion => _reduceMotion;

  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
  }

  bool isAnimating(String unitId) =>
      _movingUnitIds.contains(unitId) || _combatAnimator.isAnimating(unitId);

  bool isPositionLocked(String unitId) =>
      _positionLockedUnitIds.contains(unitId);

  bool isRetained(String unitId) =>
      _movementRetainedUnitIds.contains(unitId) ||
      _combatAnimator.isRetained(unitId);

  void pinPendingMovePositions(Set<String> unitIds) {
    if (unitIds.isEmpty) return;
    _positionLockedUnitIds.addAll(unitIds);
  }

  void preparePendingMoveOrigin(
    String unitId, {
    required int col,
    required int row,
  }) {
    final marker = _markerFor(unitId);
    if (marker == null) return;
    marker
      ..onCity = false
      ..position = _worldPositionFor(col, row);
  }

  void retainPendingAnimationMarkers(Set<String> unitIds) {
    _combatAnimator.retainPendingMarkers(unitIds);
  }

  void retainPendingMoveMarkers(Set<String> unitIds) {
    if (unitIds.isEmpty) return;
    _movementRetainedUnitIds.addAll(unitIds);
  }

  void releaseAnimationState(Iterable<String> unitIds) {
    final ids = unitIds.toSet();
    _combatAnimator.release(ids);
    _releaseMovementState(ids);
  }

  void _releaseMovementState(Iterable<String> unitIds) {
    for (final unitId in unitIds) {
      _cancelActiveMove(unitId);
      _positionLockedUnitIds.remove(unitId);
      _movementRetainedUnitIds.remove(unitId);
    }
  }

  void releaseAllAnimationState() {
    _combatAnimator.releaseAll();
    _releaseMovementState({
      ..._movingUnitIds,
      ..._positionLockedUnitIds,
      ..._movementRetainedUnitIds,
      ..._moveTokens.keys,
      ..._moveEffects.keys,
    });
  }

  void animateMove({
    required String unitId,
    int? fromCol,
    int? fromRow,
    required List<UnitMovementStep> steps,
    bool retainAtDestination = false,
    required VoidCallback onComplete,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    _cancelActiveMove(unitId);
    _positionLockedUnitIds.remove(unitId);

    final marker = _markerFor(unitId);
    if (marker == null) {
      releaseAnimationState([unitId]);
      onComplete();
      return;
    }

    if (_reduceMotion) {
      marker
        ..onCity = false
        ..position = _worldPositionFor(steps.last.col, steps.last.row)
        ..playIdle();
      _completeMoveState(unitId, retainAtDestination: retainAtDestination);
      onComplete();
      return;
    }

    final token = Object();
    _moveTokens[unitId] = token;
    _movingUnitIds.add(unitId);
    marker.onCity = false;
    if (fromCol != null && fromRow != null) {
      marker.position = _worldPositionFor(fromCol, fromRow);
    }

    final startPosition = fromCol != null && fromRow != null
        ? _worldPositionFor(fromCol, fromRow)
        : marker.position.clone();
    _syncWalkDirection(marker, startPosition, steps.first);

    final sequence = _buildMoveSequence(marker, steps);
    _moveEffects[unitId] = sequence;
    sequence
      ..removeOnFinish = false
      ..onComplete = () {
        if (!identical(_moveTokens[unitId], token)) return;
        _moveTokens.remove(unitId);
        _moveEffects.remove(unitId);
        scheduleMicrotask(sequence.removeFromParent);
        _completeMoveState(unitId, retainAtDestination: retainAtDestination);
        marker.playIdle();
        onComplete();
      };
    unawaited(
      _attachMoveEffect(
        unitId: unitId,
        token: token,
        marker: marker,
        sequence: sequence,
        onError: onError,
      ),
    );
  }

  void animateCombat({
    required String attackerUnitId,
    required String defenderUnitId,
    required bool attackerKilled,
    required bool defenderKilled,
    bool defenderRetaliated = true,
    required VoidCallback onComplete,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    _combatAnimator.animate(
      attackerUnitId: attackerUnitId,
      defenderUnitId: defenderUnitId,
      attackerKilled: attackerKilled,
      defenderKilled: defenderKilled,
      defenderRetaliated: defenderRetaliated,
      reduceMotion: _reduceMotion,
      onComplete: onComplete,
      onError: onError,
    );
  }

  void _completeMoveState(String unitId, {required bool retainAtDestination}) {
    _movingUnitIds.remove(unitId);
    if (retainAtDestination) {
      _positionLockedUnitIds.add(unitId);
      _movementRetainedUnitIds.add(unitId);
      return;
    }
    _positionLockedUnitIds.remove(unitId);
    _movementRetainedUnitIds.remove(unitId);
  }

  void _cancelActiveMove(String unitId) {
    final wasMoving = _movingUnitIds.remove(unitId);
    _moveTokens.remove(unitId);
    _moveEffects.remove(unitId)?.removeFromParent();
    if (wasMoving) _markerFor(unitId)?.playIdle();
  }

  Future<void> _attachMoveEffect({
    required String unitId,
    required Object token,
    required UnitMarker marker,
    required SequenceEffect sequence,
    required void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    try {
      await marker.add(sequence);
      if (!identical(_moveTokens[unitId], token)) {
        sequence.removeFromParent();
      }
    } catch (error, stackTrace) {
      if (!identical(_moveTokens[unitId], token)) return;
      releaseAnimationState([unitId]);
      if (onError == null) {
        Zone.current.handleUncaughtError(error, stackTrace);
      } else {
        onError(error, stackTrace);
      }
    }
  }

  SequenceEffect _buildMoveSequence(
    UnitMarker marker,
    List<UnitMovementStep> steps,
  ) {
    final effects = <Effect>[];
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final targetPosition = _worldPositionFor(step.col, step.row);
      final nextStep = i + 1 < steps.length ? steps[i + 1] : null;
      effects.add(
        MoveEffect.to(
          targetPosition,
          EffectController(duration: _moveStepDuration, curve: Curves.linear),
          target: marker,
          onComplete: nextStep == null
              ? null
              : () => _syncWalkDirection(marker, targetPosition, nextStep),
        ),
      );
    }
    return SequenceEffect(effects);
  }

  void _syncWalkDirection(
    UnitMarker marker,
    Vector2 fromPosition,
    UnitMovementStep targetStep,
  ) {
    marker.playWalkToward(
      from: fromPosition,
      to: _worldPositionFor(targetStep.col, targetStep.row),
    );
  }

  static const double _moveStepDuration = 0.6;
}
