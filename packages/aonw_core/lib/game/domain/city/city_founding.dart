import 'package:aonw_core/game/domain/city/city_founding_draft.dart';
import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_site_rules.dart';
import 'package:aonw_core/game/domain/city/city_territory_rules.dart';
import 'package:aonw_core/game/domain/city/city_tile_yield_rules.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

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
    required TileData? centerTile,
    required Iterable<GameCity> cities,
  }) {
    return startFailure(unit: unit, centerTile: centerTile, cities: cities) ==
        null;
  }

  static CityFoundingFailure? startFailure({
    required GameUnit? unit,
    required TileData? centerTile,
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
    required TileData tile,
    required MapData mapData,
    Iterable<GameCity> cities = const [],
  }) {
    if (draft.center.occupies(tile.col, tile.row)) return false;
    if (mapData.tileAt(tile.col, tile.row) == null) return false;
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

  static CityFoundingFailure? confirmFailure(CityFoundingDraft draft) {
    if (!draft.canConfirm) return CityFoundingFailure.invalidControlledHexes;
    return null;
  }

  static bool canFoundCityWith(GameUnit unit) {
    return unit.type == GameUnitType.settler || unit.hasSettlers;
  }
}
