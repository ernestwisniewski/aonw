import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/game_render_view_model.dart';
import 'package:aonw/game/presentation/engine/recommended_city_site_planner.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_option.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/artifact_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_founding_preview_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_management_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_territory_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/era_tint_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/field_improvement_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/fog_of_war_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/marker_health_fraction.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/threat_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_move_preview.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_move_preview_layer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_tile_markers.dart';
import 'package:aonw/map/rendering/map_objective_marker_layer.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

class GameRenderingCoordinator {
  final UnitMarkerLayer unitMarkers;
  final UnitMovePreviewLayer movePreview;
  final FieldImprovementMarkerLayer fieldImprovementMarkers;
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
  final HexGrid grid;
  final RecommendedCitySitePlanner _recommendedCitySitePlanner =
      RecommendedCitySitePlanner();

  GameRenderingCoordinator({
    required this.unitMarkers,
    required this.movePreview,
    required this.fieldImprovementMarkers,
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
  });

  void syncAll({
    required GameState state,
    required Component parent,
    required ValueNotifier<GameRenderViewModel> viewModelNotifier,
    List<ActionPaletteOption> workerActionPaletteOptions = const [],
    bool showCityLabels = true,
    bool strategicView = false,
  }) {
    grid.visibleResourceTypes = ResourceVisibilityRules.visibleResourceTypes(
      playerId: state.activePlayerId,
      research: state.research,
    );
    final viewModel = GameRenderViewModel.fromState(state);
    _publishViewModel(viewModel, viewModelNotifier);
    _syncGridSelection(grid, viewModel);
    _syncPlanningMarkers(state);
    _syncFieldImprovementMarkers(state, parent);
    _syncArtifactMarkers(state, parent);
    _syncMapObjectiveMarkers(state, parent);
    _syncCityMarkers(
      state,
      parent,
      showCityLabels: showCityLabels,
      strategicView: strategicView,
    );
    _syncCityManagement(state, dimmed: _shouldDimCityManagementOverlay(state));
    _syncThreatOverlay(
      state,
      enabled: _shouldShowThreatOverlay(state),
      dimmed: _shouldDimThreatOverlay(state),
    );
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
    GameRenderViewModel viewModel,
    ValueNotifier<GameRenderViewModel> viewModelNotifier,
  ) {
    if (viewModelNotifier.value == viewModel) return;
    viewModelNotifier.value = viewModel;
  }

  void _syncGridSelection(HexGrid hexGrid, GameRenderViewModel viewModel) {
    final selection = viewModel.selection;
    final tile = selection?.tile;
    if (selection?.type == GameSelectionType.tile && tile != null) {
      hexGrid.selectTile(tile.col, tile.row);
    } else {
      hexGrid.clearSelection();
    }
  }

  void _syncPlanningMarkers(GameState state) {
    final markersByCoordinate = <(int, int), HexTileMarkers>{};
    final visibility = state.activePlayerVisibility;
    final attackTargetingUnit = _selectedAttackTargetingUnit(state);
    final selectedWorker = _selectedControllableWorker(state);
    final selectedCityFounder = _selectedControllableCityFounder(state);
    final forceCitySiteMarkers = selectedCityFounder != null;
    final recommendedCitySites = selectedCityFounder == null
        ? const <(int, int)>{}
        : _recommendedCitySitePlanner.coordinates(
            state: state,
            founder: selectedCityFounder,
            mapData: grid.mapData,
          );

    for (final tile in grid.mapData.tiles) {
      if (visibility.isEnabled && !visibility.canInspectTile(tile)) continue;

      final canGrowCity = _canUseAsCityGrowthTile(tile, state.cities);
      if (attackTargetingUnit != null) {
        final canAttackTarget = _canAttackTargetTile(
          state,
          attackTargetingUnit,
          tile,
        );
        if (canAttackTarget || canGrowCity) {
          markersByCoordinate[(tile.col, tile.row)] = HexTileMarkers(
            canAttackTarget: canAttackTarget,
            canGrowCity: canGrowCity,
          );
        }
        continue;
      }

      final canFoundCity = _canUseAsCityCenter(tile, state.cities);
      final workerHex = CityHex(col: tile.col, row: tile.row);
      final workerAvailability = selectedWorker == null
          ? WorkerImprovementTileAvailability.unavailable
          : WorkerImprovementRules.availabilityForTile(
              unit: selectedWorker,
              targetHex: workerHex,
              cities: state.cities,
              fieldImprovements: state.fieldImprovements,
              mapData: grid.mapData,
              research: state.research,
            );
      final canImproveNow =
          workerAvailability == WorkerImprovementTileAvailability.availableNow;
      final canImproveAfterTechnology =
          workerAvailability ==
          WorkerImprovementTileAvailability.technologyLocked;
      final workerBuildAvailable = selectedWorker != null && canImproveNow;
      final workerBuildBlocked =
          selectedWorker != null &&
          !workerBuildAvailable &&
          _shouldShowWorkerBuildBlockedMarker(
            state: state,
            worker: selectedWorker,
            hex: workerHex,
            tile: tile,
            availability: workerAvailability,
          );
      if (!canFoundCity &&
          !canGrowCity &&
          !canImproveNow &&
          !canImproveAfterTechnology &&
          !workerBuildAvailable &&
          !workerBuildBlocked) {
        continue;
      }

      markersByCoordinate[(tile.col, tile.row)] = HexTileMarkers(
        canFoundCity: canFoundCity,
        forceShowCitySite: forceCitySiteMarkers && canFoundCity,
        recommendedCitySite:
            forceCitySiteMarkers &&
            canFoundCity &&
            recommendedCitySites.contains((tile.col, tile.row)),
        canGrowCity: canGrowCity,
        canImproveNow: canImproveNow,
        canImproveAfterTechnology: canImproveAfterTechnology,
        workerImprovementCandidate: canImproveNow,
        workerBuildAvailable: workerBuildAvailable,
        workerBuildBlocked: workerBuildBlocked,
      );
    }

    grid.setTileMarkers(markersByCoordinate);
  }

