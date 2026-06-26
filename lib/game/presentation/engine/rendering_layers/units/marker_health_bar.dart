import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';

class MarkerHealthBar {
  const MarkerHealthBar._();

  static const double _height = 4.0;
  static const double _gap = 6.0;
  static const double _ownerHeight = 7.0;
  static const double _ownerGap = 2.0;
  static const double _strokeWidth = 1.0;
  static const double _typeBadgeSize = 15.0;
  static const double _typeBadgeIconSize = 9.5;
  static const double activeGlowInflateForTesting = 3.2;
  static const int activeGlowAlphaForTesting = 42;
  static const double verticalFootprint = _gap + _height;
  static const Color _activeColor = HudPalette.gold;

  static Color healthColorForFraction(double fraction) {
    final clampedFraction = fraction.clamp(0.0, 1.0).toDouble();
    if (clampedFraction >= 0.5) {
      return Color.lerp(
        HudPalette.warning,
        HudPalette.success,
        (clampedFraction - 0.5) / 0.5,
      )!;
    }
    return Color.lerp(
      HudPalette.danger,
      HudPalette.warning,
      clampedFraction / 0.5,
    )!;
  }

  static void paint(
    Canvas canvas, {
    required Offset center,
    required double top,
    required double width,
    double fraction = 1.0,
  }) {
    final clampedFraction = fraction.clamp(0.0, 1.0).toDouble();
    final outerRect = _healthRect(center: center, top: top, width: width);
    final innerRect = outerRect.deflate(_strokeWidth);
    final fillRect = Rect.fromLTWH(
      innerRect.left,
      innerRect.top,
      innerRect.width * clampedFraction,
      innerRect.height,
    );
    const outerRadius = Radius.circular(_height / 2);
    final innerRadius = Radius.circular(innerRect.height / 2);
    final outerRRect = RRect.fromRectAndRadius(outerRect, outerRadius);

    canvas
      ..drawRRect(outerRRect, HudPaint.shadow(alpha: MapAlpha.strong))
      ..drawRRect(
        RRect.fromRectAndRadius(fillRect, innerRadius),
        HudPaint.fill(healthColorForFraction(clampedFraction)),
      )
      ..drawRRect(
        outerRRect,
        HudPaint.stroke(
          HudPalette.textBright,
          alpha: MapAlpha.solid,
          strokeWidth: _strokeWidth,
        ),
      );
  }

  static void paintOwnerIndicator(
    Canvas canvas, {
    required Offset center,
    required double top,
    required double width,
    required Color color,
  }) {
    final healthRect = _healthRect(center: center, top: top, width: width);
    final outerRect = Rect.fromLTWH(
      healthRect.left,
      healthRect.top - _ownerGap - _ownerHeight,
      width,
      _ownerHeight,
    );
    const outerRadius = Radius.circular(_ownerHeight / 2);
    final outerRRect = RRect.fromRectAndRadius(outerRect, outerRadius);

    canvas
      ..drawRRect(outerRRect, HudPaint.shadow(alpha: MapAlpha.strong))
      ..drawRRect(
        RRect.fromRectAndRadius(
          outerRect.deflate(_strokeWidth),
          const Radius.circular((_ownerHeight - _strokeWidth * 2) / 2),
        ),
        HudPaint.fill(color),
      )
      ..drawRRect(
        outerRRect,
        HudPaint.stroke(
          HudPalette.textBright,
          alpha: MapAlpha.solid,
          strokeWidth: _strokeWidth,
        ),
      );
  }

  static Rect typeIconBadgeRect({
    required Offset center,
    required double top,
    required double width,
  }) {
    final healthRect = _healthRect(center: center, top: top, width: width);
    return Rect.fromCenter(
      center: Offset(
        center.dx,
        healthRect.top - _ownerGap - _typeBadgeSize / 2,
      ),
      width: _typeBadgeSize,
      height: _typeBadgeSize,
    );
  }

  static Rect healthRect({
    required Offset center,
    required double top,
    required double width,
  }) => _healthRect(center: center, top: top, width: width);

  static Rect paintTypeIconBadge(
    Canvas canvas, {
    required Offset center,
    required double top,
    required double width,
    required GameIconData icon,
    required Color backgroundColor,
    bool active = false,
    double activePulse = 0.0,
    Color? activeColor,
  }) {
    final badgeRect = typeIconBadgeRect(center: center, top: top, width: width);
    final badgeRRect = RRect.fromRectAndRadius(
      badgeRect,
      const Radius.circular(4),
    );
    final pulse = active ? activePulse.clamp(0.0, 1.0).toDouble() : 0.0;
    final pulseColor = activeColor ?? _activeColor;

    canvas.drawRRect(
      badgeRRect.shift(const Offset(0, 1.2)),
      HudPaint.shadow(alpha: MapAlpha.soft),
    );
    if (active) {
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            badgeRect.inflate(activeGlowInflateForTesting),
            const Radius.circular(6.4),
          ),
          HudPaint.fill(
            pulseColor,
            alpha: activeGlowAlphaForTesting + (28 * pulse).round(),
          ),
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            badgeRect.inflate(1.7 + pulse),
            Radius.circular(5.8 + pulse * 0.8),
          ),
          HudPaint.stroke(
            HudPalette.goldLight,
            alpha: MapAlpha.regular + (54 * pulse).round(),
            strokeWidth: 1.0 + pulse * 0.6,
          ),
        );
    }
    canvas
      ..drawRRect(
        badgeRRect,
        HudPaint.fill(
          active
              ? Color.alphaBlend(
                  HudPaint.color(pulseColor, alpha: MapAlpha.faint),
                  HudPaint.color(backgroundColor, alpha: MapAlpha.opaque),
                )
              : HudPaint.color(backgroundColor, alpha: MapAlpha.solid),
        ),
      )
      ..drawRRect(
        badgeRRect,
        HudPaint.stroke(
          HudPalette.goldLight,
          alpha: active
              ? MapAlpha.strong + (34 * pulse).round()
              : MapAlpha.strong,
          strokeWidth: active ? 1.05 + pulse * 0.35 : _strokeWidth,
        ),
      );
    GameIconRenderer.paintIcon(
      canvas,
      icon,
      topLeft: Offset(
        badgeRect.center.dx - _typeBadgeIconSize / 2,
        badgeRect.center.dy - _typeBadgeIconSize / 2,
      ),
      size: _typeBadgeIconSize,
      color: HudPalette.goldLight,
    );
    return badgeRect;
  }

  static Rect _healthRect({
    required Offset center,
    required double top,
    required double width,
  }) {
    return Rect.fromLTWH(
      center.dx - width / 2,
      top - _gap - _height,
      width,
      _height,
    );
  }
}
