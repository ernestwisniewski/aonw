part of 'unit_marker_renderer.dart';

double _spriteTopFor({required Offset center, required double height}) {
  return center.dy - height * (0.5 + _spriteVerticalLiftFactor);
}

double _spriteStatusTopFor({
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

double _statusTopForZoom(
  Offset center,
  double baseTop,
  double tacticalViewEmphasis,
) {
  final containedTop = math.max(baseTop, center.dy + _containedStatusTopOffset);
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

double _statusWidthForZoom(double baseWidth, double tacticalViewEmphasis) {
  return lerpDouble(baseWidth, _tacticalStatusWidth, tacticalViewEmphasis)!;
}

Rect _scaleRectFromCenter(Rect rect, double spriteScale) {
  if (spriteScale == 1) return rect;
  return Rect.fromCenter(
    center: rect.center,
    width: rect.width * spriteScale,
    height: rect.height * spriteScale,
  );
}
