import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/hex/hex_coordinate.dart';

/// Temporary boundary between legacy coordinate models and [HexCoord].
///
/// Removal condition: production APIs no longer expose [HexCoordinate] or
/// [CityHex]. New code must use [HexCoord] directly instead of adding another
/// point-to-point converter.
abstract final class LegacyHexCoordAdapter {
  static HexCoord fromHexCoordinate(HexCoordinate coordinate) {
    return HexCoord(col: coordinate.col, row: coordinate.row);
  }

  static HexCoordinate toHexCoordinate(HexCoord coordinate) {
    return HexCoordinate(col: coordinate.col, row: coordinate.row);
  }

  static HexCoord fromCityHex(CityHex coordinate) {
    return HexCoord(col: coordinate.col, row: coordinate.row);
  }

  static CityHex toCityHex(HexCoord coordinate) {
    return CityHex(col: coordinate.col, row: coordinate.row);
  }
}
