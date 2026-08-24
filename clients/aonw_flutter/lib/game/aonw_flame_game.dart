import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import '../features/map/presentation/input/map_viewport_intent.dart';
import '../features/map/presentation/map_render_snapshot.dart';
import '../features/map/read_model/map_view.dart';
import 'input/flame_map_input_surface.dart';
import 'map/flame_map_camera.dart';
import 'map/gameplay_map_layers.dart';
import 'map/static_map_layers.dart';
import 'presentation/flame_scene_patch.dart';
import 'presentation/flame_scene_sink.dart';

typedef AonwFlameGameFactory = AonwFlameGame Function();

final class AonwWorld extends World implements FlameSceneSink {
  AonwWorld({bool renderStaticLayers = false})
    : terrainLayer = MapTerrainLayerComponent(
        renderEnabled: renderStaticLayers,
      ),
      referenceLayer = MapReferenceLayerComponent(
        renderEnabled: renderStaticLayers,
      ),
      gridLayer = MapGridLayerComponent(renderEnabled: renderStaticLayers) {
    unitLayer = MapUnitLayerComponent(renderEnabled: renderStaticLayers);
    reachableLayer = MapReachableLayerComponent(
      renderEnabled: renderStaticLayers,
    );
    routeLayer = MapRouteLayerComponent(renderEnabled: renderStaticLayers);
    selectionLayer = MapSelectionLayerComponent(
      renderEnabled: renderStaticLayers,
      units: unitLayer,
    );
    effectHost = MapEffectHostComponent(units: unitLayer);
    addAll([
      terrainLayer,
      referenceLayer,
      gridLayer,
      reachableLayer,
      routeLayer,
      unitLayer,
      selectionLayer,
      effectHost,
    ]);
  }

  final MapTerrainLayerComponent terrainLayer;
  final MapReferenceLayerComponent referenceLayer;
  final MapGridLayerComponent gridLayer;
  late final MapReachableLayerComponent reachableLayer;
  late final MapRouteLayerComponent routeLayer;
  late final MapUnitLayerComponent unitLayer;
  late final MapSelectionLayerComponent selectionLayer;
  late final MapEffectHostComponent effectHost;
  MapRenderSnapshot? _scene;
  MapStaticRenderCache? _staticCache;
  var _sceneWriteCount = 0;

  @visibleForTesting
  MapRenderSnapshot? get debugScene => _scene;

  @visibleForTesting
  int get debugSceneWriteCount => _sceneWriteCount;

  @visibleForTesting
  MapStaticRenderCache? get debugStaticRenderCache => _staticCache;

  MapStaticRenderCache? get _staticRenderCacheForGame => _staticCache;

  @override
  void replaceScene(MapRenderSnapshot snapshot) {
    if (identical(_scene, snapshot)) return;
    final patch = FlameScenePatch.between(_scene, snapshot);
    _scene = snapshot;
    _sceneWriteCount += 1;
    final identity = (
      mapId: snapshot.map.mapId,
      contentHash: snapshot.map.contentHash,
      cols: snapshot.map.cols,
      rows: snapshot.map.rows,
    );
    final cache = _staticCache?.identity == identity
        ? _staticCache!
        : MapStaticRenderCache.build(snapshot.map);
    _staticCache = cache;
    terrainLayer.applyCache(cache);
    referenceLayer.applyReference(
      cache: cache,
      reference: snapshot.reference,
      visible: snapshot.interaction.referenceVisible,
    );
    gridLayer.applyCache(cache);
    reachableLayer.applyReachable(cache, snapshot.interaction.reachable);
    routeLayer.applyRoute(cache, snapshot.interaction.route);
    unitLayer.applyPatch(patch, cache);
    selectionLayer.applySelection(cache, snapshot.interaction);
    effectHost.applyPatch(patch, cache);
  }

  @override
  void clearScene() {
    if (_scene == null) return;
    _scene = null;
    _staticCache = null;
    _sceneWriteCount += 1;
    terrainLayer.clearCache();
    referenceLayer.clearCache();
    gridLayer.clearCache();
    reachableLayer.clearLayer();
    routeLayer.clearLayer();
    unitLayer.clearLayer();
    selectionLayer.clearLayer();
    effectHost.clearEffects();
  }

  @override
  void onRemove() {
    clearScene();
    super.onRemove();
  }
}

