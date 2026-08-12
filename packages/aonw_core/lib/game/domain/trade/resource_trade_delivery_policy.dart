import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';

abstract interface class ResourceTradeDeliveryPolicy {
  const ResourceTradeDeliveryPolicy();

  bool canDeliver({
    required ResourceTradeAgreement agreement,
    required DiplomacyState diplomacy,
  });
}

final class DiplomacyResourceTradeDeliveryPolicy
    implements ResourceTradeDeliveryPolicy {
  const DiplomacyResourceTradeDeliveryPolicy();

  @override
  bool canDeliver({
    required ResourceTradeAgreement agreement,
    required DiplomacyState diplomacy,
  }) =>
      diplomacy.statusBetween(
        agreement.exporterPlayerId,
        agreement.importerPlayerId,
      ) !=
      DiplomaticRelationStatus.war;
}
