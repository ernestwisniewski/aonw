import 'dart:async';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/artifact_marker_tap_cycle.dart';
import 'package:aonw/game/presentation/engine/city_description_tap_tracker.dart';
import 'package:aonw/game/presentation/engine/game_camera_controller.dart';
import 'package:aonw/game/presentation/engine/game_effect_dispatcher.dart';
import 'package:aonw/game/presentation/engine/game_hover_intent_resolver.dart';
import 'package:aonw/game/presentation/engine/game_render_view_model.dart';
import 'package:aonw/game/presentation/engine/game_rendering_coordinator.dart';
import 'package:aonw/game/presentation/engine/game_scene_builder.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_component.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_option.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/artifacts/artifact_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_founding_preview_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_management_overlay.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_management_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_territory_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/cloud_drift_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/combat_hex_alert_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/era_tint_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/floating_text_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/particle_effects_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/improvements/field_improvement_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/hover_intent_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/map_pill.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/marker_density_policy.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/overlays/fog_of_war_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/overlays/threat_overlay.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/overlays/threat_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_move_preview_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw/game/presentation/engine/unit_animation_controller.dart';
import 'package:aonw/game/presentation/services/map_focus_visibility.dart';
import 'package:aonw/game/presentation/widgets/theme/player_color_theme.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_tile_markers.dart';
import 'package:aonw/map/rendering/hex_world.dart';
import 'package:aonw/map/rendering/map_objective_marker_layer.dart';
import 'package:aonw/map/rendering/world_projection.dart';
import 'package:aonw/shared/input/hex_input_behavior.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Offset;

part 'game_renderer_artifact_taps.dart';
part 'game_renderer_camera_focus.dart';
part 'game_renderer_camera_policy.dart';
part 'game_renderer_camera_rendering.dart';
part 'game_renderer_input.dart';
part 'game_renderer_state_sync.dart';
part 'game_renderer_testing.dart';
part 'game_renderer_tile_interactions.dart';
part 'game_renderer_world_lifecycle.dart';

typedef WorkerActionPaletteOptionsBuilder =
    List<ActionPaletteOption> Function({
      required GameState state,
      required GameUnit worker,
      required PendingWorkerActionSelection pendingAction,
      required MapData mapData,
    });
typedef TileInspectionCallback =
    void Function(TileData tileData, Offset anchor);
typedef ArtifactInspectionCallback =
    void Function(WorldArtifact artifact, Offset anchor);
typedef ObjectiveInspectionCallback =
    void Function(MapObjectiveProgress progress, Offset anchor);

