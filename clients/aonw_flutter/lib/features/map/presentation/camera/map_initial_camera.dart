import 'package:flutter/widgets.dart';

import 'map_camera_transform.dart';

final class MapInitialCamera {
  const MapInitialCamera._();

  static double scaleFor({
    required Size viewport,
    required Size content,
    required double authoredZoom,
  }) {
    return MapCameraTransform.fitted(
      viewport: (width: viewport.width, height: viewport.height),
      content: (width: content.width, height: content.height),
      authoredZoom: authoredZoom,
    ).zoom;
  }

  static Matrix4 centeredFit({
    required Size viewport,
    required Size content,
    required double authoredZoom,
  }) {
    final camera = MapCameraTransform.fitted(
      viewport: (width: viewport.width, height: viewport.height),
      content: (width: content.width, height: content.height),
      authoredZoom: authoredZoom,
    );
    final origin = camera.worldToScreen((x: 0, y: 0));
    return Matrix4.diagonal3Values(camera.zoom, camera.zoom, 1)
      ..setTranslationRaw(origin.x, origin.y, 0);
  }
}
