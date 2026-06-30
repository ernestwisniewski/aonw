import 'package:aonw/game/presentation/formatters/diplomacy_display_names.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';

class DiplomacyHistoryText {
  const DiplomacyHistoryText({
    required this.title,
    required this.subtitle,
    this.detail,
    this.delta,
  });

  final String title;
  final String subtitle;
  final String? detail;
  final int? delta;
}

abstract final class DiplomacyHistoryPresenter {
  static DiplomacyHistoryText scoreEntry(
    AppLocalizations l10n,
    DiplomaticScoreEntry entry, {
    String Function(String playerId)? playerNameFor,
  }) {
    final score = _scoreSubtitle(l10n, entry.scoreAfter, entry.turn);
    final subtitle = playerNameFor == null
        ? score
        : _joinParts([
            relationPairLabel(playerNameFor, entry.playerAId, entry.playerBId),
            score,
          ]);
    return DiplomacyHistoryText(
      title: scoreReasonLabel(l10n, entry.reason),
      subtitle: subtitle,
      delta: entry.delta,
    );
  }

  static DiplomacyHistoryText message(
    AppLocalizations l10n,
    DiplomaticMessage message, {
    required String Function(String playerId) playerNameFor,
  }) {
    return messageText(
      l10n,
      fromPlayerId: message.fromPlayerId,
      toPlayerId: message.toPlayerId,
      topic: message.topic,
      createdTurn: message.createdTurn,
      expiresOnTurn: message.expiresOnTurn,
      respondedTurn: message.respondedTurn,
      response: message.response,
      relationScoreDelta: message.relationScoreDelta,
      playerNameFor: playerNameFor,
    );
  }

  static DiplomacyHistoryText messageText(
    AppLocalizations l10n, {
    required String fromPlayerId,
    required String toPlayerId,
    required DiplomaticMessageTopic topic,
    required int? createdTurn,
    int? expiresOnTurn,
    int? respondedTurn,
    DiplomaticMessageResponse? response,
    int? relationScoreDelta,
    required String Function(String playerId) playerNameFor,
  }) {
    final delta = response == null ? null : relationScoreDelta;
    final detail = response == null
        ? null
        : messageResponseDetail(l10n, response, relationScoreDelta ?? 0);
    return DiplomacyHistoryText(
      title:
          '${l10n.diplomacyMessagesTitle}: ${messageTopicLabel(l10n, topic)}',
      subtitle: _joinParts([
        directionLabel(playerNameFor, fromPlayerId, toPlayerId),
        turnRangeLabel(l10n, createdTurn, respondedTurn ?? expiresOnTurn),
      ]),
      detail: detail,
      delta: delta,
    );
  }

  static DiplomacyHistoryText proposal(
    AppLocalizations l10n,
    DiplomaticProposal proposal, {
    required String Function(String playerId) playerNameFor,
  }) {
    return proposalText(
      l10n,
      fromPlayerId: proposal.fromPlayerId,
      toPlayerId: proposal.toPlayerId,
      kind: proposal.kind,
      createdTurn: proposal.createdTurn,
      expiresOnTurn: proposal.expiresOnTurn,
      playerNameFor: playerNameFor,
    );
  }

  static DiplomacyHistoryText proposalText(
    AppLocalizations l10n, {
    required String fromPlayerId,
    required String toPlayerId,
    required DiplomaticProposalKind kind,
    required int? createdTurn,
    int? expiresOnTurn,
    String? status,
    required String Function(String playerId) playerNameFor,
  }) {
    return DiplomacyHistoryText(
      title:
          '${l10n.diplomacyProposalsTitle}: ${proposalKindLabel(l10n, kind)}',
      subtitle: _joinParts([
        directionLabel(playerNameFor, fromPlayerId, toPlayerId),
        status,
        turnRangeLabel(l10n, createdTurn, expiresOnTurn),
      ]),
    );
  }