  bool _shouldShowWorkerBuildBlockedMarker({
    required GameState state,
    required GameUnit worker,
    required CityHex hex,
    required TileData tile,
    required WorkerImprovementTileAvailability availability,
  }) {
    if (worker.occupies(tile.col, tile.row)) return true;
    if (availability == WorkerImprovementTileAvailability.technologyLocked) {
      return true;
    }
    return WorkerImprovementRules.cityForImprovementHex(
          playerId: worker.ownerPlayerId,
          hex: hex,
          cities: state.cities,
        ) !=
        null;
  }

  GameUnit? _selectedAttackTargetingUnit(GameState state) {
    final pending = state.pendingAction;
    if (pending is! PendingAttackTargeting) return null;
    for (final unit in state.units) {
      if (unit.id != pending.attackerUnitId) continue;
      if (!state.canControlUnit(unit) ||
          unit.isWorking ||
          unit.movementPoints <= 0) {
        return null;
      }
      return unit;
    }
    return null;
  }

  bool _canAttackTargetTile(GameState state, GameUnit attacker, TileData tile) {
    final defender = state.unitAt(tile.col, tile.row);
    if (defender == null ||
        defender.id == attacker.id ||
        defender.ownerPlayerId == attacker.ownerPlayerId) {
      return false;
    }

    final visibility = state.activePlayerVisibility;
    if (visibility.isEnabled &&
        !visibility.canSeeDynamicAt(tile.col, tile.row)) {
      return false;
    }

    final attackerTile = grid.mapData.tileAt(attacker.col, attacker.row);
    if (attackerTile == null) return false;

    final attackerStats = UnitCombatStats.derive(attacker).applyAll(
      CombatModifierCollector.forAttacker(
        unit: attacker,
        tile: attackerTile,
        research: state.research.forPlayer(attacker.ownerPlayerId),
        technologyRuleset: TechnologyRulesets.standard,
      ),
    );
    if (attackerStats.attack <= 0) return false;

    final distance = HexDistance.between(
      HexCoordinate(col: attacker.col, row: attacker.row),
      HexCoordinate(col: tile.col, row: tile.row),
    );
    return distance <= attackerStats.range;
  }

  GameUnit? _selectedControllableWorker(GameState state) {
    final unit = state.selectedUnit;
    if (unit == null ||
        !unit.isWorker ||
        unit.isWorking ||
        !state.canControlUnit(unit)) {
      return null;
    }
    return unit;
  }

  GameUnit? _selectedControllableCityFounder(GameState state) {
    final unit = state.selectedUnit;
    if (unit == null || !state.canControlUnit(unit)) return null;
    if (unit.hasSettlers || unit.type == GameUnitType.settler) return unit;
    return null;
  }

  bool _canUseAsCityCenter(TileData tile, Iterable<GameCity> cities) {
    if (!CitySiteRules.canFoundCityOn(tile)) return false;
    final hex = CityHex(col: tile.col, row: tile.row);
    return !_isControlledByAnyCity(hex, cities) &&
        CityFoundingRules.isCenterFarEnoughFromCities(hex, cities);
  }

