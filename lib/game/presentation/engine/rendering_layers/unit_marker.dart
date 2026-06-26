import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_badges.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_input_handler.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_renderer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_sprite_controller.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_sprite.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

export 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_badges.dart'
    show UnitMarkerStateBadge;

class UnitMarker extends PositionComponent with HasPaint<String>, TapCallbacks {
  final int colorValue;
  final VoidCallback? onTap;
  final UnitMarkerSpriteController _spriteController;
  bool _selected;
  bool _pendingActionTarget;
  bool _attackTarget;
  double _healthFraction;
  bool onCity;
  String? workBadgeLabel;
  bool fortified;
  bool skippedTurn;
  bool exhausted;
  bool carryingArtifact;
  bool showPeripheralDetails;
  bool showOwnerColor;
  bool showHealthBar;
  bool showTypeBadge;
  bool showStateBadge;
  bool compactWorkVisual;
  double _markerWorldScale;
  double _spriteScale;
  double _tacticalViewEmphasis;
  bool _animateIdle;

  static const double _typeIconPulsePeriod = 1.15;
  final ComponentKey _attackTargetTintEffectKey = ComponentKey.unique();
  static const double _staticPendingActionScale = 1.06;
  static const double _focusedScale = 1.12;
  static const double _focusPulseDuration = 0.9;

  double _typeIconPulseElapsed = 0;
  double _focusPulseElapsed = 0;
  bool _reduceMotion;
  bool _actionAnimationActive = false;

  GameUnitType get unitType => _spriteController.unitType;

  set unitType(GameUnitType value) {
    final changed = _spriteController.setUnitType(value);
    if (changed) {
      _syncIdlePauseBehavior();
    }
    if (changed && isLoaded) {
      unawaited(_spriteController.loadIfNeeded());
    }
  }

  UnitMarker({
    required Vector2 position,
    required this.colorValue,
    required GameUnitType unitType,
    this.onTap,
    bool selected = false,
    bool pendingActionTarget = false,
    bool attackTarget = false,
    double healthFraction = 1.0,
    this.onCity = false,
    this.fortified = false,
    this.skippedTurn = false,
    this.exhausted = false,
    this.carryingArtifact = false,
    this.showPeripheralDetails = true,
    bool? showOwnerColor,
    bool? showHealthBar,
    bool? showTypeBadge,
    bool? showStateBadge,
    this.compactWorkVisual = false,
    double markerWorldScale = 1.0,
    double spriteScale = 1.0,
    double tacticalViewEmphasis = 0.0,
    bool animateIdle = true,
    bool reduceMotion = false,
  }) : showOwnerColor = showOwnerColor ?? showPeripheralDetails,
       showHealthBar = showHealthBar ?? showPeripheralDetails,
       showTypeBadge = showTypeBadge ?? showPeripheralDetails,
       showStateBadge = showStateBadge ?? showPeripheralDetails,
       _spriteController = UnitMarkerSpriteController(unitType),
       _selected = selected,
       _pendingActionTarget = pendingActionTarget,
       _attackTarget = attackTarget,
       _healthFraction = healthFraction.clamp(0.0, 1.0).toDouble(),
       _markerWorldScale = _normalizeMarkerWorldScale(markerWorldScale),
       _spriteScale = _normalizeSpriteScale(spriteScale),
       _tacticalViewEmphasis = _normalizeTacticalViewEmphasis(
         tacticalViewEmphasis,
       ),
       _animateIdle = animateIdle,
       _reduceMotion = reduceMotion,
       super(
         position: position,
         size: Vector2.all(UnitMarkerRenderer.markerSize),
         anchor: Anchor.center,
         priority: 20,
       ) {
    paint.filterQuality = FilterQuality.medium;
    _syncIdlePauseBehavior();
    _syncTintEffects();
    _syncFocusScale();
  }

  double get healthFraction => _healthFraction;

  set healthFraction(double value) {
    final next = value.clamp(0.0, 1.0).toDouble();
    if (_healthFraction == next) return;
    _healthFraction = next;
  }

