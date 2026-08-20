import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/authoritative_presentation_scheduler.dart';
import 'package:aonw/game/presentation/engine/game_camera_controller.dart';
import 'package:aonw/game/presentation/engine/game_effect_dispatcher.dart';
import 'package:aonw/game/presentation/engine/game_render_view_model.dart';
import 'package:aonw/game/presentation/engine/game_renderer_camera_policy.dart';
import 'package:aonw/game/presentation/engine/game_renderer_camera_settings.dart';
import 'package:aonw/game/presentation/engine/game_renderer_components.dart';
import 'package:aonw/game/presentation/engine/game_renderer_input_handler.dart';
import 'package:aonw/game/presentation/engine/game_renderer_lifecycle_handler.dart';
import 'package:aonw/game/presentation/engine/game_renderer_runtime_factory.dart';
import 'package:aonw/game/presentation/engine/game_renderer_state_sync_handler.dart';
import 'package:aonw/game/presentation/engine/game_renderer_transition_handler.dart';
import 'package:aonw/game/presentation/engine/game_scene_builder.dart';
import 'package:aonw/game/presentation/engine/hex_selection/hex_selection_target.dart';
import 'package:aonw/game/presentation/engine/hex_selection/hex_selection_target_resolver.dart';
import 'package:aonw/game/presentation/engine/map_hex_double_tap_tracker.dart';
import 'package:aonw/game/presentation/engine/map_tap_cycle.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw/game/presentation/engine/projected_transition_presenter.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_component.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_option.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/artifacts/artifact_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_management_overlay.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_management_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_territory_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/combat_hex_alert_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/particle_effects_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/hex_selection_palette/hex_selection_palette_component.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/hex_selection_palette/hex_selection_palette_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/improvements/field_improvement_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/hover_intent_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/map_pill.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/marker_density_policy.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/overlays/threat_overlay.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/overlays/threat_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw/game/presentation/engine/unit_animation_controller.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/services/map_focus_visibility.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_tile_markers.dart';
import 'package:aonw/map/rendering/hex_world.dart';
import 'package:aonw/map/rendering/map_objective_marker_layer.dart';
import 'package:aonw/map/rendering/world_projection.dart';
import 'package:aonw/shared/input/hex_input_behavior.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Offset;

part 'game_renderer_artifact_taps.dart';
part 'game_renderer_camera_focus.dart';
part 'game_renderer_camera_rendering.dart';
part 'game_renderer_entity_taps.dart';
part 'game_renderer_gamepad_input.dart';
part 'game_renderer_hex_selection.dart';
part 'game_renderer_projected_effects.dart';
part 'game_renderer_testing.dart';
part 'game_renderer_tile_interactions.dart';
part 'game_renderer_types.dart';

