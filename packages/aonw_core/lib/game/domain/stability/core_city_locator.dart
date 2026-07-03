import 'package:aonw_core/game/domain/city/game_city.dart';

abstract final class CoreCityLocator {
  static GameCity? coreCityFor({
    required String playerId,
    required Iterable<GameCity> cities,
  }) {
    GameCity? first;
    for (final city in cities) {
      if (city.ownerPlayerId != playerId) continue;
      if (city.capitalOwnerPlayerId == playerId) return city;
      if (first == null || city.id.compareTo(first.id) < 0) first = city;
    }
    return first;
  }
}
