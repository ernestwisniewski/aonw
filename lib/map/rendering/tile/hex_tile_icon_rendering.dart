part of 'hex_tile_painter.dart';

extension _HexTileIconRendering on HexTilePainter {
  void _drawResourceIcons({
    required Canvas canvas,
    required List<Rect> iconRects,
    required List<SpriteFrameId> iconPaths,
  }) {
    if (iconRects.isEmpty || iconPaths.isEmpty) return;
    final count = math.min(iconPaths.length, iconRects.length);
    for (int i = 0; i < count; i++) {
      _drawIcon(canvas, iconPaths[i], iconRects[i]);
    }
  }

  void _drawIcon(Canvas canvas, SpriteFrameId path, Rect iconRect) {
    final frame = SpriteFrames.cached(path);
    if (frame != null) {
      final geometry = frame.geometryFor(
        logicalSource: Offset.zero & frame.originalSize,
        destination: iconRect,
      );
      canvas.drawImageRect(
        frame.image,
        geometry.source,
        geometry.destination,
        HexTilePainter._paintMapIconImage,
      );
    } else {
      canvas.drawCircle(iconRect.center, iconRect.width / 2, _paintIconDot);
    }
  }

  void _drawHeightBadge({
    required Canvas canvas,
    required Offset paragraphOffset,
    required double perspectiveY,
  }) {
    canvas
      ..save()
      ..scale(1.0, 1.0 / perspectiveY)
      ..translate(paragraphOffset.dx, paragraphOffset.dy);
    _drawOutlinedText(canvas, _heightParagraph, _heightParagraphShadow);
    canvas.restore();
  }

  void _drawOutlinedText(
    Canvas canvas,
    ui.Paragraph text,
    ui.Paragraph textOutline,
  ) {
    const offsets = [
      Offset(-1, -1),
      Offset(0, -1),
      Offset(1, -1),
      Offset(-1, 0),
      Offset(1, 0),
      Offset(-1, 1),
      Offset(0, 1),
      Offset(1, 1),
    ];
    for (final offset in offsets) {
      canvas.drawParagraph(textOutline, offset);
    }
    canvas.drawParagraph(text, Offset.zero);
  }
}