/// Flame renderer for the game map.
///
/// Owns the world hierarchy, forwards input as commands, and keeps visual
/// layers in sync with [GameClientState].
class GameRenderer extends HexWorld
    with
        KeyboardEvents,
        HexInputBehavior,
        GameRendererInputAdapter,
        GameRendererLifecycleAdapter {
  static const _loadingPlayerId = '__loading__';
  static const double _selectionCameraTransitionDuration = 0.42;
  static const WorldProjection _roundEarthProjection = WorldProjection(
    strength: 0.26,
  );

  final WorldMap mapData;
  final String? imagePath;
  final CameraState? initialCamera;
  final bool startCameraOffMap;
  final bool focusActivePlayerOnFirstState;
  final Future<void> Function(GameIntent intent) onCommand;
  final TileInspectionCallback? onTileInspected;
  final ArtifactInspectionCallback? onArtifactInspected;
  final ObjectiveInspectionCallback? onObjectiveInspected;
  final VoidCallback? onHexSelectionPaletteOpened;
  final ValueChanged<double>? onLoadingProgress;
  final AppLocalizations? l10n;
  final Clock? presentationClock;

  final GameRendererCameraSettings _cameraSettings;
  late final GameRendererCameraPolicy _cameraPolicy;

  final GameSceneBuilder _sceneBuilder = GameSceneBuilder();

  late final GameRendererComponents _components;
  late final GameRendererLifecycleHandler _lifecycleHandler;
  bool _cameraFastRendering = false;
  double _cameraFastRenderHoldRemaining = 0;
  Vector2? _lastCameraPositionForFastRender;
  double? _lastCameraZoomForFastRender;
  bool _didFocusInitialPlayer = false;
  Vector2? _deferredInitialFocusPoint;
  bool _didPrimeSelectionFocus = false;
  String? _lastFocusedSelectionKey;
  final MapHexDoubleTapTracker _mapDoubleTapTracker =
      MapHexDoubleTapTracker.withStopwatch();
  final MapTapCycle _mapTapCycle = MapTapCycle();
  final ValueNotifier<RenderState> _viewModelNotifier = ValueNotifier(
    RenderState.empty,
  );
  final ValueNotifier<bool> _readyNotifier = ValueNotifier(false);
  final ValueNotifier<double> _zoomNotifier = ValueNotifier(1.0);
  final ValueNotifier<bool> _initialCameraFocusReadyNotifier;
  late final GameRendererStateSyncHandler _stateSyncHandler;
  late final GameRendererTransitionHandler _transitionHandler =
      GameRendererTransitionHandler(
        ensureActive: _ensureRendererActive,
        renderState: () => _renderState,
        isDisposed: () => _isDisposed,
        transitionControlsCamera: _cameraPolicy.transitionControlsCamera,
        applyState: _applyState,
        handleEffectsNow: _handleEffectsNow,
        unitMarkers: () => _unitMarkerLayer,
        cityMarkers: () => _cityMarkerLayer,
        unitAnimations: () => _unitAnimationController,
        synchronize: _syncAfterAction,
      );
  @override
  late final GameRendererInputHandler inputHandler = GameRendererInputHandler(
    state: () => _renderState,
    onCommand: onCommand,
    clearHover: _clearHoverIntent,
    syncHover: _syncHoverIntentForTile,
    setHoverPosition: (position) => _lastHoverWidgetPosition = position,
    openSelectionPalette: _openHexSelectionPalette,
    closeSelectionPalette: _clearHexSelectionPalette,
  );

  GameRenderer({
    required this.mapData,
    this.imagePath,
    this.initialCamera,
    this.startCameraOffMap = false,
    this.focusActivePlayerOnFirstState = false,
    required this.onCommand,
    this.onTileInspected,
    this.onArtifactInspected,
    this.onObjectiveInspected,
    this.onHexSelectionPaletteOpened,
    this.onLoadingProgress,
    this.l10n,
    this.presentationClock,
    WorkerActionPaletteOptionsBuilder? workerActionPaletteOptionsBuilder,
    MapViewMode initialViewMode = MapViewMode.tile,
    HexDisplaySettings? displaySettings,
    bool reduceMotion = false,
    bool moveCameraForUnitMovement = true,
    bool followUnitMovementCamera = false,
    bool followEnemyUnitCamera = false,
    bool? focusOwnUnitMovementCamera,
    bool? followOwnUnitMovementCamera,
    bool? focusEnemyUnitMovementCamera,
    bool? followEnemyUnitMovementCamera,
    bool cinematicCameraEnabled = false,
  }) : _cameraSettings = GameRendererCameraSettings(
         moveCameraForUnitMovement: moveCameraForUnitMovement,
         focusOwnUnitMovementCamera:
             focusOwnUnitMovementCamera ?? moveCameraForUnitMovement,
         followOwnUnitMovementCamera:
             followOwnUnitMovementCamera ?? followUnitMovementCamera,
         focusEnemyUnitMovementCamera:
             focusEnemyUnitMovementCamera ?? followEnemyUnitCamera,
         followEnemyUnitMovementCamera:
             followEnemyUnitMovementCamera ??
             (followUnitMovementCamera && followEnemyUnitCamera),
         cinematicCameraEnabled: cinematicCameraEnabled,
       ),
       _initialCameraFocusReadyNotifier = ValueNotifier(
         !focusActivePlayerOnFirstState,
       ) {
    _cameraPolicy = GameRendererCameraPolicy(
      settings: _cameraSettings,
      state: () => _renderState,
      isDisposed: () => _isDisposed,
      focusActiveSelection: () => _focusSelection(_renderState.selection),
    );
    _initializeRuntime(
      initialViewMode: initialViewMode,
      displaySettings: displaySettings ?? const HexDisplaySettings(),
      reduceMotion: reduceMotion,
      workerOptionsBuilder: workerActionPaletteOptionsBuilder,
    );
  }

  double get defaultZoom => mapData.defaultZoom;

  MapViewMode get viewMode => _stateSyncHandler.viewMode;

  set viewMode(MapViewMode value) => _stateSyncHandler.viewMode = value;

  set workerActionPaletteOptionsBuilder(
    WorkerActionPaletteOptionsBuilder? value,
  ) => _stateSyncHandler.workerOptionsBuilder = value;

  set displaySettings(HexDisplaySettings value) =>
      _stateSyncHandler.displaySettings = value;

  bool get reduceMotion => _stateSyncHandler.reduceMotion;

  set reduceMotion(bool value) => _stateSyncHandler.reduceMotion = value;

  void applyState(GameClientState state, {int? currentTurn}) =>
      _applyState(state, suppressCameraFocus: false, currentTurn: currentTurn);

  void applyStateWithoutCameraFocus(
    GameClientState state, {
    int? currentTurn,
  }) => _applyState(state, suppressCameraFocus: true, currentTurn: currentTurn);

  @override
  void setZoom(double zoom) {
    _clearHexSelectionPalette();
    _setFastCameraRendering(true);
    super.setZoom(zoom);
    _publishZoom();
    if (!_isReady) return;
    _syncMarkerDensityForZoom();
  }

  @override
  void panByScreenDelta(Vector2 screenDelta) {
    _clearHexSelectionPalette();
    _setFastCameraRendering(true);
    super.panByScreenDelta(screenDelta);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_isReady || _isDisposed) return;
    _applyDeferredInitialFocusIfReady();
    _syncMarkerDensityForZoom(force: true);
  }

  @override
  WorldProjection get worldProjection =>
      cinematicCameraEnabled ? _roundEarthProjection : WorldProjection.disabled;

  ValueListenable<Set<String>> get animatingUnitIdsListenable =>
      _unitAnimationController.animatingUnitIdsListenable;

  Future<void> applyTransition(
    GameClientState state,
    Iterable<RendererEffect> effects, {
    int? currentTurn,
  }) {
    return _transitionHandler.enqueue(
      () =>
          _transitionHandler.applyNow(state, effects, currentTurn: currentTurn),
    );
  }

  Future<void> handleEffects(Iterable<RendererEffect> effects) =>
      _transitionHandler.enqueue(() => _handleEffectsNow(effects));

  Future<void> handleEffect(RendererEffect effect) => handleEffects([effect]);

  Future<void> _handleEffectsNow(
    Iterable<RendererEffect> effects, {
    bool waitForQueuedPlayback = false,
  }) async {
    _ensureRendererActive();
    final pending = effects.toList();
    if (pending.isEmpty) return;
    if (!_isReady) {
      final batch = _queuedRendererEffects.enqueue(pending);
      if (waitForQueuedPlayback) {
        await batch.done;
      } else {
        batch.done.ignore();
      }
      return;
    }
    final initialEffectFlush = _lifecycleHandler.pendingInitialEffectFlush;
    if (initialEffectFlush != null) {
      await initialEffectFlush;
      _ensureRendererActive();
    }
    await _effectDispatcher.handleEffects(
      pending,
      beforeEffect: _ensureRendererActive,
    );
  }

  void _ensureRendererActive() {
    if (_isDisposed) throw StateError('GameRenderer disposed');
  }

  @override
  bool get rendererInputReady => _isReady;

  @override
  HexGrid get grid => _sceneBuilder.grid;

  @override
  void clearRendererHoverIntent() => _clearHoverIntent();

  @override
  void syncRendererHoverAt(Vector2 position) {
    _syncHoverIntentAtWidgetPosition(position);
  }

  @override
  void clearRendererHexSelectionPalette() => _clearHexSelectionPalette();

  @override
  GameRendererLifecycleHandler get lifecycleHandler => _lifecycleHandler;

  bool get hasReferenceImage => _lifecycleHandler.hasReferenceImage;

  bool get _isReady => _lifecycleHandler.isReady;
  bool get _isDisposed => _lifecycleHandler.isDisposed;
  GameCameraController get _cameraController =>
      _lifecycleHandler.cameraController;
  GameEffectDispatcher get _effectDispatcher =>
      _lifecycleHandler.effectDispatcher;
  QueuedRendererEffectQueue get _queuedRendererEffects =>
      _lifecycleHandler.queuedEffects;

  UnitMarkerLayer get _unitMarkerLayer => _components.unitMarkers;
  FieldImprovementMarkerLayer get _fieldImprovementMarkerLayer =>
      _components.fieldImprovements;
  ArtifactMarkerLayer get _artifactMarkerLayer => _components.artifacts;
  MapObjectiveMarkerLayer get _mapObjectiveMarkerLayer =>
      _components.mapObjectives;
  CityMarkerLayer get _cityMarkerLayer => _components.cities;
  CityTerritoryOverlayLayer get _cityTerritoryOverlayLayer =>
      _components.cityTerritory;
  CityManagementOverlayLayer get _cityManagementOverlayLayer =>
      _components.cityManagement;
  CityProductionParticleLayer get _cityProductionParticleLayer =>
      _components.cityProductionParticles;
  CombatHexAlertLayer get _combatHexAlertLayer => _components.combatAlerts;
  ThreatOverlayLayer get _threatOverlayLayer => _components.threats;
  HoverIntentMarkerLayer get _hoverIntentMarkerLayer => _components.hoverIntent;
  ActionPaletteLayer get _actionPaletteLayer => _components.actionPalette;
  HexSelectionPaletteLayer get _hexSelectionPaletteLayer =>
      _components.hexSelectionPalette;
  UnitAnimationController get _unitAnimationController =>
      _components.unitAnimations;

  GameClientState get _renderState => _stateSyncHandler.state;
  bool get _reduceMotion => _stateSyncHandler.reduceMotion;
  set _lastHoverWidgetPosition(Vector2? value) =>
      _stateSyncHandler.lastHoverWidgetPosition = value;
  set _lastSyncedHoverHex(({int col, int row, bool forceInspect})? value) =>
      _stateSyncHandler.lastSyncedHoverHex = value;

  void _applyState(
    GameClientState state, {
    required bool suppressCameraFocus,
    int? currentTurn,
  }) => _stateSyncHandler.applyState(
    state,
    suppressCameraFocus: suppressCameraFocus,
    currentTurn: currentTurn,
  );

  void _syncAfterAction({bool suppressCameraFocus = false}) => _stateSyncHandler
      .syncAfterAction(suppressCameraFocus: suppressCameraFocus);
  MarkerDensity get _currentMarkerDensity =>
      _stateSyncHandler.currentMarkerDensity;
  void _publishZoom() => _stateSyncHandler.publishZoom();
  void _syncMarkerDensityForZoom({bool force = false}) =>
      _stateSyncHandler.syncMarkerDensityForZoom(force: force);
  void _syncHoverIntentAtWidgetPosition(
    Vector2 position, {
    bool forceInspect = false,
  }) => _stateSyncHandler.syncHoverIntentAtWidgetPosition(
    position,
    forceInspect: forceInspect,
  );
  void _syncHoverIntentForTile(WorldTile tile, {bool forceInspect = false}) =>
      _stateSyncHandler.syncHoverIntentForTile(
        tile,
        forceInspect: forceInspect,
      );
  void _refreshHoverIntent() => _stateSyncHandler.refreshHoverIntent();
  void _clearHoverIntent() => _stateSyncHandler.clearHoverIntent();
  void _primeSelectionFocus() {
    _lastFocusedSelectionKey = _selectionFocusKey(_renderState.selection);
    _didPrimeSelectionFocus = true;
  }
}

