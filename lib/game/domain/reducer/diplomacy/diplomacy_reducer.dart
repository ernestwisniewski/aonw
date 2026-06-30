import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/diplomacy/diplomatic_war_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_player_ids.dart';
import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';

abstract final class DiplomacyReducer {
  static GameStateTransition sendProposal(
    GameState state,
    SendDiplomaticProposalCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    if (!_canIssue(state, command.playerId, context)) {
      return GameStateTransition(state: state);
    }
    if (!_canTargetDiscoveredPlayer(
      state,
      command.playerId,
      command.targetPlayerId,
    )) {
      return GameStateTransition(state: state);
    }

    final relation = state.diplomacy.relationBetween(
      command.playerId,
      command.targetPlayerId,
    );
    if (!_proposalAllowed(command.kind, relation.status)) {
      return GameStateTransition(state: state);
    }

    final turn = context.combatSeedTurn;
    final proposal = DiplomaticProposal(
      id:
          command.proposalId ??
          _proposalId(
            turn: turn,
            fromPlayerId: command.playerId,
            toPlayerId: command.targetPlayerId,
            kind: command.kind,
            count: state.diplomacy.pendingProposals.length,
          ),
      fromPlayerId: command.playerId,
      toPlayerId: command.targetPlayerId,
      kind: command.kind,
      createdTurn: turn,
      expiresOnTurn: turn + DiplomacyState.defaultProposalDurationTurns,
      goldPayment: _proposalGoldPayment(state, command),
    );
    final diplomacy = state.diplomacy.addProposal(proposal);
    if (identical(diplomacy, state.diplomacy)) {
      return GameStateTransition(state: state);
    }
    return GameStateTransition(
      state: state.copyWith(diplomacy: diplomacy),
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

  static GameStateTransition respondProposal(
    GameState state,
    RespondDiplomaticProposalCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    if (!_canIssue(state, command.playerId, context)) {
      return GameStateTransition(state: state);
    }
    final proposal = state.diplomacy.pendingProposals[command.proposalId];
    if (proposal == null || proposal.toPlayerId != command.playerId) {
      return GameStateTransition(state: state);
    }

    final turn = context.combatSeedTurn;
    var diplomacy = state.diplomacy.removeProposal(proposal.id);
    final events = <GameEvent>[
      DiplomaticProposalRespondedEvent(
        proposalId: proposal.id,
        fromPlayerId: proposal.fromPlayerId,
        toPlayerId: proposal.toPlayerId,
        kind: proposal.kind,
        accepted: command.accepted,
      ),
    ];

    var intendedAttacks = state.intendedAttacks;
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
        state.intendedAttacks,
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
      state = _applyGoldPayment(state, proposal);
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

    return GameStateTransition(
      state: state.copyWith(
        diplomacy: diplomacy,
        intendedAttacks: intendedAttacks,
      ),
      events: events,
    );
  }

  static int _proposalGoldPayment(
    GameState state,
    SendDiplomaticProposalCommand command,
  ) {
    if (command.kind != DiplomaticProposalKind.truce) return 0;
    final availableGold = state.playerGold[command.playerId] ?? 0;
    return command.goldPayment.clamp(0, availableGold).toInt();
  }

  static GameState _applyGoldPayment(
    GameState state,
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

  static GameStateTransition declareWar(
    GameState state,
    DeclareWarCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return DiplomaticWarReducer.declareWar(state, command, context: context);
  }

  static GameStateTransition sendMessage(
    GameState state,
    SendDiplomaticMessageCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    if (!_canIssue(state, command.playerId, context)) {
      return GameStateTransition(state: state);
    }
    if (!_canTargetDiscoveredPlayer(
      state,
      command.playerId,
      command.targetPlayerId,
    )) {
      return GameStateTransition(state: state);
    }
    if (_messageOnCooldown(state, command, context.combatSeedTurn)) {
      return GameStateTransition(state: state);
    }
    final turn = context.combatSeedTurn;
    final message = DiplomaticMessage.create(
      id:
          command.messageId ??
          _messageId(
            turn: turn,
            fromPlayerId: command.playerId,
            toPlayerId: command.targetPlayerId,
            topic: command.topic,
            count: state.diplomacy.messages.length,
          ),
      fromPlayerId: command.playerId,
      toPlayerId: command.targetPlayerId,
      topic: command.topic,
      createdTurn: turn,
      expiresOnTurn: turn + DiplomacyState.defaultMessageDurationTurns,
    );
    final diplomacy = state.diplomacy.addMessage(message);
    if (identical(diplomacy, state.diplomacy)) {
      return GameStateTransition(state: state);
    }
    return GameStateTransition(
      state: state.copyWith(diplomacy: diplomacy),
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

  static GameStateTransition respondMessage(
    GameState state,
    RespondDiplomaticMessageCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    if (!_canIssue(state, command.playerId, context)) {
      return GameStateTransition(state: state);
    }
    final message = state.diplomacy.messages[command.messageId];
    if (message == null || message.toPlayerId != command.playerId) {
      return GameStateTransition(state: state);
    }
    if (message.responded || message.isExpired(context.combatSeedTurn)) {
      return GameStateTransition(state: state);
    }

    final cooperationBonus =
        DiplomaticMessageEffects.commonEnemyCooperationBonus(
          state.diplomacy,
          message,
          command.response,
        );
    final delta = DiplomaticMessageEffects.relationDeltaForResponse(
      state.diplomacy,
      message,
      command.response,
    );
    final scoreReason = cooperationBonus == 0
        ? DiplomaticScoreChangeReason.messageResponse
        : DiplomaticScoreChangeReason.commonEnemyCooperation;
    var diplomacy = state.diplomacy.adjustRelationScore(
      message.fromPlayerId,
      message.toPlayerId,
      delta,
      turn: context.combatSeedTurn,
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
        ? context.combatSeedTurn + DiplomacyState.defaultPromiseDurationTurns
        : null;
    final updatedMessage = message.copyWith(
      response: command.response,
      respondedTurn: context.combatSeedTurn,
      relationScoreDelta: delta,
      relationScoreAfter: scoreAfter,
      promiseDueTurn: promiseDueTurn,
    );
    diplomacy = diplomacy.updateMessage(updatedMessage);

    return GameStateTransition(
      state: state.copyWith(diplomacy: diplomacy),
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

  static bool _canIssue(
    GameState state,
    String playerId,
    GameCommandContext context,
  ) {
    if (playerId.isEmpty || !context.canAct) return false;
    if (context.hasActor) return context.actorPlayerId == playerId;
    return state.activePlayerId.isEmpty || state.activePlayerId == playerId;
  }

  static bool _canTargetDiscoveredPlayer(
    GameState state,
    String playerId,
    String targetPlayerId,
  ) {
    if (playerId.isEmpty ||
        targetPlayerId.isEmpty ||
        playerId == targetPlayerId) {
      return false;
    }
    if (!knownPlayerIds(state).contains(targetPlayerId)) return false;
    if (state.diplomacy.hasContact(playerId, targetPlayerId)) return true;
    return DiplomaticContact.hasContact(
      playerId: playerId,
      targetPlayerId: targetPlayerId,
      fogOfWar: state.fogOfWar,
      units: state.units,
      cities: state.cities,
    );
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

  static bool _messageOnCooldown(
    GameState state,
    SendDiplomaticMessageCommand command,
    int turn,
  ) {
    return state.diplomacy
        .messagesBetween(command.playerId, command.targetPlayerId)
        .any(
          (message) =>
              message.fromPlayerId == command.playerId &&
              message.toPlayerId == command.targetPlayerId &&
              message.category == command.topic.category &&
              turn - message.createdTurn < 5,
        );
  }

  static List<IntendedAttack> _clearIntendedAttacksBetween(
    List<IntendedAttack> attacks,
    String playerAId,
    String playerBId,
    GameState state,
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
    GameState state,
  ) {
    final attacker = state.unitById(attack.attackerUnitId);
    if (attacker == null) return false;
    final defenderOwner =
        state.unitAt(attack.defenderCol, attack.defenderRow)?.ownerPlayerId ??
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
}
