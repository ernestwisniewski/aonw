import 'dart:async';

import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_camera_controller.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/combat_hex_alert_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/floating_text_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/particle_effects_layer.dart';
import 'package:aonw/game/presentation/engine/unit_animation_controller.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

class GameEffectDispatcher {
  final UnitAnimationController _unitAnimationController;
  final GameCameraController _cameraController;
  final ParticleEffectsLayer _particleEffectsLayer;
  final FloatingTextLayer _floatingTextLayer;
  final CombatHexAlertLayer _combatHexAlertLayer;
  final Component _particleParent;
  final Component _alertParent;
  final void Function() _onRendererStateChanged;
  final bool Function() _reduceMotion;
  final bool Function() _moveCameraForUnitMovement;
  final bool Function(String unitId) _moveCameraForUnitMovementForUnit;
  final Future<void> Function(String unitId) _onUnitMovementCameraComplete;
  final bool Function() _followUnitMovementCamera;
  final bool Function(int col, int row) _canAutoFocusMapTarget;
  final AppLocalizations? _l10n;

  GameEffectDispatcher({
    required UnitAnimationController unitAnimationController,
    required GameCameraController cameraController,
    required ParticleEffectsLayer particleEffectsLayer,
    required FloatingTextLayer floatingTextLayer,
    required CombatHexAlertLayer combatHexAlertLayer,
    required Component particleParent,
    required Component alertParent,
    required void Function() onRendererStateChanged,
    required bool Function() reduceMotion,
    bool Function()? moveCameraForUnitMovement,
    bool Function(String unitId)? moveCameraForUnitMovementForUnit,
    Future<void> Function(String unitId)? onUnitMovementCameraComplete,
    required bool Function() followUnitMovementCamera,
    bool Function(int col, int row)? canAutoFocusMapTarget,
    AppLocalizations? l10n,
  }) : _unitAnimationController = unitAnimationController,
       _cameraController = cameraController,
       _particleEffectsLayer = particleEffectsLayer,
       _floatingTextLayer = floatingTextLayer,
       _combatHexAlertLayer = combatHexAlertLayer,
       _particleParent = particleParent,
       _alertParent = alertParent,
       _onRendererStateChanged = onRendererStateChanged,
       _reduceMotion = reduceMotion,
       _moveCameraForUnitMovement = moveCameraForUnitMovement ?? (() => true),
       _moveCameraForUnitMovementForUnit =
           moveCameraForUnitMovementForUnit ?? ((_) => true),
       _onUnitMovementCameraComplete =
           onUnitMovementCameraComplete ?? ((_) async {}),
       _followUnitMovementCamera = followUnitMovementCamera,
       _canAutoFocusMapTarget = canAutoFocusMapTarget ?? ((_, _) => true),
       _l10n = l10n;

  Future<void> handleEffects(
    Iterable<RendererEffect> effects, {
    VoidCallback? beforeEffect,
  }) async {
    final pending = effects.toList(growable: false);
    final laterMovementUnitIds = <String>{};
    final retainAtDestination = List<bool>.filled(pending.length, false);
    for (var index = pending.length - 1; index >= 0; index -= 1) {
      final effect = pending[index];
      if (effect is! AnimateUnitMoveEffect) continue;
      retainAtDestination[index] = !laterMovementUnitIds.add(effect.unitId);
    }
    var completed = false;
    try {
      beforeEffect?.call();
      prepareMovementOrigins(pending);
      for (var index = 0; index < pending.length; index += 1) {
        beforeEffect?.call();
        await _handleEffect(
          pending[index],
          retainMovementAtDestination: retainAtDestination[index],
        );
      }
      beforeEffect?.call();
      completed = true;
    } finally {
      if (completed) {
        _unitAnimationController.releaseUnitAnimationState(
          laterMovementUnitIds,
        );
      } else {
        _unitAnimationController.cancelUnitAnimations(laterMovementUnitIds);
      }
    }
  }

  void prepareMovementOrigins(Iterable<RendererEffect> effects) {
    final preparedUnitIds = <String>{};
    for (final effect in effects.whereType<AnimateUnitMoveEffect>()) {
      if (!preparedUnitIds.add(effect.unitId)) continue;
      _unitAnimationController.preparePendingMoveOrigin(
        effect.unitId,
        col: effect.fromCol,
        row: effect.fromRow,
      );
    }
  }

  Future<void> handleEffect(RendererEffect effect) => handleEffects([effect]);

  Future<void> _handleEffect(
    RendererEffect effect, {
    required bool retainMovementAtDestination,
  }) async {
    switch (effect) {
      case AnimateUnitMoveEffect():
        await _handleUnitMove(
          effect,
          retainAtDestination: retainMovementAtDestination,
        );
      case PlayCombatAnimationEffect(
        :final attackerUnitId,
        :final defenderUnitId,
        :final attackerFromCol,
        :final attackerFromRow,
        :final attackerToCol,
        :final attackerToRow,
        :final attackerKilled,
        :final defenderKilled,
        :final defenderRetaliated,
      ):
        _focusCombatCamera(
          attackerUnitId: attackerUnitId,
          defenderUnitId: defenderUnitId,
          attackerFromCol: attackerFromCol,
          attackerFromRow: attackerFromRow,
          attackerToCol: attackerToCol,
          attackerToRow: attackerToRow,
        );
        await _unitAnimationController.animateUnitCombat(
          attackerUnitId: attackerUnitId,
          defenderUnitId: defenderUnitId,
          attackerKilled: attackerKilled,
          defenderKilled: defenderKilled,
          defenderRetaliated: defenderRetaliated,
          onComplete: _onRendererStateChanged,
        );
      case ShakeCameraEffect(:final intensity, :final duration):
        _cameraController.shake(intensity: intensity, duration: duration);
      case JumpCameraEffect(:final col, :final row):
        if (!_canAutoFocusMapTarget(col, row)) return;
        _cameraController.jumpToTile(col, row);
      case SmoothCameraEffect(:final col, :final row, :final duration):
        if (!_canAutoFocusMapTarget(col, row)) return;
        await _cameraController.smoothToTile(col, row, duration: duration);
      case SpawnParticleBurstEffect():
        _particleEffectsLayer.spawnBurst(
          parent: _particleParent,
          effect: effect,
        );
      case ShowFloatingTextEffect():
        _spawnFloatingText(effect);
      case ShowCityProductionBubbleEffect():
        _spawnFloatingText(_cityProductionBubbleText(effect));
      case ShowCombatHexAlertEffect():
        _combatHexAlertLayer.show(
          parent: _alertParent,
          effect: effect,
          reduceMotion: _reduceMotion(),
        );
    }
  }

