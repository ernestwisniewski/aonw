import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomatic_contact.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class DiplomaticActionGuard {
  static bool canIssue({
    required String playerId,
    required bool canAct,
    String? actorPlayerId,
    String activePlayerId = '',
  }) {
    if (playerId.isEmpty || !canAct) return false;
    if (actorPlayerId != null) return actorPlayerId == playerId;
    return activePlayerId.isEmpty || activePlayerId == playerId;
  }

  static bool canTargetDiscovered({
    required String playerId,
    required String targetPlayerId,
    required Iterable<String> knownPlayerIds,
    required DiplomacyState diplomacy,
    required FogOfWarState fogOfWar,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
  }) {
    if (playerId.isEmpty ||
        targetPlayerId.isEmpty ||
        playerId == targetPlayerId) {
      return false;
    }
    if (!knownPlayerIds.contains(targetPlayerId)) return false;
    if (diplomacy.hasContact(playerId, targetPlayerId)) return true;
    return DiplomaticContact.hasContact(
      playerId: playerId,
      targetPlayerId: targetPlayerId,
      fogOfWar: fogOfWar,
      units: units,
      cities: cities,
    );
  }
}
