import 'package:flame/events.dart';
import 'package:flame/game.dart';

/// Mixin that adds camera movement helpers to a [FlameGame].
///
/// Touch pan/pinch is driven by [HexWorld]'s viewport pointer tracker so it
/// does not compete in Flutter's gesture arena. Mouse wheel zoom remains here.
mixin CameraController on FlameGame {
  static const double minZoom = 0.2;
  static const double maxZoom = 5.0;
  static const double scrollSensitivity = 0.001;

  void onScroll(PointerScrollInfo info) {
    final delta = info.scrollDelta.global.y;
    setZoomAround(
      camera.viewfinder.zoom * (1 - delta * scrollSensitivity),
      info.eventPosition.widget,
    );
  }

  void setZoom(double zoom) {
    camera.viewfinder.zoom = zoom.clamp(minZoom, maxZoom).toDouble();
  }

  void setZoomAround(double zoom, Vector2 focalPoint) {
    final worldPoint = viewportToWorld(focalPoint);
    setZoomKeepingWorldPoint(
      zoom: zoom,
      focalPoint: focalPoint,
      worldPoint: worldPoint,
    );
  }

  void setZoomKeepingWorldPoint({
    required double zoom,
    required Vector2 focalPoint,
    required Vector2 worldPoint,
  }) {
    final clampedZoom = zoom.clamp(minZoom, maxZoom).toDouble();
    setZoom(clampedZoom);
    camera.viewfinder.position = worldPoint - focalPoint / clampedZoom;
  }

  Vector2 viewportToWorld(Vector2 viewportPoint) =>
      camera.viewfinder.position + viewportPoint / camera.viewfinder.zoom;

  void panByScreenDelta(Vector2 screenDelta) {
    camera.viewfinder.position -= screenDelta / camera.viewfinder.zoom;
  }
}
