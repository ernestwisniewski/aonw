import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomatic_relation_benefits.dart';

abstract final class CityEntryPolicy {
  static GameCity? cityCenterAt({
    required Iterable<GameCity> cities,
    required int col,
    required int row,
  }) {
    for (final city in cities) {
      if (city.occupiesCenter(col, row)) return city;
    }
    return null;
  }

  static bool canEnterCityCenter({
    required DiplomacyState diplomacy,
    required String unitOwnerPlayerId,
    required GameCity city,
  }) {
    return DiplomaticRelationBenefits.canEnterForeignCityCenter(
      diplomacy: diplomacy,
      unitOwnerPlayerId: unitOwnerPlayerId,
      cityOwnerPlayerId: city.ownerPlayerId,
    );
  }

  static bool blocksCityCenterEntry({
    required DiplomacyState diplomacy,
    required Iterable<GameCity> cities,
    required String unitOwnerPlayerId,
    required int col,
    required int row,
  }) {
    final city = cityCenterAt(cities: cities, col: col, row: row);
    if (city == null) return false;
    return !canEnterCityCenter(
      diplomacy: diplomacy,
      unitOwnerPlayerId: unitOwnerPlayerId,
      city: city,
    );
  }
}
