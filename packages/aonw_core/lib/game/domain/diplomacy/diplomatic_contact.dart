import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class DiplomaticContact {
  static Set<String> contactKeys({
    required FogOfWarState fogOfWar,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
    Iterable<String>? playerIds,
  }) {
    final players = <String>{...?playerIds, ...fogOfWar.playerIds}
      ..removeWhere((playerId) => playerId.isEmpty);
    final keys = <String>{};
    for (final playerId in players) {
      final query = FogVisibilityQuery(playerId: playerId, state: fogOfWar);
      for (final city in cities) {
        final ownerPlayerId = city.ownerPlayerId;
        if (ownerPlayerId.isEmpty || ownerPlayerId == playerId) continue;
        if (query.canRememberStaticAt(city.center.col, city.center.row)) {
          final key = DiplomacyState.relationKey(playerId, ownerPlayerId);
          if (key.isNotEmpty) keys.add(key);
        }
      }
      for (final unit in units) {
        final ownerPlayerId = unit.ownerPlayerId;
        if (ownerPlayerId.isEmpty || ownerPlayerId == playerId) continue;
        if (query.canSeeDynamicAt(unit.col, unit.row)) {
          final key = DiplomacyState.relationKey(playerId, ownerPlayerId);
          if (key.isNotEmpty) keys.add(key);
        }
      }
    }
    return Set.unmodifiable(keys);
  }

  static bool hasContact({
    required String playerId,
    required String targetPlayerId,
    required FogOfWarState fogOfWar,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
  }) {
    final key = DiplomacyState.relationKey(playerId, targetPlayerId);
    if (key.isEmpty) return false;
    return contactKeys(
      fogOfWar: fogOfWar,
      units: units,
      cities: cities,
      playerIds: [playerId],
    ).contains(key);
  }

  static DiplomacyState mergeDiscoveredContacts({
    required DiplomacyState diplomacy,
    required FogOfWarState fogOfWar,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
    Iterable<String>? playerIds,
  }) {
    return diplomacy.addContactKeys(
      contactKeys(
        fogOfWar: fogOfWar,
        units: units,
        cities: cities,
        playerIds: playerIds,
      ),
    );
  }
}
