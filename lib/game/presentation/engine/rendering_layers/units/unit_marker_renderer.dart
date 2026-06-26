import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:aonw/game/presentation/engine/rendering_layers/effects/sprite_shadow.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/marker_health_bar.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_badges.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_fallback_painter.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_type_icon_resolver.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class UnitMarkerRenderModel {
  final Color playerColor;
  final GameUnitType unitType;
  final UnitSpriteComponent? sprite;
  final Paint paint;
  final bool selected;
  final bool pendingActionTarget;
  final bool attackTarget;
  final double healthFraction;
  final bool onCity;
  final String? workBadgeLabel;
  final bool exhausted;
  final bool carryingArtifact;
  final bool showOwnerColor;
  final bool showHealthBar;
  final bool showTypeBadge;
  final bool showStateBadge;
  final bool compactWorkVisual;
  final double spriteScale;
  final double tacticalViewEmphasis;
  final double typeIconPulse;
  final UnitMarkerStateBadge? stateBadge;

  const UnitMarkerRenderModel({
    required this.playerColor,
    required this.unitType,
    required this.sprite,
    required this.paint,
    required this.selected,
    required this.pendingActionTarget,
    required this.attackTarget,
    required this.healthFraction,
    required this.onCity,
    required this.workBadgeLabel,
    required this.exhausted,
    required this.carryingArtifact,
    required this.showOwnerColor,
    required this.showHealthBar,
    required this.showTypeBadge,
    required this.showStateBadge,
    required this.compactWorkVisual,
    required this.spriteScale,
    required this.tacticalViewEmphasis,
    required this.typeIconPulse,
    required this.stateBadge,
  });

  bool get focusedMarker => selected || pendingActionTarget || attackTarget;

  bool get paintsOwnerColor => showOwnerColor || focusedMarker;

  bool get paintsTypeBadge => showTypeBadge || focusedMarker;

  bool get paintsIdentityBadge => paintsOwnerColor || paintsTypeBadge;

  bool get paintsHealthBar =>
      showHealthBar || focusedMarker || healthFraction < 0.995;

  bool get paintsStateBadge =>
      stateBadge != null && (showStateBadge || focusedMarker);

  GameIconData get typeIcon => UnitMarkerTypeIconResolver.iconFor(unitType);

  UnitMarkerFallbackSize get fallbackMarkerSize =>
      UnitMarkerRenderer.fallbackMarkerSizeFor(
        onCity: onCity,
        compactWorkVisual: compactWorkVisual,
      );
}

abstract final class UnitMarkerRenderer {
  static const double radius = 16.0;
  static const double markerSize = radius * 2;

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

  static void render(Canvas canvas, UnitMarkerRenderModel model) {
    final sprite = model.sprite;
    if (sprite != null) {
      _renderSpriteUnit(canvas, model, sprite);
      return;
    }
    _renderFallbackUnit(canvas, model);
  }

  static UnitMarkerFallbackSize fallbackMarkerSizeFor({
    required bool onCity,
    required bool compactWorkVisual,
  }) {
    return onCity || compactWorkVisual
        ? UnitMarkerFallbackSize.small
        : UnitMarkerFallbackSize.normal;
  }

  static double spriteStatusTop(UnitMarkerRenderModel model) {
    const center = Offset(radius, radius);
    final sprite = model.sprite;
    if (sprite == null) {
      return _statusTopForZoom(
        center,
        UnitMarkerFallbackPainter.statusTopFor(
          center,
          model.fallbackMarkerSize,
        ),
        model.tacticalViewEmphasis,
      );
    }
    final size = spriteSizeFor(sprite, model);
    return _statusTopForZoom(
      center,
      _spriteStatusTopFor(
        center: center,
        sprite: sprite,
        size: size,
        onCity: model.onCity,
        compactWorkVisual: model.compactWorkVisual,
      ),
      model.tacticalViewEmphasis,
    );
  }

  static Rect typeIconRect(UnitMarkerRenderModel model) {
    const center = Offset(radius, radius);
    final sprite = model.sprite;
    if (sprite == null) {
      final top = _statusTopForZoom(
        center,
        UnitMarkerFallbackPainter.statusTopFor(
          center,
          model.fallbackMarkerSize,
        ),
        model.tacticalViewEmphasis,
      );
      final width = _statusWidthForZoom(
        UnitMarkerFallbackPainter.statusWidthFor(model.fallbackMarkerSize),
        model.tacticalViewEmphasis,
      );
      return MarkerHealthBar.typeIconBadgeRect(
        center: center,
        top: top,
        width: width,
      );
    }

    final size = spriteSizeFor(sprite, model);
    final top = _statusTopForZoom(
      center,
      _spriteStatusTopFor(
        center: center,
        sprite: sprite,
        size: size,
        onCity: model.onCity,
        compactWorkVisual: model.compactWorkVisual,
      ),
      model.tacticalViewEmphasis,
    );
    final width = _statusWidthForZoom(
      math.max(28, size.width * 0.68),
      model.tacticalViewEmphasis,
    );
    return MarkerHealthBar.typeIconBadgeRect(
      center: center,
      top: top,
      width: width,
    );
  }

