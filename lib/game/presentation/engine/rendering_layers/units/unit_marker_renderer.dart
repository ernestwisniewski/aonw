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

part 'unit_marker_renderer_details.dart';
part 'unit_marker_renderer_layout.dart';
part 'unit_marker_renderer_sprite.dart';

const double _statusBarsExtentAboveTop = 27.0;
const double _workBadgeGapAboveBars = 3.0;
const double _spriteVerticalLiftFactor = 0.16;
const double _fallbackSpriteStatusInset = 9.0;
const double _fallbackSmallSpriteStatusInset = 6.0;
const double _containedStatusTopOffset = -2.0;
const double _tacticalStatusTopOffset = 15.0;
const double _statusCoverStartEmphasis = 0.72;
const double _tacticalStatusWidth = 24.0;
const List<double> _exhaustedColorMatrix = [
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
}
