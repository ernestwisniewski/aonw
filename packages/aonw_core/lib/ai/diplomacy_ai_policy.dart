import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/hex.dart';

class DiplomacyAiPolicy {
  static const int cooldownTurns = 8;

  const DiplomacyAiPolicy();

  List<GameCommand> commandsFor(GameView view, AiContext context) {
    final commands = <GameCommand>[
      ..._proposalResponses(view, context),
      ..._messageResponses(view, context),
    ];
    final initiative = _initiativeCommand(view, context);
    if (initiative != null) commands.add(initiative);
    return commands;
  }

  Iterable<GameCommand> _proposalResponses(
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
    final underPressure =
        view.pendingCityAttackThreats.any(
          (threat) => threat.attackerPlayerId == proposal.fromPlayerId,
        ) ||
        view.visibleEnemyUnits
                .where((unit) => unit.ownerPlayerId == proposal.fromPlayerId)
                .length >
            view.ownUnits.length;

    return DiplomaticProposalForecast.evaluate(
      kind: proposal.kind,
      relation: relation,
      recentHostility: view.recentHostilePlayerIds.contains(
        proposal.fromPlayerId,
      ),
      underPressure: underPressure,
      goldPayment: proposal.goldPayment,
    ).accepted;
  }

  Iterable<GameCommand> _messageResponses(
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

  GameCommand? _initiativeCommand(GameView view, AiContext context) {
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

  GameCommand? _messageInitiative(GameView view, AiContext context) {
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

  GameCommand? _cityThreatWarning(GameView view, AiContext context) {
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

  GameCommand? _closeCityComplaint(GameView view, AiContext context) {
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

  GameCommand? _commonEnemyMessage(GameView view, AiContext context) {
    for (final relation in view.diplomacy.relations.values) {
      if (!relation.involves(view.forPlayerId) ||
          relation.status != DiplomaticRelationStatus.war) {
        continue;
      }
      final enemy = relation.playerAId == view.forPlayerId
          ? relation.playerBId
          : relation.playerAId;
      for (final allyRelation in view.diplomacy.relations.values) {
        if (!allyRelation.involves(enemy) ||
            allyRelation.status != DiplomaticRelationStatus.war) {
          continue;
        }
        final target = allyRelation.playerAId == enemy
            ? allyRelation.playerBId
            : allyRelation.playerAId;
        if (target == view.forPlayerId) continue;
        if (_canSendMessage(
          view,
          target,
          DiplomaticMessageTopic.commonEnemy,
          context.turn,
        )) {
          return SendDiplomaticMessageCommand(
            playerId: view.forPlayerId,
            targetPlayerId: target,
            topic: DiplomaticMessageTopic.commonEnemy,
          );
        }
      }
    }
    return null;
  }

  GameCommand? _deescalationMessage(GameView view, AiContext context) {
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

  GameCommand? _peacefulPraise(GameView view, AiContext context) {
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

  GameCommand? _truceProposal(GameView view, AiContext context) {
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
      final underPressure =
          view.pendingCityAttackThreats.any(
            (threat) => threat.attackerPlayerId == target,
          ) ||
          relation.relationScore <= -55;
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

  GameCommand? _warDeclaration(GameView view, AiContext context) {
    final plan = context.strategicPlan;
    if (plan == null || plan.warGoals.isEmpty) return null;
    for (final goal in plan.warGoals) {
      final target = goal.targetPlayerId;
      if (!view.hasDiplomaticContactWith(target)) continue;
      final relation = view.diplomacy.relationBetween(view.forPlayerId, target);
      if (relation.status == DiplomaticRelationStatus.war ||
          relation.status == DiplomaticRelationStatus.friendly ||
          relation.status == DiplomaticRelationStatus.truce ||
          _recentlyTouched(relation, context.turn)) {
        continue;
      }
      if (relation.relationScore > -35 &&
          context.effectiveWeights.aggression < 1.2) {
        continue;
      }
      return DeclareWarCommand(
        playerId: view.forPlayerId,
        targetPlayerId: target,
      );
    }
    return null;
  }

  GameCommand? _friendshipProposal(GameView view, AiContext context) {
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
    return changed != null && turn - changed < cooldownTurns;
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
              turn - entry.turn < cooldownTurns,
        );
  }

  int _truceGoldPayment(GameView view, DiplomaticRelation relation) {
    if (relation.relationScore > -55) return 0;
    return view.ownGold >= DiplomaticProposalForecast.minimumTruceGoldPayment
        ? DiplomaticProposalForecast.minimumTruceGoldPayment
        : 0;
  }
}

extension _DiplomaticRelationAi on DiplomaticRelation {
  bool involves(String playerId) =>
      playerAId == playerId || playerBId == playerId;
}