  static Rect artifactBadgeRect(UnitMarkerRenderModel model) {
    return UnitMarkerBadgeStyle.artifactBadgeRect(
      center: const Offset(radius, radius),
      onCity: model.onCity,
    );
  }

  static UnitSpriteSize? spriteRenderSize(UnitMarkerRenderModel model) {
    final sprite = model.sprite;
    return sprite == null ? null : spriteSizeFor(sprite, model);
  }

  static Rect spriteShadowRect(UnitMarkerRenderModel model) {
    final rect = SpriteShadow.unitRect(
      center: const Offset(radius, radius),
      onCity: model.onCity || model.compactWorkVisual,
    );
    return _scaleRectFromCenter(rect, model.spriteScale);
  }

  static UnitSpriteSize spriteSizeFor(
    UnitSpriteComponent sprite,
    UnitMarkerRenderModel model,
  ) {
    final base = sprite.sizeFor(onCity: model.onCity);
    final scale = model.compactWorkVisual
        ? 0.72 * model.spriteScale
        : model.spriteScale;
    return UnitSpriteSize(
      width: base.width * scale,
      height: base.height * scale,
    );
  }

  static void _renderFallbackUnit(Canvas canvas, UnitMarkerRenderModel model) {
    const center = Offset(radius, radius);
    SpriteShadow.paint3d(
      canvas,
      spriteShadowRect(model),
      color: SpriteShadow.unitColor,
    );

    _paintPossiblyExhausted(
      canvas,
      model,
      const Rect.fromLTWH(0, 0, markerSize, markerSize).inflate(4),
      () => UnitMarkerFallbackPainter.paint(
        canvas,
        center: center,
        playerColor: model.playerColor,
        icon: model.typeIcon,
        markerSize: model.fallbackMarkerSize,
        selected: false,
      ),
    );

    final statusTop = _statusTopForZoom(
      center,
      UnitMarkerFallbackPainter.statusTopFor(center, model.fallbackMarkerSize),
      model.tacticalViewEmphasis,
    );
    final statusWidth = _statusWidthForZoom(
      UnitMarkerFallbackPainter.statusWidthFor(model.fallbackMarkerSize),
      model.tacticalViewEmphasis,
    );
    _drawUnitDetails(
      canvas,
      model,
      center: center,
      statusTop: statusTop,
      statusWidth: statusWidth,
    );
  }

  static void _renderSpriteUnit(
    Canvas canvas,
    UnitMarkerRenderModel model,
    UnitSpriteComponent sprite,
  ) {
    const center = Offset(radius, radius);
    SpriteShadow.paint3d(
      canvas,
      spriteShadowRect(model),
      color: SpriteShadow.unitColor,
    );

    final size = spriteSizeFor(sprite, model);
    final statusTop = _statusTopForZoom(
      center,
      _spriteStatusTopFor(
        center: center,
        sprite: sprite,
        size: size,
        onCity: model.onCity,
        compactWorkVisual: model.compactWorkVisual,
      ),
      model.tacticalViewEmphasis,
    );
    final statusWidth = _statusWidthForZoom(
      math.max(28, size.width * 0.68),
      model.tacticalViewEmphasis,
    );

    _paintUnitSprite(canvas, model, sprite: sprite, center: center);
    _drawUnitDetails(
      canvas,
      model,
      center: center,
      statusTop: statusTop,
      statusWidth: statusWidth,
    );
  }

  static void _drawUnitDetails(
    Canvas canvas,
    UnitMarkerRenderModel model, {
    required Offset center,
    required double statusTop,
    required double statusWidth,
  }) {
    _drawStatusBars(
      canvas,
      model,
      center: center,
      top: statusTop,
      width: statusWidth,
    );
    _drawWorkBadge(canvas, model, center: center, top: statusTop);
    _drawStateBadge(canvas, model, center: center);
    _drawArtifactBadge(canvas, model, center: center);
  }

  static double _spriteTopFor({
    required Offset center,
    required double height,
  }) {
    return center.dy - height * (0.5 + _spriteVerticalLiftFactor);
  }

