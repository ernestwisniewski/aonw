import 'package:aonw/game/presentation/engine/game_render_view_model.dart';
import 'package:aonw/game/presentation/engine/game_renderer.dart'
    show WorkerActionPaletteOptionsBuilder;
import 'package:aonw/game/presentation/engine/game_renderer_components.dart';
import 'package:aonw/game/presentation/engine/game_renderer_layer_synchronizer.dart';
import 'package:aonw/game/presentation/engine/game_renderer_lifecycle_handler.dart';
import 'package:aonw/game/presentation/engine/game_renderer_state_sync_handler.dart';
import 'package:aonw/game/presentation/engine/game_scene_builder.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/marker_density_policy.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/rendering/hex_world.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

final class GameRendererRuntime {
  const GameRendererRuntime({
    required this.stateSync,
    required this.components,
    required this.lifecycle,
  });

  final GameRendererStateSyncHandler stateSync;
  final GameRendererComponents components;
  final GameRendererLifecycleHandler lifecycle;
}

final class GameRendererRuntimeBindings {
  const GameRendererRuntimeBindings({
    required this.host,
    required this.mapData,
    required this.sceneBuilder,
    required this.viewModelNotifier,
    required this.zoomNotifier,
    required this.readyNotifier,
    required this.initialCameraFocusReadyNotifier,
    required this.loadingPlayerId,
    required this.initialViewMode,
    required this.initialDisplaySettings,
    required this.initialReduceMotion,
    required this.workerOptionsBuilder,
    required this.imagePath,
    required this.initialCamera,
    required this.startCameraOffMap,
    required this.onLoadingProgress,
    required this.l10n,
    required this.isDragging,
    required this.hasMultipleViewportPointers,
    required this.inspectionActive,
    required this.tileDataAtWidgetPosition,
    required this.markerDensityForZoomSync,
    required this.fastCameraRendering,
    required this.focusInitialActivePlayer,
    required this.focusActiveSelection,
    required this.primeSelectionFocus,
    required this.onUnitTapped,
    required this.onArtifactTapped,
    required this.onObjectiveTapped,
    required this.onCityTapped,
    required this.onPreviewWorkerImprovement,
    required this.onConfirmWorkerImprovement,
    required this.onCancelWorkerActionSelection,
    required this.onConfirmMovePreview,
    required this.moveCameraForUnitMovement,
    required this.focusCameraForUnitMovementForUnit,
    required this.followCameraForUnitMovementForUnit,
    required this.onUnitMovementCameraComplete,
    required this.canAutoFocusMapTarget,
    required this.onTileTapped,
    required this.syncFastCameraRendering,
    required this.ensureRendererActive,
  });

  final HexWorld host;
  final WorldMap mapData;
  final GameSceneBuilder sceneBuilder;
  final ValueNotifier<RenderState> viewModelNotifier;
  final ValueNotifier<double> zoomNotifier;
  final ValueNotifier<bool> readyNotifier;
  final ValueNotifier<bool> initialCameraFocusReadyNotifier;
  final String loadingPlayerId;
  final MapViewMode initialViewMode;
  final HexDisplaySettings initialDisplaySettings;
  final bool initialReduceMotion;
  final WorkerActionPaletteOptionsBuilder? workerOptionsBuilder;
  final String? imagePath;
  final CameraState? initialCamera;
  final bool startCameraOffMap;
  final ValueChanged<double>? onLoadingProgress;
  final AppLocalizations? l10n;
  final bool Function() isDragging;
  final bool Function() hasMultipleViewportPointers;
  final bool Function() inspectionActive;
  final WorldTile? Function(Vector2 position) tileDataAtWidgetPosition;
  final MarkerDensity? Function({required bool force}) markerDensityForZoomSync;
  final bool Function() fastCameraRendering;
  final void Function() focusInitialActivePlayer;
  final void Function() focusActiveSelection;
  final void Function() primeSelectionFocus;
  final void Function(String unitId) onUnitTapped;
  final void Function(WorldArtifact artifact) onArtifactTapped;
  final void Function(MapObjectiveProgress progress) onObjectiveTapped;
  final void Function(GameCity city) onCityTapped;
  final void Function(String unitId, String optionId)
  onPreviewWorkerImprovement;
  final void Function(String unitId) onConfirmWorkerImprovement;
  final void Function(String unitId) onCancelWorkerActionSelection;
  final void Function(int col, int row) onConfirmMovePreview;
  final bool Function() moveCameraForUnitMovement;
  final bool Function(String unitId) focusCameraForUnitMovementForUnit;
  final bool Function(String unitId) followCameraForUnitMovementForUnit;
  final Future<void> Function(String unitId) onUnitMovementCameraComplete;
  final bool Function(int col, int row) canAutoFocusMapTarget;
  final Future<void> Function(WorldTile tile) onTileTapped;
  final void Function(double dt) syncFastCameraRendering;
  final void Function() ensureRendererActive;
}

abstract final class GameRendererRuntimeFactory {
  static const markerDensityPolicy = MarkerDensityPolicy();