base class AonwFlameGame extends FlameGame<AonwWorld>
    implements FlameSceneSink {
  AonwFlameGame({
    AonwWorld? world,
    CameraComponent? camera,
    bool renderStaticLayers = false,
    MapHexIntentSink? onHexIntent,
  }) : super(
         world: world ?? AonwWorld(renderStaticLayers: renderStaticLayers),
         camera: camera ?? CameraComponent(),
       ) {
    // Route and application visibility are coordinated by the Flutter owner.
    pauseWhenBackgrounded = false;
    pauseEngine();
    _hexIntentSink = onHexIntent;
    mapCamera = FlameMapCameraController(this.camera);
    inputSurface = onHexIntent == null
        ? null
        : FlameMapInputSurface(
            onIntent: _handleViewportIntent,
            requestFrame: _requestInputFrame,
          );
    if (inputSurface case final surface?) add(surface);
    this.world.effectHost.onActivityChanged = _handleEffectActivity;
  }

  late final FlameMapCameraController mapCamera;
  late final FlameMapInputSurface? inputSurface;
  MapHexIntentSink? _hexIntentSink;
  MapHexCoordinate? _lastHoveredHex;
  var _hasHoveredHex = false;
  var _mountCount = 0;
  var _removeCount = 0;
  var _disposed = false;
  var _viewportActive = false;
  var _continuousRendering = false;
  var _effectsActive = false;
  var _inputFrameScheduled = false;

  FlameSceneSink get sceneSink => this;

  @visibleForTesting
  int get debugMountCount => _mountCount;

  @visibleForTesting
  int get debugRemoveCount => _removeCount;

  @visibleForTesting
  bool get debugDisposed => _disposed;

  @visibleForTesting
  bool get debugViewportActive => _viewportActive;

  @visibleForTesting
  bool get debugEffectsActive => _effectsActive;

  @visibleForTesting
  MapHexCoordinate? debugHexAtScreen(AonwPoint screenPoint) =>
      mapCamera.hexAtScreen(screenPoint);

  @visibleForTesting
  AonwPoint? debugScreenForHex(MapHexCoordinate coordinate) =>
      mapCamera.screenForHex(coordinate);

  @override
  void replaceScene(MapRenderSnapshot snapshot) {
    world.replaceScene(snapshot);
    final cache = world._staticRenderCacheForGame;
    if (cache != null) {
      mapCamera.replaceMap(
        cache: cache,
        authoredZoom: snapshot.map.defaultZoom,
      );
    }
    _requestInputFrame();
  }

  @override
  void clearScene() {
    world.clearScene();
    mapCamera.clear();
    _lastHoveredHex = null;
    _hasHoveredHex = false;
    _requestInputFrame();
  }

  void setViewportActive(bool active) {
    if (_disposed || active == _viewportActive) return;
    _viewportActive = active;
    inputSurface?.setEnabled(active);
    _synchronizeGameLoop();
  }

  void setContinuousRendering(bool enabled) {
    if (_disposed || enabled == _continuousRendering) return;
    _continuousRendering = enabled;
    _synchronizeGameLoop();
  }

  void _synchronizeGameLoop() {
    if (_viewportActive && (_continuousRendering || _effectsActive)) {
      resumeEngine();
    } else {
      pauseEngine();
    }
  }

  void setReducedMotion(bool enabled) {
    if (_disposed) return;
    world.effectHost.setReducedMotion(enabled);
  }

  void setEffectPlaybackSpeed(double speed) {
    if (_disposed) return;
    world.effectHost.setPlaybackSpeed(speed);
  }

  void skipEffects() {
    if (_disposed) return;
    world.effectHost.skipAll();
  }

  void _handleEffectActivity(bool active) {
    if (_disposed || _effectsActive == active) return;
    _effectsActive = active;
    _synchronizeGameLoop();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.center;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    inputSurface?.resize(size);
    mapCamera.resize(size);
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
      clearScene();
      dispose();
    }
    super.onDispose();
  }

  void _handleViewportIntent(MapViewportIntent intent) {
    if (!_viewportActive) return;
    mapCamera.applyIntent(intent);
    final coordinate = switch (intent) {
      MapHoverIntent(:final screenPosition) ||
      MapSelectIntent(
        :final screenPosition,
      ) => mapCamera.hexAtScreen(screenPosition),
      MapViewportFrameIntent(:final hoverScreenPosition) =>
        hoverScreenPosition == null
            ? null
            : mapCamera.hexAtScreen(hoverScreenPosition),
      MapPanIntent() || MapZoomIntent() => null,
    };
    switch (intent) {
      case MapHoverIntent():
        _emitHover(coordinate);
      case MapSelectIntent():
        _hexIntentSink?.call(MapHexSelectIntent(coordinate));
      case MapViewportFrameIntent(:final hoverScreenPosition):
        if (hoverScreenPosition != null) _emitHover(coordinate);
      case MapPanIntent() || MapZoomIntent():
        break;
    }
  }

  void _emitHover(MapHexCoordinate? coordinate) {
    if (_hasHoveredHex && coordinate == _lastHoveredHex) return;
    _hasHoveredHex = true;
    _lastHoveredHex = coordinate;
    _hexIntentSink?.call(MapHexHoverIntent(coordinate));
  }

  void _requestInputFrame() {
    if (_inputFrameScheduled || _disposed || !isAttached) return;
    _inputFrameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _inputFrameScheduled = false;
      if (!_disposed && isAttached && paused) stepEngine(stepTime: 0);
    });
  }
}