  static double _spriteStatusTopFor({
    required Offset center,
    required UnitSpriteComponent sprite,
    required UnitSpriteSize size,
    required bool onCity,
    required bool compactWorkVisual,
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

  static double _statusTopForZoom(
    Offset center,
    double baseTop,
    double tacticalViewEmphasis,
  ) {
    final containedTop = math.max(
      baseTop,
      center.dy + _containedStatusTopOffset,
    );
    final tuckT = (tacticalViewEmphasis / _statusCoverStartEmphasis)
        .clamp(0.0, 1.0)
        .toDouble();
    final coverT =
        ((tacticalViewEmphasis - _statusCoverStartEmphasis) /
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

  static double _statusWidthForZoom(
    double baseWidth,
    double tacticalViewEmphasis,
  ) {
    return lerpDouble(baseWidth, _tacticalStatusWidth, tacticalViewEmphasis)!;
  }

  static void _drawStatusBars(
    Canvas canvas,
    UnitMarkerRenderModel model, {
    required Offset center,
    required double top,
    required double width,
  }) {
    if (!model.paintsIdentityBadge && !model.paintsHealthBar) return;

    if (model.paintsTypeBadge) {
      MarkerHealthBar.paintTypeIconBadge(
        canvas,
        center: center,
        top: top,
        width: width,
        icon: model.typeIcon,
        backgroundColor: model.playerColor,
        active: model.selected || model.attackTarget,
        activePulse: model.typeIconPulse,
        activeColor: model.attackTarget ? HudPalette.danger : null,
      );
    } else if (model.paintsOwnerColor) {
      MarkerHealthBar.paintOwnerIndicator(
        canvas,
        center: center,
        top: top,
        width: width,
        color: model.playerColor,
      );
    }
    if (!model.paintsHealthBar) return;
    MarkerHealthBar.paint(
      canvas,
      center: center,
      top: top,
      width: width,
      fraction: model.healthFraction,
    );
  }

  static void _paintUnitSprite(
    Canvas canvas,
    UnitMarkerRenderModel model, {
    required UnitSpriteComponent sprite,
    required Offset center,
  }) {
    final size = spriteSizeFor(sprite, model);
    final width = size.width;
    final height = size.height;
    final destination = Rect.fromCenter(
      center: Offset(center.dx, center.dy - height * _spriteVerticalLiftFactor),
      width: width,
      height: height,
    );

    if (!sprite.isReady) {
      // Sprite atlas hasn't loaded yet - fall back to icon and keep the
      // saveLayer-based exhausted tint for parity.
      _paintPossiblyExhausted(canvas, model, destination.inflate(28), () {
        final fallbackSize = width * 0.58;
        GameIconRenderer.paintIcon(
          canvas,
          model.typeIcon,
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
      ..paint = (model.paint..filterQuality = FilterQuality.medium);

    final previousColorFilter = model.exhausted
        ? model.paint.colorFilter
        : null;
    if (model.exhausted) {
      model.paint.colorFilter = const ColorFilter.matrix(_exhaustedColorMatrix);
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

    if (model.exhausted) {
      model.paint.colorFilter = previousColorFilter;
    }
  }

  static void _paintPossiblyExhausted(
    Canvas canvas,
    UnitMarkerRenderModel model,
    Rect bounds,
    VoidCallback painter,
  ) {
    if (!model.exhausted) {
      painter();
      return;
    }

    canvas.saveLayer(bounds, HudPaint.matrixColorFilter(_exhaustedColorMatrix));
    painter();
    canvas.restore();
  }

  static Rect _scaleRectFromCenter(Rect rect, double spriteScale) {
    if (spriteScale == 1) return rect;
    return Rect.fromCenter(
      center: rect.center,
      width: rect.width * spriteScale,
      height: rect.height * spriteScale,
    );
  }

  static void _drawStateBadge(
    Canvas canvas,
    UnitMarkerRenderModel model, {
    required Offset center,
  }) {
    final badge = model.stateBadge;
    if (badge == null || !model.paintsStateBadge) return;

    UnitMarkerBadgePainter.paintStateBadge(
      canvas,
      center: center,
      badge: badge,
      onCity: model.onCity,
    );
  }

  static void _drawArtifactBadge(
    Canvas canvas,
    UnitMarkerRenderModel model, {
    required Offset center,
  }) {
    if (!model.carryingArtifact) return;

    UnitMarkerBadgePainter.paintArtifactBadge(
      canvas,
      center: center,
      onCity: model.onCity,
    );
  }

  static void _drawWorkBadge(
    Canvas canvas,
    UnitMarkerRenderModel model, {
    required Offset center,
    required double top,
  }) {
    final label = model.workBadgeLabel;
    if (label == null || label.isEmpty) return;

    UnitMarkerBadgePainter.paintWorkBadge(
      canvas,
      center: center,
      top: top,
      playerColor: model.playerColor,
      label: label,
      statusBarsExtentAboveTop: _statusBarsExtentAboveTop,
      gapAboveBars: _workBadgeGapAboveBars,
    );
  }
}
