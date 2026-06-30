import 'package:aonw_core/game/domain/diplomacy.dart';

abstract final class DiplomaticMessageEffects {
  static int commonEnemyCooperationBonus(
    DiplomacyState diplomacy,
    DiplomaticMessage message,
    DiplomaticMessageResponse response,
  ) {
    if (message.topic != DiplomaticMessageTopic.commonEnemy ||
        !_hasSharedWarEnemy(
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

  static bool _hasSharedWarEnemy(
    DiplomacyState diplomacy,
    String playerAId,
    String playerBId,
  ) {
    for (final relation in diplomacy.relations.values) {
      if (relation.status != DiplomaticRelationStatus.war) continue;
      final enemyId = _warEnemyFor(relation, playerAId);
      if (enemyId == null || enemyId == playerBId) continue;
      if (diplomacy.statusBetween(playerBId, enemyId) ==
          DiplomaticRelationStatus.war) {
        return true;
      }
    }
    return false;
  }

  static String? _warEnemyFor(DiplomaticRelation relation, String playerId) {
    if (relation.playerAId == playerId) return relation.playerBId;
    if (relation.playerBId == playerId) return relation.playerAId;
    return null;
  }
}
