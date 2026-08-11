import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/recommended_city_site_planner.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_tile_markers.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
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

  final WorldMapGrid grid;
  final RecommendedCitySitePlanner _recommendedCitySitePlanner;

  void sync(GameClientState state) {
    final markersByCoordinate = <(int, int), HexTileMarkers>{};
    final visibility = state.activePlayerVisibility;
    final attackTargetingUnit = selectedAttackTargetingUnit(state);
    final selectedWorker = _selectedControllableWorker(state);
    final workerPlanning = selectedWorker == null
        ? null
        : _WorkerPlanningIndex.fromState(state, selectedWorker);
    final selectedCityFounder = _selectedControllableCityFounder(state);
    final controlledCityHexes = {
      for (final city in state.cities)
        for (final hex in city.territoryHexes) (hex.col, hex.row),
    };
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

      final canGrowCity = _canUseAsCityGrowthTile(tile, controlledCityHexes);
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

      final canFoundCity = _canUseAsCityCenter(
        tile,
        state.cities,
        controlledCityHexes,
      );
      final workerAvailability = workerPlanning == null
          ? WorkerImprovementTileAvailability.unavailable
          : workerPlanning.availabilityFor(tile);
      final canImproveNow =
          workerAvailability == WorkerImprovementTileAvailability.availableNow;
      final canImproveAfterTechnology =
          workerAvailability ==
          WorkerImprovementTileAvailability.technologyLocked;
      final workerOccupiesTile =
          selectedWorker?.occupies(tile.col, tile.row) ?? false;
      final workerBuildAvailable = workerOccupiesTile && canImproveNow;
      final workerBuildBlocked =
          workerOccupiesTile && !workerBuildAvailable && selectedWorker != null;
      final workerImprovementCandidate =
          selectedWorker != null && !workerOccupiesTile && canImproveNow;
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
        workerImprovementCandidate: workerImprovementCandidate,
        workerBuildAvailable: workerBuildAvailable,
        workerBuildBlocked: workerBuildBlocked,
      );
    }

    grid.setTileMarkers(markersByCoordinate);
  }

  GameUnit? selectedAttackTargetingUnit(GameClientState state) {
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

  bool canAttackTargetTile(
    GameClientState state,
    GameUnit attacker,
    WorldTile tile,
  ) {
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

  GameUnit? _selectedControllableWorker(GameClientState state) {
    final unit = state.selectedUnit;
    if (unit == null ||
        !unit.isWorker ||
        unit.isWorking ||
        !state.canControlUnit(unit)) {
      return null;
    }
    return unit;
  }

  GameUnit? _selectedControllableCityFounder(GameClientState state) {
    final unit = state.selectedUnit;
    if (unit == null || !state.canControlUnit(unit)) return null;
    if (unit.hasSettlers || unit.type == GameUnitType.settler) return unit;
    return null;
  }

  bool _canUseAsCityCenter(
    WorldTile tile,
    Iterable<GameCity> cities,
    Set<(int, int)> controlledCityHexes,
  ) {
    if (!CitySiteRules.canFoundCityOn(tile)) return false;
    final hex = CityHex(col: tile.col, row: tile.row);
    return !controlledCityHexes.contains((tile.col, tile.row)) &&
        CityFoundingRules.isCenterFarEnoughFromCities(hex, cities);
  }

  bool _canUseAsCityGrowthTile(
    WorldTile tile,
    Set<(int, int)> controlledCityHexes,
  ) {
    if (!CityTileYieldRules.canCityControlTile(tile)) return false;
    return !controlledCityHexes.contains((tile.col, tile.row));
  }
}

/// Selection-time lookup data for worker planning markers.
///
/// The canonical rule checks cities and improvements for every improvement
/// type. Building these coordinate sets once avoids multiplying those scans by
/// every tile on a late-game map while preserving the same availability rule.
final class _WorkerPlanningIndex {
  const _WorkerPlanningIndex({
    required this.cityCenters,
    required this.ownedImprovementHexes,
    required this.improvedHexes,
    required this.unlockedTypes,
  });

  factory _WorkerPlanningIndex.fromState(
    GameClientState state,
    GameUnit worker,
  ) {
    final cityCenters = <(int, int)>{};
    final ownedImprovementHexes = <(int, int)>{};
    for (final city in state.cities) {
      cityCenters.add((city.center.col, city.center.row));
      if (city.ownerPlayerId != worker.ownerPlayerId) continue;
      for (final hex in city.controlledHexes) {
        if (hex != city.center) {
          ownedImprovementHexes.add((hex.col, hex.row));
        }
      }
    }
    return _WorkerPlanningIndex(
      cityCenters: cityCenters,
      ownedImprovementHexes: ownedImprovementHexes,
      improvedHexes: {
        for (final improvement in state.fieldImprovements)
          (improvement.hex.col, improvement.hex.row),
      },
      unlockedTypes: {
        for (final type in FieldImprovementType.values)
          if (TechnologyUnlockQuery.hasFieldImprovementUnlocked(
            playerId: worker.ownerPlayerId,
            improvementType: type,
            research: state.research,
            ruleset: TechnologyRulesets.standard,
          ))
            type,
      },
    );
  }

  final Set<(int, int)> cityCenters;
  final Set<(int, int)> ownedImprovementHexes;
  final Set<(int, int)> improvedHexes;
  final Set<FieldImprovementType> unlockedTypes;

  WorkerImprovementTileAvailability availabilityFor(WorldTile tile) {
    final coordinate = (tile.col, tile.row);
    if (cityCenters.contains(coordinate) ||
        improvedHexes.contains(coordinate) ||
        !ownedImprovementHexes.contains(coordinate)) {
      return WorkerImprovementTileAvailability.unavailable;
    }

    var technologyLocked = false;
    for (final type in FieldImprovementType.values) {
      if (FieldImprovementRules.requirementFailureFor(
            type,
            tile,
            ruleset: CityRulesets.standard,
          ) !=
          null) {
        continue;
      }
      if (unlockedTypes.contains(type)) {
        return WorkerImprovementTileAvailability.availableNow;
      }
      technologyLocked = true;
    }
    return technologyLocked
        ? WorkerImprovementTileAvailability.technologyLocked
        : WorkerImprovementTileAvailability.unavailable;
  }
}