/// Flame renderer for the game map.
///
/// Owns the world hierarchy, forwards input as commands, and keeps visual
/// layers in sync with [GameState].
class GameRenderer extends HexWorld
    with KeyboardEvents, LongPressDetector, HexInputBehavior {
  static const _loadingPlayerId = '__loading__';
  static const double _selectionCameraTransitionDuration = 0.42;
  static const WorldProjection _roundEarthProjection = WorldProjection(
    strength: 0.26,
  );
  static const MarkerDensityPolicy _markerDensityPolicy = MarkerDensityPolicy();

  final MapData mapData;
  final String? imagePath;
  final CameraState? initialCamera;
  final bool startCameraOffMap;
  final bool focusActivePlayerOnFirstState;
  final Future<void> Function(GameCommand command) onCommand;
  final void Function(GameCity city)? onCityDescriptionRequested;
  final TileInspectionCallback? onTileInspected;
  final TileInspectionCallback? onTileInspectionPreviewed;
  final ArtifactInspectionCallback? onArtifactInspected;
  final ObjectiveInspectionCallback? onObjectiveInspected;
  final VoidCallback? onTileInspectionConfirmed;
  final VoidCallback? onTileInspectionCanceled;
  final ValueChanged<double>? onLoadingProgress;
  final AppLocalizations? l10n;

  MapViewMode _viewMode;
  HexDisplaySettings _displaySettings;
  bool _reduceMotion;
  bool _moveCameraForUnitMovement;
  bool _followUnitMovementCamera;
  bool _followEnemyUnitCamera;
  bool _cinematicCameraEnabled;

  final GameSceneBuilder _sceneBuilder = GameSceneBuilder();

  late final GameCameraController _cameraController;

  late final UnitMarkerLayer _unitMarkerLayer;
  late final UnitMovePreviewLayer _movePreviewLayer;
  late final FieldImprovementMarkerLayer _fieldImprovementMarkerLayer;
  late final ArtifactMarkerLayer _artifactMarkerLayer;
  late final MapObjectiveMarkerLayer _mapObjectiveMarkerLayer;
  late final CityMarkerLayer _cityMarkerLayer;
  late final CityTerritoryOverlayLayer _cityTerritoryOverlayLayer;
  late final EraTintOverlayLayer _eraTintOverlayLayer;
  late final CityManagementOverlayLayer _cityManagementOverlayLayer;
  late final CityFoundingPreviewLayer _cityFoundingPreviewLayer;
  late final FogOfWarOverlayLayer _fogOfWarOverlayLayer;
  late final ParticleEffectsLayer _particleEffectsLayer;
  late final CityProductionParticleLayer _cityProductionParticleLayer;
  late final CloudDriftLayer _cloudDriftLayer;
  late final FloatingTextLayer _floatingTextLayer;
  late final CombatHexAlertLayer _combatHexAlertLayer;
  late final ThreatOverlayLayer _threatOverlayLayer;
  late final HoverIntentMarkerLayer _hoverIntentMarkerLayer;
  late final ActionPaletteLayer _actionPaletteLayer;

  late final GameRenderingCoordinator _renderingCoordinator;

  late final UnitAnimationController _unitAnimationController;
  late final GameEffectDispatcher _effectDispatcher;

  bool _isReady = false;
  bool _isDisposed = false;
  bool _cameraFastRendering = false;
  double _cameraFastRenderHoldRemaining = 0;
  Vector2? _lastCameraPositionForFastRender;
  double? _lastCameraZoomForFastRender;
  bool _didFocusInitialPlayer = false;
  Vector2? _deferredInitialFocusPoint;
  bool _didPrimeSelectionFocus = false;
  String? _lastFocusedSelectionKey;
  Vector2? _lastHoverWidgetPosition;
  ({int col, int row, bool forceInspect})? _lastSyncedHoverHex;
  GameHoverIntentResolver? _cachedHoverIntentResolver;
  GameState? _cachedHoverIntentResolverState;
  bool? _cachedHoverIntentResolverReduceMotion;
  bool _longPressInspectActive = false;
  bool _longPressInspectionPreviewActive = false;
  bool _suppressTapsUntilNextPointerDown = false;
  final CityDescriptionTapTracker _cityTapTracker =
      CityDescriptionTapTracker.withStopwatch();
  final ArtifactMarkerTapCycle _artifactTapCycle = ArtifactMarkerTapCycle();
  CityHex? _longPressInspectHex;
  GameState _renderState = const GameState(activePlayerId: _loadingPlayerId);
  final List<RendererEffect> _queuedRendererEffects = [];
  WorkerActionPaletteOptionsBuilder? _workerActionPaletteOptionsBuilder;
  final ValueNotifier<GameRenderViewModel> _viewModelNotifier = ValueNotifier(
    GameRenderViewModel.empty,
  );
  final ValueNotifier<bool> _readyNotifier = ValueNotifier(false);
  final ValueNotifier<double> _zoomNotifier = ValueNotifier(1.0);
  final ValueNotifier<bool> _initialCameraFocusReadyNotifier;
  Future<void> _transitionQueue = Future<void>.value();

  ValueListenable<Set<String>> get animatingUnitIdsListenable =>
      _unitAnimationController.animatingUnitIdsListenable;

  GameRenderer({
    required this.mapData,
    this.imagePath,
    this.initialCamera,
    this.startCameraOffMap = false,
    this.focusActivePlayerOnFirstState = false,
    required this.onCommand,
    this.onCityDescriptionRequested,
    this.onTileInspected,
    this.onTileInspectionPreviewed,
    this.onArtifactInspected,
    this.onObjectiveInspected,
    this.onTileInspectionConfirmed,
    this.onTileInspectionCanceled,
    this.onLoadingProgress,
    this.l10n,
    WorkerActionPaletteOptionsBuilder? workerActionPaletteOptionsBuilder,
    MapViewMode initialViewMode = MapViewMode.tile,
    HexDisplaySettings? displaySettings,
    bool reduceMotion = false,
    bool moveCameraForUnitMovement = true,
    bool followUnitMovementCamera = false,
    bool followEnemyUnitCamera = false,
    bool cinematicCameraEnabled = false,
  }) : _viewMode = initialViewMode,
       _displaySettings = displaySettings ?? const HexDisplaySettings(),
       _reduceMotion = reduceMotion,
       _moveCameraForUnitMovement = moveCameraForUnitMovement,
       _followUnitMovementCamera = followUnitMovementCamera,
       _followEnemyUnitCamera = followEnemyUnitCamera,
       _cinematicCameraEnabled = cinematicCameraEnabled,
       _initialCameraFocusReadyNotifier = ValueNotifier(
         !focusActivePlayerOnFirstState,
       ),
       _workerActionPaletteOptionsBuilder = workerActionPaletteOptionsBuilder {
    final localizations = l10n;
    final turnCostLabelBuilder = localizations == null
        ? null
        : (int count) => localizations.turnCountLabel(count);
    final moveConfirmationLabelBuilder = localizations == null
        ? null
        : (int count) => localizations.selectionActionConfirmWithTurns(
            localizations.turnCountLabel(count),
          );
    _unitMarkerLayer = UnitMarkerLayer(
      mapData: mapData,
      colorForPlayer: _colorForPlayer,
      onUnitTapped: _handleUnitMarkerTapped,
      reduceMotion: _reduceMotion,
    );
    _movePreviewLayer = UnitMovePreviewLayer(
      turnCostLabelBuilder: turnCostLabelBuilder,
      confirmationLabelBuilder: moveConfirmationLabelBuilder,
      confirmationLabel: localizations?.selectionActionConfirm,
    );
    _fieldImprovementMarkerLayer = FieldImprovementMarkerLayer();
    _artifactMarkerLayer = ArtifactMarkerLayer(
      onArtifactTapped: _handleArtifactMarkerTapped,
    );
    _mapObjectiveMarkerLayer = MapObjectiveMarkerLayer(
      colorForPlayer: _colorForPlayer,
      onObjectiveTapped: _handleMapObjectiveMarkerTapped,
    );
    _cityMarkerLayer = CityMarkerLayer(
      colorForPlayer: _colorForPlayer,
      onCityTapped: _handleCityMarkerTapped,
      reduceMotion: _reduceMotion,
    );
    _cityTerritoryOverlayLayer = CityTerritoryOverlayLayer(
      colorForPlayer: _colorForPlayer,
    );
    _eraTintOverlayLayer = EraTintOverlayLayer();
    _cityManagementOverlayLayer = CityManagementOverlayLayer();
    _cityFoundingPreviewLayer = CityFoundingPreviewLayer(
      colorForPlayer: _colorForPlayer,
    );
    _fogOfWarOverlayLayer = FogOfWarOverlayLayer();
    _particleEffectsLayer = ParticleEffectsLayer();
    _cityProductionParticleLayer = CityProductionParticleLayer(
      reduceMotion: _reduceMotion,
    );
    _cloudDriftLayer = CloudDriftLayer(reduceMotion: _reduceMotion);
    _floatingTextLayer = FloatingTextLayer(reduceMotion: _reduceMotion);
    _combatHexAlertLayer = CombatHexAlertLayer();
    _threatOverlayLayer = ThreatOverlayLayer();
    _hoverIntentMarkerLayer = HoverIntentMarkerLayer();
    _actionPaletteLayer = ActionPaletteLayer(
      onPreviewWorkerImprovement: _handlePreviewWorkerImprovement,
      onConfirmWorkerImprovement: _handleConfirmWorkerImprovement,
      onCancelWorkerActionSelection: _handleCancelWorkerActionSelection,
      onConfirmMovePreview: _handleConfirmMovePreview,
      turnCostLabelBuilder: turnCostLabelBuilder,
      confirmationLabelBuilder: moveConfirmationLabelBuilder,
      confirmationLabel: localizations?.selectionActionConfirm,
    );

    _unitAnimationController = UnitAnimationController(_unitMarkerLayer);
  }

  double get defaultZoom => mapData.defaultZoom;

  @override
  void setZoom(double zoom) {
    _setFastCameraRendering(true);
    super.setZoom(zoom);
    _publishZoom();
    if (!_isReady) return;
    _syncMarkerDensityForZoom();
  }

  @override
  void panByScreenDelta(Vector2 screenDelta) {
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

  MapViewMode get viewMode => _viewMode;

  set viewMode(MapViewMode value) {
    if (_viewMode == value) return;
    _viewMode = value;
    _applyViewMode();
  }

  set workerActionPaletteOptionsBuilder(
    WorkerActionPaletteOptionsBuilder? value,
  ) {
    if (_workerActionPaletteOptionsBuilder == value) return;
    _workerActionPaletteOptionsBuilder = value;
    if (_isReady) _syncAfterAction();
  }

  set displaySettings(HexDisplaySettings value) {
    if (_displaySettings == value) return;
    _displaySettings = value;
    if (_isReady) {
      _sceneBuilder.grid.displaySettings = value;
      _syncGridSelection();
    }
  }

  bool get reduceMotion => _reduceMotion;

  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    _syncReduceMotion();
  }

  bool get moveCameraForUnitMovement => _moveCameraForUnitMovement;

  set moveCameraForUnitMovement(bool value) {
    if (_moveCameraForUnitMovement == value) return;
    _moveCameraForUnitMovement = value;
  }

  bool get followUnitMovementCamera => _followUnitMovementCamera;

  set followUnitMovementCamera(bool value) {
    if (_followUnitMovementCamera == value) return;
    _followUnitMovementCamera = value;
  }

  bool get followEnemyUnitCamera => _followEnemyUnitCamera;

  set followEnemyUnitCamera(bool value) {
    if (_followEnemyUnitCamera != value) _followEnemyUnitCamera = value;
  }

  bool get cinematicCameraEnabled => _cinematicCameraEnabled;

  set cinematicCameraEnabled(bool value) {
    if (_cinematicCameraEnabled == value) return;
    _cinematicCameraEnabled = value;
    _lastSyncedHoverHex = null;
    _refreshHoverIntent();
  }

  bool get hasReferenceImage => _sceneBuilder.hasReferenceImage;

  @override
  WorldProjection get worldProjection => _cinematicCameraEnabled
      ? _roundEarthProjection
      : WorldProjection.disabled;

  @override
  void onLongPressStart(LongPressStartInfo info) {
    handleViewportLongPressStart(info.eventPosition.widget);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isReady) _cameraController.update(dt);
    _syncFastCameraRendering(dt);
  }

  @override
  void onLongPressMoveUpdate(LongPressMoveUpdateInfo info) {
    handleViewportLongPressMoveUpdate(info.eventPosition.widget);
  }

  @override
  void onLongPressUp() {
    handleViewportLongPressUp();
  }

  @override
  void onLongPressEnd(LongPressEndInfo info) {
    handleViewportLongPressEnd(info.eventPosition.widget);
  }

  @override
  void onLongPressCancel() {
    handleViewportLongPressCancel();
  }

  @override
  void handleViewportLongPressStart(Vector2 position) {
    _startLongPressInspectAtWidgetPosition(position);
  }

  @override
  void handleViewportLongPressMoveUpdate(Vector2 position) {
    _updateLongPressInspectAtWidgetPosition(position);
  }

  @override
  void handleViewportLongPressUp() {
    _confirmLongPressInspect();
    _clearHoverIntent();
  }

  @override
  void handleViewportLongPressEnd(Vector2 position) {
    _confirmLongPressInspect();
    _clearHoverIntent();
  }

  @override
  void handleViewportLongPressCancel() {
    _cancelLongPressInspect();
    _clearHoverIntent();
  }

  @override
  void handleViewportPointerDown(int pointerId, Vector2 position) {
    final inputPosition = worldInputPointForWidget(position);
    final hadActiveLongPressInspect = _longPressInspectActive;
    if (hadActiveLongPressInspect) {
      _cancelLongPressInspect();
    }
    _suppressTapsUntilNextPointerDown = hadActiveLongPressInspect;
    super.handleViewportPointerDown(pointerId, inputPosition);
    _syncHoverIntentAtWidgetPosition(position);
  }

  @override
  void handleViewportPointerMove(int pointerId, Vector2 position) {
    final inputPosition = worldInputPointForWidget(position);
    if (_longPressInspectActive) {
      _updateLongPressInspectAtWidgetPosition(position);
      return;
    }
    super.handleViewportPointerMove(pointerId, inputPosition);
    if (isDragging || hasMultipleViewportPointers) {
      _clearHoverIntent();
      return;
    }
    _syncHoverIntentAtWidgetPosition(position);
  }

  @override
  void handleViewportPointerUp(int pointerId) {
    _confirmLongPressInspect();
    super.handleViewportPointerUp(pointerId);
    _clearHoverIntent();
  }

  @override
  void handleViewportPointerCancel(int pointerId) {
    _cancelLongPressInspect();
    super.handleViewportPointerCancel(pointerId);
    _clearHoverIntent();
  }

  @override
  void handleViewportPointerHover(Vector2 position) {
    _syncHoverIntentAtWidgetPosition(position);
  }

  @override
  void handleViewportPointerExit() {
    _clearHoverIntent();
  }

  @override
  void handleViewportPanZoomStart(Vector2 focalPoint) {
    _cancelLongPressInspect();
    super.handleViewportPanZoomStart(worldInputPointForWidget(focalPoint));
    _clearHoverIntent();
  }

  @override
  void handleViewportPanZoomUpdate({
    required Vector2 panDelta,
    required double scale,
    required Vector2 focalPoint,
  }) {
    _cancelLongPressInspect();
    final inputFocalPoint = worldInputPointForWidget(focalPoint);
    final inputPreviousFocalPoint = worldInputPointForWidget(
      focalPoint - panDelta,
    );
    super.handleViewportPanZoomUpdate(
      panDelta: inputFocalPoint - inputPreviousFocalPoint,
      scale: scale,
      focalPoint: inputFocalPoint,
    );
    _clearHoverIntent();
  }

  @override
  void handleViewportPanZoomEnd() {
    super.handleViewportPanZoomEnd();
    _clearHoverIntent();
  }

  /// Updates visual layers without running renderer effects.
  void applyState(GameState state) {
    _applyState(state, suppressCameraFocus: false);
  }

  /// Updates visual layers while preserving the current camera.
  ///
  /// This is used for turn-start selection refreshes where the HUD should
  /// prepare the next action without moving the map away from the player.
  void applyStateWithoutCameraFocus(GameState state) {
    _applyState(state, suppressCameraFocus: true);
  }

  /// Applies state and effects in one pass so move animations keep their
  /// previous marker position until the Flame effect takes over.
  Future<void> applyTransition(
    GameState state,
    Iterable<RendererEffect> effects,
  ) async {
    await _enqueueTransition(() => _applyTransitionNow(state, effects));
  }

  Future<void> handleEffects(Iterable<RendererEffect> effects) async {
    await _enqueueTransition(() => _handleEffectsNow(effects));
  }

  Future<void> handleEffect(RendererEffect effect) async {
    await handleEffects([effect]);
  }

  @override
  Future<void> buildWorld() async {
    await _buildRendererWorld();
  }

  void disposeRenderer() {
    if (_isDisposed) return;
    _isDisposed = true;
    _queuedRendererEffects.clear();
    _readyNotifier.dispose();
    _zoomNotifier.dispose();
    _initialCameraFocusReadyNotifier.dispose();
    _viewModelNotifier.dispose();
    _unitAnimationController.dispose();
  }

  @visibleForTesting
  TileData? tileDataAtWidgetPositionForTesting(Vector2 widgetPosition) {
    if (!_isReady) return null;
    final inputPosition = worldInputPointForWidget(widgetPosition);
    final worldPoint = camera.globalToLocal(inputPosition);
    return _sceneBuilder.grid.tileDataAtWorldPoint(worldPoint);
  }

  Offset _inspectionAnchorForTile(TileData tileData, {Vector2? fallback}) {
    if (!_isReady) {
      return Offset(fallback?.x ?? 0, fallback?.y ?? 0);
    }
    final tileCenter = HexGeometry.tilePosition(
      col: tileData.col,
      row: tileData.row,
      hexRadius: _sceneBuilder.grid.config.hexRadius,
    );
    final worldPoint = Vector2(
      tileCenter.x,
      tileCenter.y * HexGrid.perspectiveY - 16,
    );
    final viewportPoint =
        (worldPoint - camera.viewfinder.position) * camera.viewfinder.zoom;
    final projectedPoint = worldOutputPointForWidget(viewportPoint);
    return Offset(projectedPoint.x, projectedPoint.y);
  }
}
