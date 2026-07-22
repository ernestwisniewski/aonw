import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_result.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_state.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomatic_action_guard.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';

abstract final class DiplomacyCommandSupport {
  static String? issueRejectionReason({
    required String playerId,
    required String actorPlayerId,
    required bool canAct,
  }) {
    return DiplomaticActionGuard.canIssue(
          playerId: playerId,
          canAct: canAct,
          actorPlayerId: actorPlayerId,
        )
        ? null
        : 'diplomacy_player_not_controlled';
  }

  static bool canTarget(
    DiplomacyCommandState state,
    String playerId,
    String targetPlayerId,
  ) {
    return DiplomaticActionGuard.canTargetDiscovered(
      playerId: playerId,
      targetPlayerId: targetPlayerId,
      knownPlayerIds: knownPlayerIds(state),
      diplomacy: state.diplomacy,
      fogOfWar: state.fogOfWar,
      units: state.units,
      cities: state.cities,
    );
  }

  static Set<String> knownPlayerIds(DiplomacyCommandState state) {
    return {
      ...state.playerColors.keys,
      ...state.playerCountries.keys,
      ...state.playerGold.keys,
      ...state.fogOfWar.playerIds,
      for (final unit in state.units) unit.ownerPlayerId,
      for (final city in state.cities) city.ownerPlayerId,
    }..removeWhere((playerId) => playerId.isEmpty);
  }

  static DiplomacyCommandResult reject(
    DiplomacyCommandState state,
    String reason,
  ) {
    return DiplomacyCommandResult.rejected(
      playerGold: state.playerGold,
      diplomacy: state.diplomacy,
      intendedAttacks: state.intendedAttacks,
      resourceTradeAgreements: state.resourceTradeAgreements,
      reason: reason,
    );
  }

  static DiplomacyCommandResult accept(
    DiplomacyCommandState state, {
    Map<String, int>? playerGold,
    DiplomacyState? diplomacy,
    List<IntendedAttack>? intendedAttacks,
    List<ResourceTradeAgreement>? resourceTradeAgreements,
    List<GameEvent> events = const [],
  }) {
    return DiplomacyCommandResult.accepted(
      playerGold: playerGold ?? state.playerGold,
      diplomacy: diplomacy ?? state.diplomacy,
      intendedAttacks: intendedAttacks ?? state.intendedAttacks,
      resourceTradeAgreements:
          resourceTradeAgreements ?? state.resourceTradeAgreements,
      events: events.isEmpty ? const [] : List.unmodifiable(events),
    );
  }

  static DiplomaticScoreChangedEvent scoreEvent(DiplomaticScoreEntry entry) {
    return DiplomaticScoreChangedEvent(
      playerAId: entry.playerAId,
      playerBId: entry.playerBId,
      delta: entry.delta,
      scoreAfter: entry.scoreAfter,
      reason: entry.reason,
      sourceId: entry.sourceId,
    );
  }
}