  bool get selected => _selected;

  set selected(bool value) {
    if (_selected == value) return;
    _selected = value;
    _syncIdlePauseBehavior();
    _typeIconPulseElapsed = 0;
    if (_selected && !_actionAnimationActive) {
      playIdle();
    }
    _syncTintEffects();
    _syncFocusScale(resetElapsed: true);
  }

  bool get reduceMotion => _reduceMotion;

  double get markerWorldScale => _markerWorldScale;

  set markerWorldScale(double value) {
    final next = _normalizeMarkerWorldScale(value);
    if (_markerWorldScale == next) return;
    _markerWorldScale = next;
    _syncFocusScale();
  }

  double get spriteScale => _spriteScale;

  set spriteScale(double value) {
    final next = _normalizeSpriteScale(value);
    if (_spriteScale == next) return;
    _spriteScale = next;
  }

  bool get animateIdle => _animateIdle;

  set animateIdle(bool value) {
    if (_animateIdle == value) return;
    _animateIdle = value;
  }

  double get tacticalViewEmphasis => _tacticalViewEmphasis;

  set tacticalViewEmphasis(double value) {
    final next = _normalizeTacticalViewEmphasis(value);
    if (_tacticalViewEmphasis == next) return;
    _tacticalViewEmphasis = next;
  }

  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    _typeIconPulseElapsed = 0;
    _syncTintEffects();
    _syncFocusScale(resetElapsed: true);
  }

  bool get pendingActionTarget => _pendingActionTarget;

  set pendingActionTarget(bool value) {
    if (_pendingActionTarget == value) return;
    _pendingActionTarget = value;
    _syncFocusScale(resetElapsed: true);
  }

  bool get attackTarget => _attackTarget;

  set attackTarget(bool value) {
    if (_attackTarget == value) return;
    _attackTarget = value;
    _typeIconPulseElapsed = 0;
    _syncTintEffects();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _spriteController.loadIfNeeded();
    _syncTintEffects();
    _syncFocusScale();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (animatesSpriteForTesting) {
      _spriteController.update(dt);
    }
    if (_reduceMotion) {
      if (_typeIconPulseElapsed != 0) {
        _typeIconPulseElapsed = 0;
      }
      return;
    }
    if (_selected || _attackTarget) {
      _typeIconPulseElapsed =
          (_typeIconPulseElapsed + dt) % _typeIconPulsePeriod;
    } else if (_typeIconPulseElapsed != 0) {
      _typeIconPulseElapsed = 0;
    }
    if (hasFocusPulseForTesting) {
      _focusPulseElapsed =
          (_focusPulseElapsed + dt) % (_focusPulseDuration * 2);
      _syncFocusScale();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    UnitMarkerRenderer.render(canvas, _renderModel);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return UnitMarkerInputHandler.containsLocalPoint(
      point: point,
      markerContainsPoint: super.containsLocalPoint(point),
      typeIconRect: _typeIconRect,
      artifactBadgeRect: _artifactBadgeRect,
      carryingArtifact: carryingArtifact,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    UnitMarkerInputHandler.handleTap(onTap);
  }

  void playIdle() {
    _actionAnimationActive = false;
    _spriteController.playIdle();
  }

  void playWalkToward({required Vector2 from, required Vector2 to}) {
    _actionAnimationActive = true;
    _spriteController.playWalkToward(from: from, to: to);
  }

  void playAttack() {
    _actionAnimationActive = true;
    _spriteController.playAttack();
  }

  void playAttackToward({required Vector2 from, required Vector2 to}) {
    _actionAnimationActive = true;
    _spriteController.playAttackToward(from: from, to: to);
  }

  void playWork({bool animate = true}) {
    _actionAnimationActive = animate;
    _spriteController.playWork();
  }

  void playDie() {
    _actionAnimationActive = true;
    _spriteController.playDie();
  }

  int get spriteColumnForTesting => _spriteController.currentColumn;

  UnitSpriteAction? get spriteActionForTesting => _spriteController.action;

  bool get usesTypeIconBadgeForTesting => _spriteController.hasSpriteAsset;

  double get spriteStatusTopForTesting =>
      UnitMarkerRenderer.spriteStatusTop(_renderModel);

  Rect get typeIconRectForTesting => _typeIconRect;

  Rect get artifactBadgeRectForTesting => _artifactBadgeRect;

  double get typeIconPulseForTesting => _typeIconPulse;

  Rect get _artifactBadgeRect =>
      UnitMarkerRenderer.artifactBadgeRect(_renderModel);

  double get _typeIconPulse {
    if (!_selected && !_attackTarget) return 0;
    if (_reduceMotion) return 0;
    final radians =
        (_typeIconPulseElapsed / _typeIconPulsePeriod) * math.pi * 2;
    return (0.5 + math.sin(radians) * 0.5).clamp(0.0, 1.0).toDouble();
  }

  Rect get _typeIconRect => UnitMarkerRenderer.typeIconRect(_renderModel);

  bool get pendingActionTargetForTesting => pendingActionTarget;

  bool get attackTargetForTesting => attackTarget;

  bool get reduceMotionForTesting => _reduceMotion;

  bool get showPeripheralDetailsForTesting => showPeripheralDetails;

  bool get showOwnerColorForTesting => showOwnerColor;

  bool get showHealthBarForTesting => showHealthBar;

  bool get showTypeBadgeForTesting => showTypeBadge;

  bool get showStateBadgeForTesting => showStateBadge;

  bool get compactWorkVisualForTesting => compactWorkVisual;

  double get markerWorldScaleForTesting => _markerWorldScale;

  double get spriteScaleForTesting => _spriteScale;

  bool get animateIdleForTesting => _animateIdle;

  bool get spriteIdlePausesEnabledForTesting =>
      _spriteController.idlePausesEnabled;

  double get tacticalViewEmphasisForTesting => _tacticalViewEmphasis;

  UnitSpriteSize? get spriteRenderSizeForTesting =>
      UnitMarkerRenderer.spriteRenderSize(_renderModel);

  bool get paintsOwnerColorForTesting => _renderModel.paintsOwnerColor;

  bool get paintsTypeBadgeForTesting => _renderModel.paintsTypeBadge;

  bool get paintsIdentityBadgeForTesting => _renderModel.paintsIdentityBadge;

  bool get paintsHealthBarForTesting => _renderModel.paintsHealthBar;

  bool get paintsStateBadgeForTesting => _renderModel.paintsStateBadge;

  bool get hasFocusPulseForTesting =>
      !_reduceMotion && (_selected || _pendingActionTarget);

  bool get hasSelectionTintForTesting => false;

  bool get hasSelectionRingForTesting => false;

  Rect get selectionRingRectForTesting => Rect.zero;

  double get selectionRingStrokeWidthForTesting => 0;

  bool get animatesSpriteForTesting =>
      !_reduceMotion &&
      _spriteController.hasSpriteAsset &&
      (_spriteController.action != UnitSpriteAction.idle || _animateIdle);

  bool get hasAttackTargetTintForTesting =>
      _hasEffect(_attackTargetTintEffectKey);

  String? get workBadgeLabelForTesting => workBadgeLabel;

  bool get fortifiedForTesting => fortified;

  bool get skippedTurnForTesting => skippedTurn;

  bool get exhaustedForTesting => exhausted;

  bool get carryingArtifactForTesting => carryingArtifact;

  UnitMarkerStateBadge? get stateBadgeForTesting => _stateBadge;

  double get stateBadgeRadiusForTesting =>
      UnitMarkerBadgeStyle.stateBadgeRadiusFor(onCity: onCity);

  int get stateBadgeBackgroundAlphaForTesting =>
      UnitMarkerBadgeStyle.stateBadgeBackgroundAlpha;

  int get artifactBadgeBackgroundAlphaForTesting =>
      UnitMarkerBadgeStyle.artifactBadgeBackgroundAlpha;

  int get workBadgeBackgroundAlphaForTesting =>
      UnitMarkerBadgeStyle.workBadgeBackgroundAlpha;

  double get healthFractionForTesting => _healthFraction;

  Rect get spriteShadowRectForTesting =>
      UnitMarkerRenderer.spriteShadowRect(_renderModel);

  void _syncTintEffects() {
    _removeEffect(_attackTargetTintEffectKey);
    if (_attackTarget) {
      if (_reduceMotion) {
        paint.colorFilter = ColorFilter.mode(
          HudPaint.color(HudPalette.danger, alpha: MapAlpha.faint),
          BlendMode.srcATop,
        );
      } else {
        paint.colorFilter = null;
        _ensureAttackTargetTintEffect();
      }
      return;
    }
    paint.colorFilter = null;
  }

  void _syncFocusScale({bool resetElapsed = false}) {
    if (resetElapsed) {
      _focusPulseElapsed = 0;
    }
    final shouldPulse = _selected || _pendingActionTarget;
    if (!shouldPulse) {
      scale = Vector2.all(_markerWorldScale);
      return;
    }
    if (_reduceMotion) {
      final focusScale = _pendingActionTarget ? _staticPendingActionScale : 1.0;
      scale = Vector2.all(_markerWorldScale * focusScale);
      return;
    }

    final phase = _focusPulseElapsed / _focusPulseDuration;
    final eased = Curves.easeInOut.transform(math.sin(phase * math.pi).abs());
    final focusScale = 1 + (_focusedScale - 1) * eased;
    scale = Vector2.all(_markerWorldScale * focusScale);
  }

  void _syncIdlePauseBehavior() {
    _spriteController.idlePausesEnabled = !_selected;
  }

  void _ensureAttackTargetTintEffect() {
    if (_hasEffect(_attackTargetTintEffectKey)) return;
    final effect = ColorEffect(
      HudPalette.danger,
      EffectController(
        duration: 0.45,
        alternate: true,
        infinite: true,
        curve: Curves.easeInOut,
      ),
      opacityFrom: 0.05,
      opacityTo: 0.35,
      key: _attackTargetTintEffectKey,
    )..target = this;
    unawaited(Future<void>.value(add(effect)));
  }

  bool _hasEffect(ComponentKey key) {
    return children.any((component) => component.key == key);
  }

  void _removeEffect(ComponentKey key) {
    removeWhere((component) => component.key == key);
  }

  UnitMarkerStateBadge? get _stateBadge {
    return UnitMarkerStateBadgeResolver.resolve(
      fortified: fortified,
      skippedTurn: skippedTurn,
      exhausted: exhausted,
      healthFraction: _healthFraction,
    );
  }

  static double _normalizeMarkerWorldScale(double value) =>
      value.isFinite ? value.clamp(1.0, 3.0).toDouble() : 1.0;

  static double _normalizeSpriteScale(double value) =>
      value.isFinite ? value.clamp(0.5, 1.0).toDouble() : 1.0;

  static double _normalizeTacticalViewEmphasis(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;

  UnitMarkerRenderModel get _renderModel => UnitMarkerRenderModel(
    playerColor: Color(colorValue),
    unitType: unitType,
    sprite: _spriteController.sprite,
    paint: paint,
    selected: _selected,
    pendingActionTarget: _pendingActionTarget,
    attackTarget: _attackTarget,
    healthFraction: _healthFraction,
    onCity: onCity,
    workBadgeLabel: workBadgeLabel,
    exhausted: exhausted,
    carryingArtifact: carryingArtifact,
    showOwnerColor: showOwnerColor,
    showHealthBar: showHealthBar,
    showTypeBadge: showTypeBadge,
    showStateBadge: showStateBadge,
    compactWorkVisual: compactWorkVisual,
    spriteScale: _spriteScale,
    tacticalViewEmphasis: _tacticalViewEmphasis,
    typeIconPulse: _typeIconPulse,
    stateBadge: _stateBadge,
  );
}
