import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';

enum UnitMarkerFallbackSize { normal, small }

abstract final class UnitMarkerFallbackPainter {
  static const double normalRadius = 14.0;
  static const double smallRadius = 8.0;
  static const double size = normalRadius * 2;

  static void paint(
    Canvas canvas, {
    required Offset center,
    required Color playerColor,
    required GameIconData icon,
    required UnitMarkerFallbackSize markerSize,
    required bool selected,
  }) {
    switch (markerSize) {
      case UnitMarkerFallbackSize.normal:
        _paintNormal(
          canvas,
          center: center,
          playerColor: playerColor,
          icon: icon,
          selected: selected,
        );
      case UnitMarkerFallbackSize.small:
        _paintSmall(
          canvas,
          center: center,
          playerColor: playerColor,
          icon: icon,
          selected: selected,
        );
    }
  }

  static double statusTopFor(Offset center, UnitMarkerFallbackSize markerSize) {
    return switch (markerSize) {
      UnitMarkerFallbackSize.normal => center.dy - normalRadius,
      UnitMarkerFallbackSize.small => center.dy - smallRadius,
    };
  }

  static double statusWidthFor(UnitMarkerFallbackSize markerSize) {
    return switch (markerSize) {
      UnitMarkerFallbackSize.normal => 26,
      UnitMarkerFallbackSize.small => 20,
    };
  }

  static void _paintNormal(
    Canvas canvas, {
    required Offset center,
    required Color playerColor,
    required GameIconData icon,
    required bool selected,
  }) {
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: const Offset(normalRadius, size - 2),
          width: 18,
          height: 5,
        ),
        HudPaint.shadow(alpha: MapAlpha.faint),
      )
      ..drawCircle(center, normalRadius, HudPaint.fill(playerColor))
      ..drawCircle(
        center,
        normalRadius,
        HudPaint.stroke(
          HudPalette.goldLight,
          alpha: selected ? MapAlpha.full : MapAlpha.regular,
          strokeWidth: selected ? 2.2 : 1.7,
        ),
      );

    _paintIcon(canvas, center: center, icon: icon, iconSize: 13);
  }

  static void _paintSmall(
    Canvas canvas, {
    required Offset center,
    required Color playerColor,
    required GameIconData icon,
    required bool selected,
  }) {
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + smallRadius - 1),
          width: 12,
          height: 4,
        ),
        HudPaint.shadow(alpha: MapAlpha.faint),
      )
      ..drawCircle(center, smallRadius, HudPaint.fill(playerColor))
      ..drawCircle(
        center,
        smallRadius,
        HudPaint.stroke(
          HudPalette.goldLight,
          alpha: selected ? MapAlpha.full : MapAlpha.regular,
          strokeWidth: selected ? 1.7 : 1.2,
        ),
      );

    _paintIcon(canvas, center: center, icon: icon, iconSize: 8);
  }

  static void _paintIcon(
    Canvas canvas, {
    required Offset center,
    required GameIconData icon,
    required double iconSize,
  }) {
    GameIconRenderer.paintIcon(
      canvas,
      icon,
      topLeft: Offset(center.dx - iconSize / 2, center.dy - iconSize / 2),
      size: iconSize,
      color: HudPalette.goldLight,
    );
  }
}
