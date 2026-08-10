part of 'game_event_notification_message.dart';

bool _isDiplomacyHistoryEvent(GameEvent event) {
  return switch (event) {
    DiplomaticProposalSentEvent() ||
    DiplomaticProposalRespondedEvent() ||
    DiplomaticProposalExpiredEvent() ||
    DiplomaticRelationChangedEvent() ||
    DiplomaticMessageSentEvent() ||
    DiplomaticMessageRespondedEvent() ||
    DiplomaticScoreChangedEvent() ||
    DiplomaticPromiseBrokenEvent() => true,
    _ => false,
  };
}

GameEventNotificationMessage _diplomacyHistoryMessage({
  required AppLocalizations l10n,
  required GameEventNotification notification,
  required _GameEventPlayerRoster? roster,
}) {
  final event = notification.event;
  final text = DiplomacyHistoryPresenter.event(
    l10n,
    event,
    turn: notification.turn,
    playerNameFor: (playerId) => _playerName(l10n, roster, playerId),
  );
  final details = <String>[
    if (text.detail != null) text.detail!,
    if (text.detail == null && text.delta != null)
      DiplomacyHistoryPresenter.signedDelta(text.delta!),
  ];
  return GameEventNotificationMessage(
    title: text.title,
    body: text.subtitle,
    details: details,
    thumbnail: _diplomacyThumbnail(event),
  );
}

GameEventNotificationThumbnail _diplomacyThumbnail(GameEvent event) {
  return switch (event) {
    DiplomaticProposalRespondedEvent() ||
    DiplomaticProposalExpiredEvent() ||
    DiplomaticPromiseBrokenEvent() ||
    DiplomaticRelationChangedEvent() => _diplomacyStateThumbnail(event),
    DiplomaticMessageRespondedEvent() ||
    DiplomaticScoreChangedEvent() => _diplomacyDeltaThumbnail(event),
    _ => const IconEventNotificationThumbnail(
      EventNotificationIconThumbnailKind.civilization,
    ),
  };
}

GameEventNotificationThumbnail _diplomacyStateThumbnail(GameEvent event) {
  final kind = switch (event) {
    DiplomaticProposalRespondedEvent(:final accepted) =>
      accepted
          ? EventNotificationIconThumbnailKind.success
          : EventNotificationIconThumbnailKind.warning,
    DiplomaticProposalExpiredEvent() || DiplomaticPromiseBrokenEvent() =>
      EventNotificationIconThumbnailKind.warning,
    DiplomaticRelationChangedEvent(:final newStatus) =>
      newStatus == DiplomaticRelationStatus.war
          ? EventNotificationIconThumbnailKind.warning
          : EventNotificationIconThumbnailKind.civilization,
    _ => EventNotificationIconThumbnailKind.civilization,
  };
  return IconEventNotificationThumbnail(kind);
}

GameEventNotificationThumbnail _diplomacyDeltaThumbnail(GameEvent event) {
  final delta = switch (event) {
    DiplomaticMessageRespondedEvent(:final relationDelta) => relationDelta,
    DiplomaticScoreChangedEvent(:final delta) => delta,
    _ => 0,
  };
  return IconEventNotificationThumbnail(
    delta >= 0
        ? EventNotificationIconThumbnailKind.success
        : EventNotificationIconThumbnailKind.warning,
  );
}

GameEventNotificationMessage _civilizationMetMessage({
  required AppLocalizations l10n,
  required _GameEventPlayerRoster? roster,
  required GameClientState state,
  required String metPlayerId,
}) {
  final country = _playerCountry(roster, state, metPlayerId);
  final civilizationName = GameDisplayNames.playerCountry(l10n, country);
  final leaderName = GameDisplayNames.playerCountryLeader(l10n, country);
  return GameEventNotificationMessage(
    title: l10n.eventCivilizationMetTitle,
    body: l10n.eventCivilizationMetBody(
      civilizationName,
      _playerName(l10n, roster, metPlayerId),
    ),
    details: [leaderName],
    thumbnail: const IconEventNotificationThumbnail(
      EventNotificationIconThumbnailKind.civilization,
    ),
  );
}
