import 'dart:async';

import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_camera_controller.dart';
import 'package:aonw/game/presentation/engine/game_effect_dispatcher.dart';
import 'package:aonw/game/presentation/engine/game_renderer_components.dart';
import 'package:aonw/game/presentation/engine/game_rendering_coordinator.dart';
import 'package:aonw/game/presentation/engine/game_scene_builder.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/rendering/hex_world.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:flutter/foundation.dart';

/// Owns Flame world loading, runtime controllers, queued effects, and teardown.
final class GameRendererLifecycleHandler {
  GameRendererLifecycleHandler({
    required this.host,
    required this.mapData,
    required this.components,
    required this.sceneBuilder,
    required this.imagePath,
    required this.initialCamera,
    required this.startCameraOffMap,
    required this.onLoadingProgress,
    required this.l10n,
    required this.viewMode,
    required this.displaySettings,
    required this.reduceMotion,
    required this.moveCameraForUnitMovement,
    required this.focusCameraForUnitMovementForUnit,
    required this.followCameraForUnitMovementForUnit,
    required this.onUnitMovementCameraComplete,
    required this.canAutoFocusMapTarget,
    required this.onTileTapped,
    required this.syncAfterAction,
    required this.publishZoom,
    required this.syncMarkerDensityForZoom,
    required this.syncFastCameraRendering,
    required this.ensureRendererActive,
    required this.readyNotifier,
    required this.zoomNotifier,
    required this.initialCameraFocusReadyNotifier,
    required this.viewModelNotifier,
  });

  final HexWorld host;
  final WorldMap mapData;
  final GameRendererComponents components;
  final GameSceneBuilder sceneBuilder;
  final String? imagePath;
  final CameraState? initialCamera;
  final bool startCameraOffMap;
  final ValueChanged<double>? onLoadingProgress;
  final AppLocalizations? l10n;
  final MapViewMode Function() viewMode;
  final HexDisplaySettings Function() displaySettings;
  final bool Function() reduceMotion;
  final bool Function() moveCameraForUnitMovement;
  final bool Function(String unitId) focusCameraForUnitMovementForUnit;
  final bool Function(String unitId) followCameraForUnitMovementForUnit;
  final Future<void> Function(String unitId) onUnitMovementCameraComplete;
  final bool Function(int col, int row) canAutoFocusMapTarget;
  final Future<void> Function(WorldTile tile) onTileTapped;
  final void Function({bool suppressCameraFocus}) syncAfterAction;
  final void Function() publishZoom;
  final void Function({bool force}) syncMarkerDensityForZoom;
  final void Function(double dt) syncFastCameraRendering;
  final void Function() ensureRendererActive;
  final ValueNotifier<bool> readyNotifier;
  final ValueNotifier<double> zoomNotifier;
  final ValueNotifier<bool> initialCameraFocusReadyNotifier;
  final ValueNotifier<Object> viewModelNotifier;

  final queuedEffects = QueuedRendererEffectQueue();
  late final GameCameraController cameraController;
  late final GameEffectDispatcher effectDispatcher;
  late final GameRenderingCoordinator renderingCoordinator;
  final Completer<void> _initialPresentationBarrier = Completer<void>();
  Future<void> _initialEffectFlush = Future<void>.value();
  bool _initialEffectFlushComplete = true;
  bool isReady = false;
  bool isDisposed = false;

  bool get hasReferenceImage => sceneBuilder.hasReferenceImage;
  Future<void> get initialPresentationReady =>
      _initialPresentationBarrier.future;

  Future<void>? get pendingInitialEffectFlush =>
      _initialEffectFlushComplete ? null : _initialEffectFlush;

  void update(double dt) {
    if (isReady && !isDisposed) cameraController.update(dt);
    syncFastCameraRendering(dt);
  }

  Future<void> buildWorld() async {
    try {
      await _buildWorld();
    } catch (error, stackTrace) {
      queuedEffects.cancelAll(error, stackTrace);
      disposeRenderer();
      rethrow;
    }
  }