  static DiplomacyHistoryText event(
    AppLocalizations l10n,
    GameEvent event, {
    required int? turn,
    required String Function(String playerId) playerNameFor,
  }) {
    return switch (event) {
      DiplomaticProposalSentEvent(
        :final fromPlayerId,
        :final toPlayerId,
        :final kind,
        :final expiresOnTurn,
      ) =>
        proposalText(
          l10n,
          fromPlayerId: fromPlayerId,
          toPlayerId: toPlayerId,
          kind: kind,
          createdTurn: turn,
          expiresOnTurn: expiresOnTurn,
          playerNameFor: playerNameFor,
        ),
      DiplomaticProposalRespondedEvent(
        :final fromPlayerId,
        :final toPlayerId,
        :final kind,
        :final accepted,
      ) =>
        proposalText(
          l10n,
          fromPlayerId: fromPlayerId,
          toPlayerId: toPlayerId,
          kind: kind,
          createdTurn: turn,
          status: accepted
              ? l10n.eventDiplomaticProposalAcceptedStatus
              : l10n.eventDiplomaticProposalRejectedStatus,
          playerNameFor: playerNameFor,
        ),
      DiplomaticProposalExpiredEvent(
        :final fromPlayerId,
        :final toPlayerId,
        :final kind,
      ) =>
        proposalText(
          l10n,
          fromPlayerId: fromPlayerId,
          toPlayerId: toPlayerId,
          kind: kind,
          createdTurn: turn,
          status: l10n.eventDiplomaticProposalExpiredStatus,
          playerNameFor: playerNameFor,
        ),
      DiplomaticRelationChangedEvent(
        :final playerAId,
        :final playerBId,
        :final oldStatus,
        :final newStatus,
        :final expiresOnTurn,
      ) =>
        DiplomacyHistoryText(
          title:
              '${l10n.diplomacyScoreLabel}: ${relationStatusLabel(l10n, newStatus)}',
          subtitle: _joinParts([
            relationPairLabel(playerNameFor, playerAId, playerBId),
            '${relationStatusLabel(l10n, oldStatus)} -> ${relationStatusLabel(l10n, newStatus)}',
            turnRangeLabel(l10n, turn, expiresOnTurn),
          ]),
        ),
      DiplomaticMessageSentEvent(
        :final fromPlayerId,
        :final toPlayerId,
        :final topic,
        :final expiresOnTurn,
      ) =>
        messageText(
          l10n,
          fromPlayerId: fromPlayerId,
          toPlayerId: toPlayerId,
          topic: topic,
          createdTurn: turn,
          expiresOnTurn: expiresOnTurn,
          playerNameFor: playerNameFor,
        ),
      DiplomaticMessageRespondedEvent(
        :final fromPlayerId,
        :final toPlayerId,
        :final topic,
        :final response,
        :final relationDelta,
      ) =>
        messageText(
          l10n,
          fromPlayerId: fromPlayerId,
          toPlayerId: toPlayerId,
          topic: topic,
          createdTurn: turn,
          response: response,
          relationScoreDelta: relationDelta,
          playerNameFor: playerNameFor,
        ),
      DiplomaticScoreChangedEvent(
        :final playerAId,
        :final playerBId,
        :final delta,
        :final scoreAfter,
        :final reason,
      ) =>
        DiplomacyHistoryText(
          title: scoreReasonLabel(l10n, reason),
          subtitle: _joinParts([
            relationPairLabel(playerNameFor, playerAId, playerBId),
            _scoreSubtitle(l10n, scoreAfter, turn),
          ]),
          detail: signedDelta(delta),
          delta: delta,
        ),
      DiplomaticPromiseBrokenEvent(
        :final playerAId,
        :final playerBId,
        :final delta,
        :final scoreAfter,
      ) =>
        DiplomacyHistoryText(
          title: scoreReasonLabel(
            l10n,
            DiplomaticScoreChangeReason.promiseBroken,
          ),
          subtitle: _joinParts([
            relationPairLabel(playerNameFor, playerAId, playerBId),
            _scoreSubtitle(l10n, scoreAfter, turn),
          ]),
          detail: signedDelta(delta),
          delta: delta,
        ),
      _ => throw ArgumentError.value(
        event,
        'event',
        'Expected diplomacy event',
      ),
    };
  }

  static String directionLabel(
    String Function(String playerId) playerNameFor,
    String fromPlayerId,
    String toPlayerId,
  ) {
    return '${playerNameFor(fromPlayerId)} -> ${playerNameFor(toPlayerId)}';
  }

  static String relationPairLabel(
    String Function(String playerId) playerNameFor,
    String playerAId,
    String playerBId,
  ) {
    return '${playerNameFor(playerAId)} / ${playerNameFor(playerBId)}';
  }

  static String turnRangeLabel(
    AppLocalizations l10n,
    int? startTurn,
    int? endTurn,
  ) {
    if (startTurn == null) return '';
    final start = l10n.topResourceTurnShortLabel(startTurn);
    if (endTurn == null || endTurn == startTurn) return start;
    return '$start -> ${l10n.topResourceTurnShortLabel(endTurn)}';
  }

