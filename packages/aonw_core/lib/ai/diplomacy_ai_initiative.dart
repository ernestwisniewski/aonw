part of 'diplomacy_ai_policy.dart';

extension _DiplomacyAiInitiative on DiplomacyAiPolicy {
  DomainCommand? _initiativeCommand(GameView view, AiContext context) {
    final truce = _truceProposal(view, context);
    if (truce != null) return truce;

    final war = _warDeclaration(view, context);
    if (war != null) return war;

    final message = _messageInitiative(view, context);
    if (message != null) return message;

    final friendship = _friendshipProposal(view, context);
    if (friendship != null) return friendship;

    return null;
  }

  DomainCommand? _messageInitiative(GameView view, AiContext context) {
    final threat = _cityThreatWarning(view, context);
    if (threat != null) return threat;

    final complaint = _closeCityComplaint(view, context);
    if (complaint != null) return complaint;

    final commonEnemy = _commonEnemyMessage(view, context);
    if (commonEnemy != null) return commonEnemy;

    final deescalation = _deescalationMessage(view, context);
    if (deescalation != null) return deescalation;

    return _peacefulPraise(view, context);
  }

  DomainCommand? _cityThreatWarning(GameView view, AiContext context) {
    for (final threat in view.pendingCityAttackThreats) {
      final target = threat.attackerPlayerId;
      if (_canSendMessage(
        view,
        target,
        DiplomaticMessageTopic.troopsNearCities,
        context.turn,
      )) {
        return SendDiplomaticMessageCommand(
          playerId: view.forPlayerId,
          targetPlayerId: target,
          topic: DiplomaticMessageTopic.troopsNearCities,
        );
      }
    }
    return null;
  }

  DomainCommand? _closeCityComplaint(GameView view, AiContext context) {
    const closeCityDistance = 4;
    for (final city in view.rememberedEnemyCities) {
      if (view.ownCities.every(
        (ownCity) =>
            HexDistance.between(
              HexCoordinate(col: ownCity.center.col, row: ownCity.center.row),
              HexCoordinate(col: city.center.col, row: city.center.row),
            ) >
            closeCityDistance,
      )) {
        continue;
      }
      if (!_canSendMessage(
        view,
        city.ownerPlayerId,
        DiplomaticMessageTopic.citiesTooClose,
        context.turn,
      )) {
        continue;
      }
      final score = view.diplomacy.relationScoreBetween(
        view.forPlayerId,
        city.ownerPlayerId,
      );
      if (score > 20) continue;
      return SendDiplomaticMessageCommand(
        playerId: view.forPlayerId,
        targetPlayerId: city.ownerPlayerId,
        topic: DiplomaticMessageTopic.citiesTooClose,
      );
    }
    return null;
  }

  DomainCommand? _deescalationMessage(GameView view, AiContext context) {
    for (final relation in view.diplomacy.relations.values) {
      if (!relation.involves(view.forPlayerId) ||
          relation.status == DiplomaticRelationStatus.war ||
          relation.status == DiplomaticRelationStatus.friendly ||
          relation.status == DiplomaticRelationStatus.truce ||
          relation.relationScore > -25) {
        continue;
      }
      final target = relation.playerAId == view.forPlayerId
          ? relation.playerBId
          : relation.playerAId;
      if (_canSendMessage(
        view,
        target,
        DiplomaticMessageTopic.avoidEscalation,
        context.turn,
      )) {
        return SendDiplomaticMessageCommand(
          playerId: view.forPlayerId,
          targetPlayerId: target,
          topic: DiplomaticMessageTopic.avoidEscalation,
        );
      }
    }
    return null;
  }

  DomainCommand? _peacefulPraise(GameView view, AiContext context) {
    for (final relation in view.diplomacy.relations.values) {
      if (!relation.involves(view.forPlayerId) ||
          relation.status == DiplomaticRelationStatus.war ||
          relation.status == DiplomaticRelationStatus.hostile ||
          relation.relationScore < 35) {
        continue;
      }
      final target = relation.playerAId == view.forPlayerId
          ? relation.playerBId
          : relation.playerAId;
      if (_canSendMessage(
        view,
        target,
        DiplomaticMessageTopic.peacefulPraise,
        context.turn,
      )) {
        return SendDiplomaticMessageCommand(
          playerId: view.forPlayerId,
          targetPlayerId: target,
          topic: DiplomaticMessageTopic.peacefulPraise,
        );
      }
    }
    return null;
  }

