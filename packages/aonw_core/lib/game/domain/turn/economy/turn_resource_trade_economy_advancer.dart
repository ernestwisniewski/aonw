import 'package:aonw_core/game/domain/diplomacy/diplomatic_relation_benefits.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';

import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';

abstract final class TurnResourceTradeEconomyAdvancer {
  static TurnEconomyState advance({
    required TurnEconomyState state,
    required Iterable<String> playerIds,
  }) {
    final activeImporterIds = playerIds.toSet();
    if (activeImporterIds.isEmpty || state.resourceTradeAgreements.isEmpty) {
      return state;
    }
    final gold = Map<String, int>.from(state.playerGold);
    final next = <ResourceTradeAgreement>[];
    var changed = false;
    for (final agreement in state.resourceTradeAgreements) {
      if (!agreement.isActive ||
          !activeImporterIds.contains(agreement.importerPlayerId)) {
        next.add(agreement);
        continue;
      }
      final importerGold = gold[agreement.importerPlayerId] ?? 0;
      if (importerGold < agreement.goldPerTurn) {
        changed = true;
        continue;
      }
      _transferGold(state, agreement, importerGold, gold);
      final remainingTurns = agreement.remainingTurns - 1;
      if (remainingTurns > 0) {
        next.add(agreement.copyWith(remainingTurns: remainingTurns));
      }
      changed = true;
    }
    if (!changed) return state;
    return state.copyWith(
      playerGold: Map.unmodifiable(gold),
      resourceTradeAgreements: List.unmodifiable(next),
    );
  }

  static void _transferGold(
    TurnEconomyState state,
    ResourceTradeAgreement agreement,
    int importerGold,
    Map<String, int> gold,
  ) {
    final tradeBonus = agreement.goldPerTurn > 0
        ? DiplomaticRelationBenefits.resourceTradeGoldBonus(
            diplomacy: state.diplomacy,
            playerAId: agreement.importerPlayerId,
            playerBId: agreement.exporterPlayerId,
          )
        : 0;
    final exporterGold = agreement.goldPerTurn + tradeBonus;
    if (agreement.goldPerTurn > 0) {
      gold[agreement.importerPlayerId] = importerGold - agreement.goldPerTurn;
    }
    if (exporterGold > 0) {
      gold[agreement.exporterPlayerId] =
          (gold[agreement.exporterPlayerId] ?? 0) + exporterGold;
    }
  }
}
