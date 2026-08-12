import 'package:aonw_core/game/domain/diplomacy/diplomatic_relation_benefits.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_delivery_policy.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';

abstract final class TurnResourceTradeEconomyAdvancer {
  static TurnEconomyState advance({
    required TurnEconomyState state,
    required Iterable<String> playerIds,
    bool strategicResourceStockpilesEnabled = true,
    ResourceTradeDeliveryPolicy deliveryPolicy =
        const DiplomacyResourceTradeDeliveryPolicy(),
  }) {
    final activeImporterIds = playerIds.toSet();
    if (activeImporterIds.isEmpty || state.resourceTradeAgreements.isEmpty) {
      return state;
    }
    final advance = _ResourceTradeAdvance(
      state: state,
      activeImporterIds: activeImporterIds,
      stockpilesEnabled: strategicResourceStockpilesEnabled,
      deliveryPolicy: deliveryPolicy,
    );
    for (final group in _orderedAgreementGroups(
      state.resourceTradeAgreements,
    )) {
      advance.applyGroup(group);
    }
    return advance.result;
  }
}

List<List<ResourceTradeAgreement>> _orderedAgreementGroups(
  Iterable<ResourceTradeAgreement> agreements,
) {
  final groups = <String, List<ResourceTradeAgreement>>{};
  for (final agreement in agreements) {
    final key = agreement.exchangeGroupId ?? 'single:${agreement.id}';
    groups.putIfAbsent(key, () => []).add(agreement);
  }
  final keys = groups.keys.toList()..sort();
  return [
    for (final key in keys)
      groups[key]!..sort((left, right) => left.id.compareTo(right.id)),
  ];
}

final class _ResourceTradeAdvance {
  _ResourceTradeAdvance({
    required this.state,
    required this.activeImporterIds,
    required this.stockpilesEnabled,
    required this.deliveryPolicy,
  }) : gold = Map.from(state.playerGold),
       strategicResources = state.strategicResources;

  final TurnEconomyState state;
  final Set<String> activeImporterIds;
  final bool stockpilesEnabled;
  final ResourceTradeDeliveryPolicy deliveryPolicy;
  final Map<String, int> gold;
  final List<ResourceTradeAgreement> agreements = [];
  StrategicResourceAccounts strategicResources;
  bool changed = false;

  void applyGroup(List<ResourceTradeAgreement> group) {
    if (!_isDue(group)) {
      agreements.addAll(group);
      return;
    }
    if (!_hasGoldForEveryLeg(group)) {
      changed = true;
      return;
    }
    if (!_routesAllowEveryLeg(group) || !_hasStockForEveryLeg(group)) {
      _ageGroup(group);
      return;
    }
    for (final agreement in group) {
      _transferResource(agreement);
    }
    for (final agreement in group) {
      _transferGold(agreement);
    }
    _ageGroup(group);
  }

  bool _isDue(List<ResourceTradeAgreement> group) {
    if (group.any((agreement) => !agreement.isActive)) return false;
    final settlementPlayerId = group
        .map((agreement) => agreement.importerPlayerId)
        .reduce((left, right) => left.compareTo(right) <= 0 ? left : right);
    return activeImporterIds.contains(settlementPlayerId);
  }

  bool _hasGoldForEveryLeg(Iterable<ResourceTradeAgreement> group) {
    final requiredByPlayer = <String, int>{};
    for (final agreement in group) {
      requiredByPlayer.update(
        agreement.importerPlayerId,
        (value) => value + agreement.goldPerTurn,
        ifAbsent: () => agreement.goldPerTurn,
      );
    }
    return requiredByPlayer.entries.every(
      (entry) => (gold[entry.key] ?? 0) >= entry.value,
    );
  }

  bool _routesAllowEveryLeg(Iterable<ResourceTradeAgreement> group) =>
      group.every(
        (agreement) => deliveryPolicy.canDeliver(
          agreement: agreement,
          diplomacy: state.diplomacy,
        ),
      );

  bool _hasStockForEveryLeg(Iterable<ResourceTradeAgreement> group) {
    final requiredByPlayer = <String, StrategicResourceBundle>{};
    for (final agreement in group) {
      final delivery = _stockpileDelivery(agreement);
      if (delivery == null) continue;
      requiredByPlayer.update(
        agreement.exporterPlayerId,
        (value) => value.plus(delivery),
        ifAbsent: () => delivery,
      );
    }
    return requiredByPlayer.entries.every(
      (entry) => strategicResources.forPlayer(entry.key).covers(entry.value),
    );
  }

  StrategicResourceBundle? _stockpileDelivery(
    ResourceTradeAgreement agreement,
  ) {
    if (!stockpilesEnabled ||
        !ResourceCatalog.isStockpiled(agreement.resource)) {
      return null;
    }
    return StrategicResourceBundle({
      agreement.resource: agreement.amountPerTurn,
    });
  }

  void _transferResource(ResourceTradeAgreement agreement) {
    final delivery = _stockpileDelivery(agreement);
    if (delivery == null) return;
    strategicResources = strategicResources.transfer(
      fromPlayerId: agreement.exporterPlayerId,
      toPlayerId: agreement.importerPlayerId,
      bundle: delivery,
    );
  }

  void _transferGold(ResourceTradeAgreement agreement) {
    final importerGold = gold[agreement.importerPlayerId] ?? 0;
    final tradeBonus = agreement.goldPerTurn > 0
        ? DiplomaticRelationBenefits.resourceTradeGoldBonus(
            diplomacy: state.diplomacy,
            playerAId: agreement.importerPlayerId,
            playerBId: agreement.exporterPlayerId,
          )
        : 0;
    if (agreement.goldPerTurn > 0) {
      gold[agreement.importerPlayerId] = importerGold - agreement.goldPerTurn;
    }
    final exporterGold = agreement.goldPerTurn + tradeBonus;
    if (exporterGold > 0) {
      gold[agreement.exporterPlayerId] =
          (gold[agreement.exporterPlayerId] ?? 0) + exporterGold;
    }
  }

  void _ageGroup(Iterable<ResourceTradeAgreement> group) {
    for (final agreement in group) {
      final remainingTurns = agreement.remainingTurns - 1;
      if (remainingTurns > 0) {
        agreements.add(agreement.copyWith(remainingTurns: remainingTurns));
      }
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
