import 'package:aonw_core/game/domain/city/city_founding_draft.dart';
import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_site_rules.dart';
import 'package:aonw_core/game/domain/city/city_territory_rules.dart';
import 'package:aonw_core/game/domain/city/city_tile_yield_rules.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

export 'package:aonw_core/game/domain/city/city_founding_draft.dart';

enum CityFoundingFailure {
  noCommander,
  noSettlers,
  invalidCenter,
  cityAlreadyExists,
  centerOccupied,
  tooCloseToCity,
  invalidControlledHexes,
}

abstract final class CityFoundingRules {
  static const int minimumCenterDistance = 3;

  static bool canStart({
    required GameUnit? unit,
    required MapTileView? centerTile,
    required Iterable<GameCity> cities,
  }) {
    return startFailure(unit: unit, centerTile: centerTile, cities: cities) ==
        null;
  }

  static CityFoundingFailure? startFailure({
    required GameUnit? unit,
    required MapTileView? centerTile,
    required Iterable<GameCity> cities,
  }) {
    if (unit == null) {
      return CityFoundingFailure.noCommander;
    }
    if (!canFoundCityWith(unit)) {
      return unit.type == GameUnitType.commander
          ? CityFoundingFailure.noSettlers
          : CityFoundingFailure.noCommander;
    }
    if (centerTile == null || !CitySiteRules.canFoundCityOn(centerTile)) {
      return CityFoundingFailure.invalidCenter;
    }
    if (cities.any((city) => city.occupiesCenter(unit.col, unit.row))) {
      return CityFoundingFailure.cityAlreadyExists;
    }
    final draftCenter = CityHex(col: unit.col, row: unit.row);
    if (cities.any((city) => city.controlledHexes.contains(draftCenter))) {
      return CityFoundingFailure.centerOccupied;
    }
    if (!isCenterFarEnoughFromCities(draftCenter, cities)) {
      return CityFoundingFailure.tooCloseToCity;
    }
    return null;
  }

  static bool isCenterFarEnoughFromCities(
    CityHex center,
    Iterable<GameCity> cities,
  ) {
    for (final city in cities) {
      final distance = CityTerritoryRules.distance(
        from: center,
        to: city.center,
        maxDistance: minimumCenterDistance - 1,
      );
      if (distance < minimumCenterDistance) return false;
    }
    return true;
  }

  static bool isControlledHexCandidate({
    required CityFoundingDraft draft,
    required MapTileView tile,
    required MapTileLookup mapTiles,
    Iterable<GameCity> cities = const [],
  }) {
    if (draft.center.occupies(tile.col, tile.row)) return false;
    if (mapTiles.tileAt(tile.col, tile.row) == null) return false;
    if (!CityTileYieldRules.canCityControlTile(tile)) return false;
    final target = CityHex(col: tile.col, row: tile.row);
    final distance = CityTerritoryRules.distance(
      from: draft.center,
      to: target,
      maxDistance: CityFoundingDraft.maxRadius,
    );
    if (distance > CityFoundingDraft.maxRadius) {
      return false;
    }
    for (final city in cities) {
      if (city.center == target) return false;
      if (city.controlledHexes.contains(target)) return false;
    }
    return true;
  }

  /// Returns statically legal hexes touching the connected draft territory.
  static Set<CityHex> selectableControlledHexes({
    required CityFoundingDraft draft,
    required MapTileLookup mapTiles,
    Iterable<GameCity> cities = const [],
  }) {
    if (draft.controlledHexes.length >=
            CityFoundingDraft.requiredControlledHexes ||
        !draft.hasConnectedTerritory) {
      return const {};
    }

    final selected = draft.controlledHexes.toSet();
    final candidates = <CityHex>{};
    for (final territoryHex in draft.territoryHexes) {
      for (final neighbor in HexGridTopology.neighbors(
        col: territoryHex.col,
        row: territoryHex.row,
      )) {
        final candidate = CityHex(col: neighbor.col, row: neighbor.row);
        if (candidate == draft.center || selected.contains(candidate)) continue;
        final tile = mapTiles.tileAt(candidate.col, candidate.row);
        if (tile == null ||
            !isControlledHexCandidate(
              draft: draft,
              tile: tile,
              mapTiles: mapTiles,
              cities: cities,
            )) {
          continue;
        }
        candidates.add(candidate);
      }
    }
    return Set.unmodifiable(candidates);
  }

  /// Whether successive legal selections can complete the current draft.
  static bool canCompleteDraft({
    required CityFoundingDraft draft,
    required MapTileLookup mapTiles,
    Iterable<GameCity> cities = const [],
  }) {
    if (draft.controlledHexes.length >
            CityFoundingDraft.requiredControlledHexes ||
        !draft.hasConnectedTerritory) {
      return false;
    }
    if (draft.hasRequiredControlledHexes) return draft.canConfirm;

    for (final candidate in selectableControlledHexes(
      draft: draft,
      mapTiles: mapTiles,
      cities: cities,
    )) {
      if (canCompleteDraft(
        draft: draft.copyWith(
          controlledHexes: [...draft.controlledHexes, candidate],
        ),
        mapTiles: mapTiles,
        cities: cities,
      )) {
        return true;
      }
    }
    return false;
  }

  /// Toggles one hex while keeping only territory connected to the center.
  static CityFoundingDraft toggleControlledHexSelection({
    required CityFoundingDraft draft,
    required CityHex target,
    required MapTileLookup mapTiles,
    Iterable<GameCity> cities = const [],
  }) {
    if (draft.controlledHexes.contains(target)) {
      return draft.copyWith(
        controlledHexes: _connectedControlledHexesAfterRemoving(
          draft: draft,
          target: target,
        ),
      );
    }
    if (!selectableControlledHexes(
      draft: draft,
      mapTiles: mapTiles,
      cities: cities,
    ).contains(target)) {
      return draft;
    }
    return draft.copyWith(controlledHexes: [...draft.controlledHexes, target]);
  }

  static CityFoundingFailure? confirmFailure(CityFoundingDraft draft) {
    if (!draft.canConfirm) return CityFoundingFailure.invalidControlledHexes;
    return null;
  }

  static bool canFoundCityWith(GameUnit unit) {
    return unit.type == GameUnitType.settler || unit.hasSettlers;
  }

  static List<CityHex> _connectedControlledHexesAfterRemoving({
    required CityFoundingDraft draft,
    required CityHex target,
  }) {
    final remaining = [
      for (final hex in draft.controlledHexes)
        if (hex != target) hex,
    ];
    final unvisited = remaining.toSet();
    final connected = <CityHex>{};
    final frontier = <CityHex>[draft.center];
    while (frontier.isNotEmpty) {
      final current = frontier.removeLast();
      for (final neighbor in HexGridTopology.neighbors(
        col: current.col,
        row: current.row,
      )) {
        final hex = CityHex(col: neighbor.col, row: neighbor.row);
        if (!unvisited.remove(hex)) continue;
        connected.add(hex);
        frontier.add(hex);
      }
    }
    return [
      for (final hex in remaining)
        if (connected.contains(hex)) hex,
    ];
  }
}