  static GameRendererRuntime create(GameRendererRuntimeBindings bindings) {
    late GameRendererStateSyncHandler stateSync;
    late GameRendererComponents components;
    late GameRendererLifecycleHandler lifecycle;

    final layerSynchronizer = GameRendererLayerSynchronizer(
      mapData: bindings.mapData,
      markerDensityPolicy: markerDensityPolicy,
      sceneBuilder: bindings.sceneBuilder,
      viewModelNotifier: bindings.viewModelNotifier,
      zoomNotifier: bindings.zoomNotifier,
      isReady: () => lifecycle.isReady,
      isDisposed: () => lifecycle.isDisposed,
      world: () => bindings.host.world,
      camera: () => bindings.host.camera,
      cameraController: () => lifecycle.cameraController,
      renderingCoordinator: () => lifecycle.renderingCoordinator,
      combatHexAlertLayer: () => components.combatAlerts,
      cityProductionParticleLayer: () => components.cityProductionParticles,
      cloudDriftLayer: () => components.cloudDrift,
      cityMarkerLayer: () => components.cities,
      unitMarkerLayer: () => components.unitMarkers,
      artifactMarkerLayer: () => components.artifacts,
      mapObjectiveMarkerLayer: () => components.mapObjectives,
      cityTerritoryOverlayLayer: () => components.cityTerritory,
      movePreviewLayer: () => components.movePreview,
      floatingTextLayer: () => components.floatingText,
      markerDensityForZoomSync: bindings.markerDensityForZoomSync,
      fastCameraRendering: bindings.fastCameraRendering,
      state: () => stateSync.state,
      currentTurn: () => stateSync.currentTurn,
      viewMode: () => stateSync.viewMode,
      reduceMotion: () => stateSync.reduceMotion,
      workerActionPaletteOptions: () => stateSync.workerActionPaletteOptions(),
      focusInitialActivePlayer: bindings.focusInitialActivePlayer,
      focusActiveSelection: bindings.focusActiveSelection,
      primeSelectionFocus: bindings.primeSelectionFocus,
      syncHoverIntentAfterStateChange: () =>
          stateSync.syncHoverIntentAfterStateChange(),
    );
    stateSync = GameRendererStateSyncHandler(
      loadingPlayerId: bindings.loadingPlayerId,
      initialViewMode: bindings.initialViewMode,
      initialDisplaySettings: bindings.initialDisplaySettings,
      initialReduceMotion: bindings.initialReduceMotion,
      workerOptionsBuilder: bindings.workerOptionsBuilder,
      mapData: bindings.mapData,
      layerSynchronizer: layerSynchronizer,
      sceneBuilder: bindings.sceneBuilder,
      viewModelNotifier: bindings.viewModelNotifier,
      isReady: () => lifecycle.isReady,
      isDisposed: () => lifecycle.isDisposed,
      isDragging: bindings.isDragging,
      hasMultipleViewportPointers: bindings.hasMultipleViewportPointers,
      inspectionActive: bindings.inspectionActive,
      hoverIntentMarkerLayer: () => components.hoverIntent,
      tileDataAtWidgetPosition: bindings.tileDataAtWidgetPosition,
    );
    components = GameRendererComponents(
      mapData: bindings.mapData,
      reduceMotion: bindings.initialReduceMotion,
      colorForPlayer: layerSynchronizer.colorForPlayer,
      onUnitTapped: bindings.onUnitTapped,
      onArtifactTapped: bindings.onArtifactTapped,
      onObjectiveTapped: bindings.onObjectiveTapped,
      onCityTapped: bindings.onCityTapped,
      onPreviewWorkerImprovement: bindings.onPreviewWorkerImprovement,
      onConfirmWorkerImprovement: bindings.onConfirmWorkerImprovement,
      onCancelWorkerActionSelection: bindings.onCancelWorkerActionSelection,
      onConfirmMovePreview: bindings.onConfirmMovePreview,
      l10n: bindings.l10n,
    );
    lifecycle = GameRendererLifecycleHandler(
      host: bindings.host,
      mapData: bindings.mapData,
      components: components,
      sceneBuilder: bindings.sceneBuilder,
      imagePath: bindings.imagePath,
      initialCamera: bindings.initialCamera,
      startCameraOffMap: bindings.startCameraOffMap,
      onLoadingProgress: bindings.onLoadingProgress,
      l10n: bindings.l10n,
      viewMode: () => stateSync.viewMode,
      displaySettings: () => stateSync.displaySettings,
      reduceMotion: () => stateSync.reduceMotion,
      moveCameraForUnitMovement: bindings.moveCameraForUnitMovement,
      focusCameraForUnitMovementForUnit:
          bindings.focusCameraForUnitMovementForUnit,
      followCameraForUnitMovementForUnit:
          bindings.followCameraForUnitMovementForUnit,
      onUnitMovementCameraComplete: bindings.onUnitMovementCameraComplete,
      canAutoFocusMapTarget: bindings.canAutoFocusMapTarget,
      onTileTapped: bindings.onTileTapped,
      syncAfterAction: stateSync.syncAfterAction,
      publishZoom: layerSynchronizer.publishZoom,
      syncMarkerDensityForZoom: layerSynchronizer.syncMarkerDensityForZoom,
      syncFastCameraRendering: bindings.syncFastCameraRendering,
      ensureRendererActive: bindings.ensureRendererActive,
      readyNotifier: bindings.readyNotifier,
      zoomNotifier: bindings.zoomNotifier,
      initialCameraFocusReadyNotifier: bindings.initialCameraFocusReadyNotifier,
      viewModelNotifier: bindings.viewModelNotifier,
    );
    return GameRendererRuntime(
      stateSync: stateSync,
      components: components,
      lifecycle: lifecycle,
    );
  }
}
