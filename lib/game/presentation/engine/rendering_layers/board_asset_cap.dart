import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class BoardAssetCapStyle {
  const BoardAssetCapStyle({
    required this.componentSize,
    required this.topSize,
    required this.sideDepth,
    required this.rimWidth,
    required this.rimColor,
    required this.rimShadowColor,
    required this.sideColor,
    required this.surfaceColor,
    required this.assetOpacity,
    required this.shadowAlpha,
  });

  final ui.Size componentSize;
  final ui.Size topSize;
  final double sideDepth;
  final double rimWidth;
  final Color rimColor;
  final Color rimShadowColor;
  final Color sideColor;
  final Color surfaceColor;
  final double assetOpacity;
  final int shadowAlpha;

  ui.Rect topRectFor(ui.Offset center) {
    return ui.Rect.fromCenter(
      center: center.translate(0, -sideDepth / 2),
      width: topSize.width,
      height: topSize.height,
    );
  }
}

abstract final class BoardAssetCapStyles {
  static const city = BoardAssetCapStyle(
    componentSize: ui.Size(98, 60),
    topSize: ui.Size(84, 46),
    sideDepth: 8,
    rimWidth: 5,
    rimColor: Color(0xFFD4B46A),
    rimShadowColor: Color(0xFF77551F),
    sideColor: Color(0xFF5D421B),
    surfaceColor: Color(0xFF181713),
    assetOpacity: 0.96,
    shadowAlpha: 76,
  );

  static const improvement = BoardAssetCapStyle(
    componentSize: ui.Size(71, 44),
    topSize: ui.Size(58, 30),
    sideDepth: 6,
    rimWidth: 4,
    rimColor: Color(0xFFC8CCD2),
    rimShadowColor: Color(0xFF666C75),
    sideColor: Color(0xFF4A5059),
    surfaceColor: Color(0xFF15171A),
    assetOpacity: 0.94,
    shadowAlpha: 58,
  );
}

abstract final class BoardAssetCapPainter {
  static void paint({
    required Canvas canvas,
    required BoardAssetCapStyle style,
    required ui.Rect topRect,
    required ui.Image image,
    required ui.Rect sourceRect,
    required Paint imagePaint,
    Color? rimColor,
    Color? rimShadowColor,
  }) {
    final resolvedRimColor = rimColor ?? style.rimColor;
    final resolvedRimShadowColor = rimShadowColor ?? style.rimShadowColor;
    final sideRect = topRect.shift(ui.Offset(0, style.sideDepth));
    final rimRect = topRect.inflate(style.rimWidth);
    final shadowRect = sideRect
        .inflate(style.rimWidth * 0.85)
        .shift(ui.Offset(0, style.sideDepth * 0.35));
    final topPath = Path()..addOval(topRect);

    canvas
      ..drawOval(
        shadowRect,
        Paint()
          ..color = Colors.black.withAlpha(style.shadowAlpha)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
      )
      ..drawPath(
        _sidePath(topRect: topRect, sideRect: sideRect),
        _sidePaint(style, rimShadowColor: resolvedRimShadowColor),
      )
      ..drawOval(rimRect, Paint()..color = resolvedRimShadowColor)
      ..drawOval(
        rimRect.shift(const ui.Offset(0, -1.4)),
        Paint()..color = resolvedRimColor,
      )
      ..drawOval(topRect.inflate(1.1), Paint()..color = resolvedRimShadowColor)
      ..drawOval(topRect, Paint()..color = style.surfaceColor)
      ..save()
      ..clipPath(topPath, doAntiAlias: true);
    // Apply the asset opacity through colorFilters on the individual paints
    // instead of wrapping the inner draws in a saveLayer. saveLayer allocates
    // an off-screen buffer on Impeller (Apple Metal) and was a per-marker hot
    // path; the colorFilter form composites inline.
    final opacityFilter = ColorFilter.mode(
      Colors.white.withAlpha((style.assetOpacity * 255).round()),
      BlendMode.modulate,
    );
    final previousImageFilter = imagePaint.colorFilter;
    imagePaint.colorFilter = opacityFilter;
    canvas
      ..drawImageRect(image, sourceRect, topRect, imagePaint)
      ..drawRect(
        topRect,
        Paint()
          ..shader = ui.Gradient.linear(
            topRect.topLeft,
            topRect.bottomRight,
            [
              Colors.white.withAlpha(42),
              Colors.transparent,
              Colors.black.withAlpha(44),
            ],
            const [0, 0.45, 1],
          )
          ..colorFilter = opacityFilter,
      );
    imagePaint.colorFilter = previousImageFilter;
    canvas
      ..restore()
      ..drawOval(
        topRect.deflate(1.2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withAlpha(52),
      )
      ..drawOval(
        rimRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Colors.black.withAlpha(96),
      );
  }

  static Path clipPathFor(ui.Rect topRect) => Path()..addOval(topRect);

  static Paint _sidePaint(
    BoardAssetCapStyle style, {
    required Color rimShadowColor,
  }) {
    return Paint()
      ..shader = ui.Gradient.linear(
        style.componentSize.center(ui.Offset.zero),
        style.componentSize.bottomCenter(ui.Offset.zero),
        [style.sideColor.withAlpha(238), rimShadowColor.withAlpha(246)],
      );
  }

  static Path _sidePath({required ui.Rect topRect, required ui.Rect sideRect}) {
    const k = 0.5522847498307936;
    final path = Path()
      ..moveTo(topRect.left, topRect.center.dy)
      ..cubicTo(
        topRect.left,
        topRect.center.dy + topRect.height * 0.5 * k,
        topRect.center.dx - topRect.width * 0.5 * k,
        topRect.bottom,
        topRect.center.dx,
        topRect.bottom,
      )
      ..cubicTo(
        topRect.center.dx + topRect.width * 0.5 * k,
        topRect.bottom,
        topRect.right,
        topRect.center.dy + topRect.height * 0.5 * k,
        topRect.right,
        topRect.center.dy,
      )
      ..lineTo(sideRect.right, sideRect.center.dy)
      ..cubicTo(
        sideRect.right,
        sideRect.center.dy + sideRect.height * 0.5 * k,
        sideRect.center.dx + sideRect.width * 0.5 * k,
        sideRect.bottom,
        sideRect.center.dx,
        sideRect.bottom,
      )
      ..cubicTo(
        sideRect.center.dx - sideRect.width * 0.5 * k,
        sideRect.bottom,
        sideRect.left,
        sideRect.center.dy + sideRect.height * 0.5 * k,
        sideRect.left,
        sideRect.center.dy,
      )
      ..close();
    return path;
  }
}
