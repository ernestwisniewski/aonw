import 'package:aonw_core/game/domain/city/game_city.dart';

/// Locates the canonical stability core of an empire: the player's capital
/// when present, otherwise the owned city that sorts first by id.
///
/// Cohesion costs, AI founding projections and their UI previews must all
/// agree on this choice, so every consumer goes through this locator.
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
