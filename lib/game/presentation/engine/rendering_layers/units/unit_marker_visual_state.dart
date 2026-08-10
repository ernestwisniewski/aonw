part of 'unit_marker.dart';

extension _UnitMarkerVisualState on UnitMarker {
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

double _normalizeMarkerWorldScale(double value) =>
    value.isFinite ? value.clamp(1.0, 3.0).toDouble() : 1.0;

double _normalizeSpriteScale(double value) =>
    value.isFinite ? value.clamp(0.5, 1.0).toDouble() : 1.0;

double _normalizeTacticalViewEmphasis(double value) =>
    value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