extension _GameRendererRuntimeInitialization on GameRenderer {
  void _initializeRuntime({
    required MapViewMode initialViewMode,
    required HexDisplaySettings displaySettings,
    required bool reduceMotion,
    required WorkerActionPaletteOptionsBuilder? workerOptionsBuilder,
  }) {
    final runtime = GameRendererRuntimeFactory.create(
      GameRendererRuntimeBindings(
        host: this,
        mapData: mapData,
        sceneBuilder: _sceneBuilder,
        viewModelNotifier: _viewModelNotifier,
        zoomNotifier: _zoomNotifier,
        readyNotifier: _readyNotifier,
        initialCameraFocusReadyNotifier: _initialCameraFocusReadyNotifier,
        loadingPlayerId: GameRenderer._loadingPlayerId,
        initialViewMode: initialViewMode,
        initialDisplaySettings: displaySettings,
        initialReduceMotion: reduceMotion,
        workerOptionsBuilder: workerOptionsBuilder,
        imagePath: imagePath,
        initialCamera: initialCamera,
        startCameraOffMap: startCameraOffMap,
        onLoadingProgress: onLoadingProgress,
        l10n: l10n,
        isDragging: () => isDragging,
        hasMultipleViewportPointers: () => hasMultipleViewportPointers,
        inspectionActive: () => inputHandler.isActive,
        tileDataAtWidgetPosition: tileDataAtWidgetPosition,
        markerDensityForZoomSync: _markerDensityForZoomSync,
        fastCameraRendering: () => _cameraFastRendering,
        focusInitialActivePlayer: _focusInitialActivePlayer,
        focusActiveSelection: _focusActiveSelection,
        primeSelectionFocus: _primeSelectionFocus,
        onUnitTapped: _handleUnitMarkerTapped,
        onArtifactTapped: _handleArtifactMarkerTapped,
        onObjectiveTapped: _handleMapObjectiveMarkerTapped,
        onCityTapped: _handleCityMarkerTapped,
        onPreviewWorkerImprovement: _handlePreviewWorkerImprovement,
        onConfirmWorkerImprovement: _handleConfirmWorkerImprovement,
        onCancelWorkerActionSelection: _handleCancelWorkerActionSelection,
        onConfirmMovePreview: _handleConfirmMovePreview,
        onHexSelectionTargetSelected: _handleHexSelectionTargetSelected,
        moveCameraForUnitMovement: () => moveCameraForUnitMovement,
        focusCameraForUnitMovementForUnit: _cameraPolicy.focusCameraForUnit,
        followCameraForUnitMovementForUnit: _cameraPolicy.followCameraForUnit,
        onUnitMovementCameraComplete: _cameraPolicy.restoreAfterUnitMovement,
        canAutoFocusMapTarget: _canAutoFocusMapTarget,
        onTileTapped: _handleTileTapped,
        syncFastCameraRendering: _syncFastCameraRendering,
        ensureRendererActive: _ensureRendererActive,
      ),
    );
    _stateSyncHandler = runtime.stateSync;
    _components = runtime.components;
    _lifecycleHandler = runtime.lifecycle;
  }
}
