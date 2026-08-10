part of 'unit_marker_renderer.dart';

void _renderFallbackUnit(Canvas canvas, UnitMarkerRenderModel model) {
  const center = Offset(UnitMarkerRenderer.radius, UnitMarkerRenderer.radius);
  SpriteShadow.paint3d(
    canvas,
    UnitMarkerRenderer.spriteShadowRect(model),
    color: SpriteShadow.unitColor,
  );

  _paintPossiblyExhausted(
    canvas,
    model,
    const Rect.fromLTWH(
      0,
      0,
      UnitMarkerRenderer.markerSize,
      UnitMarkerRenderer.markerSize,
    ).inflate(4),
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

void _renderSpriteUnit(
  Canvas canvas,
  UnitMarkerRenderModel model,
  UnitSpriteComponent sprite,
) {
  const center = Offset(UnitMarkerRenderer.radius, UnitMarkerRenderer.radius);
  SpriteShadow.paint3d(
    canvas,
    UnitMarkerRenderer.spriteShadowRect(model),
    color: SpriteShadow.unitColor,
  );

  final size = UnitMarkerRenderer.spriteSizeFor(sprite, model);
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

void _paintUnitSprite(
  Canvas canvas,
  UnitMarkerRenderModel model, {
  required UnitSpriteComponent sprite,
  required Offset center,
}) {
  final size = UnitMarkerRenderer.spriteSizeFor(sprite, model);
  final width = size.width;
  final height = size.height;
  final destination = Rect.fromCenter(
    center: Offset(center.dx, center.dy - height * _spriteVerticalLiftFactor),
    width: width,
    height: height,
  );

  if (!sprite.isReady) {
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

  sprite
    ..size.setValues(width, height)
    ..paint = (model.paint..filterQuality = FilterQuality.medium);

  final previousColorFilter = model.exhausted ? model.paint.colorFilter : null;
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

void _paintPossiblyExhausted(
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
