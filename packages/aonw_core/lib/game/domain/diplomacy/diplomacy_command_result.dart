import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';

/// Persistence-neutral result containing only diplomacy-owned mutations.
final class DiplomacyCommandResult {
  const DiplomacyCommandResult.accepted({
    required this.playerGold,
    required this.diplomacy,
    required this.intendedAttacks,
    required this.resourceTradeAgreements,
    this.events = const [],
  }) : accepted = true,
       reason = null;

  const DiplomacyCommandResult.rejected({
    required this.playerGold,
    required this.diplomacy,
    required this.intendedAttacks,
    required this.resourceTradeAgreements,
    required this.reason,
  }) : accepted = false,
       events = const [];

  final bool accepted;
  final String? reason;
  final Map<String, int> playerGold;
  final DiplomacyState diplomacy;
  final List<IntendedAttack> intendedAttacks;
  final List<ResourceTradeAgreement> resourceTradeAgreements;
  final List<GameEvent> events;
}
