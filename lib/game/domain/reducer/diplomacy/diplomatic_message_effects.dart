import 'package:aonw_core/game/domain/diplomacy.dart';

abstract final class DiplomaticMessageEffects {
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
