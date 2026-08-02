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
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
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
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/services/map_focus_visibility.dart';
import 'package:aonw/game/presentation/widgets/theme/player_color_theme.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_tile_markers.dart';
import 'package:aonw/map/rendering/hex_world.dart';
import 'package:aonw/map/rendering/map_objective_marker_layer.dart';
import 'package:aonw/map/rendering/world_projection.dart';
import 'package:aonw/shared/input/hex_input_behavior.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw_core/domain/world_map.dart';
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
part 'game_renderer_camera.dart';
part 'game_renderer_camera_focus.dart';
part 'game_renderer_camera_policy.dart';
part 'game_renderer_camera_rendering.dart';
part 'game_renderer_gamepad_input.dart';
part 'game_renderer_input.dart';
part 'game_renderer_lifecycle.dart';
part 'game_renderer_projected_effects.dart';
part 'game_renderer_state_sync.dart';
part 'game_renderer_testing.dart';
part 'game_renderer_tile_interactions.dart';
part 'game_renderer_transitions.dart';
part 'game_renderer_types.dart';

/// Flame renderer for the game map.
///
/// Owns the world hierarchy, forwards input as commands, and keeps visual
/// layers in sync with [GameClientState].
class GameRenderer extends HexWorld
    with
        KeyboardEvents,
        LongPressDetector,
        HexInputBehavior,
        GameRendererInput,
        GameRendererCamera,
        GameRendererStateSync,
        GameRendererTransitions,
        GameRendererLifecycle {
  static const _loadingPlayerId = '__loading__';
  static const double _selectionCameraTransitionDuration = 0.42;
  static const WorldProjection _roundEarthProjection = WorldProjection(
    strength: 0.26,
  );
  static const MarkerDensityPolicy _markerDensityPolicy = MarkerDensityPolicy();

  final WorldMap mapData;
  final String? imagePath;
  final CameraState? initialCamera;
  final bool startCameraOffMap;
  final bool focusActivePlayerOnFirstState;
  final Future<void> Function(GameIntent intent) onCommand;
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
  GameClientState? _cachedHoverIntentResolverState;
  bool? _cachedHoverIntentResolverReduceMotion;
  int? _currentTurn;
  bool _longPressInspectActive = false;
  bool _longPressInspectionPreviewActive = false;
  bool _suppressTapsUntilNextPointerDown = false;
  final CityDescriptionTapTracker _cityTapTracker =
      CityDescriptionTapTracker.withStopwatch();
  final ArtifactMarkerTapCycle _artifactTapCycle = ArtifactMarkerTapCycle();
  CityHex? _longPressInspectHex;
  var _renderState = GameClientState(activePlayerId: _loadingPlayerId);
  final _queuedRendererEffects = _QueuedRendererEffectQueue();
  WorkerActionPaletteOptionsBuilder? _workerActionPaletteOptionsBuilder;
  final ValueNotifier<RenderState> _viewModelNotifier = ValueNotifier(
    RenderState.empty,
  );
  final ValueNotifier<bool> _readyNotifier = ValueNotifier(false);
  final ValueNotifier<double> _zoomNotifier = ValueNotifier(1.0);
  final ValueNotifier<bool> _initialCameraFocusReadyNotifier;
  Future<void> _transitionQueue = Future<void>.value();

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
    _initializeRendererComponents();
  }
}
