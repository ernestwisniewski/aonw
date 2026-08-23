import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../features/map/presentation/map_render_snapshot.dart';
import 'presentation/flame_scene_sink.dart';

typedef AonwFlameGameFactory = AonwFlameGame Function();

final class AonwWorld extends World implements FlameSceneSink {
  MapRenderSnapshot? _scene;
  var _sceneWriteCount = 0;

  @visibleForTesting
  MapRenderSnapshot? get debugScene => _scene;

  @visibleForTesting
  int get debugSceneWriteCount => _sceneWriteCount;

  @override
  void replaceScene(MapRenderSnapshot snapshot) {
    if (identical(_scene, snapshot)) return;
    _scene = snapshot;
    _sceneWriteCount += 1;
  }

  @override
  void clearScene() {
    if (_scene == null) return;
    _scene = null;
    _sceneWriteCount += 1;
  }

  @override
  void onRemove() {
    clearScene();
    super.onRemove();
  }
}

base class AonwFlameGame extends FlameGame<AonwWorld> {
  AonwFlameGame({AonwWorld? world, CameraComponent? camera})
    : super(world: world ?? AonwWorld(), camera: camera ?? CameraComponent()) {
    // Route and application visibility are coordinated by the Flutter owner.
    pauseWhenBackgrounded = false;
    pauseEngine();
  }

  var _mountCount = 0;
  var _removeCount = 0;
  var _disposed = false;
  var _viewportActive = false;
  var _continuousRendering = false;

  FlameSceneSink get sceneSink => world;

  @visibleForTesting
  int get debugMountCount => _mountCount;

  @visibleForTesting
  int get debugRemoveCount => _removeCount;

  @visibleForTesting
  bool get debugDisposed => _disposed;

  @visibleForTesting
  bool get debugViewportActive => _viewportActive;

  void setViewportActive(bool active) {
    if (_disposed || active == _viewportActive) return;
    _viewportActive = active;
    _synchronizeGameLoop();
  }

  void setContinuousRendering(bool enabled) {
    if (_disposed || enabled == _continuousRendering) return;
    _continuousRendering = enabled;
    _synchronizeGameLoop();
  }

  void _synchronizeGameLoop() {
    if (_viewportActive && _continuousRendering) {
      resumeEngine();
    } else {
      pauseEngine();
    }
  }

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  void onMount() {
    _mountCount += 1;
    super.onMount();
  }

  @override
  void onRemove() {
    _removeCount += 1;
    super.onRemove();
  }

  @override
  void onDispose() {
    if (!_disposed) {
      _disposed = true;
      world.clearScene();
      dispose();
    }
    super.onDispose();
  }
}
