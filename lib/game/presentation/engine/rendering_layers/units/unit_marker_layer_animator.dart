import 'dart:async';

import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker.dart';
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
       _worldPositionFor = worldPositionFor;

  final UnitMarker? Function(String unitId) _markerFor;
  final Vector2 Function(int col, int row) _worldPositionFor;
  bool _reduceMotion;

  final Set<String> _animatingUnitIds = {};
  final Set<String> _positionLockedUnitIds = {};
  final Set<String> _retainedAnimationUnitIds = {};

  Set<String> get animatingUnitIds => Set.unmodifiable(_animatingUnitIds);

  bool get reduceMotion => _reduceMotion;

  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
  }

  bool isAnimating(String unitId) => _animatingUnitIds.contains(unitId);

  bool isPositionLocked(String unitId) =>
      _positionLockedUnitIds.contains(unitId);

  bool isRetained(String unitId) => _retainedAnimationUnitIds.contains(unitId);

  void pinPendingMovePositions(Set<String> unitIds) {
    if (unitIds.isEmpty) return;
    _positionLockedUnitIds.addAll(unitIds);
  }

  void retainPendingAnimationMarkers(Set<String> unitIds) {
    if (unitIds.isEmpty) return;
    _retainedAnimationUnitIds.addAll(unitIds);
  }

  void animateMove({
    required String unitId,
    int? fromCol,
    int? fromRow,
    required List<UnitMovementStep> steps,
    required VoidCallback onComplete,
  }) {
    _positionLockedUnitIds.remove(unitId);

    final marker = _markerFor(unitId);
    if (marker == null) {
      onComplete();
      return;
    }

    if (_reduceMotion) {
      marker
        ..onCity = false
        ..position = _worldPositionFor(steps.last.col, steps.last.row)
        ..playIdle();
      onComplete();
      return;
    }

    _animatingUnitIds.add(unitId);
    marker.onCity = false;
    if (fromCol != null && fromRow != null) {
      marker.position = _worldPositionFor(fromCol, fromRow);
    }

    final startPosition = fromCol != null && fromRow != null
        ? _worldPositionFor(fromCol, fromRow)
        : marker.position.clone();
    _syncWalkDirection(marker, startPosition, steps.first);

    final sequence = _buildMoveSequence(marker, steps);
    sequence
      ..removeOnFinish = false
      ..onComplete = () {
        scheduleMicrotask(sequence.removeFromParent);
        _animatingUnitIds.remove(unitId);
        marker.playIdle();
        onComplete();
      };
    unawaited(Future<void>.value(marker.add(sequence)));
  }

  void animateCombat({
    required String attackerUnitId,
    required String defenderUnitId,
    required bool attackerKilled,
    required bool defenderKilled,
    required VoidCallback onComplete,
  }) {
    final attackerMarker = _markerFor(attackerUnitId);
    final defenderMarker = _markerFor(defenderUnitId);
    if (attackerMarker == null && defenderMarker == null) {
      _clearCombatRetention(attackerUnitId, defenderUnitId);
      onComplete();
      return;
    }

    if (_reduceMotion) {
      _clearCombatRetention(attackerUnitId, defenderUnitId);
      attackerMarker?.playIdle();
      defenderMarker?.playIdle();
      onComplete();
      return;
    }

    if (attackerMarker != null) _animatingUnitIds.add(attackerUnitId);
    if (defenderMarker != null) _animatingUnitIds.add(defenderUnitId);

    if (attackerMarker != null && defenderMarker != null) {
      attackerMarker.playAttackToward(
        from: attackerMarker.position,
        to: defenderMarker.position,
      );
      defenderMarker.playAttackToward(
        from: defenderMarker.position,
        to: attackerMarker.position,
      );
    } else {
      attackerMarker?.playAttack();
      defenderMarker?.playAttack();
    }

    var defenderDieStarted = false;
    var attackerDieStarted = false;
    final anchor = attackerMarker ?? defenderMarker!;
    final effect = FunctionEffect<UnitMarker>((_, progress) {
      if (defenderKilled && !defenderDieStarted && progress >= 0.48) {
        defenderMarker?.playDie();
        defenderDieStarted = true;
      }
      if (attackerKilled && !attackerDieStarted && progress >= 0.72) {
        attackerMarker?.playDie();
        attackerDieStarted = true;
      }
    }, EffectController(duration: _combatAnimationDuration));
    effect
      ..target = anchor
      ..removeOnFinish = false
      ..onComplete = () {
        scheduleMicrotask(effect.removeFromParent);
        _animatingUnitIds
          ..remove(attackerUnitId)
          ..remove(defenderUnitId);
        _clearCombatRetention(attackerUnitId, defenderUnitId);
        if (!attackerKilled) attackerMarker?.playIdle();
        if (!defenderKilled) defenderMarker?.playIdle();
        onComplete();
      };
    unawaited(Future<void>.value(anchor.add(effect)));
  }

  void _clearCombatRetention(String attackerUnitId, String defenderUnitId) {
    _retainedAnimationUnitIds
      ..remove(attackerUnitId)
      ..remove(defenderUnitId);
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
  static const double _combatAnimationDuration = 0.72;
}
