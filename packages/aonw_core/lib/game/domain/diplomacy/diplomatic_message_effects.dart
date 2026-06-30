import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomatic_shared_war.dart';

abstract final class DiplomaticMessageEffects {
  static int relationDeltaForResponse(
    DiplomacyState diplomacy,
    DiplomaticMessage message,
    DiplomaticMessageResponse response,
  ) {
    return response.relationScoreDelta +
        commonEnemyCooperationBonus(diplomacy, message, response);
  }

  static int commonEnemyCooperationBonus(
    DiplomacyState diplomacy,
    DiplomaticMessage message,
    DiplomaticMessageResponse response,
  ) {
    if (message.topic != DiplomaticMessageTopic.commonEnemy ||
        !DiplomaticSharedWar.hasSharedWarEnemy(
          diplomacy,
          message.fromPlayerId,
          message.toPlayerId,
        )) {
      return 0;
    }
    return switch (response) {
      DiplomaticMessageResponse.conciliatory => 8,
      DiplomaticMessageResponse.neutral => 4,
      DiplomaticMessageResponse.evasive ||
      DiplomaticMessageResponse.aggressive => 0,
    };
  }
}
