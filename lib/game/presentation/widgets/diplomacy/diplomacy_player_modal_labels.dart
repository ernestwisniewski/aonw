part of 'diplomacy_player_modal.dart';

String _topicLabel(AppLocalizations l10n, DiplomaticMessageTopic topic) {
  return DiplomacyHistoryPresenter.messageTopicLabel(l10n, topic);
}

String _responseLabel(
  AppLocalizations l10n,
  DiplomaticMessageResponse response,
) {
  return DiplomacyHistoryPresenter.messageResponseLabel(l10n, response);
}

String _proposalLabel(AppLocalizations l10n, DiplomaticProposalKind kind) {
  return DiplomacyHistoryPresenter.proposalKindLabel(l10n, kind);
}

String _scoreReasonLabel(
  AppLocalizations l10n,
  DiplomaticScoreChangeReason reason,
) {
  return DiplomacyHistoryPresenter.scoreReasonLabel(l10n, reason);
}
