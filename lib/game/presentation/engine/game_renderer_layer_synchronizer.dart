import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/game_camera_controller.dart';
import 'package:aonw/game/presentation/engine/game_render_view_model.dart';
import 'package:aonw/game/presentation/engine/game_rendering_coordinator.dart';
import 'package:aonw/game/presentation/engine/game_scene_builder.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_option.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/artifacts/artifact_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_territory_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/cloud_drift_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/combat_hex_alert_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/floating_text_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/particle_effects_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/marker_density_policy.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_move_preview_layer.dart';
import 'package:aonw/game/presentation/widgets/theme/player_color_theme.dart';
import 'package:aonw/map/rendering/map_objective_marker_layer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

/// Synchronizes the renderer's layer graph from the current presentation state.
final class GameRendererLayerSynchronizer {
  GameRendererLayerSynchronizer({
    required this.mapData,
    required this.markerDensityPolicy,
    required this.sceneBuilder,
    required this.viewModelNotifier,
    required this.zoomNotifier,
    required this.isReady,
    required this.isDisposed,
    required this.world,
    required this.camera,
    required this.cameraController,
    required this.renderingCoordinator,
    required this.combatHexAlertLayer,
    required this.cityProductionParticleLayer,
    required this.cloudDriftLayer,
    required this.cityMarkerLayer,
    required this.unitMarkerLayer,
    required this.artifactMarkerLayer,
    required this.mapObjectiveMarkerLayer,
    required this.cityTerritoryOverlayLayer,
    required this.movePreviewLayer,
    required this.floatingTextLayer,
    required this.markerDensityForZoomSync,
    required this.state,
    required this.currentTurn,
    required this.viewMode,
    required this.reduceMotion,
    required this.workerActionPaletteOptions,
    required this.focusInitialActivePlayer,
    required this.focusActiveSelection,
    required this.primeSelectionFocus,
    required this.syncHoverIntentAfterStateChange,
  });

  final WorldMap mapData;
  final MarkerDensityPolicy markerDensityPolicy;
  final GameSceneBuilder sceneBuilder;
  final ValueNotifier<RenderState> viewModelNotifier;
  final ValueNotifier<double> zoomNotifier;
  final bool Function() isReady;
  final bool Function() isDisposed;
  final World Function() world;
  final CameraComponent Function() camera;
  final GameCameraController Function() cameraController;
  final GameRenderingCoordinator Function() renderingCoordinator;
  final CombatHexAlertLayer Function() combatHexAlertLayer;
  final CityProductionParticleLayer Function() cityProductionParticleLayer;
  final CloudDriftLayer Function() cloudDriftLayer;
  final CityMarkerLayer Function() cityMarkerLayer;
  final UnitMarkerLayer Function() unitMarkerLayer;
  final ArtifactMarkerLayer Function() artifactMarkerLayer;
  final MapObjectiveMarkerLayer Function() mapObjectiveMarkerLayer;
  final CityTerritoryOverlayLayer Function() cityTerritoryOverlayLayer;
  final UnitMovePreviewLayer Function() movePreviewLayer;
  final FloatingTextLayer Function() floatingTextLayer;
  final MarkerDensity? Function({required bool force}) markerDensityForZoomSync;
  final GameClientState Function() state;
  final int? Function() currentTurn;
  final MapViewMode Function() viewMode;
  final bool Function() reduceMotion;
  final List<ActionPaletteOption> Function() workerActionPaletteOptions;
  final void Function() focusInitialActivePlayer;
  final void Function() focusActiveSelection;
  final void Function() primeSelectionFocus;
  final void Function() syncHoverIntentAfterStateChange;

  void syncAfterAction({bool suppressCameraFocus = false}) {
    if (isDisposed()) return;
    renderingCoordinator().syncAll(
      state: state(),
      parent: world(),
      viewModelNotifier: viewModelNotifier,
      workerActionPaletteOptions: workerActionPaletteOptions(),
      showCityLabels: shouldShowCityLabels,
      strategicView: viewMode() == MapViewMode.tile,
    );
    combatHexAlertLayer().syncState(
      parent: sceneBuilder.grid,
      state: state(),
      currentTurn: currentTurn(),
      reduceMotion: reduceMotion(),
    );
    _syncCityProductionParticles();
    _syncCloudDriftLayer();
    if (suppressCameraFocus) {
      primeSelectionFocus();
    } else {
      focusInitialActivePlayer();
      focusActiveSelection();
    }
    syncHoverIntentAfterStateChange();
  }