  bool _canUseAsCityGrowthTile(TileData tile, Iterable<GameCity> cities) {
    if (!CityTileYieldRules.canCityControlTile(tile)) return false;
    final hex = CityHex(col: tile.col, row: tile.row);
    return !_isControlledByAnyCity(hex, cities);
  }

  bool _isControlledByAnyCity(CityHex hex, Iterable<GameCity> cities) {
    for (final city in cities) {
      if (city.controlsHex(hex)) return true;
    }
    return false;
  }

  void _syncCityMarkers(
    GameState state,
    Component world, {
    required bool showCityLabels,
    required bool strategicView,
  }) {
    final knownCities = state.citiesKnownToActivePlayer;
    final visibility = state.activePlayerVisibility;
    final selection = state.selection;
    final selectedCityId = selection?.type == GameSelectionType.city
        ? selection?.city?.id
        : null;
    final selectedTerritoryCityId = _selectedTerritoryCityId(
      selection,
      knownCities,
    );
    cityTerritory.sync(
      parent: grid,
      cities: knownCities,
      selectedCityId: selectedTerritoryCityId,
      strategicView: strategicView,
      canShowHex: visibility.isEnabled
          ? (hex) => visibility.canRememberStaticAt(hex.col, hex.row)
          : null,
    );
    cityMarkers.sync(
      parent: world,
      cities: knownCities,
      selectedCityId: selectedCityId,
      healthFractions: _cityHealthFractions(state, knownCities),
      showLabels: showCityLabels,
      citiesWithStoredArtifacts: _citiesWithStoredArtifacts(state),
      research: state.research,
    );
  }

  Set<String> _citiesWithStoredArtifacts(GameState state) {
    return {
      for (final artifact in state.artifacts)
        if (artifact.location.isStored && artifact.location.cityId != null)
          artifact.location.cityId!,
    };
  }

  String? _selectedTerritoryCityId(
    GameSelection? selection,
    Iterable<GameCity> cities,
  ) {
    if (selection == null) return null;
    if (selection.type == GameSelectionType.city) {
      return selection.city?.id;
    }
    if (selection.type != GameSelectionType.fieldImprovement) {
      return null;
    }

    final improvement = selection.fieldImprovement;
    if (improvement == null) return null;

    final builtByCityId = improvement.builtByCityId;
    for (final city in cities) {
      if (city.id == builtByCityId || city.controlsHex(improvement.hex)) {
        return city.id;
      }
    }
    return null;
  }

  void _syncFieldImprovementMarkers(GameState state, Component world) {
    final visibility = state.activePlayerVisibility;
    final visibleImprovements = state.fieldImprovements
        .where(
          (improvement) =>
              !visibility.isEnabled ||
              visibility.canRememberStaticAt(
                improvement.hex.col,
                improvement.hex.row,
              ),
        )
        .toList(growable: false);
    fieldImprovementMarkers.sync(
      parent: world,
      improvements: visibleImprovements,
      cities: state.cities,
      research: state.research,
      selectedHex: _selectedFieldImprovementHex(state),
    );
  }

  void _syncArtifactMarkers(GameState state, Component world) {
    final visibility = state.activePlayerVisibility;
    final occupiedHexes = {
      for (final unit in state.unitsVisibleToActivePlayer)
        CityHex(col: unit.col, row: unit.row),
    };
    final visibleArtifacts = state.artifacts
        .where((artifact) {
          final hex = _artifactMarkerHex(artifact);
          if (hex == null) return false;
          return !visibility.isEnabled ||
              visibility.canSeeDynamicAt(hex.col, hex.row);
        })
        .toList(growable: false);
    artifactMarkers.sync(
      parent: world,
      artifacts: visibleArtifacts,
      selectedHex: _selectedArtifactHex(state),
      occupiedHexes: occupiedHexes,
    );
  }

  void _syncMapObjectiveMarkers(GameState state, Component world) {
    final visibility = state.activePlayerVisibility;
    final occupiedHexes = {
      for (final unit in state.unitsVisibleToActivePlayer)
        CityHex(col: unit.col, row: unit.row),
    };
    final visibleObjectives = grid.mapData.objectives
        .where((objective) {
          final hex = objective.hex;
          return !visibility.isEnabled ||
              visibility.canRememberStaticAt(hex.col, hex.row);
        })
        .toList(growable: false);
    final snapshot = MapObjectiveRules.snapshot(
      objectives: visibleObjectives,
      cities: state.citiesKnownToActivePlayer,
      units: state.unitsVisibleToActivePlayer,
      holdStatesByObjectiveId: state.mapObjectiveHoldStatesByObjectiveId,
    );
    mapObjectiveMarkers.sync(
      parent: world,
      objectives: snapshot.entries,
      occupiedHexes: occupiedHexes,
    );
  }