  void _focusCombatCamera({
    required String attackerUnitId,
    required String defenderUnitId,
    required int? attackerFromCol,
    required int? attackerFromRow,
    required int? attackerToCol,
    required int? attackerToRow,
  }) {
    final attackerPoint = _unitAnimationController.unitWorldPosition(
      attackerUnitId,
    );
    if (attackerPoint != null) {
      _cameraController.centerOnWorldPoint(attackerPoint);
      return;
    }
    if (attackerFromCol != null &&
        attackerFromRow != null &&
        _canAutoFocusMapTarget(attackerFromCol, attackerFromRow)) {
      _cameraController.jumpToTile(attackerFromCol, attackerFromRow);
      return;
    }
    final defenderPoint = _unitAnimationController.unitWorldPosition(
      defenderUnitId,
    );
    if (defenderPoint != null) {
      _cameraController.centerOnWorldPoint(defenderPoint);
      return;
    }
    if (attackerToCol != null &&
        attackerToRow != null &&
        _canAutoFocusMapTarget(attackerToCol, attackerToRow)) {
      _cameraController.jumpToTile(attackerToCol, attackerToRow);
    }
  }

  Future<void> _handleUnitMove(
    AnimateUnitMoveEffect effect, {
    required bool retainAtDestination,
  }) async {
    final unitId = effect.unitId;
    _unitAnimationController.preparePendingMoveOrigin(
      unitId,
      col: effect.fromCol,
      row: effect.fromRow,
    );
    final unitVisible =
        _unitAnimationController.unitWorldPosition(unitId) != null;
    var followingMovement = false;
    var movedCamera = false;
    if (unitVisible &&
        _moveCameraForUnitMovement() &&
        _moveCameraForUnitMovementForUnit(unitId)) {
      await _cameraController.smoothToTile(
        effect.fromCol,
        effect.fromRow,
        duration: 0.28,
        curve: Curves.easeOutCubic,
      );
      movedCamera = true;
      if (_followUnitMovementCamera()) {
        followingMovement = true;
        _cameraController.followWorldPoint(
          () => _unitAnimationController.unitWorldPosition(unitId),
        );
      }
    }
    try {
      await _unitAnimationController.animateUnitMove(
        unitId: unitId,
        fromCol: effect.fromCol,
        fromRow: effect.fromRow,
        steps: effect.steps,
        retainAtDestination: retainAtDestination,
        onComplete: retainAtDestination ? () {} : _onRendererStateChanged,
      );
    } finally {
      if (followingMovement) {
        _cameraController.stopFollowingWorldPoint();
      }
      if (movedCamera) {
        await _onUnitMovementCameraComplete(unitId);
      }
    }
  }

  void _spawnFloatingText(ShowFloatingTextEffect effect) {
    if (effect.delay == Duration.zero) {
      _floatingTextLayer.spawn(parent: _particleParent, effect: effect);
    } else {
      unawaited(
        Future<void>.delayed(effect.delay, () {
          _floatingTextLayer.spawn(parent: _particleParent, effect: effect);
        }),
      );
    }
  }

  ShowFloatingTextEffect _cityProductionBubbleText(
    ShowCityProductionBubbleEffect effect,
  ) {
    return ShowFloatingTextEffect(
      text:
          '${_productionTargetLabel(effect.target)} • '
          '${_productionEtaLabel(effect)}',
      col: effect.col,
      row: effect.row,
      colorValue: 0xFFFFE5A3,
      delay: effect.delay,
      presentation: FloatingTextPresentation.bubble,
      anchor: FloatingTextAnchor.city(effect.cityId),
    );
  }

  String _productionTargetLabel(CityProductionTarget target) => _l10n == null
      ? ''
      : switch (target) {
          BuildingProductionTarget(:final buildingType) =>
            GameDisplayNames.cityBuilding(_l10n, buildingType),
          UnitProductionTarget(:final unitType) => GameDisplayNames.unitType(
            _l10n,
            unitType,
          ),
          ProjectProductionTarget(:final projectType) =>
            GameDisplayNames.cityProject(_l10n, projectType),
          WonderProductionTarget(:final wonderType) => wonderType.displayName,
        };

  String _productionEtaLabel(ShowCityProductionBubbleEffect effect) {
    final l10n = _l10n;
    if (l10n == null) return '';
    if (effect.target is ProjectProductionTarget) {
      return l10n.cityProductionContinuous;
    }
    final turns = effect.turnsRemaining;
    if (turns == null) {
      return l10n.cityProductionNoProduction;
    }
    if (turns <= 0) return l10n.cityProductionReady;
    return _turnsLabel(turns, l10n);
  }

  String _turnsLabel(int turns, AppLocalizations l10n) {
    if (turns == 1) return l10n.cityProductionTurnOne;
    return l10n.cityProductionTurns(turns);
  }
}