  static String messageTopicLabel(
    AppLocalizations l10n,
    DiplomaticMessageTopic topic,
  ) {
    return switch (topic) {
      DiplomaticMessageTopic.troopsNearCities =>
        l10n.diplomacyMessageTroopsNearCities,
      DiplomaticMessageTopic.citiesTooClose =>
        l10n.diplomacyMessageCitiesTooClose,
      DiplomaticMessageTopic.blockedRoutes =>
        l10n.diplomacyMessageBlockedRoutes,
      DiplomaticMessageTopic.withdrawScouts =>
        l10n.diplomacyMessageWithdrawScouts,
      DiplomaticMessageTopic.avoidEscalation =>
        l10n.diplomacyMessageAvoidEscalation,
      DiplomaticMessageTopic.commonEnemy => l10n.diplomacyMessageCommonEnemy,
      DiplomaticMessageTopic.expansionProvocation =>
        l10n.diplomacyMessageExpansionProvocation,
      DiplomaticMessageTopic.peacefulPraise =>
        l10n.diplomacyMessagePeacefulPraise,
    };
  }

  static String messageResponseLabel(
    AppLocalizations l10n,
    DiplomaticMessageResponse response,
  ) {
    return switch (response) {
      DiplomaticMessageResponse.conciliatory =>
        l10n.diplomacyResponseConciliatory,
      DiplomaticMessageResponse.neutral => l10n.diplomacyResponseNeutral,
      DiplomaticMessageResponse.evasive => l10n.diplomacyResponseEvasive,
      DiplomaticMessageResponse.aggressive => l10n.diplomacyResponseAggressive,
    };
  }

  static String messageResponseDetail(
    AppLocalizations l10n,
    DiplomaticMessageResponse response,
    int relationScoreDelta,
  ) {
    return '${messageResponseLabel(l10n, response)} '
        '(${signedDelta(relationScoreDelta)})';
  }

  static String proposalKindLabel(
    AppLocalizations l10n,
    DiplomaticProposalKind kind,
  ) {
    return switch (kind) {
      DiplomaticProposalKind.friendship => l10n.diplomacyProposalFriendship,
      DiplomaticProposalKind.truce => l10n.diplomacyProposalTruce,
    };
  }

  static String scoreReasonLabel(
    AppLocalizations l10n,
    DiplomaticScoreChangeReason reason,
  ) {
    return switch (reason) {
      DiplomaticScoreChangeReason.manual => l10n.diplomacyScoreReasonManual,
      DiplomaticScoreChangeReason.unitAttack =>
        l10n.diplomacyScoreReasonUnitAttack,
      DiplomaticScoreChangeReason.cityAttack =>
        l10n.diplomacyScoreReasonCityAttack,
      DiplomaticScoreChangeReason.declarationOfWar =>
        l10n.diplomacyScoreReasonDeclarationOfWar,
      DiplomaticScoreChangeReason.warmongerPenalty =>
        l10n.diplomacyScoreReasonWarmongerPenalty,
      DiplomaticScoreChangeReason.proposalAccepted =>
        l10n.diplomacyScoreReasonProposalAccepted,
      DiplomaticScoreChangeReason.proposalRejected =>
        l10n.diplomacyScoreReasonProposalRejected,
      DiplomaticScoreChangeReason.messageResponse =>
        l10n.diplomacyScoreReasonMessageResponse,
      DiplomaticScoreChangeReason.commonEnemyCooperation =>
        l10n.diplomacyScoreReasonCommonEnemyCooperation,
      DiplomaticScoreChangeReason.promiseBroken =>
        l10n.diplomacyScoreReasonPromiseBroken,
    };
  }

  static String relationStatusLabel(
    AppLocalizations l10n,
    DiplomaticRelationStatus status,
  ) {
    return DiplomacyDisplayNames.relation(l10n, status);
  }

  static String signedDelta(int delta) => delta > 0 ? '+$delta' : '$delta';

  static String _scoreSubtitle(AppLocalizations l10n, int score, int? turn) {
    return _joinParts([
      '${l10n.diplomacyScoreLabel}: $score',
      if (turn != null) l10n.topResourceTurnShortLabel(turn),
    ]);
  }

  static String _joinParts(Iterable<String?> parts) {
    return parts
        .where((part) => part != null && part.isNotEmpty)
        .cast<String>()
        .join(' · ');
  }
}
