import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_territory_rules.dart';
import 'package:aonw_core/game/domain/city/city_tile_yield_rules.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract final class CityExpansionRules {
  static bool canClaim({
    required GameCity city,
    required CityHex target,
    required TileData? tile,
    required Iterable<GameCity> cities,
    int? radius,
    bool allowCoast = false,
    bool allowOcean = false,
  }) {
    if (tile == null) return false;
    if (city.controlsHex(target)) return false;
    if (!CityTileYieldRules.canCityControlTile(
      tile,
      allowCoast: allowCoast,
      allowOcean: allowOcean,
    )) {
      return false;
    }
    if (_ownerOf(target, cities) != null) return false;
    if (!_isAdjacentToCity(city, target)) return false;
    final maxRadius = radius ?? city.territoryRadius;
    final distance = CityTerritoryRules.distance(
      from: city.center,
      to: target,
      maxDistance: maxRadius,
    );
    if (distance > maxRadius) return false;
    return CityTerritoryRules.hasExpansionSupport(
      center: city.center,
      controlledHexes: city.controlledHexes,
      target: target,
      maxDistance: maxRadius,
    );
  }

  static bool isUnowned(CityHex hex, Iterable<GameCity> cities) {
    return _ownerOf(hex, cities) == null;
  }

  static GameCity? _ownerOf(CityHex hex, Iterable<GameCity> cities) {
    for (final city in cities) {
      if (city.controlsHex(hex)) return city;
    }
    return null;
  }

  static bool _isAdjacentToCity(GameCity city, CityHex target) {
    for (final owned in city.territoryHexes) {
      for (final neighbor in HexGridTopology.neighbors(
        col: owned.col,
        row: owned.row,
      )) {
        if (neighbor.col == target.col && neighbor.row == target.row) {
          return true;
        }
      }
    }
    return false;
  }
}
