import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';

abstract final class DiplomaticSharedWar {
  static bool hasSharedWarEnemy(
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
