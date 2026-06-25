import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';

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
    final score = relation.relationScore;
    final underPressure =
        view.pendingCityAttackThreats.any(
          (threat) => threat.attackerPlayerId == proposal.fromPlayerId,
        ) ||
        view.visibleEnemyUnits
                .where((unit) => unit.ownerPlayerId == proposal.fromPlayerId)
                .length >
            view.ownUnits.length;

    return switch (proposal.kind) {
      DiplomaticProposalKind.friendship =>
        relation.status != DiplomaticRelationStatus.war &&
            score >= -15 &&
            !view.recentHostilePlayerIds.contains(proposal.fromPlayerId),
      DiplomaticProposalKind.truce =>
        relation.status == DiplomaticRelationStatus.war ||
            underPressure ||
            score >= -35,
    };
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

    final friendship = _friendshipProposal(view, context);
    if (friendship != null) return friendship;

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

  bool _recentlyTouched(DiplomaticRelation relation, int turn) {
    final changed = relation.lastChangedTurn;
    return changed != null && turn - changed < cooldownTurns;
  }
}

extension _DiplomaticRelationAi on DiplomaticRelation {
  bool involves(String playerId) =>
      playerAId == playerId || playerBId == playerId;
}
