import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:aonw/game/presentation/engine/rendering_layers/marker_health_bar.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/sprite_shadow.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_badges.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_fallback_painter.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_input_handler.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_sprite_controller.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_type_icon_resolver.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_sprite.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
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

  static const double _radius = 16.0;
  static const double _size = _radius * 2;

  // Mirrors MarkerHealthBar's type/owner + health stack above the unit sprite.
  static const double _statusBarsExtentAboveTop = 27.0;
  static const double _workBadgeGapAboveBars = 3.0;
  static const double _spriteVerticalLiftFactor = 0.16;
  static const double _fallbackSpriteStatusInset = 9.0;
  static const double _fallbackSmallSpriteStatusInset = 6.0;
  static const double _containedStatusTopOffset = -2.0;
  static const double _tacticalStatusTopOffset = 15.0;
  static const double _statusCoverStartEmphasis = 0.72;
  static const double _tacticalStatusWidth = 24.0;
  static const double _typeIconPulsePeriod = 1.15;
  static const List<double> _exhaustedColorMatrix = [
    0.6264,
    0.1759,
    0.0177,
    0,
    0,
    0.0524,
    0.7499,
    0.0177,
    0,
    0,
    0.0524,
    0.1759,
    0.5917,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
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
         size: Vector2.all(_size),
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
    final playerColor = Color(colorValue);

    if (onCity) {
      _renderSmall(canvas, playerColor);
    } else {
      _renderNormal(canvas, playerColor);
    }
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

  void _renderNormal(Canvas canvas, Color playerColor) {
    const center = Offset(_radius, _radius);
    SpriteShadow.paint3d(
      canvas,
      spriteShadowRectForTesting,
      color: SpriteShadow.unitColor,
    );
    final sprite = _spriteController.sprite;
    if (sprite != null) {
      _renderSpriteUnit(
        canvas,
        sprite: sprite,
        playerColor: playerColor,
        center: center,
      );
      return;
    }

    final fallbackSize = compactWorkVisual
        ? UnitMarkerFallbackSize.small
        : UnitMarkerFallbackSize.normal;

    _paintPossiblyExhausted(
      canvas,
      const Rect.fromLTWH(0, 0, _size, _size).inflate(4),
      () => UnitMarkerFallbackPainter.paint(
        canvas,
        center: center,
        playerColor: playerColor,
        icon: _typeIcon,
        markerSize: fallbackSize,
        selected: false,
      ),
    );
    final statusTop = _statusTopForZoom(
      center,
      UnitMarkerFallbackPainter.statusTopFor(center, fallbackSize),
    );
    final statusWidth = _statusWidthForZoom(
      UnitMarkerFallbackPainter.statusWidthFor(fallbackSize),
    );
    _drawStatusBars(
      canvas,
      center: center,
      top: statusTop,
      width: statusWidth,
      playerColor: playerColor,
      typeIcon: _typeIcon,
    );
    _drawWorkBadge(
      canvas,
      center: center,
      top: statusTop,
      playerColor: playerColor,
    );
    _drawStateBadge(canvas, center: center);
    _drawArtifactBadge(canvas, center: center);
  }

  void _renderSmall(Canvas canvas, Color playerColor) {
    const center = Offset(_radius, _radius);
    SpriteShadow.paint3d(
      canvas,
      spriteShadowRectForTesting,
      color: SpriteShadow.unitColor,
    );
    final sprite = _spriteController.sprite;
    if (sprite != null) {
      _renderSpriteUnit(
        canvas,
        sprite: sprite,
        playerColor: playerColor,
        center: center,
      );
      return;
    }

    _paintPossiblyExhausted(
      canvas,
      const Rect.fromLTWH(0, 0, _size, _size).inflate(4),
      () => UnitMarkerFallbackPainter.paint(
        canvas,
        center: center,
        playerColor: playerColor,
        icon: _typeIcon,
        markerSize: UnitMarkerFallbackSize.small,
        selected: false,
      ),
    );
    final statusTop = _statusTopForZoom(
      center,
      UnitMarkerFallbackPainter.statusTopFor(
        center,
        UnitMarkerFallbackSize.small,
      ),
    );
    final statusWidth = _statusWidthForZoom(
      UnitMarkerFallbackPainter.statusWidthFor(UnitMarkerFallbackSize.small),
    );
    _drawStatusBars(
      canvas,
      center: center,
      top: statusTop,
      width: statusWidth,
      playerColor: playerColor,
      typeIcon: _typeIcon,
    );
    _drawWorkBadge(
      canvas,
      center: center,
      top: statusTop,
      playerColor: playerColor,
    );
    _drawStateBadge(canvas, center: center);
    _drawArtifactBadge(canvas, center: center);
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

  void _renderSpriteUnit(
    Canvas canvas, {
    required UnitSpriteComponent sprite,
    required Color playerColor,
    required Offset center,
  }) {
    final size = _spriteSizeFor(sprite);
    final width = size.width;
    final statusTop = _statusTopForZoom(
      center,
      _spriteStatusTopFor(center: center, sprite: sprite, size: size),
    );
    final statusWidth = _statusWidthForZoom(math.max(28, width * 0.68));

    _paintUnitSprite(canvas, sprite: sprite, center: center);
    _drawStatusBars(
      canvas,
      center: center,
      top: statusTop,
      width: statusWidth,
      playerColor: playerColor,
      typeIcon: _typeIcon,
    );
    _drawWorkBadge(
      canvas,
      center: center,
      top: statusTop,
      playerColor: playerColor,
    );
    _drawStateBadge(canvas, center: center);
    _drawArtifactBadge(canvas, center: center);
  }

  double _spriteTopFor({required Offset center, required double height}) {
    return center.dy - height * (0.5 + _spriteVerticalLiftFactor);
  }

  double _spriteStatusTopFor({
    required Offset center,
    required UnitSpriteComponent sprite,
    required UnitSpriteSize size,
  }) {
    final height = size.height;
    final spriteTop = _spriteTopFor(center: center, height: height);
    final contentTopOffset = sprite.visibleContentTopOffsetFor(size);
    if (contentTopOffset != null) return spriteTop + contentTopOffset;
    return spriteTop +
        (onCity || compactWorkVisual
            ? _fallbackSmallSpriteStatusInset
            : _fallbackSpriteStatusInset);
  }

  double _statusTopForZoom(Offset center, double baseTop) {
    final containedTop = math.max(
      baseTop,
      center.dy + _containedStatusTopOffset,
    );
    final tuckT = (_tacticalViewEmphasis / _statusCoverStartEmphasis)
        .clamp(0.0, 1.0)
        .toDouble();
    final coverT =
        ((_tacticalViewEmphasis - _statusCoverStartEmphasis) /
                (1.0 - _statusCoverStartEmphasis))
            .clamp(0.0, 1.0)
            .toDouble();
    final tuckedTop = lerpDouble(
      baseTop,
      containedTop,
      Curves.easeOutCubic.transform(tuckT),
    )!;
    return lerpDouble(
      tuckedTop,
      center.dy + _tacticalStatusTopOffset,
      Curves.easeInCubic.transform(coverT),
    )!;
  }

  double _statusWidthForZoom(double baseWidth) {
    return lerpDouble(baseWidth, _tacticalStatusWidth, _tacticalViewEmphasis)!;
  }

  void _drawStatusBars(
    Canvas canvas, {
    required Offset center,
    required double top,
    required double width,
    required Color playerColor,
    GameIconData? typeIcon,
  }) {
    final paintIdentity = paintsIdentityBadgeForTesting;
    final paintHealth = paintsHealthBarForTesting;
    final icon = typeIcon;
    if (!paintIdentity && !paintHealth) return;

    if (paintsTypeBadgeForTesting && icon != null) {
      MarkerHealthBar.paintTypeIconBadge(
        canvas,
        center: center,
        top: top,
        width: width,
        icon: icon,
        backgroundColor: playerColor,
        active: _selected || _attackTarget,
        activePulse: _typeIconPulse,
        activeColor: _attackTarget ? HudPalette.danger : null,
      );
    } else if (paintsOwnerColorForTesting) {
      MarkerHealthBar.paintOwnerIndicator(
        canvas,
        center: center,
        top: top,
        width: width,
        color: playerColor,
      );
    }
    if (!paintHealth) return;
    MarkerHealthBar.paint(
      canvas,
      center: center,
      top: top,
      width: width,
      fraction: _healthFraction,
    );
  }

  void _paintUnitSprite(
    Canvas canvas, {
    required UnitSpriteComponent sprite,
    required Offset center,
  }) {
    final size = _spriteSizeFor(sprite);
    final width = size.width;
    final height = size.height;
    final destination = Rect.fromCenter(
      center: Offset(center.dx, center.dy - height * _spriteVerticalLiftFactor),
      width: width,
      height: height,
    );

    if (!sprite.isReady) {
      // Sprite atlas hasn't loaded yet — fall back to icon and keep the
      // saveLayer-based exhausted tint for parity.
      _paintPossiblyExhausted(canvas, destination.inflate(28), () {
        final fallbackSize = width * 0.58;
        GameIconRenderer.paintIcon(
          canvas,
          _typeIcon,
          topLeft: Offset(
            center.dx - fallbackSize / 2,
            center.dy - fallbackSize / 2,
          ),
          size: fallbackSize,
          color: HudPalette.goldLight,
        );
      });
      return;
    }

    // Ready sprite path: bypass saveLayer by attaching the exhausted color
    // matrix directly to the sprite's paint. This avoids the off-screen
    // buffer that saveLayer allocates per exhausted unit, which Impeller
    // treats as a hard sync point.
    sprite
      ..size.setValues(width, height)
      ..paint = (paint..filterQuality = FilterQuality.medium);

    final previousColorFilter = exhausted ? paint.colorFilter : null;
    if (exhausted) {
      paint.colorFilter = const ColorFilter.matrix(_exhaustedColorMatrix);
    }

    canvas.save();
    if (sprite.isMirrored) {
      canvas
        ..translate(destination.right, destination.top)
        ..scale(-1, 1);
    } else {
      canvas.translate(destination.left, destination.top);
    }
    sprite.render(canvas);
    canvas.restore();

    if (exhausted) {
      paint.colorFilter = previousColorFilter;
    }
  }

  UnitSpriteSize _spriteSizeFor(UnitSpriteComponent sprite) {
    final base = sprite.sizeFor(onCity: onCity);
    final scale = compactWorkVisual ? 0.72 * _spriteScale : _spriteScale;
    return UnitSpriteSize(
      width: base.width * scale,
      height: base.height * scale,
    );
  }

  UnitMarkerFallbackSize get _fallbackMarkerSize => onCity || compactWorkVisual
      ? UnitMarkerFallbackSize.small
      : UnitMarkerFallbackSize.normal;

  int get spriteColumnForTesting => _spriteController.currentColumn;

  UnitSpriteAction? get spriteActionForTesting => _spriteController.action;

  bool get usesTypeIconBadgeForTesting => _spriteController.hasSpriteAsset;

  double get spriteStatusTopForTesting {
    const center = Offset(_radius, _radius);
    final sprite = _spriteController.sprite;
    if (sprite == null) {
      return _statusTopForZoom(
        center,
        UnitMarkerFallbackPainter.statusTopFor(center, _fallbackMarkerSize),
      );
    }
    final size = _spriteSizeFor(sprite);
    return _statusTopForZoom(
      center,
      _spriteStatusTopFor(center: center, sprite: sprite, size: size),
    );
  }

  Rect get typeIconRectForTesting => _typeIconRect;

  Rect get artifactBadgeRectForTesting => _artifactBadgeRect;

  double get typeIconPulseForTesting => _typeIconPulse;

  Rect get _artifactBadgeRect => UnitMarkerBadgeStyle.artifactBadgeRect(
    center: const Offset(_radius, _radius),
    onCity: onCity,
  );

  GameIconData get _typeIcon => UnitMarkerTypeIconResolver.iconFor(unitType);

  double get _typeIconPulse {
    if (!_selected && !_attackTarget) return 0;
    if (_reduceMotion) return 0;
    final radians =
        (_typeIconPulseElapsed / _typeIconPulsePeriod) * math.pi * 2;
    return (0.5 + math.sin(radians) * 0.5).clamp(0.0, 1.0).toDouble();
  }

  Rect get _typeIconRect {
    const center = Offset(_radius, _radius);
    final sprite = _spriteController.sprite;
    if (sprite == null) {
      final top = _statusTopForZoom(
        center,
        UnitMarkerFallbackPainter.statusTopFor(center, _fallbackMarkerSize),
      );
      final width = _statusWidthForZoom(
        UnitMarkerFallbackPainter.statusWidthFor(_fallbackMarkerSize),
      );
      return MarkerHealthBar.typeIconBadgeRect(
        center: center,
        top: top,
        width: width,
      );
    }

    final size = _spriteSizeFor(sprite);
    final top = _statusTopForZoom(
      center,
      _spriteStatusTopFor(center: center, sprite: sprite, size: size),
    );
    final width = _statusWidthForZoom(math.max(28, size.width * 0.68));
    return MarkerHealthBar.typeIconBadgeRect(
      center: center,
      top: top,
      width: width,
    );
  }

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

  UnitSpriteSize? get spriteRenderSizeForTesting {
    final sprite = _spriteController.sprite;
    return sprite == null ? null : _spriteSizeFor(sprite);
  }

  bool get _focusedMarker => _selected || _pendingActionTarget || _attackTarget;

  bool get paintsOwnerColorForTesting => showOwnerColor || _focusedMarker;

  bool get paintsTypeBadgeForTesting => showTypeBadge || _focusedMarker;

  bool get paintsIdentityBadgeForTesting =>
      paintsOwnerColorForTesting || paintsTypeBadgeForTesting;

  bool get paintsHealthBarForTesting =>
      (showHealthBar || _focusedMarker || _healthFraction < 0.995);

  bool get paintsStateBadgeForTesting =>
      _stateBadge != null && (showStateBadge || _focusedMarker);

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

  Rect get spriteShadowRectForTesting {
    final rect = SpriteShadow.unitRect(
      center: const Offset(_radius, _radius),
      onCity: onCity || compactWorkVisual,
    );
    return _scaleRectFromCenter(rect);
  }

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

  void _paintPossiblyExhausted(
    Canvas canvas,
    Rect bounds,
    VoidCallback painter,
  ) {
    if (!exhausted) {
      painter();
      return;
    }

    canvas.saveLayer(bounds, HudPaint.matrixColorFilter(_exhaustedColorMatrix));
    painter();
    canvas.restore();
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

  Rect _scaleRectFromCenter(Rect rect) {
    if (_spriteScale == 1) return rect;
    return Rect.fromCenter(
      center: rect.center,
      width: rect.width * _spriteScale,
      height: rect.height * _spriteScale,
    );
  }

  void _drawStateBadge(Canvas canvas, {required Offset center}) {
    final badge = _stateBadge;
    if (badge == null || !paintsStateBadgeForTesting) return;

    UnitMarkerBadgePainter.paintStateBadge(
      canvas,
      center: center,
      badge: badge,
      onCity: onCity,
    );
  }

  void _drawArtifactBadge(Canvas canvas, {required Offset center}) {
    if (!carryingArtifact) return;

    UnitMarkerBadgePainter.paintArtifactBadge(
      canvas,
      center: center,
      onCity: onCity,
    );
  }

  void _drawWorkBadge(
    Canvas canvas, {
    required Offset center,
    required double top,
    required Color playerColor,
  }) {
    final label = workBadgeLabel;
    if (label == null || label.isEmpty) return;

    UnitMarkerBadgePainter.paintWorkBadge(
      canvas,
      center: center,
      top: top,
      playerColor: playerColor,
      label: label,
      statusBarsExtentAboveTop: _statusBarsExtentAboveTop,
      gapAboveBars: _workBadgeGapAboveBars,
    );
  }
}
