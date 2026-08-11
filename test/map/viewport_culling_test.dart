import 'dart:ui' as ui;

import 'package:aonw/map/rendering/viewport_culling.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects positioned children outside the current canvas clip', () async {
    final parent = _CullParent();
    final visible = _RenderCounter(
      position: Vector2(20, 20),
      size: Vector2.all(10),
    );
    final offscreen = _RenderCounter(
      position: Vector2(500, 500),
      size: Vector2.all(10),
    );
    await parent.addAll([visible, offscreen]);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..clipRect(const ui.Rect.fromLTWH(0, 0, 100, 100));
    parent.renderTree(canvas);
    recorder.endRecording().dispose();

    expect(visible.renderCount, 1);
    expect(offscreen.renderCount, 0);
  });

  test('tap hit testing visits only the indexed spatial bucket', () async {
    final world = ViewportCullingWorld();
    final targets = [
      _TapCounter(position: Vector2(20, 20)),
      for (var index = 0; index < 1000; index++)
        _TapCounter(position: Vector2(1000 + index * 200, 1000)),
    ];
    await world.addAll(targets);
    world.refreshSpatialHitTestIndex();

    final hits = world.componentsAtPoint(Vector2(20, 20)).toList();

    expect(hits, contains(targets.first));
    expect(targets.first.containsCallCount, 1);
    expect(
      targets
          .skip(1)
          .fold<int>(0, (sum, target) => sum + target.containsCallCount),
      0,
    );
  });
}

class _CullParent extends Component with ViewportCullingParent {}

class _RenderCounter extends PositionComponent {
  _RenderCounter({required super.position, required super.size});

  int renderCount = 0;

  @override
  void render(ui.Canvas canvas) {
    renderCount++;
  }
}

class _TapCounter extends PositionComponent with TapCallbacks {
  _TapCounter({required super.position})
    : super(size: Vector2.all(20), anchor: Anchor.center);

  int containsCallCount = 0;

  @override
  bool containsLocalPoint(Vector2 point) {
    containsCallCount++;
    return super.containsLocalPoint(point);
  }
}
