part of 'diplomacy_ai_policy.dart';

extension _DiplomacyAiResponses on DiplomacyAiPolicy {
  Iterable<DomainCommand> _proposalResponses(
    GameView view,
    AiContext context,
  ) sync* {
    for (final proposal in view.diplomacy.proposalsFor(view.forPlayerId)) {
      if (proposal.toPlayerId != view.forPlayerId) continue;
      final accepted = _acceptProposal(view, context, proposal);
      yield RespondDiplomaticProposalCommand(
        playerId: view.forPlayerId,
        proposalId: proposal.id,
        accepted: accepted,
      );
    }
  }

  bool _acceptProposal(
    GameView view,
    AiContext context,
    DiplomaticProposal proposal,
  ) {
    final relation = view.diplomacy.relationBetween(
      view.forPlayerId,
      proposal.fromPlayerId,
    );
    final underPressure = ProposalAcceptancePolicy.isUnderPressure(
      hasPendingCityAttackThreat: view.pendingCityAttackThreats.any(
        (threat) => threat.attackerPlayerId == proposal.fromPlayerId,
      ),
      visibleOpponentUnitCount: view.visibleEnemyUnits
          .where((unit) => unit.ownerPlayerId == proposal.fromPlayerId)
          .length,
      ownUnitCount: view.ownUnits.length,
    );

    return ProposalAcceptancePolicy.evaluate(
      kind: proposal.kind,
      relation: relation,
      recentHostility: view.recentHostilePlayerIds.contains(
        proposal.fromPlayerId,
      ),
      underPressure: underPressure,
      goldPayment: proposal.goldPayment,
    ).accepted;
  }

  Iterable<DomainCommand> _messageResponses(
    GameView view,
    AiContext context,
  ) sync* {
    for (final message in view.diplomacy.messagesFor(view.forPlayerId)) {
      if (message.toPlayerId != view.forPlayerId || message.responded) {
        continue;
      }
      yield RespondDiplomaticMessageCommand(
        playerId: view.forPlayerId,
        messageId: message.id,
        response: _messageResponse(view, context, message),
      );
    }
  }

  DiplomaticMessageResponse _messageResponse(
    GameView view,
    AiContext context,
    DiplomaticMessage message,
  ) {
    final score = view.diplomacy.relationScoreBetween(
      view.forPlayerId,
      message.fromPlayerId,
    );
    final rivalMilitary = view.visibleEnemyUnits
        .where((unit) => unit.ownerPlayerId == message.fromPlayerId)
        .length;
    final weaker = view.ownUnits.length < rivalMilitary;
    if (message.topic == DiplomaticMessageTopic.commonEnemy &&
        DiplomaticSharedWar.hasSharedWarEnemy(
          view.diplomacy,
          view.forPlayerId,
          message.fromPlayerId,
        )) {
      return score >= -45
          ? DiplomaticMessageResponse.conciliatory
          : DiplomaticMessageResponse.neutral;
    }
    if (message.topic == DiplomaticMessageTopic.peacefulPraise) {
      return score >= -25
          ? DiplomaticMessageResponse.conciliatory
          : DiplomaticMessageResponse.neutral;
    }
    if (weaker || score >= 20) return DiplomaticMessageResponse.conciliatory;
    if (score >= -10) return DiplomaticMessageResponse.neutral;
    if (context.effectiveWeights.aggression >= 1.25) {
      return DiplomaticMessageResponse.aggressive;
    }
    return DiplomaticMessageResponse.evasive;
  }
}