  CityHex? _artifactMarkerHex(WorldArtifact artifact) {
    final location = artifact.location;
    return switch (location.kind) {
      WorldArtifactLocationKind.map || WorldArtifactLocationKind.excavation =>
        switch ((location.col, location.row)) {
          (final int col, final int row) => CityHex(col: col, row: row),
          _ => null,
        },
      WorldArtifactLocationKind.carried ||
      WorldArtifactLocationKind.stored => null,
    };
  }

  CityHex? _selectedArtifactHex(GameState state) {
    final selection = state.selection;
    final tile = selection?.tile;
    if (tile == null) return null;
    final selectedHex = CityHex(col: tile.col, row: tile.row);
    for (final artifact in state.artifacts) {
      if (_artifactMarkerHex(artifact) == selectedHex) return selectedHex;
    }
    return null;
  }

  CityHex? _selectedFieldImprovementHex(GameState state) {
    final selection = state.selection;
    if (selection?.type != GameSelectionType.fieldImprovement) return null;
    return selection?.fieldImprovement?.hex;
  }

  Map<String, double> _cityHealthFractions(
    GameState state,
    Iterable<GameCity> cities,
  ) {
    return {
      for (final city in cities) city.id: MarkerHealthFraction.forCity(city),
    };
  }

  void _syncCityManagement(GameState state, {required bool dimmed}) {
    final visibility = state.activePlayerVisibility;
    cityManagement.sync(
      parent: grid,
      state: state,
      mapData: grid.mapData,
      cityRuleset: CityRulesets.standard,
      canShowHex: visibility.isEnabled
          ? (hex) => visibility.canSeeDynamicAt(hex.col, hex.row)
          : null,
      dimmed: dimmed,
    );
  }

  void _syncThreatOverlay(
    GameState state, {
    required bool enabled,
    required bool dimmed,
  }) {
    if (!enabled) {
      threatOverlay.clear();
      return;
    }
    threatOverlay.sync(
      parent: grid,
      state: state,
      mapData: grid.mapData,
      dimmed: dimmed,
    );
  }

  void _syncFogOfWar(GameState state) {
    fogOfWar.sync(
      parent: grid,
      mapData: grid.mapData,
      visibility: state.activePlayerVisibility,
    );
  }

  void _syncEraTint(GameState state) {
    eraTint.sync(
      parent: grid,
      mapData: grid.mapData,
      playerResearch: state.research.forPlayer(state.activePlayerId),
    );
  }

  void _syncUnitMarkers(GameState state, Component world) {
    final cityTiles = {
      for (final city in state.citiesKnownToActivePlayer)
        (col: city.center.col, row: city.center.row),
    };
    unitMarkers.sync(
      parent: world,
      units: state.unitsVisibleToActivePlayer,
      selectedUnitId: state.selectedUnitId,
      pendingAction: state.pendingAction,
      attackTargetUnitIds: _attackTargetUnitIds(state),
      cityTiles: cityTiles,
      artifactExcavationTurnsByUnitId: _artifactExcavationTurnsByUnitId(state),
    );
  }

  Map<String, int> _artifactExcavationTurnsByUnitId(GameState state) {
    return {
      for (final artifact in state.artifacts)
        if (artifact.location.isBeingExcavated &&
            artifact.location.unitId != null)
          artifact.location.unitId!: artifact.location.remainingTurns,
    };
  }

  Set<String> _attackTargetUnitIds(GameState state) {
    final attacker = _selectedAttackTargetingUnit(state);
    if (attacker == null) return const {};

    return {
      for (final unit in state.unitsVisibleToActivePlayer)
        if (unit.ownerPlayerId != attacker.ownerPlayerId)
          if (grid.mapData.tileAt(unit.col, unit.row) case final tile?)
            if (_canAttackTargetTile(state, attacker, tile)) unit.id,
    };
  }

  void _syncMovePreview(
    GameState state,
    Component parent, {
    required bool dimmed,
  }) {
    final entries = <UnitMovePreviewLayerEntry>[];
    for (final unit in state.units) {
      final entry = _queuedPathEntryForUnit(state, unit, dimmed);
      if (entry != null) entries.add(entry);
    }

    final activePreview = state.movePreview;
    if (activePreview != null &&
        _canShowPathForUnit(state, activePreview.unitId)) {
      final selected = state.selectedUnitId == activePreview.unitId;
      entries
        ..removeWhere((entry) => entry.preview.unitId == activePreview.unitId)
        ..add(
          UnitMovePreviewLayerEntry(
            id: 'active:${activePreview.unitId}',
            preview: activePreview,
            unitType: _unitTypeForPlan(state, activePreview),
            dimmed: dimmed,
            subdued: !selected,
            showCostLabel: false,
            showConfirmationHint: selected,
            showTargetPulse: selected,
            showTargetArrow: false,
          ),
        );
    }

    movePreview.syncMany(parent: parent, previews: entries);
  }

