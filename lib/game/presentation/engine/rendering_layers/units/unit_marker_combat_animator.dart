import 'dart:async';

import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker.dart';
import 'package:flame/effects.dart';
import 'package:flutter/foundation.dart';

final class UnitMarkerCombatAnimator {
  UnitMarkerCombatAnimator({
    required UnitMarker? Function(String unitId) markerFor,
  }) : _markerFor = markerFor;

  final UnitMarker? Function(String unitId) _markerFor;
  final Set<String> _animatingUnitIds = {};
  final Set<String> _retainedUnitIds = {};
  final Map<String, _CombatAnimationState> _animations = {};

  Set<String> get animatingUnitIds => Set.unmodifiable(_animatingUnitIds);

  bool isAnimating(String unitId) => _animatingUnitIds.contains(unitId);

  bool isRetained(String unitId) => _retainedUnitIds.contains(unitId);

  void retainPendingMarkers(Iterable<String> unitIds) {
    _retainedUnitIds.addAll(unitIds);
  }

  void release(Iterable<String> unitIds) {
    final ids = unitIds.toSet();
    final animations = {for (final unitId in ids) ?_animations[unitId]};
    for (final animation in animations) {
      _cancelAnimation(animation);
    }
    _animatingUnitIds.removeAll(ids);
    _retainedUnitIds.removeAll(ids);
  }

  void releaseAll() {
    for (final animation in _animations.values.toSet()) {
      _cancelAnimation(animation);
    }
    _animatingUnitIds.clear();
    _retainedUnitIds.clear();
  }