  Future<void> _buildWorld() async {
    onLoadingProgress?.call(0);
    cameraController = GameCameraController(
      camera: host.camera,
      mapData: mapData,
      reduceMotion: reduceMotion(),
    );
    onLoadingProgress?.call(0.08);
    await sceneBuilder.build(
      parent: host.world,
      mapData: mapData,
      imagePath: imagePath,
      viewMode: viewMode(),
      displaySettings: displaySettings(),
      onTileTapped: (tile) => unawaited(onTileTapped(tile)),
      onReferenceImageProgress: (progress) {
        final clamped = progress.clamp(0.0, 1.0).toDouble();
        onLoadingProgress?.call(0.08 + clamped * 0.62);
      },
    );
    onLoadingProgress?.call(0.72);

    effectDispatcher = GameEffectDispatcher(
      unitAnimationController: components.unitAnimations,
      cameraController: cameraController,
      particleEffectsLayer: components.particles,
      floatingTextLayer: components.floatingText,
      combatHexAlertLayer: components.combatAlerts,
      actionTargetHexFocusLayer: components.actionTargetHexFocus,
      particleParent: host.world,
      alertParent: sceneBuilder.grid,
      onRendererStateChanged: syncAfterAction,
      reduceMotion: reduceMotion,
      moveCameraForUnitMovement: moveCameraForUnitMovement,
      focusCameraForUnitMovementForUnit: focusCameraForUnitMovementForUnit,
      followCameraForUnitMovementForUnit: followCameraForUnitMovementForUnit,
      onUnitMovementCameraComplete: onUnitMovementCameraComplete,
      canAutoFocusMapTarget: canAutoFocusMapTarget,
      l10n: l10n,
    );
    onLoadingProgress?.call(0.78);

    renderingCoordinator = GameRenderingCoordinator(
      unitMarkers: components.unitMarkers,
      movePreview: components.movePreview,
      fieldImprovementMarkers: components.fieldImprovements,
      transportNetwork: components.transportNetwork,
      artifactMarkers: components.artifacts,
      mapObjectiveMarkers: components.mapObjectives,
      cityMarkers: components.cities,
      cityTerritory: components.cityTerritory,
      eraTint: components.eraTint,
      cityManagement: components.cityManagement,
      cityFounding: components.cityFounding,
      fogOfWar: components.fogOfWar,
      threatOverlay: components.threats,
      actionPalette: components.actionPalette,
      grid: sceneBuilder.grid,
    );
    onLoadingProgress?.call(0.84);

    isReady = true;
    if (startCameraOffMap) {
      cameraController.hideMap();
    } else {
      cameraController.restore(initialCamera);
    }
    publishZoom();
    syncMarkerDensityForZoom(force: true);
    syncAfterAction();
    onLoadingProgress?.call(0.92);
    _initialEffectFlushComplete = false;
    _initialEffectFlush = flushQueuedEffectBatches().whenComplete(
      () => _initialEffectFlushComplete = true,
    );
    unawaited(_releaseInitialPresentationBarrier());
    onLoadingProgress?.call(0.98);
    if (!isDisposed) readyNotifier.value = true;
    onLoadingProgress?.call(1);
  }

  Future<void> flushQueuedEffectBatches() async {
    effectDispatcher.prepareMovementOrigins(queuedEffects.pendingEffects);
    while (queuedEffects.hasPending && !isDisposed) {
      final batch = queuedEffects.takeNext();
      try {
        await effectDispatcher.handleEffects(
          batch.effects,
          beforeEffect: ensureRendererActive,
        );
        batch.complete();
      } catch (error, stackTrace) {
        batch.completeError(error, stackTrace);
      } finally {
        queuedEffects.finish(batch);
      }
    }
  }

  Future<void> _releaseInitialPresentationBarrier() async {
    await _initialEffectFlush;
    if (!_initialPresentationBarrier.isCompleted) {
      _initialPresentationBarrier.complete();
    }
  }

  void disposeRenderer() {
    if (isDisposed) return;
    isDisposed = true;
    final error = StateError(
      'GameRenderer disposed before queued effects completed',
    );
    if (!_initialPresentationBarrier.isCompleted) {
      _initialPresentationBarrier.complete();
    }
    queuedEffects.cancelAll(error, StackTrace.current);
    if (isReady) cameraController.cancelPendingMotion();
    readyNotifier.dispose();
    zoomNotifier.dispose();
    initialCameraFocusReadyNotifier.dispose();
    viewModelNotifier.dispose();
    components.unitAnimations.dispose();
  }
}

/// Thin Flame adapter; mutable lifecycle state lives in the handler.
mixin GameRendererLifecycleAdapter on HexWorld {
  GameRendererLifecycleHandler get lifecycleHandler;

  @override
  void update(double dt) {
    super.update(dt);
    lifecycleHandler.update(dt);
  }

  @override
  Future<void> buildWorld() => lifecycleHandler.buildWorld();

  void disposeRenderer() => lifecycleHandler.disposeRenderer();
}

final class QueuedRendererEffectQueue {
  final List<QueuedRendererEffectBatch> _pending = [];
  QueuedRendererEffectBatch? _active;

  bool get hasPending => _pending.isNotEmpty;

  Iterable<RendererEffect> get pendingEffects sync* {
    for (final batch in _pending) {
      yield* batch.effects;
    }
  }

  QueuedRendererEffectBatch enqueue(Iterable<RendererEffect> effects) {
    final batch = QueuedRendererEffectBatch(effects);
    _pending.add(batch);
    return batch;
  }

  QueuedRendererEffectBatch takeNext() {
    final batch = _pending.removeAt(0);
    _active = batch;
    return batch;
  }

  void finish(QueuedRendererEffectBatch batch) {
    if (identical(_active, batch)) _active = null;
  }

  void cancelAll(Object error, StackTrace stackTrace) {
    _active?.completeError(error, stackTrace);
    for (final batch in _pending) {
      batch.completeError(error, stackTrace);
    }
    _pending.clear();
  }
}

final class QueuedRendererEffectBatch {
  QueuedRendererEffectBatch(Iterable<RendererEffect> effects)
    : effects = List<RendererEffect>.unmodifiable(effects);

  final List<RendererEffect> effects;
  final Completer<void> _completer = Completer<void>();

  Future<void> get done => _completer.future;

  void complete() {
    if (!_completer.isCompleted) _completer.complete();
  }

  void completeError(Object error, StackTrace stackTrace) {
    if (!_completer.isCompleted) {
      _completer.completeError(error, stackTrace);
    }
  }
}
