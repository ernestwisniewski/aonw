import 'package:flutter/widgets.dart';

final class MapInitialCamera {
  const MapInitialCamera._();

  static double scaleFor({
    required Size viewport,
    required Size content,
    required double authoredZoom,
  }) {
    final fit = (viewport.width / content.width).clamp(
      0.0,
      viewport.height / content.height,
    );
    return fit * authoredZoom;
  }

  static Matrix4 centeredFit({
    required Size viewport,
    required Size content,
    required double authoredZoom,
  }) {
    final scale = scaleFor(
      viewport: viewport,
      content: content,
      authoredZoom: authoredZoom,
    );
    final translation = Offset(
      (viewport.width - content.width * scale) / 2,
      (viewport.height - content.height * scale) / 2,
    );
    return Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(translation.dx, translation.dy, 0);
  }
}