  void animate({
    required String attackerUnitId,
    required String defenderUnitId,
    required bool attackerKilled,
    required bool defenderKilled,
    required bool defenderRetaliated,
    required bool reduceMotion,
    required VoidCallback onComplete,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    final unitIds = {attackerUnitId, defenderUnitId};
    _cancelPreviousAnimations(unitIds);
    final markers = _CombatMarkers(
      attacker: _markerFor(attackerUnitId),
      defender: _markerFor(defenderUnitId),
    );
    if (!markers.hasAny) {
      _completeImmediately(unitIds, markers, onComplete: onComplete);
      return;
    }
    if (reduceMotion) {
      _completeImmediately(
        unitIds,
        markers,
        playIdle: true,
        onComplete: onComplete,
      );
      return;
    }
    _startAnimation(
      unitIds: unitIds,
      attackerUnitId: attackerUnitId,
      defenderUnitId: defenderUnitId,
      markers: markers,
      attackerKilled: attackerKilled,
      defenderKilled: defenderKilled,
      defenderRetaliated: defenderRetaliated,
      onComplete: onComplete,
      onError: onError,
    );
  }

  void _cancelPreviousAnimations(Set<String> unitIds) {
    final previousAnimations = {
      for (final unitId in unitIds) ?_animations[unitId],
    };
    for (final animation in previousAnimations) {
      _cancelAnimation(animation);
    }
  }

  void _completeImmediately(
    Set<String> unitIds,
    _CombatMarkers markers, {
    bool playIdle = false,
    required VoidCallback onComplete,
  }) {
    _retainedUnitIds.removeAll(unitIds);
    if (playIdle) markers.playIdle();
    onComplete();
  }

  void _startAnimation({
    required Set<String> unitIds,
    required String attackerUnitId,
    required String defenderUnitId,
    required _CombatMarkers markers,
    required bool attackerKilled,
    required bool defenderKilled,
    required bool defenderRetaliated,
    required VoidCallback onComplete,
    required void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    if (markers.attacker != null) _animatingUnitIds.add(attackerUnitId);
    if (markers.defender != null) _animatingUnitIds.add(defenderUnitId);
    markers.playAttack(defenderRetaliated: defenderRetaliated);

    final deathProgress = _CombatDeathProgress(
      markers: markers,
      attackerKilled: attackerKilled,
      defenderKilled: defenderKilled,
    );
    final effect = FunctionEffect<UnitMarker>(
      (_, progress) => deathProgress.apply(progress),
      EffectController(duration: _combatAnimationDuration),
    );
    final animation = _CombatAnimationState(unitIds, effect, markers);
    effect
      ..target = markers.anchor
      ..removeOnFinish = false
      ..onComplete = () => _completeAnimation(
        animation,
        markers: markers,
        attackerKilled: attackerKilled,
        defenderKilled: defenderKilled,
        onComplete: onComplete,
      );
    _registerAnimation(animation);
    unawaited(
      _attachEffect(
        animation: animation,
        anchor: markers.anchor,
        onError: onError,
      ),
    );
  }

  void _completeAnimation(
    _CombatAnimationState animation, {
    required _CombatMarkers markers,
    required bool attackerKilled,
    required bool defenderKilled,
    required VoidCallback onComplete,
  }) {
    if (!_isCurrent(animation)) return;
    _removeAnimation(animation);
    scheduleMicrotask(animation.effect.removeFromParent);
    _animatingUnitIds.removeAll(animation.unitIds);
    _retainedUnitIds.removeAll(animation.unitIds);
    markers.playSurvivorIdle(
      attackerKilled: attackerKilled,
      defenderKilled: defenderKilled,
    );
    onComplete();
  }

  void _registerAnimation(_CombatAnimationState animation) {
    for (final unitId in animation.unitIds) {
      _animations[unitId] = animation;
    }
  }

  bool _isCurrent(_CombatAnimationState animation) {
    return animation.unitIds.every(
      (unitId) => identical(_animations[unitId], animation),
    );
  }

  void _removeAnimation(_CombatAnimationState animation) {
    for (final unitId in animation.unitIds) {
      if (identical(_animations[unitId], animation)) {
        _animations.remove(unitId);
      }
    }
  }

  void _cancelAnimation(_CombatAnimationState animation) {
    _removeAnimation(animation);
    animation.effect.removeFromParent();
    _animatingUnitIds.removeAll(animation.unitIds);
    _retainedUnitIds.removeAll(animation.unitIds);
    animation.markers.playIdle();
  }

  Future<void> _attachEffect({
    required _CombatAnimationState animation,
    required UnitMarker anchor,
    required void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    try {
      await anchor.add(animation.effect);
      if (!_isCurrent(animation)) {
        animation.effect.removeFromParent();
      }
    } catch (error, stackTrace) {
      if (!_isCurrent(animation)) return;
      release(animation.unitIds);
      if (onError == null) {
        Zone.current.handleUncaughtError(error, stackTrace);
      } else {
        onError(error, stackTrace);
      }
    }
  }

  static const double _combatAnimationDuration = 0.72;
}

final class _CombatMarkers {
  const _CombatMarkers({required this.attacker, required this.defender});

  final UnitMarker? attacker;
  final UnitMarker? defender;

  bool get hasAny => attacker != null || defender != null;

  UnitMarker get anchor => attacker ?? defender!;

  void playAttack({required bool defenderRetaliated}) {
    final attackerMarker = attacker;
    final defenderMarker = defender;
    if (attackerMarker != null && defenderMarker != null) {
      attackerMarker.playAttackToward(
        from: attackerMarker.position,
        to: defenderMarker.position,
      );
      if (defenderRetaliated) {
        defenderMarker.playAttackToward(
          from: defenderMarker.position,
          to: attackerMarker.position,
        );
      }
      return;
    }
    attackerMarker?.playAttack();
    if (defenderRetaliated) defenderMarker?.playAttack();
  }

  void playIdle() {
    attacker?.playIdle();
    defender?.playIdle();
  }

  void playSurvivorIdle({
    required bool attackerKilled,
    required bool defenderKilled,
  }) {
    if (!attackerKilled) attacker?.playIdle();
    if (!defenderKilled) defender?.playIdle();
  }
}

final class _CombatDeathProgress {
  _CombatDeathProgress({
    required this.markers,
    required this.attackerKilled,
    required this.defenderKilled,
  });

  final _CombatMarkers markers;
  final bool attackerKilled;
  final bool defenderKilled;
  bool _defenderDieStarted = false;
  bool _attackerDieStarted = false;

  void apply(double progress) {
    if (defenderKilled && !_defenderDieStarted && progress >= 0.48) {
      markers.defender?.playDie();
      _defenderDieStarted = true;
    }
    if (attackerKilled && !_attackerDieStarted && progress >= 0.72) {
      markers.attacker?.playDie();
      _attackerDieStarted = true;
    }
  }
}

final class _CombatAnimationState {
  _CombatAnimationState(Set<String> unitIds, this.effect, this.markers)
    : unitIds = Set<String>.unmodifiable(unitIds);

  final Set<String> unitIds;
  final FunctionEffect<UnitMarker> effect;
  final _CombatMarkers markers;
}
