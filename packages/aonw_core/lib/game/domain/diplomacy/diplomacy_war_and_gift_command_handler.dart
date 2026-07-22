import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_result.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_state.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_support.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomatic_warmonger_reputation.dart';
import 'package:aonw_core/game/domain/diplomacy/gold_amount.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';

abstract final class DiplomacyWarAndGiftCommandHandler {
  static DiplomacyCommandResult declareWar({
    required DiplomacyCommandState state,
    required DeclareWarCommand command,
    required String actorPlayerId,
    required int turn,
    required bool canAct,
  }) {
    final rejectionReason = _warRejectionReason(
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      turn: turn,
      canAct: canAct,
    );
    if (rejectionReason != null) {
      return DiplomacyCommandSupport.reject(state, rejectionReason);
    }
    final oldRelation = state.diplomacy.relationBetween(
      command.playerId,
      command.targetPlayerId,
    );
    final declaration = state.diplomacy.declareWarWithScoreEntry(
      playerId: command.playerId,
      targetPlayerId: command.targetPlayerId,
      turn: turn,
    );
    final reputation = DiplomaticWarmongerReputation.apply(
      diplomacy: declaration.state,
      aggressorPlayerId: command.playerId,
      victimPlayerId: command.targetPlayerId,
      action: DiplomaticWarmongerAction.declarationOfWar,
      turn: turn,
    );
    final nextRelation = reputation.diplomacy.relationBetween(
      command.playerId,
      command.targetPlayerId,
    );
    return DiplomacyCommandSupport.accept(
      state,
      diplomacy: reputation.diplomacy,
      resourceTradeAgreements: _removePairTrades(
        state.resourceTradeAgreements,
        command.playerId,
        command.targetPlayerId,
      ),
      events: [
        DiplomaticRelationChangedEvent(
          playerAId: nextRelation.playerAId,
          playerBId: nextRelation.playerBId,
          oldStatus: oldRelation.status,
          newStatus: nextRelation.status,
          reason: DiplomaticRelationChangeReason.declarationOfWar,
        ),
        if (declaration.entry != null)
          DiplomacyCommandSupport.scoreEvent(declaration.entry!),
        for (final entry in reputation.entries)
          DiplomacyCommandSupport.scoreEvent(entry),
      ],
    );
  }

  static DiplomacyCommandResult sendGoldGift({
    required DiplomacyCommandState state,
    required SendGoldGiftCommand command,
    required String actorPlayerId,
    required int turn,
    required bool canAct,
  }) {
    final rejectionReason = _giftRejectionReason(
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      turn: turn,
      canAct: canAct,
    );
    if (rejectionReason != null) {
      return DiplomacyCommandSupport.reject(state, rejectionReason);
    }
    final amount = GoldAmount(command.amount);
    final availableGold = state.playerGold[command.playerId] ?? 0;
    final recipientGold = state.playerGold[command.targetPlayerId] ?? 0;
    final adjustment = state.diplomacy.adjustRelationScoreWithEntry(
      command.playerId,
      command.targetPlayerId,
      DiplomaticGoldGiftRules.relationDeltaFor(amount.value),
      turn: turn,
      reason: DiplomaticScoreChangeReason.goldGift,
      sourceId: 'gold_gift.$turn.${command.playerId}.${command.targetPlayerId}',
    );
    return DiplomacyCommandSupport.accept(
      state,
      playerGold: Map.unmodifiable({
        ...state.playerGold,
        command.playerId: availableGold - amount.value,
        command.targetPlayerId: recipientGold + amount.value,
      }),
      diplomacy: adjustment.state,
      events: [
        if (adjustment.entry != null)
          DiplomacyCommandSupport.scoreEvent(adjustment.entry!),
      ],
    );
  }

  static String? _warRejectionReason({
    required DiplomacyCommandState state,
    required DeclareWarCommand command,
    required String actorPlayerId,
    required int turn,
    required bool canAct,
  }) {
    final permissionReason = _permissionRejectionReason(
      state: state,
      playerId: command.playerId,
      targetPlayerId: command.targetPlayerId,
      actorPlayerId: actorPlayerId,
      canAct: canAct,
    );
    if (permissionReason != null) return permissionReason;
    final relation = state.diplomacy.relationBetween(
      command.playerId,
      command.targetPlayerId,
    );
    if (relation.status == DiplomaticRelationStatus.truce &&
        relation.statusExpiresOnTurn != null &&
        turn < relation.statusExpiresOnTurn!) {
      return 'diplomacy_truce_active';
    }
    return relation.status == DiplomaticRelationStatus.war
        ? 'diplomacy_war_already_active'
        : null;
  }

  static String? _giftRejectionReason({
    required DiplomacyCommandState state,
    required SendGoldGiftCommand command,
    required String actorPlayerId,
    required int turn,
    required bool canAct,
  }) {
    final permissionReason = _permissionRejectionReason(
      state: state,
      playerId: command.playerId,
      targetPlayerId: command.targetPlayerId,
      actorPlayerId: actorPlayerId,
      canAct: canAct,
    );
    if (permissionReason != null) return permissionReason;
    if (command.amount < 0) return 'diplomacy_invalid_gold_amount';
    final status = state.diplomacy.statusBetween(
      command.playerId,
      command.targetPlayerId,
    );
    if (status == DiplomaticRelationStatus.war ||
        status == DiplomaticRelationStatus.truce) {
      return 'diplomacy_gold_gift_blocked_by_relation';
    }
    if (!GoldAmount(
      command.amount,
    ).canFundFrom(state.playerGold[command.playerId] ?? 0)) {
      return 'diplomacy_gold_unavailable';
    }
    if (DiplomaticGoldGiftRules.relationDeltaFor(command.amount) <= 0 ||
        _giftOnCooldown(state, command, turn)) {
      return 'diplomacy_gold_gift_unavailable';
    }
    return null;
  }

  static String? _permissionRejectionReason({
    required DiplomacyCommandState state,
    required String playerId,
    required String targetPlayerId,
    required String actorPlayerId,
    required bool canAct,
  }) {
    final issueReason = DiplomacyCommandSupport.issueRejectionReason(
      playerId: playerId,
      actorPlayerId: actorPlayerId,
      canAct: canAct,
    );
    if (issueReason != null) return issueReason;
    return DiplomacyCommandSupport.canTarget(state, playerId, targetPlayerId)
        ? null
        : 'diplomacy_target_not_discovered';
  }

  static bool _giftOnCooldown(
    DiplomacyCommandState state,
    SendGoldGiftCommand command,
    int turn,
  ) {
    return state.diplomacy
        .scoreEntriesBetween(command.playerId, command.targetPlayerId)
        .any(
          (entry) =>
              entry.reason == DiplomaticScoreChangeReason.goldGift &&
              turn >= entry.turn &&
              turn - entry.turn < DiplomaticGoldGiftRules.cooldownTurns,
        );
  }

  static List<ResourceTradeAgreement> _removePairTrades(
    List<ResourceTradeAgreement> agreements,
    String playerAId,
    String playerBId,
  ) {
    final pairKey = DiplomacyState.relationKey(playerAId, playerBId);
    final retained = [
      for (final agreement in agreements)
        if (DiplomacyState.relationKey(
              agreement.exporterPlayerId,
              agreement.importerPlayerId,
            ) !=
            pairKey)
          agreement,
    ];
    return retained.length == agreements.length
        ? agreements
        : List.unmodifiable(retained);
  }
}