  UnitMovePreviewLayerEntry? _queuedPathEntryForUnit(
    GameState state,
    GameUnit unit,
    bool dimmed,
  ) {
    if (!state.canControlUnit(unit)) return null;
    final tradeRoute = unit.merchantTradeRoute;
    if (tradeRoute != null && tradeRoute.steps.length >= 2) {
      final tradePlan = UnitMovementPlan(
        unitId: unit.id,
        targetCol: tradeRoute.targetCol,
        targetRow: tradeRoute.targetRow,
        totalCost: tradeRoute.steps.last.cumulativeCost,
        availableMovementPoints: unit.movementPoints,
        steps: tradeRoute.steps,
      );
      final travelledUpToIndex = tradeRoute.steps.indexWhere(
        (s) => s.col == unit.col && s.row == unit.row,
      );
      final selected = state.selectedUnitId == unit.id;
      return UnitMovePreviewLayerEntry(
        id: 'trade:${unit.id}',
        preview: tradePlan,
        travelledUpToIndex: travelledUpToIndex < 0 ? 0 : travelledUpToIndex,
        unitType: unit.type,
        routeKind: UnitMovePreviewRouteKind.trade,
        dimmed: dimmed,
        subdued: !selected,
        showCostLabel: false,
        showConfirmedTarget: selected,
      );
    }

    final queuedPath = unit.queuedPath;
    if (queuedPath != null && queuedPath.steps.length >= 2) {
      final queuedPlan = UnitMovementPlan(
        unitId: unit.id,
        targetCol: queuedPath.targetCol,
        targetRow: queuedPath.targetRow,
        totalCost: queuedPath.steps.last.cumulativeCost,
        availableMovementPoints: unit.movementPoints,
        steps: queuedPath.steps,
      );
      final travelledUpToIndex = queuedPath.steps.indexWhere(
        (s) => s.col == unit.col && s.row == unit.row,
      );
      final selected = state.selectedUnitId == unit.id;
      return UnitMovePreviewLayerEntry(
        id: 'queued:${unit.id}',
        preview: queuedPlan,
        travelledUpToIndex: travelledUpToIndex < 0 ? 0 : travelledUpToIndex,
        unitType: unit.type,
        dimmed: dimmed,
        subdued: !selected,
        showCostLabel: selected,
        showConfirmedTarget: selected,
      );
    }
    return null;
  }

  GameUnitType? _unitTypeForPlan(GameState state, UnitMovementPlan plan) {
    for (final unit in state.units) {
      if (unit.id == plan.unitId) return unit.type;
    }
    return null;
  }

  bool _canShowPathForUnit(GameState state, String unitId) {
    for (final unit in state.units) {
      if (unit.id == unitId) return state.canControlUnit(unit);
    }
    return false;
  }

  bool _shouldShowThreatOverlay(GameState state) {
    return state.interactionMode == GameInteractionMode.attackTargeting;
  }

  bool _shouldDimThreatOverlay(GameState state) {
    return state.interactionMode != GameInteractionMode.attackTargeting;
  }

  bool _shouldDimCityManagementOverlay(GameState state) {
    final mode = state.interactionMode;
    final selectedUnit = state.selectedUnit;
    if (mode == GameInteractionMode.moveTargeting &&
        selectedUnit != null &&
        selectedUnit.isWorker &&
        !selectedUnit.isWorking &&
        state.canControlUnit(selectedUnit)) {
      return false;
    }
    return mode != GameInteractionMode.standard &&
        mode != GameInteractionMode.workerAction &&
        mode != GameInteractionMode.cityWorkedHexSelection &&
        mode != GameInteractionMode.cityExpansionSelection;
  }

  void _syncCityFounding(GameState state, Component world) {
    if (!grid.isMounted) return;
    final visibility = state.activePlayerVisibility;
    cityFounding.sync(
      parent: world,
      draft: state.cityFoundingDraft,
      mapData: grid.mapData,
      cities: state.cities,
      canShowHex: visibility.isEnabled
          ? (hex) => visibility.canSeeDynamicAt(hex.col, hex.row)
          : null,
    );
  }
}