  void _syncCityProductionParticles() {
    cityProductionParticleLayer()
      ..visible = shouldShowProductionParticles
      ..sync(
        parent: world(),
        cities: state().citiesKnownToActivePlayer.where(
          (city) => city.ownerPlayerId == state().activePlayerId,
        ),
        colorForPlayer: colorForPlayer,
      );
  }

  void _syncCloudDriftLayer() {
    cloudDriftLayer().sync(
      parent: world(),
      mapData: mapData,
      visibility: state().activePlayerVisibility,
    );
  }

  MarkerDensity get currentMarkerDensity {
    final viewportSize = camera().viewport.size;
    return markerDensityPolicy.resolve(
      zoom: camera().viewfinder.zoom,
      viewportWidth: viewportSize.x,
      viewportHeight: viewportSize.y,
    );
  }

  bool get shouldShowCityLabels => currentMarkerDensity.showCityLabels;

  void publishZoom() {
    if (isDisposed()) return;
    final zoom = camera().viewfinder.zoom;
    if (zoomNotifier.value == zoom) return;
    zoomNotifier.value = zoom;
  }

  void syncMarkerDensityForZoom({bool force = false}) {
    final density = markerDensityForZoomSync(force: force);
    if (density == null) return;
    cityMarkerLayer()
      ..markerWorldScale = density.markerWorldScale
      ..setLabelVisibility(density.showCityLabels)
      ..showHealthBar = density.showHealthBar;
    unitMarkerLayer().markerWorldScale = density.markerWorldScale;
    artifactMarkerLayer().markerWorldScale = density.markerWorldScale;
    mapObjectiveMarkerLayer().markerWorldScale = density.markerWorldScale;
    unitMarkerLayer().setDetailVisibility(
      showPeripheralDetails: density.showUnitPeripheralDetails,
      showOwnerColor: density.showOwnerColor,
      showHealthBar: density.showHealthBar,
      showTypeBadge: density.showTypeBadge,
      showStateBadge: density.showStateBadge,
    );
    cityTerritoryOverlayLayer().zoomEmphasis = density.territoryOverlayEmphasis;
    unitMarkerLayer()
      ..spriteScale = density.unitSpriteScale
      ..tacticalViewEmphasis = density.unitTacticalEmphasis
      ..animateIdle = density.animateUnitIdle;
    movePreviewLayer().showCostLabel = density.showCostLabel;
    floatingTextLayer().visible = density.showFloatingText;
    cityProductionParticleLayer().visible = shouldShowProductionParticles;
    _syncCityProductionParticles();
  }

  bool get shouldShowProductionParticles =>
      currentMarkerDensity.showProductionParticles &&
      !_mapDecisionModeSuppressesProductionParticles;

  bool get _mapDecisionModeSuppressesProductionParticles {
    return switch (state().interactionMode) {
      GameInteractionMode.cityFounding ||
      GameInteractionMode.moveTargeting ||
      GameInteractionMode.cityWorkedHexSelection ||
      GameInteractionMode.cityExpansionSelection ||
      GameInteractionMode.workerAction ||
      GameInteractionMode.merchantTradeRouteSelection ||
      GameInteractionMode.merchantMoveToCitySelection ||
      GameInteractionMode.attackTargeting => true,
      _ => false,
    };
  }

  void syncReduceMotion() {
    final value = reduceMotion();
    unitMarkerLayer().reduceMotion = value;
    cityMarkerLayer().reduceMotion = value;
    cityProductionParticleLayer().reduceMotion = value;
    cloudDriftLayer().reduceMotion = value;
    floatingTextLayer().reduceMotion = value;
    if (isReady()) cameraController().reduceMotion = value;
  }

  int colorForPlayer(String playerId) {
    return PlayerColorTheme.resolveValue(
      state().colorForPlayer(playerId) ?? Player.palette.first,
    );
  }
}
