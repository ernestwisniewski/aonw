import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';

abstract final class DiplomaticRelationBenefits {
  static const int friendlyResourceTradeGoldBonus = 1;

  static bool hasRightOfPassage({
    required DiplomacyState diplomacy,
    required String playerAId,
    required String playerBId,
  }) {
    return diplomacy.statusBetween(playerAId, playerBId) ==
        DiplomaticRelationStatus.friendly;
  }

  static bool canEnterForeignCityCenter({
    required DiplomacyState diplomacy,
    required String unitOwnerPlayerId,
    required String cityOwnerPlayerId,
  }) {
    if (unitOwnerPlayerId == cityOwnerPlayerId) return true;
    return false;
  }

  static int resourceTradeGoldBonus({
    required DiplomacyState diplomacy,
    required String playerAId,
    required String playerBId,
  }) {
    return diplomacy.statusBetween(playerAId, playerBId) ==
            DiplomaticRelationStatus.friendly
        ? friendlyResourceTradeGoldBonus
        : 0;
  }
}