  DomainCommand? _truceProposal(GameView view, AiContext context) {
    for (final relation in view.diplomacy.relations.values) {
      if (!relation.involves(view.forPlayerId) ||
          relation.status != DiplomaticRelationStatus.war ||
          _recentlyTouched(relation, context.turn)) {
        continue;
      }
      final target = relation.playerAId == view.forPlayerId
          ? relation.playerBId
          : relation.playerAId;
      if (!view.hasDiplomaticContactWith(target)) continue;
      if (_recentlyRejectedProposal(view, target, context.turn)) continue;
      final underPressure = ProposalAcceptancePolicy.isUnderPressure(
        hasPendingCityAttackThreat: view.pendingCityAttackThreats.any(
          (threat) => threat.attackerPlayerId == target,
        ),
        visibleOpponentUnitCount: 0,
        ownUnitCount: 0,
        severeHostility: relation.relationScore <= -55,
      );
      if (!underPressure || _hasPendingProposal(view, target)) continue;
      return SendDiplomaticProposalCommand(
        playerId: view.forPlayerId,
        targetPlayerId: target,
        kind: DiplomaticProposalKind.truce,
        goldPayment: _truceGoldPayment(view, relation),
      );
    }
    return null;
  }

  DomainCommand? _friendshipProposal(GameView view, AiContext context) {
    for (final relation in view.diplomacy.relations.values) {
      if (!relation.involves(view.forPlayerId) ||
          relation.status != DiplomaticRelationStatus.neutral ||
          relation.relationScore < 45 ||
          _recentlyTouched(relation, context.turn)) {
        continue;
      }
      final target = relation.playerAId == view.forPlayerId
          ? relation.playerBId
          : relation.playerAId;
      if (!view.hasDiplomaticContactWith(target)) continue;
      if (_hasPendingProposal(view, target)) continue;
      return SendDiplomaticProposalCommand(
        playerId: view.forPlayerId,
        targetPlayerId: target,
        kind: DiplomaticProposalKind.friendship,
      );
    }
    return null;
  }

  bool _hasPendingProposal(GameView view, String targetPlayerId) {
    return view.diplomacy
        .proposalsFor(view.forPlayerId)
        .any(
          (proposal) =>
              proposal.fromPlayerId == view.forPlayerId &&
              proposal.toPlayerId == targetPlayerId,
        );
  }

  bool _canSendMessage(
    GameView view,
    String targetPlayerId,
    DiplomaticMessageTopic topic,
    int turn,
  ) {
    if (!view.hasDiplomaticContactWith(targetPlayerId)) return false;
    final status = view.diplomacy.statusBetween(
      view.forPlayerId,
      targetPlayerId,
    );
    if (status == DiplomaticRelationStatus.war) return false;
    return !view.diplomacy
        .messagesBetween(view.forPlayerId, targetPlayerId)
        .any(
          (message) =>
              message.fromPlayerId == view.forPlayerId &&
              message.toPlayerId == targetPlayerId &&
              message.category == topic.category &&
              turn - message.createdTurn < 5,
        );
  }

  bool _recentlyTouched(DiplomaticRelation relation, int turn) {
    final changed = relation.lastChangedTurn;
    return changed != null && turn - changed < DiplomacyAiPolicy.cooldownTurns;
  }

  bool _recentlyRejectedProposal(
    GameView view,
    String targetPlayerId,
    int turn,
  ) {
    return view.diplomacy
        .scoreEntriesBetween(view.forPlayerId, targetPlayerId)
        .any(
          (entry) =>
              entry.reason == DiplomaticScoreChangeReason.proposalRejected &&
              turn >= entry.turn &&
              turn - entry.turn < DiplomacyAiPolicy.cooldownTurns,
        );
  }

  int _truceGoldPayment(GameView view, DiplomaticRelation relation) {
    if (relation.relationScore > -55) return 0;
    return view.ownGold >= ProposalAcceptancePolicy.minimumTruceGoldPayment
        ? ProposalAcceptancePolicy.minimumTruceGoldPayment
        : 0;
  }
}
