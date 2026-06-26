import 'dart:math' as math;

import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';

enum UnitMarkerStateBadge { fortified, healing, skippedTurn, exhausted }

abstract final class UnitMarkerStateBadgeResolver {
  static UnitMarkerStateBadge? resolve({
    required bool fortified,
    required bool skippedTurn,
    required bool exhausted,
    required double healthFraction,
  }) {
    if (fortified) {
      return healthFraction < 0.995
          ? UnitMarkerStateBadge.healing
          : UnitMarkerStateBadge.fortified;
    }
    if (skippedTurn) return UnitMarkerStateBadge.skippedTurn;
    if (exhausted) return UnitMarkerStateBadge.exhausted;
    return null;
  }
}

abstract final class UnitMarkerBadgeStyle {
  static const double stateBadgeRadius = 5.5;
  static const double stateBadgeOnCityRadius = 5.0;
  static const double artifactBadgeRadius = 5.8;
  static const double artifactBadgeOnCityRadius = 5.2;
  static const int stateBadgeBackgroundAlpha = 205;
  static const int artifactBadgeBackgroundAlpha = 226;
  static const int workBadgeBackgroundAlpha = 186;

  static double stateBadgeRadiusFor({required bool onCity}) =>
      onCity ? stateBadgeOnCityRadius : stateBadgeRadius;

  static double artifactBadgeRadiusFor({required bool onCity}) =>
      onCity ? artifactBadgeOnCityRadius : artifactBadgeRadius;

  static Rect stateBadgeRect({required Offset center, required bool onCity}) {
    return Rect.fromCircle(
      center: Offset(
        center.dx + (onCity ? 8.0 : 10.0),
        center.dy + (onCity ? 6.5 : 8.5),
      ),
      radius: stateBadgeRadiusFor(onCity: onCity),
    );
  }

  static Rect artifactBadgeRect({
    required Offset center,
    required bool onCity,
  }) {
    return Rect.fromCircle(
      center: Offset(
        center.dx - (onCity ? 8.0 : 10.0),
        center.dy + (onCity ? 6.5 : 8.5),
      ),
      radius: artifactBadgeRadiusFor(onCity: onCity),
    );
  }
}

abstract final class UnitMarkerBadgePainter {
  static void paintStateBadge(
    Canvas canvas, {
    required Offset center,
    required UnitMarkerStateBadge badge,
    required bool onCity,
  }) {
    final spec = _UnitMarkerStateBadgeSpec.forBadge(badge);
    final rect = UnitMarkerBadgeStyle.stateBadgeRect(
      center: center,
      onCity: onCity,
    );
    final badgeCenter = rect.center;
    final radius = UnitMarkerBadgeStyle.stateBadgeRadiusFor(onCity: onCity);

    canvas
      ..drawCircle(
        badgeCenter.translate(0, 1.2),
        radius + 1.0,
        HudPaint.shadow(alpha: MapAlpha.soft),
      )
      ..drawCircle(
        badgeCenter,
        radius + 0.6,
        HudPaint.fill(HudPalette.surfaceDeep, alpha: MapAlpha.solid),
      )
      ..drawCircle(
        badgeCenter,
        radius,
        HudPaint.fill(
          spec.background,
          alpha: UnitMarkerBadgeStyle.stateBadgeBackgroundAlpha,
        ),
      )
      ..drawCircle(
        badgeCenter,
        radius,
        HudPaint.stroke(HudPalette.goldLight, alpha: MapAlpha.regular),
      );
    GameIconRenderer.paintIcon(
      canvas,
      spec.icon,
      topLeft: rect.deflate(2).topLeft,
      size: rect.deflate(2).width,
      color: HudPaint.color(HudPalette.goldLight, alpha: MapAlpha.solid),
    );
  }

  static void paintArtifactBadge(
    Canvas canvas, {
    required Offset center,
    required bool onCity,
  }) {
    final rect = UnitMarkerBadgeStyle.artifactBadgeRect(
      center: center,
      onCity: onCity,
    );
    final badgeCenter = rect.center;
    final radius = UnitMarkerBadgeStyle.artifactBadgeRadiusFor(onCity: onCity);

    canvas
      ..drawCircle(
        badgeCenter.translate(0, 1.2),
        radius + 1.0,
        HudPaint.shadow(alpha: MapAlpha.soft),
      )
      ..drawCircle(
        badgeCenter,
        radius + 0.8,
        HudPaint.fill(HudPalette.surfaceDeep, alpha: MapAlpha.solid),
      )
      ..drawCircle(
        badgeCenter,
        radius,
        HudPaint.fill(
          HudPalette.gold,
          alpha: UnitMarkerBadgeStyle.artifactBadgeBackgroundAlpha,
        ),
      )
      ..drawCircle(
        badgeCenter,
        radius,
        HudPaint.stroke(HudPalette.goldLight, alpha: MapAlpha.strong),
      );
    GameIconRenderer.paintIcon(
      canvas,
      GameIcons.resources,
      topLeft: rect.deflate(2.0).topLeft,
      size: rect.deflate(2.0).width,
      color: HudPaint.color(HudPalette.bg, alpha: MapAlpha.solid),
    );
  }

  static void paintWorkBadge(
    Canvas canvas, {
    required Offset center,
    required double top,
    required Color playerColor,
    required String label,
    required double statusBarsExtentAboveTop,
    required double gapAboveBars,
  }) {
    if (label.isEmpty) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: HudPalette.textBright,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          fontFeatures: GameUiTheme.tabularFigures,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final width = math.max(28.0, textPainter.width + 12);
    final height = textPainter.height + 6;
    final bottom = top - statusBarsExtentAboveTop - gapAboveBars;
    final rect = Rect.fromLTWH(
      center.dx - width / 2,
      bottom - height,
      width,
      height,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(5));

    canvas
      ..drawRRect(
        rrect.shift(const Offset(0, 1.5)),
        HudPaint.shadow(alpha: MapAlpha.soft),
      )
      ..drawRRect(
        rrect,
        HudPaint.fill(
          playerColor,
          alpha: UnitMarkerBadgeStyle.workBadgeBackgroundAlpha,
        ),
      )
      ..drawRRect(
        rrect,
        HudPaint.stroke(HudPalette.textBright, alpha: MapAlpha.regular),
      );
    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2,
      ),
    );
  }
}

class _UnitMarkerStateBadgeSpec {
  final GameIconData icon;
  final Color background;

  const _UnitMarkerStateBadgeSpec({
    required this.icon,
    required this.background,
  });

  factory _UnitMarkerStateBadgeSpec.forBadge(UnitMarkerStateBadge badge) {
    return switch (badge) {
      UnitMarkerStateBadge.fortified => const _UnitMarkerStateBadgeSpec(
        icon: GameIcons.defense,
        background: HudPalette.info,
      ),
      UnitMarkerStateBadge.healing => const _UnitMarkerStateBadgeSpec(
        icon: GameIcons.heartPlus,
        background: HudPalette.success,
      ),
      UnitMarkerStateBadge.skippedTurn => const _UnitMarkerStateBadgeSpec(
        icon: GameIcons.skipTurn,
        background: HudPalette.textSecondary,
      ),
      UnitMarkerStateBadge.exhausted => const _UnitMarkerStateBadgeSpec(
        icon: GameIcons.hourglass,
        background: HudPalette.textTertiary,
      ),
    };
  }
}
