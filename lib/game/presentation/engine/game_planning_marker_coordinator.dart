import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/recommended_city_site_planner.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_tile_markers.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

class GamePlanningMarkerCoordinator {
  GamePlanningMarkerCoordinator({
    required this.grid,
    RecommendedCitySitePlanner? recommendedCitySitePlanner,
  }) : _recommendedCitySitePlanner =
           recommendedCitySitePlanner ?? RecommendedCitySitePlanner();

  final HexGrid grid;
  final RecommendedCitySitePlanner _recommendedCitySitePlanner;

  void sync(GameState state) {
    final markersByCoordinate = <(int, int), HexTileMarkers>{};
    final visibility = state.activePlayerVisibility;
    final attackTargetingUnit = selectedAttackTargetingUnit(state);
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
        final canAttackTarget = canAttackTargetTile(
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

  GameUnit? selectedAttackTargetingUnit(GameState state) {
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

  bool canAttackTargetTile(GameState state, GameUnit attacker, TileData tile) {
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
}
