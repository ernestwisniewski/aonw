import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/game_planning_marker_coordinator.dart';
import 'package:aonw/game/presentation/engine/game_render_view_model.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_option.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/artifacts/artifact_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_founding_preview_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_management_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_territory_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/era_tint_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/improvements/field_improvement_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/overlays/fog_of_war_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/overlays/threat_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/transport/transport_network_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/marker_health_fraction.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_move_preview_layer.dart';
import 'package:aonw/game/presentation/engine/unit_move_preview_entry_builder.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/map_objective_marker_layer.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

part 'game_rendering_coordinator_city_sync.dart';
part 'game_rendering_coordinator_unit_sync.dart';
part 'game_rendering_coordinator_world_sync.dart';

class GameRenderingCoordinator {
  final UnitMarkerLayer unitMarkers;
  final UnitMovePreviewLayer movePreview;
  final FieldImprovementMarkerLayer fieldImprovementMarkers;
  final TransportNetworkLayer transportNetwork;
  final ArtifactMarkerLayer artifactMarkers;
  final MapObjectiveMarkerLayer mapObjectiveMarkers;
  final CityMarkerLayer cityMarkers;
  final CityTerritoryOverlayLayer cityTerritory;
  final EraTintOverlayLayer eraTint;
  final CityManagementOverlayLayer cityManagement;
  final CityFoundingPreviewLayer cityFounding;
  final FogOfWarOverlayLayer fogOfWar;
  final ThreatOverlayLayer threatOverlay;
  final ActionPaletteLayer actionPalette;
  final WorldMapGrid grid;
  final GamePlanningMarkerCoordinator _planningMarkers;

  GameRenderingCoordinator({
    required this.unitMarkers,
    required this.movePreview,
    required this.fieldImprovementMarkers,
    required this.transportNetwork,
    required this.artifactMarkers,
    required this.mapObjectiveMarkers,
    required this.cityMarkers,
    required this.cityTerritory,
    required this.eraTint,
    required this.cityManagement,
    required this.cityFounding,
    required this.fogOfWar,
    required this.threatOverlay,
    required this.actionPalette,
    required this.grid,
  }) : _planningMarkers = GamePlanningMarkerCoordinator(grid: grid);

  void syncAll({
    required GameClientState state,
    required Component parent,
    required ValueNotifier<RenderState> viewModelNotifier,
    List<ActionPaletteOption> workerActionPaletteOptions = const [],
    bool showCityLabels = true,
    bool strategicView = false,
  }) {
    grid.visibleResourceTypes = ResourceVisibilityRules.visibleResourceTypes(
      playerId: state.activePlayerId,
      research: state.research,
    );
    final viewModel = RenderState.fromState(state);
    _publishViewModel(viewModel, viewModelNotifier);
    _syncGridSelection(grid, viewModel);
    _planningMarkers.sync(state);
    _syncFieldImprovementMarkers(state, parent);
    _syncTransportNetwork(state);
    _syncArtifactMarkers(state, parent);
    _syncMapObjectiveMarkers(state, parent);
    _syncCityMarkers(
      state,
      parent,
      showCityLabels: showCityLabels,
      strategicView: strategicView,
    );
    _syncCityManagement(state, dimmed: _shouldDimCityManagementOverlay(state));
    threatOverlay.clear();
    _syncEraTint(state);
    _syncFogOfWar(state);
    _syncUnitMarkers(state, parent);
    _syncMovePreview(
      state,
      parent,
      dimmed: state.interactionMode == GameInteractionMode.attackTargeting,
    );
    _syncCityFounding(state, parent);
    actionPalette.sync(
      parent: parent,
      state: state,
      options: workerActionPaletteOptions,
    );
  }

  void _publishViewModel(
    RenderState viewModel,
    ValueNotifier<RenderState> viewModelNotifier,
  ) {
    if (viewModelNotifier.value == viewModel) return;
    viewModelNotifier.value = viewModel;
  }

  void _syncGridSelection(WorldMapGrid grid, RenderState viewModel) {
    final selection = viewModel.selection;
    final tile = selection?.tile;
    if (selection?.type == GameSelectionType.tile && tile != null) {
      grid.selectTile(tile.col, tile.row);
    } else {
      grid.clearSelection();
    }
  }
}
