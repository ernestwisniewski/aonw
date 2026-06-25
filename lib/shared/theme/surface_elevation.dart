import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

/// Semantic elevation levels for HUD/UI surfaces.
///
/// `flat` is a quiet inline container, `raised` is a primary HUD panel,
/// `floating` is for popovers and pills, and `modal` is the emphasized
/// surface used by active or hero states.
enum SurfaceElevation {
  flat,
  raised,
  floating,
  modal;

  _ElevationSpec get _spec => switch (this) {
    SurfaceElevation.flat => const _ElevationSpec(
      background: HudPalette.surface,
      backgroundAlpha: 210,
      defaultBorder: BorderEmphasis.subtle,
      borderColor: HudPalette.gold,
      blurRadius: 12,
      shadowAlpha: 80,
      shadowOffset: Offset(0, 4),
    ),
    SurfaceElevation.raised => const _ElevationSpec(
      background: HudPalette.surface,
      backgroundAlpha: 230,
      defaultBorder: BorderEmphasis.strong,
      borderColor: HudPalette.gold,
      blurRadius: 18,
      shadowAlpha: 115,
      shadowOffset: Offset(0, 7),
    ),
    SurfaceElevation.floating => const _ElevationSpec(
      background: HudPalette.bg,
      backgroundAlpha: 215,
      defaultBorder: BorderEmphasis.regular,
      borderColor: HudPalette.gold,
      blurRadius: 10,
      shadowAlpha: 92,
      shadowOffset: Offset(0, 4),
    ),
    SurfaceElevation.modal => const _ElevationSpec(
      background: HudPalette.gold,
      backgroundAlpha: 235,
      defaultBorder: BorderEmphasis.active,
      borderColor: HudPalette.goldLight,
      blurRadius: 20,
      shadowAlpha: 115,
      shadowOffset: Offset(0, 6),
      glowAlpha: 90,
    ),
  };

  int get borderAlpha => _spec.defaultBorder.alpha;

  Color fill({Color? background, int? alpha}) {
    final spec = _spec;
    return (background ?? spec.background).withAlpha(
      alpha ?? spec.backgroundAlpha,
    );
  }

  Color strokeColor({
    Color? accent,
    Color? color,
    BorderEmphasis? border,
    int? alpha,
  }) {
    final spec = _spec;
    final emphasis = border ?? spec.defaultBorder;
    return (color ?? accent ?? spec.borderColor).withAlpha(
      alpha ?? emphasis.alpha,
    );
  }

  List<BoxShadow> shadows({
    Color color = Colors.black,
    int? alpha,
    Color? glowColor,
    int? glowAlpha,
    double? glowBlurRadius,
  }) {
    final spec = _spec;
    return [
      BoxShadow(
        color: color.withAlpha(alpha ?? spec.shadowAlpha),
        blurRadius: spec.blurRadius,
        offset: spec.shadowOffset,
      ),
      if (glowColor != null)
        BoxShadow(
          color: glowColor.withAlpha(glowAlpha ?? spec.glowAlpha),
          blurRadius: glowBlurRadius ?? spec.blurRadius,
          offset: Offset.zero,
        ),
    ];
  }

  BoxDecoration decoration({
    Color? accent,
    Color? background,
    Color? borderColor,
    Gradient? gradient,
    int? backgroundAlpha,
    Object? border,
    int? borderAlpha,
    double? borderWidth,
    SurfaceShape shape = SurfaceShape.card,
    BorderRadiusGeometry? borderRadius,
    double? radius,
    bool includeShadow = true,
    List<BoxShadow>? boxShadow,
    Color? glowColor,
    int? glowAlpha,
  }) {
    final spec = _spec;
    final resolvedBorder = border is BorderEmphasis
        ? border
        : spec.defaultBorder;
    final resolvedBorderColor =
        borderColor ??
        (border is Color ? border : null) ??
        accent ??
        spec.borderColor;
    final resolvedBorderSide = borderAlpha == null
        ? resolvedBorder.side(resolvedBorderColor, width: borderWidth ?? 1)
        : BorderSide(
            color: resolvedBorderColor.withAlpha(borderAlpha),
            width: borderWidth ?? 1,
          );
    return BoxDecoration(
      color: gradient == null
          ? fill(background: background, alpha: backgroundAlpha)
          : null,
      gradient: gradient,
      borderRadius:
          borderRadius ?? BorderRadius.circular(radius ?? shape.radius),
      border: Border.fromBorderSide(resolvedBorderSide),
      boxShadow:
          boxShadow ??
          (includeShadow
              ? shadows(glowColor: glowColor, glowAlpha: glowAlpha)
              : null),
    );
  }

  BoxDecoration bandDecoration({
    Color? background,
    Gradient? gradient,
    int? backgroundAlpha,
    Color? borderColor,
    BorderEmphasis border = BorderEmphasis.regular,
    bool topBorder = false,
    List<BoxShadow>? boxShadow,
  }) {
    final side = border.side(borderColor ?? _spec.borderColor);
    return BoxDecoration(
      color: gradient == null
          ? fill(background: background, alpha: backgroundAlpha)
          : null,
      gradient: gradient,
      border: topBorder ? Border(top: side) : Border(bottom: side),
      boxShadow: boxShadow,
    );
  }
}

class _ElevationSpec {
  const _ElevationSpec({
    required this.background,
    required this.backgroundAlpha,
    required this.defaultBorder,
    required this.borderColor,
    required this.blurRadius,
    required this.shadowAlpha,
    required this.shadowOffset,
    this.glowAlpha = 0,
  });

  final Color background;
  final int backgroundAlpha;
  final BorderEmphasis defaultBorder;
  final Color borderColor;
  final double blurRadius;
  final int shadowAlpha;
  final Offset shadowOffset;
  final int glowAlpha;
}
