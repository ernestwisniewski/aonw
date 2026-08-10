part of 'action_palette_component.dart';

extension _ActionPaletteIconRendering on ActionPaletteComponent {
  void _paintBackground(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    HudCanvasShapes.roundedSurface(
      canvas,
      rect,
      elevation: SurfaceElevation.raised,
      border: BorderEmphasis.regular,
      backgroundAlpha: 232,
      borderAlpha: 132,
      radius: ActionPaletteComponent._barRadius,
    );
  }

  void _paintIcon(Canvas canvas, ActionPaletteOption option, Rect rect) {
    final iconRrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    final tintPaint = option.isRecommended
        ? ActionPaletteComponent._recommendedTintPaint
        : ActionPaletteComponent._availableTintPaint;
    if (!option.isBlocked) {
      canvas.drawRRect(iconRrect, tintPaint);
    }

    if (!_paintVectorIcon(canvas, option, rect) &&
        !_paintImprovementSprite(canvas, option, rect)) {
      _paintFallbackIcon(canvas, option, rect);
    }

    if (option.isBlocked) {
      canvas.drawRRect(iconRrect, ActionPaletteComponent._blockedOverlayPaint);
      _paintBadge(canvas, rect, 'L', GameUiTheme.textMuted);
    }
    if (option.isRecommended) {
      _strokeIcon(canvas, rect, GameUiTheme.gold, 2);
      _paintBadge(canvas, rect, '*', GameUiTheme.goldLight);
    }
    if (option.selected || option.id == _previewedOptionId) {
      _strokeIcon(canvas, rect.deflate(1), GameUiTheme.goldLight, 3);
    }
  }

  void _paintFallbackIcon(
    Canvas canvas,
    ActionPaletteOption option,
    Rect rect,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: option.label.characters.firstOrNull ?? '?',
        style: GameUiTheme.cardTitle.copyWith(fontSize: 18),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  bool _paintVectorIcon(Canvas canvas, ActionPaletteOption option, Rect rect) {
    final icon = option.vectorIcon;
    if (icon == null) return false;
    final iconSize = math.min(rect.width, rect.height) - 14;
    GameIconRenderer.paintIcon(
      canvas,
      icon,
      topLeft: Offset(
        rect.center.dx - iconSize / 2,
        rect.center.dy - iconSize / 2,
      ),
      size: iconSize,
      color: option.isBlocked ? GameUiTheme.textMuted : GameUiTheme.goldLight,
    );
    return true;
  }

  void _paintBadge(Canvas canvas, Rect iconRect, String label, Color color) {
    final badgeRect = Rect.fromCircle(
      center: Offset(iconRect.right - 7, iconRect.top + 7),
      radius: 7,
    );
    canvas.drawOval(
      badgeRect,
      HudPaint.surface(
        SurfaceElevation.raised,
        background: HudPalette.surfaceDeep,
        alpha: 230,
      ),
    );
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          fontFamily: GameUiTheme.bodyFont,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        badgeRect.center.dx - painter.width / 2,
        badgeRect.center.dy - painter.height / 2,
      ),
    );
  }

  void _strokeIcon(Canvas canvas, Rect rect, Color color, double width) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      HudPaint.border(
        BorderEmphasis.active,
        color: color,
        alpha: 255,
        strokeWidth: width,
      ),
    );
  }

  bool _paintImprovementSprite(
    Canvas canvas,
    ActionPaletteOption option,
    Rect rect,
  ) {
    final type = _improvementTypeFor(option);
    if (type == null) return false;
    final image = FieldImprovementSpriteCache.imageFor(
      FieldImprovementSpriteCatalog.assetPathFor(type),
    );
    if (image == null) return false;
    final source = _sourceRectFor(image, option);
    if (source == null) return false;
    canvas.drawImageRect(
      image,
      _spriteSourceFor(option: option, baseSource: source),
      _spriteDestinationFor(option: option, baseSource: source, iconRect: rect),
      ActionPaletteComponent._spritePaint,
    );
    return true;
  }

  AnimationFrameAdjustment _frameAdjustmentFor(ActionPaletteOption option) {
    final type = _improvementTypeFor(option);
    if (type == null) return const AnimationFrameAdjustment();
    return _adjustments.adjustmentFor(
      assetPath: FieldImprovementSpriteCatalog.assetPathFor(type),
      animationId: FieldImprovementSpriteCatalog.adjustmentIdForVariant(
        type: type,
        eraColumn: option.iconAtlasColumn ?? 0,
      ),
      frameIndex: 0,
    );
  }

  ui.Rect _spriteSourceFor({
    required ActionPaletteOption option,
    required ui.Rect baseSource,
  }) {
    return _frameAdjustmentFor(option).croppedSourceFor(baseSource);
  }

  ui.Rect _spriteDestinationFor({
    required ActionPaletteOption option,
    required ui.Rect baseSource,
    required Rect iconRect,
  }) {
    final adjustment = _frameAdjustmentFor(option);
    final baseDestination = iconRect.deflate(4);
    final offset = adjustment.scaledOffset(
      baseSize: BoardAssetCapStyles.improvement.topSize,
      targetSize: baseDestination.size,
    );
    return adjustment
        .adjustedDestinationFor(
          baseSource: baseSource,
          baseDestination: baseDestination,
        )
        .shift(offset);
  }
}

FieldImprovementType? _improvementTypeFor(ActionPaletteOption option) {
  final row = option.iconAtlasRow;
  if (row == null ||
      row < 0 ||
      row >= FieldImprovementSpriteCatalog.typesInAtlasOrder.length) {
    return null;
  }
  return FieldImprovementSpriteCatalog.typesInAtlasOrder[row];
}

ui.Rect? _sourceRectFor(ui.Image image, ActionPaletteOption option) {
  final type = _improvementTypeFor(option);
  if (type == null) return null;
  return FieldImprovementSpriteCatalog.sourceRectFor(
    imageWidth: image.width,
    imageHeight: image.height,
    type: type,
    eraColumn: option.iconAtlasColumn ?? 0,
  );
}
