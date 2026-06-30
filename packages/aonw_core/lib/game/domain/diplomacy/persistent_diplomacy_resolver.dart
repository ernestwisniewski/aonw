import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/trade.dart';

class PersistentDiplomacyResolver {
  const PersistentDiplomacyResolver();

  PersistentDiplomacyResult sendProposal({
    required PersistentGameState state,
    required SendDiplomaticProposalCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) {
    if (!_canIssue(state, command.playerId, actorPlayerId, canAct: canAct)) {
      return _reject(state, 'diplomacy_player_not_controlled');
    }
    if (!_canTarget(state, command.playerId, command.targetPlayerId)) {
      return _reject(state, 'diplomacy_target_not_discovered');
    }

    final diplomacy = state.runtimeState.diplomacy;
    final relation = diplomacy.relationBetween(
      command.playerId,
      command.targetPlayerId,
    );
    if (!_proposalAllowed(command.kind, relation.status)) {
      return _reject(state, 'diplomacy_proposal_not_allowed');
    }

    final proposal = DiplomaticProposal(
      id:
          command.proposalId ??
          _proposalId(
            turn: turn,
            fromPlayerId: command.playerId,
            toPlayerId: command.targetPlayerId,
            kind: command.kind,
            count: diplomacy.pendingProposals.length,
          ),
      fromPlayerId: command.playerId,
      toPlayerId: command.targetPlayerId,
      kind: command.kind,
      createdTurn: turn,
      expiresOnTurn: turn + DiplomacyState.defaultProposalDurationTurns,
      goldPayment: _goldPaymentForCommand(state, command),
    );
    final nextDiplomacy = diplomacy.addProposal(proposal);
    if (identical(nextDiplomacy, diplomacy)) {
      return _reject(state, 'diplomacy_duplicate_proposal');
    }
    return _accept(
      _withDiplomacy(state, nextDiplomacy),
      events: [
        DiplomaticProposalSentEvent(
          proposalId: proposal.id,
          fromPlayerId: proposal.fromPlayerId,
          toPlayerId: proposal.toPlayerId,
          kind: proposal.kind,
          expiresOnTurn: proposal.expiresOnTurn,
        ),
      ],
    );
  }

  PersistentDiplomacyResult respondProposal({
    required PersistentGameState state,
    required RespondDiplomaticProposalCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) {
    if (!_canIssue(state, command.playerId, actorPlayerId, canAct: canAct)) {
      return _reject(state, 'diplomacy_player_not_controlled');
    }
    final proposal =
        state.runtimeState.diplomacy.pendingProposals[command.proposalId];
    if (proposal == null || proposal.toPlayerId != command.playerId) {
      return _reject(state, 'diplomacy_proposal_not_found');
    }
    if (command.accepted && !_canFundAccepted(state, proposal)) {
      return _reject(state, 'diplomacy_proposal_payment_unavailable');
    }

    var diplomacy = state.runtimeState.diplomacy.removeProposal(proposal.id);
    final events = <GameEvent>[
      DiplomaticProposalRespondedEvent(
        proposalId: proposal.id,
        fromPlayerId: proposal.fromPlayerId,
        toPlayerId: proposal.toPlayerId,
        kind: proposal.kind,
        accepted: command.accepted,
      ),
    ];

    var nextState = state;
    var intendedAttacks = state.runtimeState.intendedAttacks;
    if (command.accepted) {
      final oldRelation = diplomacy.relationBetween(
        proposal.fromPlayerId,
        proposal.toPlayerId,
      );
      final newStatus = switch (proposal.kind) {
        DiplomaticProposalKind.friendship => DiplomaticRelationStatus.friendly,
        DiplomaticProposalKind.truce => DiplomaticRelationStatus.truce,
      };
      final expiresOnTurn = proposal.kind == DiplomaticProposalKind.truce
          ? turn + DiplomacyState.defaultTruceDurationTurns
          : null;
      diplomacy = diplomacy
          .setStatus(
            proposal.fromPlayerId,
            proposal.toPlayerId,
            newStatus,
            turn: turn,
            reason: DiplomaticRelationChangeReason.proposalAccepted,
            statusExpiresOnTurn: expiresOnTurn,
          )
          .adjustRelationScore(
            proposal.fromPlayerId,
            proposal.toPlayerId,
            proposal.kind == DiplomaticProposalKind.friendship ? 18 : 10,
            turn: turn,
            reason: DiplomaticScoreChangeReason.proposalAccepted,
            sourceId: proposal.id,
          );
      intendedAttacks = _clearIntendedAttacksBetween(
        state.runtimeState.intendedAttacks,
        proposal.fromPlayerId,
        proposal.toPlayerId,
        state,
      );
      final relation = diplomacy.relationBetween(
        proposal.fromPlayerId,
        proposal.toPlayerId,
      );
      events.addAll([
        DiplomaticRelationChangedEvent(
          playerAId: relation.playerAId,
          playerBId: relation.playerBId,
          oldStatus: oldRelation.status,
          newStatus: relation.status,
          reason: DiplomaticRelationChangeReason.proposalAccepted,
          expiresOnTurn: relation.statusExpiresOnTurn,
        ),
        _scoreEvent(
          diplomacy,
          proposal.fromPlayerId,
          proposal.toPlayerId,
          sourceId: proposal.id,
          reason: DiplomaticScoreChangeReason.proposalAccepted,
        ),
      ]);
      nextState = _applyAcceptedPayment(state, proposal);
    } else {
      diplomacy = diplomacy.adjustRelationScore(
        proposal.fromPlayerId,
        proposal.toPlayerId,
        -6,
        turn: turn,
        reason: DiplomaticScoreChangeReason.proposalRejected,
        sourceId: proposal.id,
      );
      events.add(
        _scoreEvent(
          diplomacy,
          proposal.fromPlayerId,
          proposal.toPlayerId,
          sourceId: proposal.id,
          reason: DiplomaticScoreChangeReason.proposalRejected,
        ),
      );
    }

    return _accept(
      nextState.copyWith(
        runtimeState: nextState.runtimeState.copyWith(
          diplomacy: diplomacy,
          intendedAttacks: intendedAttacks,
        ),
      ),
      events: events,
    );
  }

  PersistentDiplomacyResult declareWar({
    required PersistentGameState state,
    required DeclareWarCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) {
    if (!_canIssue(state, command.playerId, actorPlayerId, canAct: canAct)) {
      return _reject(state, 'diplomacy_player_not_controlled');
    }
    if (!_canTarget(state, command.playerId, command.targetPlayerId)) {
      return _reject(state, 'diplomacy_target_not_discovered');
    }
    final currentDiplomacy = state.runtimeState.diplomacy;
    final relation = currentDiplomacy.relationBetween(
      command.playerId,
      command.targetPlayerId,
    );
    if (relation.status == DiplomaticRelationStatus.truce &&
        relation.statusExpiresOnTurn != null &&
        turn < relation.statusExpiresOnTurn!) {
      return _reject(state, 'diplomacy_truce_active');
    }
    if (relation.status == DiplomaticRelationStatus.war) {
      return _reject(state, 'diplomacy_war_already_active');
    }

    var diplomacy = currentDiplomacy.declareWar(
      playerId: command.playerId,
      targetPlayerId: command.targetPlayerId,
      turn: turn,
    );
    final reputation = DiplomaticWarmongerReputation.apply(
      diplomacy: diplomacy,
      aggressorPlayerId: command.playerId,
      victimPlayerId: command.targetPlayerId,
      action: DiplomaticWarmongerAction.declarationOfWar,
      turn: turn,
    );
    diplomacy = reputation.diplomacy;

    final nextRelation = diplomacy.relationBetween(
      command.playerId,
      command.targetPlayerId,
    );
    return _accept(
      state.copyWith(
        runtimeState: state.runtimeState.copyWith(
          diplomacy: diplomacy,
          resourceTradeAgreements: _removeResourceTradeAgreementsBetween(
            state.runtimeState.resourceTradeAgreements,
            command.playerId,
            command.targetPlayerId,
          ),
        ),
      ),
      events: [
        DiplomaticRelationChangedEvent(
          playerAId: nextRelation.playerAId,
          playerBId: nextRelation.playerBId,
          oldStatus: relation.status,
          newStatus: nextRelation.status,
          reason: DiplomaticRelationChangeReason.declarationOfWar,
        ),
        _scoreEvent(
          diplomacy,
          command.playerId,
          command.targetPlayerId,
          reason: DiplomaticScoreChangeReason.declarationOfWar,
        ),
        ..._warmongerScoreEvents(reputation.entries),
      ],
    );
  }

  PersistentDiplomacyResult sendGoldGift({
    required PersistentGameState state,
    required SendGoldGiftCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) {
    if (!_canIssue(state, command.playerId, actorPlayerId, canAct: canAct)) {
      return _reject(state, 'diplomacy_player_not_controlled');
    }
    if (!_canTarget(state, command.playerId, command.targetPlayerId)) {
      return _reject(state, 'diplomacy_target_not_discovered');
    }
    if (command.amount < 0) {
      return _reject(state, 'diplomacy_invalid_gold_amount');
    }
    final relation = state.runtimeState.diplomacy.relationBetween(
      command.playerId,
      command.targetPlayerId,
    );
    if (relation.status == DiplomaticRelationStatus.war ||
        relation.status == DiplomaticRelationStatus.truce) {
      return _reject(state, 'diplomacy_gold_gift_blocked_by_relation');
    }

    final availableGold = state.playerGold[command.playerId] ?? 0;
    final amount = GoldAmount(command.amount);
    if (!amount.canFundFrom(availableGold)) {
      return _reject(state, 'diplomacy_gold_unavailable');
    }
    final relationDelta = DiplomaticGoldGiftRules.relationDeltaFor(
      amount.value,
    );
    if (relationDelta <= 0 || _giftOnCooldown(state, command, turn)) {
      return _reject(state, 'diplomacy_gold_gift_unavailable');
    }

    final recipientGold = state.playerGold[command.targetPlayerId] ?? 0;
    final sourceId = _goldGiftSourceId(
      turn: turn,
      playerId: command.playerId,
      targetPlayerId: command.targetPlayerId,
    );
    final diplomacy = state.runtimeState.diplomacy.adjustRelationScore(
      command.playerId,
      command.targetPlayerId,
      relationDelta,
      turn: turn,
      reason: DiplomaticScoreChangeReason.goldGift,
      sourceId: sourceId,
    );

    return _accept(
      state.copyWith(
        playerGold: {
          ...state.playerGold,
          command.playerId: availableGold - amount.value,
          command.targetPlayerId: recipientGold + amount.value,
        },
        runtimeState: state.runtimeState.copyWith(diplomacy: diplomacy),
      ),
      events: [
        _scoreEvent(
          diplomacy,
          command.playerId,
          command.targetPlayerId,
          sourceId: sourceId,
          reason: DiplomaticScoreChangeReason.goldGift,
        ),
      ],
    );
  }

  PersistentDiplomacyResult sendMessage({
    required PersistentGameState state,
    required SendDiplomaticMessageCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) {
    if (!_canIssue(state, command.playerId, actorPlayerId, canAct: canAct)) {
      return _reject(state, 'diplomacy_player_not_controlled');
    }
    if (!_canTarget(state, command.playerId, command.targetPlayerId)) {
      return _reject(state, 'diplomacy_target_not_discovered');
    }
    if (_messageOnCooldown(state, command, turn)) {
      return _reject(state, 'diplomacy_message_cooldown');
    }
    final diplomacy = state.runtimeState.diplomacy;
    final message = DiplomaticMessage.create(
      id:
          command.messageId ??
          _messageId(
            turn: turn,
            fromPlayerId: command.playerId,
            toPlayerId: command.targetPlayerId,
            topic: command.topic,
            count: diplomacy.messages.length,
          ),
      fromPlayerId: command.playerId,
      toPlayerId: command.targetPlayerId,
      topic: command.topic,
      createdTurn: turn,
      expiresOnTurn: turn + DiplomacyState.defaultMessageDurationTurns,
    );
    final nextDiplomacy = diplomacy.addMessage(message);
    if (identical(nextDiplomacy, diplomacy)) {
      return _reject(state, 'diplomacy_message_not_added');
    }
    return _accept(
      _withDiplomacy(state, nextDiplomacy),
      events: [
        DiplomaticMessageSentEvent(
          messageId: message.id,
          fromPlayerId: message.fromPlayerId,
          toPlayerId: message.toPlayerId,
          topic: message.topic,
          category: message.category,
          expiresOnTurn: message.expiresOnTurn,
        ),
      ],
    );
  }

  PersistentDiplomacyResult respondMessage({
    required PersistentGameState state,
    required RespondDiplomaticMessageCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) {
    if (!_canIssue(state, command.playerId, actorPlayerId, canAct: canAct)) {
      return _reject(state, 'diplomacy_player_not_controlled');
    }
    final message = state.runtimeState.diplomacy.messages[command.messageId];
    if (message == null || message.toPlayerId != command.playerId) {
      return _reject(state, 'diplomacy_message_not_found');
    }
    if (message.responded || message.isExpired(turn)) {
      return _reject(state, 'diplomacy_message_unavailable');
    }

    final cooperationBonus =
        DiplomaticMessageEffects.commonEnemyCooperationBonus(
          state.runtimeState.diplomacy,
          message,
          command.response,
        );
    final delta = DiplomaticMessageEffects.relationDeltaForResponse(
      state.runtimeState.diplomacy,
      message,
      command.response,
    );
    final scoreReason = cooperationBonus == 0
        ? DiplomaticScoreChangeReason.messageResponse
        : DiplomaticScoreChangeReason.commonEnemyCooperation;
    var diplomacy = state.runtimeState.diplomacy.adjustRelationScore(
      message.fromPlayerId,
      message.toPlayerId,
      delta,
      turn: turn,
      reason: scoreReason,
      sourceId: message.id,
    );
    final scoreAfter = diplomacy.relationScoreBetween(
      message.fromPlayerId,
      message.toPlayerId,
    );
    final promiseDueTurn =
        command.response.isPromiseTone &&
            message.topic.canCreateWithdrawalPromise
        ? turn + DiplomacyState.defaultPromiseDurationTurns
        : null;
    final updatedMessage = message.copyWith(
      response: command.response,
      respondedTurn: turn,
      relationScoreDelta: delta,
      relationScoreAfter: scoreAfter,
      promiseDueTurn: promiseDueTurn,
    );
    diplomacy = diplomacy.updateMessage(updatedMessage);

    return _accept(
      _withDiplomacy(state, diplomacy),
      events: [
        DiplomaticMessageRespondedEvent(
          messageId: updatedMessage.id,
          fromPlayerId: updatedMessage.fromPlayerId,
          toPlayerId: updatedMessage.toPlayerId,
          topic: updatedMessage.topic,
          response: command.response,
          relationDelta: delta,
          relationScoreAfter: scoreAfter,
          promiseDueTurn: promiseDueTurn,
        ),
        DiplomaticScoreChangedEvent(
          playerAId: diplomacy
              .relationBetween(message.fromPlayerId, message.toPlayerId)
              .playerAId,
          playerBId: diplomacy
              .relationBetween(message.fromPlayerId, message.toPlayerId)
              .playerBId,
          delta: delta,
          scoreAfter: scoreAfter,
          reason: scoreReason,
          sourceId: message.id,
        ),
      ],
    );
  }

  static PersistentDiplomacyResult _accept(
    PersistentGameState state, {
    List<GameEvent> events = const [],
  }) {
    return PersistentDiplomacyResult(
      accepted: true,
      state: state,
      events: events,
    );
  }

  static PersistentDiplomacyResult _reject(
    PersistentGameState state,
    String reason,
  ) {
    return PersistentDiplomacyResult(
      accepted: false,
      state: state,
      reason: reason,
    );
  }

  static bool _canIssue(
    PersistentGameState state,
    String playerId,
    String actorPlayerId, {
    required bool canAct,
  }) {
    return DiplomaticActionGuard.canIssue(
      playerId: playerId,
      canAct: canAct,
      actorPlayerId: actorPlayerId,
    );
  }

  static bool _canTarget(
    PersistentGameState state,
    String playerId,
    String targetPlayerId,
  ) {
    return DiplomaticActionGuard.canTargetDiscovered(
      playerId: playerId,
      targetPlayerId: targetPlayerId,
      knownPlayerIds: _knownPlayerIds(state),
      diplomacy: state.runtimeState.diplomacy,
      fogOfWar: state.fogOfWar,
      units: state.units,
      cities: state.cities,
    );
  }

  static Set<String> _knownPlayerIds(PersistentGameState state) {
    return {
      ...state.playerColors.keys,
      ...state.playerCountries.keys,
      ...state.playerGold.keys,
      ...state.fogOfWar.playerIds,
      for (final unit in state.units) unit.ownerPlayerId,
      for (final city in state.cities) city.ownerPlayerId,
    }..removeWhere((playerId) => playerId.isEmpty);
  }

  static bool _proposalAllowed(
    DiplomaticProposalKind kind,
    DiplomaticRelationStatus status,
  ) {
    return switch (kind) {
      DiplomaticProposalKind.friendship =>
        status == DiplomaticRelationStatus.neutral ||
            status == DiplomaticRelationStatus.hostile ||
            status == DiplomaticRelationStatus.truce,
      DiplomaticProposalKind.truce =>
        status == DiplomaticRelationStatus.hostile ||
            status == DiplomaticRelationStatus.war,
    };
  }

  static int _goldPaymentForCommand(
    PersistentGameState state,
    SendDiplomaticProposalCommand command,
  ) {
    if (command.kind != DiplomaticProposalKind.truce) return 0;
    if (command.goldPayment <= 0) return GoldAmount.zero.value;
    final requested = GoldAmount(command.goldPayment);
    final availableGold = state.playerGold[command.playerId] ?? 0;
    return requested.value.clamp(0, availableGold).toInt();
  }

  static bool _canFundAccepted(
    PersistentGameState state,
    DiplomaticProposal proposal,
  ) {
    if (proposal.goldPayment <= 0) return true;
    final payment = GoldAmount(proposal.goldPayment);
    final payerGold = state.playerGold[proposal.fromPlayerId] ?? 0;
    return payment.canFundFrom(payerGold);
  }

  static PersistentGameState _applyAcceptedPayment(
    PersistentGameState state,
    DiplomaticProposal proposal,
  ) {
    if (proposal.goldPayment <= 0) return state;
    final payerGold = state.playerGold[proposal.fromPlayerId] ?? 0;
    final transfer = proposal.goldPayment.clamp(0, payerGold).toInt();
    if (transfer <= 0) return state;
    final recipientGold = state.playerGold[proposal.toPlayerId] ?? 0;
    return state.copyWith(
      playerGold: {
        ...state.playerGold,
        proposal.fromPlayerId: payerGold - transfer,
        proposal.toPlayerId: recipientGold + transfer,
      },
    );
  }

  static bool _giftOnCooldown(
    PersistentGameState state,
    SendGoldGiftCommand command,
    int turn,
  ) {
    return state.runtimeState.diplomacy
        .scoreEntriesBetween(command.playerId, command.targetPlayerId)
        .any(
          (entry) =>
              entry.reason == DiplomaticScoreChangeReason.goldGift &&
              turn >= entry.turn &&
              turn - entry.turn < DiplomaticGoldGiftRules.cooldownTurns,
        );
  }

  static bool _messageOnCooldown(
    PersistentGameState state,
    SendDiplomaticMessageCommand command,
    int turn,
  ) {
    return state.runtimeState.diplomacy
        .messagesBetween(command.playerId, command.targetPlayerId)
        .any(
          (message) =>
              message.fromPlayerId == command.playerId &&
              message.toPlayerId == command.targetPlayerId &&
              message.category == command.topic.category &&
              turn - message.createdTurn < 5,
        );
  }

  static PersistentGameState _withDiplomacy(
    PersistentGameState state,
    DiplomacyState diplomacy,
  ) {
    return state.copyWith(
      runtimeState: state.runtimeState.copyWith(diplomacy: diplomacy),
    );
  }

  static List<IntendedAttack> _clearIntendedAttacksBetween(
    List<IntendedAttack> attacks,
    String playerAId,
    String playerBId,
    PersistentGameState state,
  ) {
    return [
      for (final attack in attacks)
        if (!_attackBetween(attack, playerAId, playerBId, state)) attack,
    ];
  }

  static bool _attackBetween(
    IntendedAttack attack,
    String playerAId,
    String playerBId,
    PersistentGameState state,
  ) {
    final attacker = state.units.byId(attack.attackerUnitId);
    if (attacker == null) return false;
    final defenderOwner =
        state.units
            .unitAt(attack.defenderCol, attack.defenderRow)
            ?.ownerPlayerId ??
        state.cities
            .where(
              (city) =>
                  city.occupiesCenter(attack.defenderCol, attack.defenderRow),
            )
            .firstOrNull
            ?.ownerPlayerId;
    if (defenderOwner == null) return false;
    final key = DiplomacyState.relationKey(playerAId, playerBId);
    return DiplomacyState.relationKey(attacker.ownerPlayerId, defenderOwner) ==
        key;
  }

  static List<ResourceTradeAgreement> _removeResourceTradeAgreementsBetween(
    Iterable<ResourceTradeAgreement> agreements,
    String playerAId,
    String playerBId,
  ) {
    final key = DiplomacyState.relationKey(playerAId, playerBId);
    return [
      for (final agreement in agreements)
        if (DiplomacyState.relationKey(
              agreement.exporterPlayerId,
              agreement.importerPlayerId,
            ) !=
            key)
          agreement,
    ];
  }

  static DiplomaticScoreChangedEvent _scoreEvent(
    DiplomacyState diplomacy,
    String playerAId,
    String playerBId, {
    required DiplomaticScoreChangeReason reason,
    String? sourceId,
  }) {
    final relation = diplomacy.relationBetween(playerAId, playerBId);
    final history = diplomacy.scoreEntriesBetween(playerAId, playerBId);
    final latest = history.isEmpty ? null : history.last;
    return DiplomaticScoreChangedEvent(
      playerAId: relation.playerAId,
      playerBId: relation.playerBId,
      delta: latest?.delta ?? 0,
      scoreAfter: relation.relationScore,
      reason: reason,
      sourceId: sourceId,
    );
  }

  static List<DiplomaticScoreChangedEvent> _warmongerScoreEvents(
    Iterable<DiplomaticScoreEntry> entries,
  ) {
    return [
      for (final entry in entries)
        DiplomaticScoreChangedEvent(
          playerAId: entry.playerAId,
          playerBId: entry.playerBId,
          delta: entry.delta,
          scoreAfter: entry.scoreAfter,
          reason: entry.reason,
          sourceId: entry.sourceId,
        ),
    ];
  }

  static String _proposalId({
    required int turn,
    required String fromPlayerId,
    required String toPlayerId,
    required DiplomaticProposalKind kind,
    required int count,
  }) {
    return 'proposal.$turn.$fromPlayerId.$toPlayerId.${kind.name}.$count';
  }

  static String _messageId({
    required int turn,
    required String fromPlayerId,
    required String toPlayerId,
    required DiplomaticMessageTopic topic,
    required int count,
  }) {
    return 'message.$turn.$fromPlayerId.$toPlayerId.${topic.name}.$count';
  }

  static String _goldGiftSourceId({
    required int turn,
    required String playerId,
    required String targetPlayerId,
  }) {
    return 'gold_gift.$turn.$playerId.$targetPlayerId';
  }
}
