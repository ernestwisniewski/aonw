import 'package:aonw_core/game/domain/diplomacy/diplomatic_relation_benefits.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';

import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';

abstract final class TurnResourceTradeEconomyAdvancer {
  static TurnEconomyState advance({
    required TurnEconomyState state,
    required Iterable<String> playerIds,
    bool strategicResourceStockpilesEnabled = true,
  }) {
    final activeImporterIds = playerIds.toSet();
    if (activeImporterIds.isEmpty || state.resourceTradeAgreements.isEmpty) {
      return state;
    }
    final advance = _ResourceTradeAdvance(
      state: state,
      activeImporterIds: activeImporterIds,
      stockpilesEnabled: strategicResourceStockpilesEnabled,
    );
    for (final agreement in state.resourceTradeAgreements) {
      advance.apply(agreement);
    }
    return advance.result;
  }
}

final class _ResourceTradeAdvance {
  _ResourceTradeAdvance({
    required this.state,
    required this.activeImporterIds,
    required this.stockpilesEnabled,
  }) : gold = Map.from(state.playerGold),
       strategicResources = state.strategicResources;

  final TurnEconomyState state;
  final Set<String> activeImporterIds;
  final bool stockpilesEnabled;
  final Map<String, int> gold;
  final List<ResourceTradeAgreement> agreements = [];
  StrategicResourceAccounts strategicResources;
  bool changed = false;

  void apply(ResourceTradeAgreement agreement) {
    if (!agreement.isActive ||
        !activeImporterIds.contains(agreement.importerPlayerId)) {
      agreements.add(agreement);
      return;
    }
    final importerGold = gold[agreement.importerPlayerId] ?? 0;
    if (importerGold < agreement.goldPerTurn) {
      changed = true;
      return;
    }
    final delivery = _stockpileDelivery(agreement);
    if (delivery != null && !_canDeliver(agreement, delivery)) {
      _age(agreement);
      return;
    }
    if (delivery != null) _transferResource(agreement, delivery);
    _transferGold(agreement, importerGold);
    _age(agreement);
  }

  StrategicResourceBundle? _stockpileDelivery(
    ResourceTradeAgreement agreement,
  ) {
    if (!stockpilesEnabled ||
        !ResourceCatalog.isStockpiled(agreement.resource)) {
      return null;
    }
    return StrategicResourceBundle({agreement.resource: 1});
  }

  bool _canDeliver(
    ResourceTradeAgreement agreement,
    StrategicResourceBundle delivery,
  ) =>
      strategicResources.forPlayer(agreement.exporterPlayerId).covers(delivery);

  void _transferResource(
    ResourceTradeAgreement agreement,
    StrategicResourceBundle delivery,
  ) {
    strategicResources = strategicResources.transfer(
      fromPlayerId: agreement.exporterPlayerId,
      toPlayerId: agreement.importerPlayerId,
      bundle: delivery,
    );
  }

  void _transferGold(ResourceTradeAgreement agreement, int importerGold) {
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

  void _age(ResourceTradeAgreement agreement) {
    final remainingTurns = agreement.remainingTurns - 1;
    if (remainingTurns > 0) {
      agreements.add(agreement.copyWith(remainingTurns: remainingTurns));
    }
    changed = true;
  }

  TurnEconomyState get result {
    if (!changed) return state;
    return state.copyWith(
      playerGold: Map.unmodifiable(gold),
      resourceTradeAgreements: List.unmodifiable(agreements),
      strategicResources: strategicResources,
    );
  }
}
